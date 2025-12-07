/*
 * channel.c
 *
 *  Created on: Sep 22, 2024
 *      Author: HP
 */
#include "channel.h"
#include <kern/proc/user_environment.h>
#include <kern/cpu/sched.h>
#include <inc/string.h>
#include <inc/disk.h>

//===============================
// 1) INITIALIZE THE CHANNEL:
//===============================
// initialize its lock & queue
void init_channel(struct Channel *chan, char *name)
{
	strcpy(chan->name, name);
	init_queue(&(chan->queue));
}

//===============================
// 2) SLEEP ON A GIVEN CHANNEL:
//===============================
// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
// Ref: xv6-x86 OS code
void sleep(struct Channel *chan, struct kspinlock* lk)
{
	//TODO: [PROJECT'25.IM#5] KERNEL PROTECTION: #1 CHANNEL - sleep
	//Your code is here
	//Comment the following line
	//panic("sleep() is not implemented yet...!!");

	/* Get the current process */
	struct Env* current_process = get_cpu_proc();

	if(current_process == NULL)
		return;

	acquire_kspinlock(&ProcessQueues.qlock);

	/* Adding the current process in the wait queue */
	enqueue(&chan->queue, current_process);

	/* Block the current Process and Release the lock */
	current_process->env_status = ENV_BLOCKED;
	current_process->channel = chan;
	release_kspinlock(lk);
	sched();

	release_kspinlock(&ProcessQueues.qlock);

	/* Reacquire the Lock */
	acquire_kspinlock(lk);
}

//==================================================
// 3) WAKEUP ONE BLOCKED PROCESS ON A GIVEN CHANNEL:
//==================================================
// Wake up ONE process sleeping on chan.
// The qlock must be held.
// Ref: xv6-x86 OS code
// chan MUST be of type "struct Env_Queue" to hold the blocked processes
void wakeup_one(struct Channel *chan)
{
	//TODO: [PROJECT'25.IM#5] KERNEL PROTECTION: #2 CHANNEL - wakeup_one
	//Your code is here
	//Comment the following line
	//panic("wakeup_one() is not implemented yet...!!");

	struct Env* process_to_wake;

	acquire_kspinlock(&ProcessQueues.qlock);
	process_to_wake = dequeue(&chan->queue);

	/* Wake up the first process in the wait queue if it exists */
	if(process_to_wake != NULL)
	{
		sched_insert_ready(process_to_wake);
		process_to_wake->channel = 0;
	}

	release_kspinlock(&ProcessQueues.qlock);
}

//====================================================
// 4) WAKEUP ALL BLOCKED PROCESSES ON A GIVEN CHANNEL:
//====================================================
// Wake up all processes sleeping on chan.
// The queues lock must be held.
// Ref: xv6-x86 OS code
// chan MUST be of type "struct Env_Queue" to hold the blocked processes

void wakeup_all(struct Channel *chan)
{
	//TODO: [PROJECT'25.IM#5] KERNEL PROTECTION: #3 CHANNEL - wakeup_all
	//Your code is here
	//Comment the following line
	//panic("wakeup_all() is not implemented yet...!!");

	struct Env_Queue* waiting_queue = &chan->queue;

	acquire_kspinlock(&ProcessQueues.qlock);

	/* Wake up all blocked processes */
	while(queue_size(&chan->queue) > 0)
	{
		struct Env* process_to_wake = dequeue(waiting_queue);
		sched_insert_ready(process_to_wake);
		process_to_wake->channel = 0;
	}

	release_kspinlock(&ProcessQueues.qlock);
}
