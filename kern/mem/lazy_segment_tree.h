/*
 * lazy_segment_tree.h
 *
 *  Created on: Dec 5, 2025
 *      Author: peter
 */

#ifndef KERN_MEM_LAZY_SEGMENT_TREE_H_
#define KERN_MEM_LAZY_SEGMENT_TREE_H_

#include <inc/mmu.h>
#include <inc/memlayout.h>


struct Node
{
  int64 mx, pre, suf, sum;
};

struct LazyNode
{
  int rev;
};

struct queryNode
{
  uint32 start, end;
};

#define PAGE_NOT_FREE -80000LL // a large negative number to represent non-free page
//KHEAP pages number
#define NUM_OF_SEG_KHEAP_PAGES 65540

#define L ((node << 1) + 1)
#define R ((node << 1) + 2)
#define mid (l + (r - l) / 2)



struct LazyNode lazy[NUM_OF_SEG_KHEAP_PAGES << 2];
struct Node seg[NUM_OF_SEG_KHEAP_PAGES << 2];

void build(uint32 l, uint32 r, uint32 node);
void update(uint32 l, uint32 r, uint32 node, uint32 lq, uint32 rq, uint32 val); // 1 for free , 0 for allocated
void propagate(uint32 l, uint32 r, uint32 node);
struct Node merge(struct Node left, struct Node right);
struct queryNode query_worst_fit(uint32 l, uint32 r, uint32 node, uint32 sz);
void update_pages_state(uint32 l, uint32 r, uint32 val);
void build_seg_tree();
struct queryNode get_best_fit(uint32 sz);
struct queryNode get_worst_fit(uint32 sz);
int64 query_sum(uint32 l , uint32 r, uint32 node, uint32 lq , uint32 rq);
int64 get_free_pages(uint32 l , uint32 r);

#endif /* KERN_MEM_LAZY_SEGMENT_TREE_H_ */
