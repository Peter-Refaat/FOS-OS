/*
 * fault_handler.c
 *
 *  Created on: Oct 12, 2022
 *      Author: HP
 */

#include "trap.h"
#include <kern/proc/user_environment.h>
#include <kern/cpu/sched.h>
#include <kern/cpu/cpu.h>
#include <kern/disk/pagefile_manager.h>
#include <kern/mem/memory_manager.h>
#include <kern/mem/kheap.h>

//2014 Test Free(): Set it to bypass the PAGE FAULT on an instruction with this length and continue executing the next one
// 0 means don't bypass the PAGE FAULT
uint8 bypassInstrLength = 0;

//===============================
// REPLACEMENT STRATEGIES
//===============================
//2020
void setPageReplacmentAlgorithmLRU(int LRU_TYPE)
{
	assert(LRU_TYPE == PG_REP_LRU_TIME_APPROX || LRU_TYPE == PG_REP_LRU_LISTS_APPROX);
	_PageRepAlgoType = LRU_TYPE ;
}
void setPageReplacmentAlgorithmCLOCK(){_PageRepAlgoType = PG_REP_CLOCK;}
void setPageReplacmentAlgorithmFIFO(){_PageRepAlgoType = PG_REP_FIFO;}
void setPageReplacmentAlgorithmModifiedCLOCK(){_PageRepAlgoType = PG_REP_MODIFIEDCLOCK;}
/*2018*/ void setPageReplacmentAlgorithmDynamicLocal(){_PageRepAlgoType = PG_REP_DYNAMIC_LOCAL;}
/*2021*/ void setPageReplacmentAlgorithmNchanceCLOCK(int PageWSMaxSweeps){_PageRepAlgoType = PG_REP_NchanceCLOCK;  page_WS_max_sweeps = PageWSMaxSweeps;}
/*2024*/ void setFASTNchanceCLOCK(bool fast){ FASTNchanceCLOCK = fast; };
/*2025*/ void setPageReplacmentAlgorithmOPTIMAL(){ _PageRepAlgoType = PG_REP_OPTIMAL; };

//2020
uint32 isPageReplacmentAlgorithmLRU(int LRU_TYPE){return _PageRepAlgoType == LRU_TYPE ? 1 : 0;}
uint32 isPageReplacmentAlgorithmCLOCK(){if(_PageRepAlgoType == PG_REP_CLOCK) return 1; return 0;}
uint32 isPageReplacmentAlgorithmFIFO(){if(_PageRepAlgoType == PG_REP_FIFO) return 1; return 0;}
uint32 isPageReplacmentAlgorithmModifiedCLOCK(){if(_PageRepAlgoType == PG_REP_MODIFIEDCLOCK) return 1; return 0;}
/*2018*/ uint32 isPageReplacmentAlgorithmDynamicLocal(){if(_PageRepAlgoType == PG_REP_DYNAMIC_LOCAL) return 1; return 0;}
/*2021*/ uint32 isPageReplacmentAlgorithmNchanceCLOCK(){if(_PageRepAlgoType == PG_REP_NchanceCLOCK) return 1; return 0;}
/*2021*/ uint32 isPageReplacmentAlgorithmOPTIMAL(){if(_PageRepAlgoType == PG_REP_OPTIMAL) return 1; return 0;}

//===============================
// PAGE BUFFERING
//===============================
void enableModifiedBuffer(uint32 enableIt){_EnableModifiedBuffer = enableIt;}
uint8 isModifiedBufferEnabled(){  return _EnableModifiedBuffer ; }

void enableBuffering(uint32 enableIt){_EnableBuffering = enableIt;}
uint8 isBufferingEnabled(){  return _EnableBuffering ; }

void setModifiedBufferLength(uint32 length) { _ModifiedBufferLength = length;}
uint32 getModifiedBufferLength() { return _ModifiedBufferLength;}

//===============================
// FAULT HANDLERS
//===============================

//==================
// [0] INIT HANDLER:
//==================
void fault_handler_init()
{
	//setPageReplacmentAlgorithmLRU(PG_REP_LRU_TIME_APPROX);
	//setPageReplacmentAlgorithmOPTIMAL();
	setPageReplacmentAlgorithmCLOCK();
	//setPageReplacmentAlgorithmModifiedCLOCK();
	enableBuffering(0);
	enableModifiedBuffer(0) ;
	setModifiedBufferLength(1000);
}
//==================
// [1] MAIN HANDLER:
//==================
/*2022*/
uint32 last_eip = 0;
uint32 before_last_eip = 0;
uint32 last_fault_va = 0;
uint32 before_last_fault_va = 0;
int8 num_repeated_fault  = 0;
extern uint32 sys_calculate_free_frames() ;

struct Env* last_faulted_env = NULL;
void fault_handler(struct Trapframe *tf)
{

	/******************************************************/
	// Read processor's CR2 register to find the faulting address
	uint32 fault_va = rcr2();

	//	print_trapframe(tf);
	/******************************************************/

	//If same fault va for 3 times, then panic
	//UPDATE: 3 FAULTS MUST come from the same environment (or the kernel)
	struct Env* cur_env = get_cpu_proc();
//	cprintf("************Faulted VA = %x , Rounded Down VA = %x ************ , ENVID = %d  \n", fault_va, ROUNDDOWN(fault_va,PAGE_SIZE) , cur_env->env_id);


	if (last_fault_va == fault_va && last_faulted_env == cur_env)
	{
		num_repeated_fault++ ;
		if (num_repeated_fault == 3)
		{
			print_trapframe(tf);
			panic("Failed to handle fault! fault @ at va = %x from eip = %x causes va (%x) to be faulted for 3 successive times\n", before_last_fault_va, before_last_eip, fault_va);
		}
	}
	else
	{
		before_last_fault_va = last_fault_va;
		before_last_eip = last_eip;
		num_repeated_fault = 0;
	}
	last_eip = (uint32)tf->tf_eip;
	last_fault_va = fault_va ;
	last_faulted_env = cur_env;
	/******************************************************/
	//2017: Check stack overflow for Kernel
	int userTrap = 0;
	if ((tf->tf_cs & 3) == 3) {
		userTrap = 1;
	}
	if (!userTrap)
	{
		struct cpu* c = mycpu();
		//cprintf("trap from KERNEL\n");
		if (cur_env && fault_va >= (uint32)cur_env->kstack && fault_va < (uint32)cur_env->kstack + PAGE_SIZE)
			panic("User Kernel Stack: overflow exception!");
		else if (fault_va >= (uint32)c->stack && fault_va < (uint32)c->stack + PAGE_SIZE)
			panic("Sched Kernel Stack of CPU #%d: overflow exception!", c - CPUS);
#if USE_KHEAP
		if (fault_va >= KERNEL_HEAP_MAX)
			panic("Kernel: heap overflow exception!");
#endif
	}
	//2017: Check stack underflow for User
	else
	{
		//cprintf("trap from USER\n");
		if (fault_va >= USTACKTOP && fault_va < USER_TOP)
			panic("User: stack underflow exception!");
	}

	//get a pointer to the environment that caused the fault at runtime
	//cprintf("curenv = %x\n", curenv);
	struct Env* faulted_env = cur_env;
	if (faulted_env == NULL)
	{
		cprintf("\nFaulted VA = %x\n", fault_va);
		print_trapframe(tf);
		panic("faulted env == NULL!");
	}
	//check the faulted address, is it a table or not ?
	//If the directory entry of the faulted address is NOT PRESENT then

	if ( (faulted_env->env_page_directory[PDX(fault_va)] & PERM_PRESENT) != PERM_PRESENT)
	{
		faulted_env->tableFaultsCounter ++ ;
		table_fault_handler(faulted_env, fault_va);
	}
	else
	{
		if (userTrap)
		{
			/*============================================================================================*/
			//TODO: [PROJECT'25.GM#3] FAULT HANDLER I - #2 Check for invalid pointers
			//(e.g. pointing to unmarked user heap page, kernel or wrong access rights),
			//your code is here
			//since we checked already that the Table itself is present, we can get the permissions for the page
			int perms = pt_get_page_permissions(faulted_env->env_page_directory, ROUNDDOWN(fault_va,PAGE_SIZE));

//			cprintf("permissions: %d\n" , perms);
//			cprintf("writable: %d\n" , perms&PERM_WRITEABLE);
//			cprintf("present: %d\n" , perms&PERM_PRESENT);
//			cprintf("IN HEAP: %d\n" , fault_va >= USER_HEAP_START && fault_va < USER_HEAP_MAX );
//			cprintf("MARKED AS HEAP: %d\n" , perms&PERM_WRITEABLE);

			if(perms ==-1){
				panic("perms does not exist");
			}
			if(!(perms & PERM_WRITEABLE) && (perms & PERM_PRESENT) /*&& tf->tf_err == FEC_WR*/){
				cprintf("Page @va=%x has READONLY permission\n", fault_va);
				env_exit();
			}
			else if(!(perms & PERM_UHPAGE) && fault_va >= USER_HEAP_START && fault_va < USER_HEAP_MAX){
				cprintf("Page @va=%x is exist in USER HEAP but not marked as UHPAGE\n", fault_va);
				env_exit();
			}
			else if( /*(!(perms & PERM_USER) && (perms & PERM_PRESENT)) ||*/ fault_va >= USER_TOP){
				cprintf("Page @va=%x does not belong to the USER VIRTUAL ADDRESS SPACE\n", fault_va);
				env_exit();
			}
			/*============================================================================================*/
		}

		/*2022: Check if fault due to Access Rights */
		int perms = pt_get_page_permissions(faulted_env->env_page_directory, fault_va);
		if (perms & PERM_PRESENT)
			panic("Page @va=%x is exist! page fault due to violation of ACCESS RIGHTS\n", fault_va) ;
		/*============================================================================================*/


		// we have normal page fault =============================================================
		faulted_env->pageFaultsCounter ++ ;

//				cprintf("[%08s] user PAGE fault va %08x\n", faulted_env->prog_name, fault_va);
//				cprintf("\nPage working set BEFORE fault handler...\n");
//				env_page_ws_print(faulted_env);
		//int ffb = sys_calculate_free_frames();

		if(isBufferingEnabled())
		{
			__page_fault_handler_with_buffering(faulted_env, fault_va);
		}
		else
		{
			page_fault_handler(faulted_env, fault_va);
		}

		//		cprintf("\nPage working set AFTER fault handler...\n");
		//		env_page_ws_print(faulted_env);
		//		int ffa = sys_calculate_free_frames();
		//		cprintf("fault handling @%x: difference in free frames (after - before = %d)\n", fault_va, ffa - ffb);
	}

	/*************************************************************/
	//Refresh the TLB cache
	tlbflush();
	/*************************************************************/
}


//=========================
// [2] TABLE FAULT HANDLER:
//=========================
void table_fault_handler(struct Env * curenv, uint32 fault_va)
{
	//panic("table_fault_handler() is not implemented yet...!!");
	//Check if it's a stack page
	uint32* ptr_table;
#if USE_KHEAP
	{
		ptr_table = create_page_table(curenv->env_page_directory, (uint32)fault_va);
	}
#else
	{
		__static_cpt(curenv->env_page_directory, (uint32)fault_va, &ptr_table);
	}
#endif
}

//=========================
// [3] PAGE FAULT HANDLER:
//=========================
/* Calculate the number of page faults according th the OPTIMAL replacement strategy
 * Given:
 * 	1. Initial Working Set List (that the process started with)
 * 	2. Max Working Set Size
 * 	3. Page References List (contains the stream of referenced VAs till the process finished)
 *
 * 	IMPORTANT: This function SHOULD NOT change any of the given lists
 */
int get_optimal_num_faults(struct WS_List *initWorkingSet, int maxWSSize, struct PageRef_List *pageReferences)
{
	//TODO: [PROJECT'25.IM#1] FAULT HANDLER II - #2 get_optimal_num_faults
	//Your code is here
	//Comment the following line
	//panic("get_optimal_num_faults() is not implemented yet...!!");

	//Dstructures

	uint32 *Active_WS_VAs = kmalloc(maxWSSize * sizeof(uint32));
	if(Active_WS_VAs == NULL){
		panic("cannot allocate memory for optimal algorithm simulation , get_optimal_num_faults");
	}
	//iterators
	struct WorkingSetElement *elm;
	struct PageRefElement *curPageRef = NULL ;
	struct PageRefElement *loopy;

	// variables
	int curWsSize = 0;
	int faults = 0;
	int curIdx = 0;
	int pageReferencesSize = LIST_SIZE(pageReferences);
	short hitFlag = 0;
	int curPageIdx = 0;
	int victimIdx = -1;
	int maxDis = -1;
	int curDis = 0;
	short found = 0;

	uint32 curVa = 0;
	uint32 loopVa=0;

	LIST_FOREACH(elm,(initWorkingSet)){
		if(curWsSize < maxWSSize){
				Active_WS_VAs[curWsSize++] = ROUNDDOWN(elm->virtual_address, PAGE_SIZE)/PAGE_SIZE;
		}
		else{
			panic("intial WS is bigger than WS size");
		}
	}

	LIST_FOREACH(curPageRef ,(pageReferences)){
		hitFlag = 0;
		//if it is in current working set
		curVa = ROUNDDOWN(curPageRef->virtual_address, PAGE_SIZE)/PAGE_SIZE;
		for(int i =0 ; i < curWsSize ; i++){
			if(Active_WS_VAs[i] == curVa){
				hitFlag = 1;
				break;
			}
		}

		if(hitFlag == 0){
			faults++;
			// if there is a place , place
			if(curWsSize<maxWSSize){
				Active_WS_VAs[curWsSize++] = curVa;
			}
			// replacement
			else{
				victimIdx = -1;
				maxDis = -1;
				curDis = 0;
				found = 0;
				for(int i =0 ; i < curWsSize ; i++){
					loopy = curPageRef;
					curDis = 0;
					found = 0;
					for(int k = curPageIdx+1; k<pageReferencesSize; k++){
						loopy = LIST_NEXT(loopy);
						loopVa = ROUNDDOWN(loopy->virtual_address, PAGE_SIZE)/PAGE_SIZE;
						curDis++;
						if(loopVa == Active_WS_VAs[i]){
							found = 1;
							break;
						}
					}
					if(found == 0){
						victimIdx = i;
						break;
					}
					else{
						if(maxDis<curDis){
							maxDis = curDis;
							victimIdx = i;
						}
					}
				}
				if(victimIdx == -1){
					panic("can't be like that man , get_optimal_num_faults");
				}
				Active_WS_VAs[victimIdx] = curVa;
			}
		}
		else{
			// HIT , nothing to do
		}
		curPageIdx++;
	}

	kfree(Active_WS_VAs);
	return faults;
}


void page_replacement(struct Env * e,uint32 fva){
#if USE_KHEAP
	fva = ROUNDDOWN(fva, PAGE_SIZE);
	uint32 ova = ROUNDDOWN(e->page_last_WS_element->virtual_address, PAGE_SIZE);
	// UNALLOCATE OLD
	int perms = pt_get_page_permissions(e->env_page_directory , ova);
	uint32 *ptr_pg_table =NULL;
	struct FrameInfo *fi = get_frame_info(e->env_page_directory, ova ,&ptr_pg_table);
	if(fi ==0){panic("should be replaced but has no frame in mem!!\n");}
	if(perms & PERM_MODIFIED){
		//write it on page file;
		pf_update_env_page(e , ova, fi );
	}
	unmap_frame(e->env_page_directory, ova);
	struct WorkingSetElement* nextptr = LIST_NEXT(e->page_last_WS_element);
	if(nextptr== 0){
		nextptr = LIST_FIRST(&(e->page_WS_list));
	}
	LIST_REMOVE(&(e->page_WS_list) , e->page_last_WS_element);
	kfree(e->page_last_WS_element);

	ptr_pg_table =NULL;
	fi = get_frame_info(e->env_page_directory, fva ,&ptr_pg_table);
	if(fi != 0 ){
		// already in mem ya man just set it's present bit
		cprintf("in mem here in replace page\n");
		pt_set_page_permissions(e->env_page_directory,fva,PERM_PRESENT , 0 );
	}
	else
	{
		// load from page file
		allocate_frame(&fi);
		if(fi == NULL){panic("not enough space\n");}
		map_frame(e->env_page_directory , fi,fva , PERM_PRESENT | PERM_WRITEABLE | PERM_USER);

		int pf_ret = pf_read_env_page(e, (void*)fva);
		if(pf_ret == E_PAGE_NOT_EXIST_IN_PF) {
			if((fva >=USER_HEAP_START && fva < USER_HEAP_MAX) || (fva >= USTACKBOTTOM && fva < USTACKTOP)) {
				/*int pf_space_check = pf_update_env_page(faulted_env,rdfva,ptr_frame_info);
				if(pf_space_check == E_NO_PAGE_FILE_SPACE){
					panic("page file is full , cannot add faulted address va =%x" , fault_va);
				}*/
			}
			else
			{
				unmap_frame(e->env_page_directory,fva);
				cprintf("Page @va=%x does not exist in the page file\n", fva);
				env_exit();
			}
		}
	}

	struct WorkingSetElement* newWSE = env_page_ws_list_create_element(e, fva);
	e->page_last_WS_element = nextptr;
	LIST_INSERT_BEFORE(&(e->page_WS_list), e->page_last_WS_element, newWSE);
	pt_set_page_permissions(e->env_page_directory, fva, PERM_USED , 0);

#endif
}
void page_fault_handler(struct Env * faulted_env, uint32 fault_va)
{
#if USE_KHEAP
	if (isPageReplacmentAlgorithmOPTIMAL())
	{
		//TODO: [PROJECT'25.IM#1] FAULT HANDLER II - #1 Optimal Reference Stream
		//Your code is here
		//Comment the following line
		/*	[1] keep track of active working set
			[2] if faulted page not in memory read it from disk
			 	 Else , just set its present bit
			[3] if the faulted page in the active ws , do nothing
				else
					if active ws is full , reset all present and delete all
					else
			[4] add faulted page to the active ws
			[5] add the faulted page to the end of the reference stream
			*/
//		panic("page_fault_handler().REPLACEMENT is not implemented yet...!!");
		uint32 rdva = ROUNDDOWN(fault_va, PAGE_SIZE);

		uint32 *ptr_pg_table;
		struct FrameInfo* fi  = get_frame_info(faulted_env->env_page_directory , rdva , &ptr_pg_table);

		if((fi == 0) ){ // not in memory
//			cprintf(" va = %x not in mem \n" ,rdva );
			struct WorkingSetElement *elm2;
//			LIST_FOREACH( elm2, &(faulted_env->page_WS_list)){
//						cprintf(" cur va  in loop = %x \n" ,ROUNDDOWN(elm2->virtual_address, PAGE_SIZE) );
//
//					}
			int ret = alloc_page(faulted_env->env_page_directory, rdva ,  PERM_USER | PERM_PRESENT | PERM_WRITEABLE ,0);
			if(ret == E_NO_MEM) {
				panic("NOT FREE FRAMES TO ALLOCATE SPACE FOR THE REQUIRED PAGE FROM PAGE FILE");
			}
			int pf_ret = pf_read_env_page(faulted_env, (void*)rdva);
			if(pf_ret == E_PAGE_NOT_EXIST_IN_PF) {
				if((rdva >=USER_HEAP_START && rdva < USER_HEAP_MAX) || (rdva >= USTACKBOTTOM && rdva < USTACKTOP)) {
					/*int pf_space_check = pf_update_env_page(faulted_env,rdfva,ptr_frame_info);
					if(pf_space_check == E_NO_PAGE_FILE_SPACE){
						panic("page file is full , cannot add faulted address va =%x" , fault_va);
					}*/
				}
				else
				{
					unmap_frame(faulted_env->env_page_directory,rdva);
					cprintf("Page @va=%x does not exist in the page file\n", rdva);
					env_exit();
				}
			}
		}
		// exist just set it's present bit
		else{
			pt_set_page_permissions(faulted_env->env_page_directory,rdva,PERM_PRESENT | PERM_WRITEABLE,0);
		}

		struct WorkingSetElement *elm;
		bool existInWS =0;
		LIST_FOREACH( elm, &(faulted_env->ActiveList)){
//			cprintf(" cur va  in loop = %x , rouunded downVa = %x \n" ,ROUNDDOWN(elm->virtual_address, PAGE_SIZE) ,rdva );
			if(ROUNDDOWN(elm->virtual_address, PAGE_SIZE) == rdva){
				existInWS = 1;
//				cprintf(" va = %x , exist\n" ,rdva );
			}
		}
		if(existInWS == 1){
			// nothing
		}
		else{
//			cprintf("entered at va = %x\n" ,rdva );
			if(LIST_SIZE(&(faulted_env->ActiveList)) == faulted_env->page_WS_max_size){
				elm = NULL;
				LIST_FOREACH_SAFE( elm, &(faulted_env->ActiveList),WorkingSetElement)
				{
						pt_set_page_permissions(faulted_env->env_page_directory,ROUNDDOWN(elm->virtual_address, PAGE_SIZE) ,0 , PERM_PRESENT );
//						unmap_frame(faulted_env->env_page_directory, elm->virtual_address);
						// can we unmap ?
//						cprintf("removed va = %x\n" ,ROUNDDOWN(elm->virtual_address, PAGE_SIZE) );
						LIST_REMOVE(&(faulted_env->ActiveList), elm);
						kfree(elm);

				}
			}

			struct WorkingSetElement* new_ws_element = env_page_ws_list_create_element(faulted_env, rdva);
			LIST_INSERT_TAIL(&(faulted_env->ActiveList), new_ws_element);

		}
//		pt_set_page_permissions(faulted_env->env_page_directory,rdva ,0 , PERM_PRESENT );
		struct PageRefElement* pr = kmalloc(sizeof(struct PageRefElement));
		pr->virtual_address = rdva;
		LIST_INSERT_TAIL(&faulted_env->referenceStreamList , pr);
	}
	else
	{
		struct WorkingSetElement *victimWSElement = NULL;
		uint32 wsSize = LIST_SIZE(&(faulted_env->page_WS_list));
		if(wsSize < (faulted_env->page_WS_max_size))
		{
			//TODO: [PROJECT'25.GM#3] FAULT HANDLER I - #3 placement
			//Your code is here
			//Comment the following line
			//panic("page_fault_handler().PLACEMENT is not implemented yet...!!");

			uint32 rdfva = ROUNDDOWN(fault_va,PAGE_SIZE); //rounded down faulted virtual address
			int ret = alloc_page(faulted_env->env_page_directory, rdfva ,  PERM_USER | PERM_PRESENT | PERM_WRITEABLE ,0);
			if(ret == E_NO_MEM) {
				panic("NOT FREE FRAMES TO ALLOCATE SPACE FOR THE REQUIRED PAGE FROM PAGE FILE");
			}

			int pf_ret = pf_read_env_page(faulted_env, (void*)rdfva);
			if(pf_ret == E_PAGE_NOT_EXIST_IN_PF) {
				if((rdfva >=USER_HEAP_START && rdfva < USER_HEAP_MAX) || (rdfva >= USTACKBOTTOM && rdfva < USTACKTOP)) {
					/*int pf_space_check = pf_update_env_page(faulted_env,rdfva,ptr_frame_info);
					if(pf_space_check == E_NO_PAGE_FILE_SPACE){
						panic("page file is full , cannot add faulted address va =%x" , fault_va);
					}*/
				}
				else
				{
					unmap_frame(faulted_env->env_page_directory,rdfva);
					cprintf("Page @va=%x does not exist in the page file\n", rdfva);
					env_exit();
				}
			}

	        struct WorkingSetElement* new_ws_element = env_page_ws_list_create_element(faulted_env, rdfva);
	        	//LIST_INSERT_TAIL(&(faulted_env->page_WS_list) ,new_ws_element);
	        	//faulted_env->page_last_WS_element = new_ws_element;

	            if(faulted_env->page_last_WS_element == NULL){
	            	LIST_INSERT_TAIL(&(faulted_env->page_WS_list), new_ws_element);

	            	if (LIST_SIZE(&(faulted_env->page_WS_list)) == faulted_env->page_WS_max_size)
	            		faulted_env->page_last_WS_element = LIST_FIRST(&(faulted_env->page_WS_list));
	            }
	            else
	            	LIST_INSERT_BEFORE(&(faulted_env->page_WS_list), faulted_env->page_last_WS_element, new_ws_element);

			}
		else
		{
			if (isPageReplacmentAlgorithmCLOCK())
			{
				//TODO: [PROJECT'25.IM#1] FAULT HANDLER II - #3 Clock Replacement
				//Your code is here
				//Comment the following line
				//panic("page_fault_handler().REPLACEMENT is not implemented yet...!!");
				struct WorkingSetElement* wse;
				int perm = pt_get_page_permissions(faulted_env->env_page_directory , ROUNDDOWN(faulted_env->page_last_WS_element->virtual_address, PAGE_SIZE) );
				while(perm & PERM_USED){

					pt_set_page_permissions(faulted_env->env_page_directory , ROUNDDOWN(faulted_env->page_last_WS_element->virtual_address, PAGE_SIZE) ,0 , PERM_USED);
					faulted_env->page_last_WS_element = LIST_NEXT(faulted_env->page_last_WS_element);
					if(faulted_env->page_last_WS_element == 0){
						faulted_env->page_last_WS_element = LIST_FIRST(&(faulted_env->page_WS_list));
					}
					perm = pt_get_page_permissions(faulted_env->env_page_directory , ROUNDDOWN(faulted_env->page_last_WS_element->virtual_address, PAGE_SIZE));
//					cprintf("perms used : %d , va = %x \n" , perm & PERM_USED ,faulted_env->page_last_WS_element->virtual_address );
				}
				//
//				pt_set_page_permissions(faulted_env->env_page_directory , ROUNDDOWN(fault_va, PAGE_SIZE) ,PERM_USED , 0);
//				faulted_env->page_last_WS_element = LIST_NEXT((faulted_env->page_last_WS_element));

				page_replacement(faulted_env, fault_va);
			}
			else if (isPageReplacmentAlgorithmLRU(PG_REP_LRU_TIME_APPROX))
						{
							//TODO: [PROJECT'25.IM#6] FAULT HANDLER II - #2 LRU Aging Replacement
							//Your code is here
							//cprintf("env page ws print is called before lru\n");
//
//							cprintf("faulted address = %x\n",fault_va);
//							env_page_ws_print(faulted_env);

							struct WorkingSetElement* current=LIST_FIRST(&(faulted_env->page_WS_list));
							struct WorkingSetElement *victim = NULL;
							uint32 min_counter = 0xFFFFFFFF;
							//update_WS_time_stamps();

							while (current != NULL)
							{
							    if (current->time_stamp < min_counter)
							    {
							    	min_counter = current->time_stamp;
							        victim = current;
							    }
							    current = LIST_NEXT(current);
							}
							faulted_env->page_last_WS_element = victim;
							page_replacement(faulted_env, fault_va);

						}

			else if (isPageReplacmentAlgorithmModifiedCLOCK())
						{
							//TODO: [PROJECT'25.IM#6] FAULT HANDLER II - #3 Modified Clock Replacement
							//Your code is here

						    if (LIST_EMPTY(&(faulted_env->page_WS_list))) {
						        panic("MODCLOCK: empty WS on replacement");
						    }

						    struct WorkingSetElement *start = faulted_env->page_last_WS_element;
						    if (!start) start = LIST_FIRST(&(faulted_env->page_WS_list));
						    struct WorkingSetElement *current = start;
						    struct WorkingSetElement *victim = NULL;
						    for(int i =0  ; i< 2 ; i++ ){
						    do {
						        int pt = pt_get_page_permissions(faulted_env->env_page_directory, current->virtual_address);
						        bool used = (pt != -1) && (pt & PERM_USED);
						        bool modified = (pt != -1) && (pt & PERM_MODIFIED);
						        if (!used && !modified) {
						            victim = current;
						            break;
						        }
						        current = (current == LIST_LAST(&(faulted_env->page_WS_list))) ? LIST_FIRST(&(faulted_env->page_WS_list)) : LIST_NEXT(current);
						    } while (current != start);

						    if (!victim) {
						        current = start;
						        do {
						            int pt = pt_get_page_permissions(faulted_env->env_page_directory, current->virtual_address);
						            bool used = (pt != -1) && (pt & PERM_USED);
						            bool modified = (pt != -1) && (pt & PERM_MODIFIED);
						            if (used) {
						                pt_set_page_permissions(faulted_env->env_page_directory, current->virtual_address, 0, PERM_USED);
						            } else if (!used && modified) {
						                victim = current;
						                break;
						            }
						            current = (current == LIST_LAST(&(faulted_env->page_WS_list))) ? LIST_FIRST(&(faulted_env->page_WS_list)) : LIST_NEXT(current);
						        } while (current != start);
						    }
						}
						    if (!victim) {
						        victim = start;
						    }

							faulted_env->page_last_WS_element = victim;
							page_replacement(faulted_env, fault_va);

							//Comment the following line
							//panic("page_fault_handler().REPLACEMENT is not implemented yet...!!");
						}
					}
	}
#endif
}


void __page_fault_handler_with_buffering(struct Env * curenv, uint32 fault_va)
{
	panic("this function is not required...!!");
}



