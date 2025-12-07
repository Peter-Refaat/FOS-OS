#include <inc/lib.h>
#define TABLE_IN_MEMORY 0
#define TABLE_NOT_EXIST 1
//==================================================================================//
//============================== GIVEN FUNCTIONS ===================================//
//==================================================================================//

struct PageAlloc {
    uint32 start_va;
    uint32 size;
    LIST_ENTRY(PageAlloc) prev_next_info;
};

LIST_HEAD(PageAllocList, PageAlloc);
struct PageAllocList alloc_list_PBA;

//==============================================
// [1] INITIALIZE USER HEAP:
//==============================================
int __firstTimeFlag = 1;
void uheap_init()
{
	if(__firstTimeFlag)
	{
		initialize_dynamic_allocator(USER_HEAP_START, USER_HEAP_START + DYN_ALLOC_MAX_SIZE);
		uheapPlaceStrategy = sys_get_uheap_strategy();

		uheapPageAllocStart = dynAllocEnd + PAGE_SIZE;
		uheapPageAllocBreak = uheapPageAllocStart;

		LIST_INIT(&alloc_list_PBA);
		__firstTimeFlag = 0;
	}
}

//==============================================
// [2] GET A PAGE FROM THE KERNEL FOR DA:
//==============================================
int get_page(void* va)
{
	int ret = __sys_allocate_page(ROUNDDOWN(va, PAGE_SIZE), PERM_USER|PERM_WRITEABLE|PERM_UHPAGE);
	if (ret < 0)
		panic("get_page() in user: failed to allocate page from the kernel");
	return 0;
}

//==============================================
// [3] RETURN A PAGE FROM THE DA TO KERNEL:
//==============================================
void return_page(void* va)
{
	int ret = __sys_unmap_frame(ROUNDDOWN((uint32)va, PAGE_SIZE));
	if (ret < 0)
		panic("return_page() in user: failed to return a page to the kernel");
}

//==================================================================================//
//============================ REQUIRED FUNCTIONS ==================================//
//==================================================================================//



// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

void add_alloc(uint32 start_va, uint32 size)
{
    struct PageAlloc *new_node = (struct PageAlloc*)alloc_block(sizeof(struct PageAlloc));
    if (!new_node)
        panic("add_allocation: failed to allocate node");

    new_node->start_va = start_va;
    new_node->size = size;

    //insert first node
    if (LIST_SIZE(&alloc_list_PBA) == 0) {
        LIST_INSERT_HEAD(&alloc_list_PBA, new_node);
        return;
    }
    //insert at head if new address is smaller
    struct PageAlloc *first = LIST_FIRST(&alloc_list_PBA);
    if (first->start_va > start_va) {
        LIST_INSERT_HEAD(&alloc_list_PBA, new_node);
        return;
    }
    //insert in middle or end
    struct PageAlloc *current;
    LIST_FOREACH(current, &alloc_list_PBA) {
        struct PageAlloc *next = LIST_NEXT(current);
        if (next == NULL || next->start_va > start_va) {
            LIST_INSERT_AFTER(&alloc_list_PBA, current, new_node);
            return;
        }
    }
}

void remove_alloc(uint32 start_va)
{
    struct PageAlloc *curr;
    LIST_FOREACH(curr, &alloc_list_PBA) {
        if (curr->start_va == start_va) {
            LIST_REMOVE(&alloc_list_PBA, curr);
            free_block(curr);
            return;
        }
    }
}

uint32 find_alloc(uint32 start_va)
{
    struct PageAlloc *curr;
    LIST_FOREACH(curr, &alloc_list_PBA) {
        if (curr->start_va == start_va)
            return curr->size;
    }
    return 0;
}

int is_range_free(uint32 start_va, uint32 size)
{
    uint32 end_va = start_va + size;
    struct PageAlloc *current;

    // loop through all allocations and check if any overlap
    LIST_FOREACH(current, &alloc_list_PBA) {
    	uint32 alloc_start = current->start_va;
        uint32 alloc_end = current->start_va + current->size;

        // Two ranges overlap if one starts before the other ends
        int overlap = (start_va < alloc_end) && (end_va > alloc_start);

        if (overlap) {
            return 0;  // Overlap -> Not free
        }
    }
    return 1;  // Free
}

//uint32 find_custom_fit(uint32 size)
//{
//    // ========== EXACT FIT SEARCH ==========
//	 uint32 current_va = uheapPageAllocStart;
//
//    while (current_va < uheapPageAllocBreak)
//    {
//        if (is_range_free(current_va, PAGE_SIZE))
//        {
//            uint32 window_start = current_va;
//            uint32 window_size = 0;
//            uint32 scan_va = current_va;
//
//            // make sure it is exact size
//            while (scan_va < uheapPageAllocBreak && is_range_free(scan_va, PAGE_SIZE))
//            {
//                window_size += PAGE_SIZE;
//                scan_va += PAGE_SIZE;
//            }
//
//            if (window_size == size)
//                return window_start;//found exact
//
//            current_va = scan_va;
//        }
//        else
//        {
//            current_va += PAGE_SIZE; // skip allocated page
//        }
//    }
//
//    // ========== WORST FIT SEARCH ==========
//    current_va = uheapPageAllocStart;
//    uint32 best_va = 0;
//    uint32 best_window_size = 0;
//
//    while (current_va < uheapPageAllocBreak)
//    {
//        if (is_range_free(current_va, PAGE_SIZE))
//        {
//            uint32 window_start = current_va;
//            uint32 window_size = 0;
//            uint32 scan_va = current_va;
//
//            while (scan_va < uheapPageAllocBreak &&
//                   is_range_free(scan_va, PAGE_SIZE))
//            {
//                window_size += PAGE_SIZE;
//                scan_va += PAGE_SIZE;
//            }
//            // update best
//            if (window_size >= size && window_size > best_window_size)
//            {
//                best_va = window_start;
//                best_window_size = window_size;
//            }
//
//            current_va = scan_va;// jump to end of this window
//        }
//        else
//        {
//            current_va += PAGE_SIZE;// skip allocated page
//        }
//    }
//
//    if (best_va != 0)
//        return best_va;
//
//    // ========== EXTEND HEAP ==========
//    if (uheapPageAllocBreak + size < uheapPageAllocBreak ||
//        uheapPageAllocBreak + size > USER_HEAP_MAX) {
//        return 0;
//    }
//
//    return uheapPageAllocBreak;
//}

uint32 find_custom_fit(uint32 size)
{
    uint32 curr_va = uheapPageAllocStart;
    uint32 best_va = 0;
    uint32 best_window_size = 0;

    while (curr_va < uheapPageAllocBreak)
    {
        if (is_range_free(curr_va, PAGE_SIZE))
        {
            uint32 window_start = curr_va;
            uint32 window_size = 0;
            uint32 scan_va = curr_va;

            // Measure the contiguous free window
            while (scan_va < uheapPageAllocBreak && is_range_free(scan_va, PAGE_SIZE))
            {
                window_size += PAGE_SIZE;
                scan_va += PAGE_SIZE;
            }

            // Exact fit found
            if (window_size == size)
                return window_start;

            // worst fit -> Track the largest Window
            if (window_size >= size && window_size > best_window_size)
            {
                best_va = window_start;
                best_window_size = window_size;
            }

            curr_va = scan_va;  // Jump to end of this free window
        }
        else
        {
            curr_va += PAGE_SIZE;  // Skip allocated page
        }
    }

    if (best_va != 0)
        return best_va;

    // ========== EXTEND HEAP ==========
    if (uheapPageAllocBreak + size < uheapPageAllocBreak ||
        uheapPageAllocBreak + size > USER_HEAP_MAX) {
        return 0;
    }

    return uheapPageAllocBreak;
}

//=================================
void *malloc(uint32 size)
{
    uheap_init();
    if (size == 0) return NULL;

    if (size <= DYN_ALLOC_MAX_BLOCK_SIZE) {
        return alloc_block(size);
    }

    uint32 requestedSize = size;
    size = ROUNDUP(size, PAGE_SIZE);

    if (size < requestedSize) {
        return NULL;
    }

    uint32 alloc_va = find_custom_fit(size);
    if (alloc_va == 0) {
        return NULL;
    }

    if (alloc_va == uheapPageAllocBreak) {
        uint32 extend_va = uheapPageAllocBreak;

        if (extend_va + size < extend_va || extend_va + size > USER_HEAP_MAX) {
            return NULL;
        }

        uheapPageAllocBreak += size;
        sys_allocate_user_mem(extend_va, size);
        add_alloc(extend_va, size);
        return (void*) extend_va;
    }

    sys_allocate_user_mem(alloc_va, size);
    add_alloc(alloc_va, size);
    return (void*) alloc_va;
}

// [2] FREE SPACE FROM USER HEAP:
//=================================
void free(void* virtual_address)
{
    if (virtual_address == NULL)
        return;

    uint32 va = (uint32)virtual_address;

    if (va >= USER_HEAP_START && va < dynAllocEnd) {
        free_block(virtual_address);
        return;
    }

    if (va >= uheapPageAllocStart && va < USER_HEAP_MAX) {
        uint32 size = find_alloc(va);
        if (size == 0)
            panic("free(): invalid address - not found in page allocator");

        sys_free_user_mem(va, size);
        remove_alloc(va);


        uint32 new_break = uheapPageAllocStart;
        struct PageAlloc *current;
        LIST_FOREACH(current, &alloc_list_PBA) {
            uint32 end_va = current->start_va + current->size;
            if (end_va > new_break)
                new_break = end_va;
        }
        uheapPageAllocBreak = new_break;

        return;
    }

    panic("free(): invalid address - outside heap ranges");
}

//=================================
// [3] ALLOCATE SHARED VARIABLE:
//=================================
void* smalloc(char *sharedVarName, uint32 size, uint8 isWritable)
{
	//==============================================================
	//DON'T CHANGE THIS CODE========================================
	uheap_init();
	if (size == 0) return NULL ;
	//==============================================================
	//TODO: [PROJECT'25.IM#3] SHARED MEMORY - #2 smalloc
	//Your code is here
	//Comment the following line
	//panic("smalloc() is not implemented yet...!!");

     //uint32 original_size = size;
	 size = ROUNDUP(size, PAGE_SIZE);

	 uint32 alloc_va = find_custom_fit(size);
	 if (alloc_va == 0) {
	     return NULL;
	 }

	 //Extend Break
	 if (alloc_va == uheapPageAllocBreak) {
	     uint32 extend_break_va = uheapPageAllocBreak;
	     uheapPageAllocBreak += size;

	     int ret = sys_create_shared_object(sharedVarName, size, isWritable, (void*)extend_break_va);
	     if (ret < 0) {
	         uheapPageAllocBreak -= size;
	         return NULL;
	     }
	     add_alloc(extend_break_va, size);
	     return (void*) extend_break_va;
	 }

	 int ret = sys_create_shared_object(sharedVarName, size, isWritable, (void*)alloc_va);
	 if (ret < 0)
	     return NULL;

	 add_alloc(alloc_va, size);
	 return (void*) alloc_va;


}

//========================================
// [4] SHARE ON ALLOCATED SHARED VARIABLE:
//========================================
void* sget(int32 ownerEnvID, char *sharedVarName)
{
	//==============================================================
	//DON'T CHANGE THIS CODE========================================
	uheap_init();
	//==============================================================

	//TODO: [PROJECT'25.IM#3] SHARED MEMORY - #4 sget
	//Your code is here
	//Comment the following line
	//panic("sget() is not implemented yet...!!");

//    acquire_kspinlock(&AllShares.shareslock);
//    if (find_share(ownerEnvID, sharedVarName) == NULL)
//    {
//        release_kspinlock(&AllShares.shareslock);
//        return NULL;
//    }
//    release_kspinlock(&AllShares.shareslock);

	int size = sys_size_of_shared_object(ownerEnvID,sharedVarName);
	if (size <= 0) {
		    return NULL; // dosen't exist
		}
	//uint32 original_size = size;
	 size = ROUNDUP(size, PAGE_SIZE);
	 uint32 alloc_va = find_custom_fit(size);
	 if (alloc_va == 0) {
	     return NULL;
	 }

	 //Extend Break
	 if (alloc_va == uheapPageAllocBreak) {
	     uint32 extend_break_va = uheapPageAllocBreak;
	     uheapPageAllocBreak += size;

	     int ret = sys_get_shared_object(ownerEnvID, sharedVarName, (void*)extend_break_va);
	     if (ret < 0) {
	         uheapPageAllocBreak -= size;
	         return NULL;
	     }
	     add_alloc(extend_break_va, size);
	     return (void*) extend_break_va;
	 }

	 int ret = sys_get_shared_object(ownerEnvID, sharedVarName, (void*)alloc_va);
	 if (ret < 0) {
	     return NULL;
	 }
	 add_alloc(alloc_va, size);
	 return (void*) alloc_va;


}


//==================================================================================//
//============================== BONUS FUNCTIONS ===================================//
//==================================================================================//


//=================================
// REALLOC USER SPACE:
//=================================
//	Attempts to resize the allocated space at "virtual_address" to "new_size" bytes,
//	possibly moving it in the heap.
//	If successful, returns the new virtual_address, in which case the old virtual_address must no longer be accessed.
//	On failure, returns a null pointer, and the old virtual_address remains valid.

//	A call with virtual_address = null is equivalent to malloc().
//	A call with new_size = zero is equivalent to free().

//  Hint: you may need to use the sys_move_user_mem(...)
//		which switches to the kernel mode, calls move_user_mem(...)
//		in "kern/mem/chunk_operations.c", then switch back to the user mode here
//	the move_user_mem() function is empty, make sure to implement it.
void *realloc(void *virtual_address, uint32 new_size)
{
	//==============================================================
	//DON'T CHANGE THIS CODE========================================
	uheap_init();
	//==============================================================
	panic("realloc() is not implemented yet...!!");
}


//=================================
// FREE SHARED VARIABLE:
//=================================
//	This function frees the shared variable at the given virtual_address
//	To do this, we need to switch to the kernel, free the pages AND "EMPTY" PAGE TABLES
//	from main memory then switch back to the user again.
//
//	use sys_delete_shared_object(...); which switches to the kernel mode,
//	calls delete_shared_object(...) in "shared_memory_manager.c", then switch back to the user mode here
//	the delete_shared_object() function is empty, make sure to implement it.
void sfree(void* virtual_address)
{
	//TODO: [PROJECT'25.BONUS#5] EXIT #2 - sfree
	//Your code is here
	//Comment the following line
	panic("sfree() is not implemented yet...!!");

	//	1) you should find the ID of the shared variable at the given address
	//	2) you need to call sys_freeSharedObject()
}


//==================================================================================//
//========================== MODIFICATION FUNCTIONS ================================//
//==================================================================================//
