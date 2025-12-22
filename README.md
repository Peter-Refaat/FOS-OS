# FOS-OS (Faculty Operating System)

FOS is an educational operating system designed to demonstrate core OS concepts including memory management, process scheduling, and concurrency.

## Features Implemented

### 1. Fault Handling & Paging
Integrated a robust page fault handler that manages memory virtualization and on-demand paging.
- **Fault Handler**: Manages both page faults and table faults, ensuring efficient memory allocation and retrieval from the page file.
- **Placement & Replacement Algorithms**:
    - **FIFO**: Simple first-in-first-out replacement.
    - **Clock**: Integrated use-bit based approximation for LRU.
    - **LRU**: Least Recently Used algorithm with timestamping.
    - **N-Chance Clock**: A variation of the Clock algorithm that gives pages multiple "chances" before eviction.
    - **Optimal Replacement**: Implemented for performance evaluation, selecting the page that will not be used for the longest period in the future.

### 2. Memory Management
- **Kernel Heap**: A dedicated heap for the kernel, supporting `kmalloc` and `kfree` for dynamic memory allocation within kernel space.
- **Dynamic Allocator**: The core allocation logic using strategies like **First-Fit** to manage memory blocks efficiently, minimizing fragmentation.
- **User Heap**: Provides user-level programs with dynamic memory allocation capabilities (`malloc`, `free`), managing the user-space heap range.
- **Shared Memory**: Enables inter-process communication (IPC) by allowing multiple environments to map and share the same physical memory pages using `smalloc`, `sget`, and `sfree`.

### 3. Concurrency & Synchronization
- **Locks**:
    - **Spinlocks**: Used for protecting short critical sections where the overhead of sleeping is higher than busy-waiting.
    - **Sleeplocks**: Designed for long-duration locks where the process yields the CPU and sleeps until the lock is available.
- **Semaphores**: Kernel-level semaphores for process synchronization.

### 4. CPU Scheduling
Implemented multiple scheduling policies to manage process execution:
- **Round Robin (RR)**: Basic time-slicing for fair distribution of CPU time.
- **Priority Round Robin (PRIRR)**: Combines priority levels with Round Robin scheduling within each level.
