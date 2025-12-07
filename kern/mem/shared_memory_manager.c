#include <inc/memlayout.h>
#include "shared_memory_manager.h"

#include <inc/mmu.h>
#include <inc/error.h>
#include <inc/string.h>
#include <inc/assert.h>
#include <inc/queue.h>
#include <inc/environment_definitions.h>

#include <kern/proc/user_environment.h>
#include <kern/trap/syscall.h>
#include "kheap.h"
#include "memory_manager.h"

//==================================================================================//
//============================== GIVEN FUNCTIONS ===================================//
//==================================================================================//

//===========================
// [1] INITIALIZE SHARES:
//===========================
//Initialize the list and the corresponding lock
void sharing_init()
{
#if USE_KHEAP
	LIST_INIT(&AllShares.shares_list) ;
	init_kspinlock(&AllShares.shareslock, "shares lock");
	//init_sleeplock(&AllShares.sharessleeplock, "shares sleep lock");
#else
	panic("not handled when KERN HEAP is disabled");
#endif
}

//=========================
// [2] Find Share Object:
//=========================
//Search for the given shared object in the "shares_list"
//Return:
//	a) if found: ptr to Share object
//	b) else: NULL
struct Share* find_share(int32 ownerID, char* name)
{
#if USE_KHEAP

	struct Share * ret = NULL;
	bool wasHeld = holding_kspinlock(&(AllShares.shareslock));
	if (!wasHeld)
	{
		acquire_kspinlock(&(AllShares.shareslock));
	}
	{
		struct Share * shr ;
		LIST_FOREACH(shr, &(AllShares.shares_list))
		{
			//cprintf("shared var name = %s compared with %s\n", name, shr->name);
			if(shr->ownerID == ownerID && strcmp(name, shr->name)==0)
			{
				//cprintf("%s found\n", name);
				ret = shr;
				break;
			}
		}
	}
	if (!wasHeld)
	{
		release_kspinlock(&(AllShares.shareslock));
	}
	return ret;
#else
	panic("not handled when KERN HEAP is disabled");
#endif
}

//==============================
// [3] Get Size of Share Object:
//==============================
int size_of_shared_object(int32 ownerID, char* shareName)
{
	// This function should return the size of the given shared object
	// RETURN:
	//	a) If found, return size of shared object
	//	b) Else, return E_SHARED_MEM_NOT_EXISTS
	//
	struct Share* ptr_share = find_share(ownerID, shareName);
	if (ptr_share == NULL)
		return E_SHARED_MEM_NOT_EXISTS;
	else
		return ptr_share->size;

	return 0;
}
//===========================================================


//==================================================================================//
//============================ REQUIRED FUNCTIONS ==================================//
//==================================================================================//

//=====================================
// [1] Alloc & Initialize Share Object:
//=====================================
//Allocates a new shared object and initialize its member
//It dynamically creates the "framesStorage"
//Return: allocatedObject (pointer to struct Share) passed by reference
struct Share* alloc_share(int32 ownerID, char* shareName, uint32 size, uint8 isWritable)
{
	//TODO: [PROJECT'25.IM#3] SHARED MEMORY - #1 alloc_share
	//Your code is here
	//Comment the following line
	//panic("alloc_share() is not implemented yet...!!");

	struct Share *sharedObject = kmalloc(sizeof(struct Share));
	if (sharedObject == NULL)
			return NULL; // allocation fails

	sharedObject->ownerID = ownerID;
	sharedObject->size = size;
	sharedObject->isWritable = isWritable;
	sharedObject->references = 1;
	strncpy(sharedObject->name, shareName, 64);

	//uint32 mask = ~(1 << 31);

	sharedObject->ID = 0; // 0 for now untill smalloc is implemented


	uint32 numOfPages = ROUNDUP(size,PAGE_SIZE) / PAGE_SIZE;
	sharedObject->framesStorage = kmalloc(numOfPages * sizeof(struct FrameInfo *)); // allocate framesStorage array

	if (sharedObject->framesStorage == NULL)
		{
			kfree(sharedObject); // undo allocation
			return NULL;
		}

	for(int i =0; i < numOfPages; i++){
		sharedObject->framesStorage[i] = 0; // Initialize it by ZEROs
	}

	return sharedObject;


}


//=========================
// [4] Create Share Object:
//=========================
int create_shared_object(int32 ownerID, char* shareName, uint32 size,uint8 isWritable, void* virtual_address)
{
	//TODO: [PROJECT'25.IM#3] SHARED MEMORY - #5 get_shared_object
		//Your code is here
		//Comment the following line
		//panic("create_shared_object() is not implemented yet...!!");
#if USE_KHEAP
    struct Env* myenv = get_cpu_proc();


    uint32 va_start = (uint32)virtual_address;

    if (va_start < USER_HEAP_START || va_start >= USER_HEAP_MAX)
        return E_NO_SHARE;


    acquire_kspinlock(&AllShares.shareslock);
    if (find_share(ownerID, shareName) != NULL)
    {
        release_kspinlock(&AllShares.shareslock);
        return E_SHARED_MEM_EXISTS;
    }
    release_kspinlock(&AllShares.shareslock);

    // allocate share struct only
    struct Share* sharedObject = alloc_share(ownerID, shareName, size, isWritable);
    if (sharedObject == NULL)
        return E_NO_SHARE;

    int numOfPages = ROUNDUP(size, PAGE_SIZE) / PAGE_SIZE;

    // allocate and map frames
    for (int i = 0; i < numOfPages; i++)
    {
        struct FrameInfo* frame;

        int ret = allocate_frame(&frame);

        if ( ret != 0)
        {
            // unallocate allocated
            for (int j = 0; j < i; j++)
            {
                uint32 va = va_start + j * PAGE_SIZE;
                unmap_frame(myenv->env_page_directory, va);
                free_frame(sharedObject->framesStorage[j]);
            }
            kfree(sharedObject->framesStorage);
            kfree(sharedObject);
            return E_NO_SHARE;
        }

        sharedObject->framesStorage[i] = frame;

        uint32 curVa = va_start + i * PAGE_SIZE;

        uint32 perm = PERM_WRITEABLE|  PERM_USER | PERM_PRESENT | PERM_UHPAGE;

        map_frame(myenv->env_page_directory, frame, curVa, perm);
    }

    //generate ID from the Share struct address
    sharedObject->ID = ((uint32)sharedObject) & ~(1 << 31);

    //insert into the list
    acquire_kspinlock(&AllShares.shareslock);
    LIST_INSERT_HEAD(&AllShares.shares_list, sharedObject);
    release_kspinlock(&AllShares.shareslock);

    return sharedObject->ID;
#else
	panic("Need USE_KHEAP = 1");
#endif
}



//======================
// [5] Get Share Object:
//======================
int get_shared_object(int32 ownerID, char* shareName, void* virtual_address)
{
	//TODO: [PROJECT'25.IM#3] SHARED MEMORY - #5 get_shared_object
	//Your code is here
	//Comment the following line
	//panic("get_shared_object() is not implemented yet...!!");
#if USE_KHEAP
	struct Env* myenv = get_cpu_proc(); //The calling environment

	// 	This function should share the required object in the heap of the current environment
	//	starting from the given virtual_address with the specified permissions of the object: read_only/writable
	// 	and return the ShareObjectID
	// RETURN:
	//	a) ID of the shared object (its VA after masking out its msb) if success
	//	b) E_SHARED_MEM_NOT_EXISTS if the shared object is not exists

	// C.S
	acquire_kspinlock(&AllShares.shareslock);

	//search in shares list
	struct Share* sharedObject = find_share(ownerID, shareName);
	if(sharedObject == NULL){
		 release_kspinlock(&AllShares.shareslock);
		return E_SHARED_MEM_NOT_EXISTS ;
	}

	 sharedObject->references++;

	 release_kspinlock(&AllShares.shareslock);


	int size = sharedObject->size;
	int numOfFrames = ROUNDUP(size,PAGE_SIZE) / PAGE_SIZE;

	// share the frames
	for(int i = 0; i < numOfFrames ; i++){
		struct FrameInfo *frame = sharedObject->framesStorage[i];

		uint32 perms = PERM_USER | PERM_PRESENT | PERM_UHPAGE;

		//check writable perm
		if(sharedObject->isWritable){
			perms = PERM_WRITEABLE | PERM_USER | PERM_PRESENT | PERM_UHPAGE;// writable
		}

		map_frame(myenv->env_page_directory,frame,((uint32)virtual_address + (uint32)i*PAGE_SIZE),perms);
	}



	return sharedObject->ID;

#else
	panic("Need USE_KHEAP = 1");
#endif
}

//==================================================================================//
//============================== BONUS FUNCTIONS ===================================//
//==================================================================================//
//=========================
// [1] Delete Share Object:
//=========================
//delete the given shared object from the "shares_list"
//it should free its framesStorage and the share object itself
void free_share(struct Share* ptrShare)
{
	//TODO: [PROJECT'25.BONUS#5] EXIT #2 - free_share
	//Your code is here
	//Comment the following line
	panic("free_share() is not implemented yet...!!");
}


//=========================
// [2] Free Share Object:
//=========================
int delete_shared_object(int32 sharedObjectID, void *startVA)
{
	//TODO: [PROJECT'25.BONUS#5] EXIT #2 - delete_shared_object
	//Your code is here
	//Comment the following line
	panic("delete_shared_object() is not implemented yet...!!");

	struct Env* myenv = get_cpu_proc(); //The calling environment

	// This function should free (delete) the shared object from the User Heapof the current environment
	// If this is the last shared env, then the "frames_store" should be cleared and the shared object should be deleted
	// RETURN:
	//	a) 0 if success
	//	b) E_SHARED_MEM_NOT_EXISTS if the shared object is not exists

	// Steps:
	//	1) Get the shared object from the "shares" array (use get_share_object_ID())
	//	2) Unmap it from the current environment "myenv"
	//	3) If one or more table becomes empty, remove it
	//	4) Update references
	//	5) If this is the last share, delete the share object (use free_share())
	//	6) Flush the cache "tlbflush()"

}
