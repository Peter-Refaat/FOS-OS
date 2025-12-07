#include "kheap.h"

#include <inc/dynamic_allocator.h>
#include <kern/conc/sleeplock.h>
#include <kern/proc/user_environment.h>
#include <kern/mem/memory_manager.h>
#include "../conc/kspinlock.h"
#include "lazy_segment_tree.h"

struct klist{
	uint32 start_va;
	uint32 size_pages;
	LIST_ENTRY(klist) prev_next_info;
};

LIST_HEAD(klist_head,klist);

struct klist_head virt_addr_of_size[NUM_OF_SEG_KHEAP_PAGES];
struct klist* node_of_start_page[NUM_OF_SEG_KHEAP_PAGES];
uint32 allocated_pages_PBA[NUM_OF_SEG_KHEAP_PAGES];

struct sleeplock Kheap_sleep_lock;


//==================================================================================//
//============================== GIVEN FUNCTIONS ===================================//
//==================================================================================//

//==============================================
// [1] INITIALIZE KERNEL HEAP:
//==============================================
//TODO: [PROJECT'25.GM#2] KERNEL HEAP - #0 kheap_init [GIVEN]
//Remember to initialize locks (if any)
void kheap_init()
{
	//==================================================================================
	//DON'T CHANGE THESE LINES==========================================================
	//==================================================================================
	{
		initialize_dynamic_allocator(KERNEL_HEAP_START, KERNEL_HEAP_START + DYN_ALLOC_MAX_SIZE);
		set_kheap_strategy(KHP_PLACE_CUSTOMFIT);
		kheapPageAllocStart = dynAllocEnd + PAGE_SIZE;
		kheapPageAllocBreak = kheapPageAllocStart;
		// for fast implementations
		build_seg_tree();
		for(int i = 0 ; i < NUM_OF_SEG_KHEAP_PAGES; ++i)
		{
			LIST_INIT(&(virt_addr_of_size[i]));
			allocated_pages_PBA[i] = 0;
			node_of_start_page[i] = NULL;
		}
		init_sleeplock(&Kheap_sleep_lock, "Kernel Heap Sleep Lock");

	}
	//==================================================================================
	//==================================================================================
}

//==============================================
// [2] GET A PAGE FROM THE KERNEL FOR DA:
//==============================================
int get_page(void* va)
{
	int ret = alloc_page(ptr_page_directory, ROUNDDOWN((uint32)va, PAGE_SIZE), PERM_WRITEABLE, 1);
	if (ret < 0)
		panic("get_page() in kern: failed to allocate page from the kernel");
	return 0;
}

//==============================================
// [3] RETURN A PAGE FROM THE DA TO KERNEL:
//==============================================
void return_page(void* va)
{
	unmap_frame(ptr_page_directory, ROUNDDOWN((uint32)va, PAGE_SIZE));
}


//==============================================
// HELPER FAST KERN FUNCTIONS:
//==============================================

void add_free_page_block(uint32 start_page_idx, uint32 num_pages)
{
    if(num_pages == 0 || num_pages > NUM_OF_SEG_KHEAP_PAGES)
        return;

    // Should not already have a free block here
    if (node_of_start_page[start_page_idx] != NULL)
        return;

    struct klist* node = (struct klist*)alloc_block(sizeof(struct klist));
    node->start_va = kheapPageAllocStart + (start_page_idx << PTXSHIFT);
    node->size_pages = num_pages;

    LIST_INSERT_HEAD(&(virt_addr_of_size[num_pages]), node);
    node_of_start_page[start_page_idx] = node;
}


void remove_free_block(uint32 start_page_idx, uint32 block_size)
{
    if (block_size == 0 || block_size > NUM_OF_SEG_KHEAP_PAGES)
        return;

    if (start_page_idx >= NUM_OF_SEG_KHEAP_PAGES)
        return;

    struct klist* node = node_of_start_page[start_page_idx];
    if (node != NULL)
    {
        if (node->size_pages != block_size) {
            panic("remove_free_block: size mismatch at page %u", start_page_idx);
        }

        LIST_REMOVE(&virt_addr_of_size[block_size], node);
        node_of_start_page[start_page_idx] = NULL;
        free_block(node);
    }
}


//==================================================================================//
//============================ REQUIRED FUNCTIONS ==================================//
//==================================================================================//
//===================================
// [1] ALLOCATE SPACE IN KERNEL HEAP:
//===================================
void* kmalloc(unsigned int size)
{
	//TODO: [PROJECT'25.GM#2] KERNEL HEAP - #1 kmalloc
	//Your code is here
	//Comment the following line
	// kpanic_into_prompt("kmalloc() is not implemented yet...!!");
	//TODO: [PROJECT'25.BONUS#3] FAST PAGE ALLOCATOR

#if FASTKHEAP
	/* block allocation*/
//	cprintf("FAST IMPLEMENTATION  KMALLOC YA MAN\n");
		if(size <= DYN_ALLOC_MAX_BLOCK_SIZE)
		{
			return alloc_block(size);
		}

		acquire_sleeplock(&Kheap_sleep_lock);
		size = ROUNDUP(size,PAGE_SIZE);
		uint32 num_of_pages = (size >> PTXSHIFT);

		/* Try best fit */
		if(!LIST_EMPTY(&(virt_addr_of_size[num_of_pages])))
		{
			struct klist* lst = LIST_FIRST(&virt_addr_of_size[num_of_pages]);
			uint32 start_va = lst->start_va;
			uint32 start_page = GET_KHEAP_PAGE_OF(start_va);
			for(uint32 i = 0 ; i < num_of_pages ; ++i)
			{
				alloc_page(ptr_page_directory, start_va + (i << PTXSHIFT), PERM_PRESENT | PERM_WRITEABLE, 1);
				allocated_pages_PBA[start_page + i] = num_of_pages;
			}
			update_pages_state(start_page , start_page + num_of_pages - 1, 0);
			remove_free_block(start_page,num_of_pages);
			release_sleeplock(&Kheap_sleep_lock);
			return (void*)start_va;
		}

		/* Try worst fit */
		struct queryNode ret = get_worst_fit(num_of_pages);
		if(ret.start != -1 && ret.end != -1)
		{
			uint32 sz = ret.end - ret.start + 1;

			struct klist* node = node_of_start_page[ret.start];
			remove_free_block(ret.start,sz);
			for(uint32 i = 0; i < num_of_pages; i++)
			{
				alloc_page(ptr_page_directory,
						   kheapPageAllocStart + ((ret.start + i) << PTXSHIFT),
						   PERM_PRESENT | PERM_WRITEABLE, 1);
				allocated_pages_PBA[ret.start + i] = num_of_pages;
			}
			update_pages_state(ret.start, ret.start + num_of_pages - 1, 0);
			uint32 rem = sz - num_of_pages;
			uint32 left_start = ret.start + num_of_pages;
			add_free_page_block(left_start, rem);
			update_pages_state(left_start, ret.end, 1);
			release_sleeplock(&Kheap_sleep_lock);
			return (void*)(kheapPageAllocStart + (ret.start << PTXSHIFT));
		}

		/* try to extend kheapPageAllocBreak */
		if(kheapPageAllocBreak <= KERNEL_HEAP_MAX - size)
		{
			uint32 start_address_to_be_allocated = kheapPageAllocBreak;
			kheapPageAllocBreak += size;

			for(uint32 i = 0 ; i < num_of_pages ; ++i)
			{
				alloc_page(ptr_page_directory, start_address_to_be_allocated + (i << PTXSHIFT), PERM_PRESENT | PERM_WRITEABLE, 1);
				allocated_pages_PBA[GET_KHEAP_PAGE_OF(start_address_to_be_allocated + (i << PTXSHIFT))] = num_of_pages;
			}
			release_sleeplock(&Kheap_sleep_lock);
			return (void*) start_address_to_be_allocated;
		}
		release_sleeplock(&Kheap_sleep_lock);
		return NULL;

#else
	/* block allocation*/
	if(size <= DYN_ALLOC_MAX_BLOCK_SIZE)
	{
		return alloc_block(size);
	}

	acquire_sleeplock(&Kheap_sleep_lock);
	size = ROUNDUP(size,PAGE_SIZE);
	uint32 num_of_pages = (size >> PTXSHIFT);

	/* try exact fit */
	uint32 left = kheapPageAllocStart;
	uint32 right = kheapPageAllocStart;
	uint32 counter = 0;
	uint32 start_address_to_be_allocated = 0;
	bool found = 0;

	while(left < kheapPageAllocBreak)
	{
		if (right < left)
		    right = left;

		uint32 *ptr_page_table = NULL;
		struct FrameInfo* ret = get_frame_info(ptr_page_directory, right, &ptr_page_table);

		while(right < kheapPageAllocBreak && counter < num_of_pages && ret == NULL)
		{
			counter++;
			right += PAGE_SIZE;
			ret = get_frame_info(ptr_page_directory, right, &ptr_page_table);
		}

		if(counter == num_of_pages)
		{
			bool left_allocated = 1;
			bool right_allocated = 1;
			struct FrameInfo* left_alloc = NULL;
			struct FrameInfo* right_alloc = NULL;

			if(left != kheapPageAllocStart)
				left_alloc = get_frame_info(ptr_page_directory, (left - PAGE_SIZE), &ptr_page_table);

			if(right != kheapPageAllocBreak)
				right_alloc = get_frame_info(ptr_page_directory, right, &ptr_page_table);

			if(left_alloc == NULL)
			{
				left_allocated = 0;
			}

			if(right_alloc == NULL)
			{
				right_allocated = 0;
			}

			if(left_allocated != 0 && right_allocated != 0)
			{
				start_address_to_be_allocated = left;
				found = 1;
				break;
			}
		}
		struct FrameInfo* left_alloc = get_frame_info(ptr_page_directory, left, &ptr_page_table);
		counter -= (left_alloc == NULL); // decrement counter if free
		left += PAGE_SIZE;
	}

	if(found == 1)
	{
		for(uint32 i = 0 ; i < num_of_pages ; ++i)
		{
			alloc_page(ptr_page_directory, start_address_to_be_allocated + (i << PTXSHIFT), PERM_PRESENT | PERM_WRITEABLE, 1);
			allocated_pages_PBA[GET_KHEAP_PAGE_OF(start_address_to_be_allocated + (i << PTXSHIFT))] = -1;
		}
		allocated_pages_PBA[GET_KHEAP_PAGE_OF(start_address_to_be_allocated)] = (size >> PTXSHIFT);
		release_sleeplock(&Kheap_sleep_lock);
		return (void*) start_address_to_be_allocated;
	}

	/* try worst fit */
	uint32 max = 0;
	left = kheapPageAllocStart;
	right = kheapPageAllocStart;
	counter = 0;
	start_address_to_be_allocated = 0;

	while(left < kheapPageAllocBreak)
		{
			if (right < left)
				right = left;

			uint32 *ptr_page_table = NULL;
			struct FrameInfo* left_alloc = get_frame_info(ptr_page_directory, left, &ptr_page_table);
			if(left_alloc != NULL)
			{
				left += PAGE_SIZE;
				continue;
			}

			struct FrameInfo* ret = get_frame_info(ptr_page_directory, right, &ptr_page_table);
			while(right < kheapPageAllocBreak && ret == NULL)
			{
					counter++;
					right += PAGE_SIZE;
					ret = get_frame_info(ptr_page_directory, right, &ptr_page_table);
			}

			if(counter > max)
			{
				max = counter;
				start_address_to_be_allocated = left;
			}

			left = right;
			counter = 0;
		}

	if(max >= num_of_pages)
	{
		for(uint32 i = 0 ; i < num_of_pages ; ++i)
		{
			alloc_page(ptr_page_directory, start_address_to_be_allocated + (i << PTXSHIFT), PERM_PRESENT | PERM_WRITEABLE, 1);
			allocated_pages_PBA[GET_KHEAP_PAGE_OF(start_address_to_be_allocated + (i << PTXSHIFT))] = -1;
		}
		allocated_pages_PBA[GET_KHEAP_PAGE_OF(start_address_to_be_allocated)] = (size >> PTXSHIFT);
		release_sleeplock(&Kheap_sleep_lock);
		return (void*) start_address_to_be_allocated;
	}

	/* try to extend kheapPageAllocBreak */
	if(kheapPageAllocBreak <= KERNEL_HEAP_MAX - size)
	{
		start_address_to_be_allocated = kheapPageAllocBreak;
		kheapPageAllocBreak += size;

		for(uint32 i = 0 ; i < num_of_pages ; ++i)
		{
			alloc_page(ptr_page_directory, start_address_to_be_allocated + (i << PTXSHIFT), PERM_PRESENT | PERM_WRITEABLE, 1);
			allocated_pages_PBA[GET_KHEAP_PAGE_OF(start_address_to_be_allocated + (i << PTXSHIFT))] = -1;
		}
		allocated_pages_PBA[GET_KHEAP_PAGE_OF(start_address_to_be_allocated)] = (size >> PTXSHIFT);
		release_sleeplock(&Kheap_sleep_lock);
		return (void*) start_address_to_be_allocated;
	}
	release_sleeplock(&Kheap_sleep_lock);
	return NULL;
#endif
}

//=================================
// [2] FREE SPACE FROM KERNEL HEAP:
//=================================
void kfree(void* virtual_address)
{
	//TODO: [PROJECT'25.GM#2] KERNEL HEAP - #2 kfree
	//Your code is here
	//Comment the following line
	// panic("kfree() is not implemented yet...!!");

#if FASTKHEAP
//	cprintf("FAST IMPLEMENTATION  KFREE YA MAN\n");
	uint32 va = ROUNDDOWN((uint32)virtual_address, PAGE_SIZE);

		/* Block allocator */
		if(va >= dynAllocStart && va < dynAllocEnd)
		{
			free_block(virtual_address);
			return;
		}

		acquire_sleeplock(&Kheap_sleep_lock);
		/* Page allocator */
		if(va >= kheapPageAllocStart && va < kheapPageAllocBreak)
		{
			uint32 page_idx = GET_KHEAP_PAGE_OF(va);
			uint32 size = allocated_pages_PBA[page_idx];

			if (size == 0) {
				panic("kfree: Double free at page %u", page_idx);
			}

			// 1. Unmap physical pages and mark as free
			for(uint32 i = 0; i < size; i++)
			{
				return_page((void*)(va + (i << PTXSHIFT)));
				allocated_pages_PBA[page_idx + i] = 0;
			}

			// 2. Find merge boundaries
			uint32 break_idx = GET_KHEAP_PAGE_OF(kheapPageAllocBreak);
			uint32 merged_start = page_idx;
			uint32 merged_end = page_idx + size;  // one past the last freed page

			// Merge DOWN (find start of contiguous free region)
			while(merged_start > 0 && allocated_pages_PBA[merged_start - 1] == 0)
			{
				merged_start--;
			}

			// Merge UP (find end of contiguous free region)
			while(merged_end < break_idx && allocated_pages_PBA[merged_end] == 0)
			{
				merged_end++;
			}

			// 3. Remove old free blocks that will be merged
			// Remove DOWN neighbor if it exists
			if(merged_start < page_idx)
			{
	//			struct klist* down_node = node_of_start_page[merged_start];
	//			if(down_node != NULL)
	//			{
					uint32 down_size = page_idx - merged_start;
					remove_free_block(merged_start, down_size);
	//			}
			}

			// Remove UP neighbor if it exists
			if(merged_end > page_idx + size)
			{
	//			struct klist* up_node = node_of_start_page[page_idx + size];
	//			if(up_node != NULL)
	//			{
					uint32 up_size = merged_end - (page_idx + size);
					remove_free_block(page_idx + size, up_size);
	//			}
			}

			// 4. Handle the merged block
			uint32 total_size = merged_end - merged_start;

			// If merged block reaches the break, shrink the heap
			if(merged_end == break_idx)
			{
				update_pages_state(merged_start, merged_end - 1, 0);
				kheapPageAllocBreak = KERNEL_HEAP_START + DYN_ALLOC_MAX_SIZE + PAGE_SIZE + (merged_start << PTXSHIFT);
			}
			else
			{
				// Add as new free block
				update_pages_state(merged_start, merged_end - 1, 1);
				add_free_page_block(merged_start, total_size);
			}
			release_sleeplock(&Kheap_sleep_lock);
			return;
		}

		panic("kfree: Invalid virtual address %x", va);


#else
	acquire_sleeplock(&Kheap_sleep_lock);
	uint32 va = ROUNDDOWN((uint32)virtual_address, PAGE_SIZE);
	uint32 size;

	/* Check if the given virtual address is in page allocator */
	if( (va >= kheapPageAllocStart && va < kheapPageAllocBreak) && allocated_pages_PBA[GET_KHEAP_PAGE_OF(va)] != 0)
	{
		size = allocated_pages_PBA[GET_KHEAP_PAGE_OF(va)];

		for(uint32 i = 0; i < size; i++)
		{
			return_page((void*)(va + (i << PTXSHIFT)));
			allocated_pages_PBA[GET_KHEAP_PAGE_OF(va + (i << PTXSHIFT))] = 0;
		}

		// check if the break needs to be reduced
		while(allocated_pages_PBA[GET_KHEAP_PAGE_OF(kheapPageAllocBreak - PAGE_SIZE)] == 0)
		{
			kheapPageAllocBreak -= PAGE_SIZE;
		}
		release_sleeplock(&Kheap_sleep_lock);
		return;
	}

	/* Check if the given virtual address is in block allocator */
	else if((va >= dynAllocStart && va < dynAllocEnd))
	{
		free_block(virtual_address);
		return;
	}
#endif

}

//=================================
// [3] FIND VA OF GIVEN PA:
//=================================
unsigned int kheap_virtual_address(unsigned int physical_address)
{
	//TODO: [PROJECT'25.GM#2] KERNEL HEAP - #3 kheap_virtual_address
	//Your code is here
	//Comment the following line
//	panic("kheap_virtual_address() is not implemented yet...!!");
	struct FrameInfo* fi = to_frame_info(physical_address);
	if(fi == NULL || fi->references == 0 || fi->virt == 0)
		return 0;
	return (fi->virt | (physical_address & 0x00000FFF));
	/*EFFICIENT IMPLEMENTATION ~O(1) IS REQUIRED */
}

//=================================
// [4] FIND PA OF GIVEN VA:
//=================================
unsigned int kheap_physical_address(unsigned int virtual_address)
{
	//TODO: [PROJECT'25.GM#2] KERNEL HEAP - #4 kheap_physical_address
	//Return the physical address mapped to the given kernel heap virtual address.
	//If the page table does not exist or the page is not present, return 0.

	uint32* ptr_page_table = NULL;
	int ret = get_page_table(ptr_page_directory, virtual_address,&ptr_page_table);

	if (ret == TABLE_NOT_EXIST)
		return 0;

	uint32 PTE = ptr_page_table[PTX(virtual_address)];

    if (!(PTE & PERM_PRESENT))
        return 0;

	uint32 frame_number_physical_address = PTE & 0xFFFFF000;
	uint32 offset = virtual_address & 0x00000FFF;

	return ((frame_number_physical_address) | offset);
	/*EFFICIENT IMPLEMENTATION ~O(1) IS REQUIRED */
}

//=================================================================================//
//============================== BONUS FUNCTION ===================================//
//=================================================================================//
// krealloc():

//	Attempts to resize the allocated space at "virtual_address" to "new_size" bytes,
//	possibly moving it in the heap.
//	If successful, returns the new virtual_address, in which case the old virtual_address must no longer be accessed.
//	On failure, returns a null pointer, and the old virtual_address remains valid.

//	A call with virtual_address = null is equivalent to kmalloc().
//	A call with new_size = zero is equivalent to kfree().

extern __inline__ uint32 get_block_size(void *va);

void *krealloc(void *virtual_address, uint32 new_size)
{
	//TODO: [PROJECT'25.BONUS#2] KERNEL REALLOC - krealloc
	//Your code is here
	//Comment the following line
	//panic("krealloc() is not implemented yet...!!");

	uint32 va = ROUNDDOWN((uint32)virtual_address, PAGE_SIZE);
	new_size = ROUNDUP(new_size,PAGE_SIZE);
	uint32 num_of_old_pages = allocated_pages_PBA[GET_KHEAP_PAGE_OF(va)];
	uint32 old_size = num_of_old_pages << PTXSHIFT;
	uint32 new_virtual_address = 0;

	/* If it's in Page Allocator Range */
	if(va >= kheapPageAllocStart && va < kheapPageAllocBreak)
	{

		acquire_sleeplock(&Kheap_sleep_lock);
		/* Check if the virtual_address = NULL then kmalloc */
		if (virtual_address == NULL)
		{
			release_sleeplock(&Kheap_sleep_lock);
			return kmalloc(new_size);
		}

		/* Check if the new_size = 0 then free */
		if (new_size == 0)
		{
			kfree(virtual_address);
			release_sleeplock(&Kheap_sleep_lock);
			return NULL;
		}

		/* if the same size then return */
		if (new_size == old_size)
		{
			release_sleeplock(&Kheap_sleep_lock);
			return virtual_address;
		}

		/* Check if the new size is less than the old size */
		if(new_size < old_size)
		{
			/* If cross alocation page -> block */
			if (new_size <= DYN_ALLOC_MAX_BLOCK_SIZE)
			{
				new_virtual_address = (uint32)alloc_block(new_size);
				memmove((void *)new_virtual_address, (void *)virtual_address, new_size);
				kfree(virtual_address);
				release_sleeplock(&Kheap_sleep_lock);
				return (void*)new_virtual_address;
			}

			/* Free till we reach the new_size but still in page allocator */
			else
			{
				uint32 size_to_be_free = old_size - new_size;
				kfree((void*)va + old_size - size_to_be_free);
				allocated_pages_PBA[GET_KHEAP_PAGE_OF(va)]= (new_size >> PTXSHIFT);
				release_sleeplock(&Kheap_sleep_lock);
				return virtual_address;
			}
		}
		else
		{
			/* Check if there is a space for the new size above the allocated space and within kheapPageAllocStart - kheapPageAllocBreak range */
			if(va <= kheapPageAllocBreak - new_size)
			{

				uint32 num_of_new_pages = (new_size >> PTXSHIFT) - num_of_old_pages;
				bool can_be_alloc = 1;

				// check if this space is free
				for(int i = 0; i < num_of_new_pages; i++) //
				{
					if(allocated_pages_PBA[GET_KHEAP_PAGE_OF(va + ((num_of_old_pages + i) << PTXSHIFT))] != 0)
					{
						can_be_alloc = 0;
						break;
					}
				}

				// if free then extend
				if(can_be_alloc == 1)
				{
					for(int i = 0; i < num_of_new_pages; i++)
					{
						alloc_page(ptr_page_directory, va + old_size + (i << PTXSHIFT), PERM_PRESENT | PERM_WRITEABLE, 1);
						allocated_pages_PBA[GET_KHEAP_PAGE_OF(va + old_size + (i << PTXSHIFT))] = (new_size >> PTXSHIFT);
					}
					uint32 old_last_page = GET_KHEAP_PAGE_OF(va + ((num_of_old_pages - 1) << PTXSHIFT));
					uint32 new_last_page = GET_KHEAP_PAGE_OF(va + ((num_of_new_pages + num_of_old_pages - 1) << PTXSHIFT));
					update_pages_state(old_last_page, new_last_page, 0);
					uint32 old_last_page_sizes = node_of_start_page[old_last_page]->size_pages;
					remove_free_block(old_last_page, old_last_page_sizes);
					add_free_page_block(new_last_page, GET_KHEAP_PAGE_OF(node_of_start_page[new_last_page]->start_va) - num_of_new_pages + old_last_page_sizes);

					allocated_pages_PBA[GET_KHEAP_PAGE_OF(va)] += num_of_new_pages;
					release_sleeplock(&Kheap_sleep_lock);
					return (void*)va;
				}

				/* try to extend kheapPageAllocBreak */
				if(kheapPageAllocBreak <= KERNEL_HEAP_MAX - new_size)
				{
					uint32 start_address_to_be_allocated = kheapPageAllocBreak;
					kheapPageAllocBreak += new_size;

					for(uint32 i = 0 ; i < num_of_new_pages ; ++i)
					{
						alloc_page(ptr_page_directory, start_address_to_be_allocated + (i << PTXSHIFT), PERM_PRESENT | PERM_WRITEABLE, 1);
						allocated_pages_PBA[GET_KHEAP_PAGE_OF(start_address_to_be_allocated + (i << PTXSHIFT))] = num_of_new_pages;
					}
					release_sleeplock(&Kheap_sleep_lock);
					return (void*) start_address_to_be_allocated;
				}
			}
		}

		/* Try to reallocate the space with the new size using a new chunk */
		new_virtual_address = (uint32)kmalloc(new_size);

		// if successfully reallocated copy content to the new chunk and free the old chunk
		if (new_virtual_address != (uint32)NULL)
		{
			memmove((void *)new_virtual_address, (void *)virtual_address, (num_of_old_pages << PTXSHIFT));
			kfree(virtual_address);
			release_sleeplock(&Kheap_sleep_lock);
			return (void*) new_virtual_address;
		}
	}

	/* If it is in block allocator range */
		else if (va >= KERNEL_HEAP_START && va < dynAllocEnd)
		{
			/* Check if the virtual_address = NULL then alloc_block */
			if (virtual_address == NULL)
				return alloc_block(new_size);

			/* Check if the new_size = 0 then free */
			if (new_size == 0)
			{
				free_block(virtual_address);
				return NULL;
			}

			/* if the same size then return */
			if (new_size == get_block_size(virtual_address))
				return virtual_address;

			/* If cross allocation block -> page */
			if (new_size > DYN_ALLOC_MAX_BLOCK_SIZE)
			{
				new_virtual_address = (uint32)kmalloc(new_size);

				// if successfully reallocated copy content to the new chunk and free the old chunk
				if (new_virtual_address != (uint32)NULL)
				{
					memmove((void *)new_virtual_address, (void *)virtual_address, get_block_size(virtual_address));
					free_block(virtual_address);
				}
				return (void *)new_virtual_address;
			}

			/* Check if the new size is less than the old size */
			if (new_size < get_block_size(virtual_address))
			{
				/* Free size to get the new_size */
				uint32 virtaddr_to_be_free = (uint32)virtual_address + new_size + 1;
				free_block((void *)virtaddr_to_be_free);
				return virtual_address;
			}
		}

	return (void *)new_virtual_address;
}
