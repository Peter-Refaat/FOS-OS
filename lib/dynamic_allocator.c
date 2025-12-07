/*
 * dynamic_allocator.c
 *
 *  Created on: Sep 21, 2023
 *      Author: HP
 */
#include <inc/assert.h>
#include <inc/string.h>
#include "../inc/dynamic_allocator.h"

//==================================================================================//
//============================== GIVEN FUNCTIONS ===================================//
//==================================================================================//
//==================================
//==================================
// [1] GET PAGE VA:
//==================================
__inline__ uint32 to_page_va(struct PageInfoElement *ptrPageInfo)
{
	if (ptrPageInfo < &pageBlockInfoArr[0] || ptrPageInfo >= &pageBlockInfoArr[DYN_ALLOC_MAX_SIZE/PAGE_SIZE])
			panic("to_page_va called with invalid pageInfoPtr");
	//Get start VA of the page from the corresponding Page Info pointer
	int idxInPageInfoArr = (ptrPageInfo - pageBlockInfoArr);
	return dynAllocStart + (idxInPageInfoArr << PGSHIFT);
}

//==================================
// [2] GET PAGE INFO OF PAGE VA:
//==================================
__inline__ struct PageInfoElement * to_page_info(uint32 va)
{
	int idxInPageInfoArr = (va - dynAllocStart) >> PGSHIFT;
	if (idxInPageInfoArr < 0 || idxInPageInfoArr >= DYN_ALLOC_MAX_SIZE/PAGE_SIZE)
		panic("to_page_info called with invalid pa");
	return &pageBlockInfoArr[idxInPageInfoArr];
}

//==================================================================================//
//============================ REQUIRED FUNCTIONS ==================================//
//==================================================================================//

//==================================
// [1] INITIALIZE DYNAMIC ALLOCATOR:
//==================================
bool is_initialized = 0;
void initialize_dynamic_allocator(uint32 daStart, uint32 daEnd)
{
	//==================================================================================
	//DON'T CHANGE THESE LINES==========================================================
	//==================================================================================
	{
		assert(daEnd <= daStart + DYN_ALLOC_MAX_SIZE);
		is_initialized = 1;
	}
	//==================================================================================
	//==================================================================================
	//TODO: [PROJECT'25.GM#1] DYNAMIC ALLOCATOR - #1 initialize_dynamic_allocator
	//Your code is here

	//global variables
	dynAllocStart=daStart;
	dynAllocEnd= daEnd;

	//initializing pageBlockInfoArr: for each page size=0 , free=0
    memset(pageBlockInfoArr, 0, sizeof(pageBlockInfoArr));

	//initializing freePagesList: make it contains or points to all the pages
	LIST_INIT(&freePagesList);
	LIST_INSERT_HEAD(&freePagesList,&pageBlockInfoArr[0]);

	int numPages = (daEnd - daStart) / PAGE_SIZE;
	for(int i=1;i<numPages;i++){
		LIST_INSERT_TAIL(&freePagesList,&pageBlockInfoArr[i]);
	}

	//initializing freeBlockLists:all NULL
	for (int i = 0; i <= LOG2_MAX_SIZE - LOG2_MIN_SIZE; i++) {
	    LIST_INIT(&freeBlockLists[i]);
	}

	//Comment the following line
	//panic("initialize_dynamic_allocator() Not implemented yet");

}

//===========================
// [2] GET BLOCK SIZE:
//===========================
__inline__ uint32 get_block_size(void *va)
{
	//TODO: [PROJECT'25.GM#1] DYNAMIC ALLOCATOR - #2 get_block_size
	//Your code is here

    if (va < (void*)dynAllocStart || va >= (void*)dynAllocEnd)
        panic("Block out of boundaries");

    struct PageInfoElement *page_info = to_page_info((uint32)va);
    return page_info->block_size;
	//Comment the following line
	//panic("get_block_size() Not implemented yet");
}

//===========================
// 3) ALLOCATE BLOCK:
//===========================
void *alloc_block(uint32 size)
{
	//==================================================================================
	//DON'T CHANGE THESE LINES==========================================================
	//==================================================================================
	{
		assert(size <= DYN_ALLOC_MAX_BLOCK_SIZE);
	}
	//==================================================================================
	//==================================================================================
	//TODO: [PROJECT'25.GM#1] DYNAMIC ALLOCATOR - #3 alloc_block
	//Your code is here

	if(size==0){
		return NULL;
	}

	for(int i=DYN_ALLOC_MIN_BLOCK_SIZE;i<=DYN_ALLOC_MAX_BLOCK_SIZE;i<<=1){
		if(size<=i){
			size=(uint32)i;
			break;
		}
	}
	//size=nearest_pow2_ceil(size);

	//Case 1:
	uint32 x=size,log=0;
	while(x!=1){
		x/=2;
		log++;
	}

	int indx=(int)(log - LOG2_MIN_SIZE);
	//int indxs=(int)(log2_ceil(size)-LOG2_MIN_SIZE);
	if(!LIST_EMPTY(&freeBlockLists[indx])){
		struct BlockElement* block=	LIST_FIRST(&freeBlockLists[indx]);
		LIST_REMOVE(&freeBlockLists[indx],block);
		struct PageInfoElement* page=to_page_info((uint32)block);
		page->num_of_free_blocks--;
		return (void*)block;
	}

	//case 2:
	else if(LIST_EMPTY(&freeBlockLists[indx]) && !LIST_EMPTY(&freePagesList)){
		struct PageInfoElement* page=LIST_FIRST(&freePagesList);
		page->block_size=size;
		page->num_of_free_blocks=PAGE_SIZE/size;
		LIST_REMOVE(&freePagesList,page);
		uint32 va=to_page_va(page);
		//////////////////////////
		get_page((void*)va);
	    //////////////////////////

		for(uint32 i=0;i<PAGE_SIZE/size;i++){
			struct BlockElement* block=(struct BlockElement*)(va+(size*i));
			LIST_INSERT_TAIL(&freeBlockLists[indx],block);
		}
		/////////////////////////////////////////
		struct BlockElement* block=	LIST_FIRST(&freeBlockLists[indx]);
		LIST_REMOVE(&freeBlockLists[indx],block);
		struct PageInfoElement* page_to_add=to_page_info((uint32)block);
		page_to_add->num_of_free_blocks--;
		return (void*)block;
	}

	//case 3&4:
	else if(LIST_EMPTY(&freeBlockLists[indx]) && LIST_EMPTY(&freePagesList)){
		for(int i=indx+1;i<=LOG2_MAX_SIZE-LOG2_MIN_SIZE;i++){
			if(!LIST_EMPTY(&freeBlockLists[i])){
				struct BlockElement* block=	LIST_FIRST(&freeBlockLists[i]);
				LIST_REMOVE(&freeBlockLists[i],block);
				struct PageInfoElement* page=to_page_info((uint32)block);
				page->num_of_free_blocks--;
				return (void*)block;
			}
		}
		panic("no free blocks nor free pages");
		return (void*)NULL;
	}

	return (void*)NULL;
	//Comment the following line
	//panic("alloc_block() Not implemented yet");

	//TODO: [PROJECT'25.BONUS#1] DYNAMIC ALLOCATOR - block if no free block
}

//===========================
// [4] FREE BLOCK:
//===========================
void free_block(void *va)
{
	//==================================================================================
	//DON'T CHANGE THESE LINES==========================================================
	//==================================================================================
	{
		assert((uint32)va >= dynAllocStart && (uint32)va < dynAllocEnd);
	}
	//==================================================================================
	//==================================================================================

	//TODO: [PROJECT'25.GM#1] DYNAMIC ALLOCATOR - #4 free_block
	//Your code is here

	struct BlockElement* block=(struct BlockElement*) va;
	uint32 size=get_block_size((void*)block);
	uint32 x=size,log=0;
		while(x!=1){
			x/=2;
			log++;
		}
	int indx=(int)(log - LOG2_MIN_SIZE);
	struct PageInfoElement* page=to_page_info((uint32)block);

	LIST_INSERT_TAIL(&freeBlockLists[indx],block);

	page->num_of_free_blocks++;
	int max_blocks=PAGE_SIZE/size;
	if(page->num_of_free_blocks==max_blocks){
		LIST_FOREACH(block,&freeBlockLists[indx]){
			if(page==to_page_info((uint32)block)){
				LIST_REMOVE(&freeBlockLists[indx],block);
			}

		}
		//////////////////////////////////
        uint32 page_va = to_page_va(page);
        return_page((void*)page_va);

		page->block_size=0;
		page->num_of_free_blocks=0;
		LIST_INSERT_TAIL(&freePagesList,page);
	}

	//Comment the following line
	//panic("free_block() Not implemented yet");
}

//==================================================================================//
//============================== BONUS FUNCTIONS ===================================//
//==================================================================================//

//===========================
// [1] REALLOCATE BLOCK:
//===========================
//void *realloc_block(void* va, uint32 new_size)
//{
//	//TODO: [PROJECT'25.BONUS#2] KERNEL REALLOC - realloc_block
//	//Your code is here
//	//Comment the following line
//	//panic("realloc_block() Not implemented yet");
//
//}
