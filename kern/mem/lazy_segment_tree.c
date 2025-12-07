/*
 * lazy_segment_tree.c
 *
 *  Created on: Dec 5, 2025
 *      Author: peter
 */


#include "lazy_segment_tree.h"

struct Node merge(struct Node left , struct Node right)
{
  struct Node ret;
  ret.sum = left.sum + right.sum;
  ret.pre = MAX(left.pre, left.sum + right.pre);
  ret.suf = MAX(right.suf, right.sum + left.suf);
  ret.mx = MAX(MAX(left.mx, right.mx), left.suf + right.pre);
  return ret;
}

void build(uint32 l , uint32 r , uint32 node)
{
  lazy[node].rev = -1;
  if(l == r)
  {
    seg[node].pre = seg[node].suf = seg[node].mx = seg[node].sum = PAGE_NOT_FREE;
    return;
  }
  build(l, mid, L);
  build(mid + 1, r, R);
  seg[node] = merge(seg[L], seg[R]);
}

void propagate(uint32 l, uint32 r , uint32 node)
{
  if(lazy[node].rev == -1)
    return;
  uint32 val = lazy[node].rev ? 1 : 0;
  seg[node].sum = (r - l + 1) * (!val ? PAGE_NOT_FREE : 1);
  seg[node].pre = seg[node].suf = seg[node].mx = seg[node].sum;
  if(l != r)
  {
    lazy[L].rev = lazy[node].rev;
    lazy[R].rev = lazy[node].rev;
  }
  lazy[node].rev = -1;
}

void update(uint32 l , uint32 r , uint32 node , uint32 lq , uint32 rq , uint32 val) // 1 for free , 0 for allocated
{
  propagate(l, r, node);
  if(l > rq || r < lq)
    return;
  if(l >= lq && r <= rq)
  {
    lazy[node].rev = val;
    propagate(l, r, node);
    return;
  }
  update(l, mid, L, lq, rq, val);
  update(mid + 1, r, R, lq, rq, val);
  seg[node] = merge(seg[L], seg[R]);
}

struct queryNode query_worst_fit(uint32 l , uint32 r , uint32 node , uint32 sz)
{
  propagate(l, r, node);
  if(seg[node].mx < sz)
    return (struct queryNode){-1, -1};
  if(l == r)
    return (struct queryNode){l, l};
  propagate(l, mid, L);
  propagate(mid + 1, r, R);
  if(seg[L].mx == seg[node].mx)
    return query_worst_fit(l, mid, L, sz);
  if(seg[L].suf + seg[R].pre == seg[node].mx)
  {
    uint32 start = mid - seg[L].suf + 1;
    uint32 end = start + seg[node].mx - 1;
    return (struct queryNode){start, end};
  }
  return query_worst_fit(mid + 1, r, R, sz);
}


/* val = 0 if you want to mark the pages from l to r as allocated and val = 1 if you want to mark them as free */
void update_pages_state(uint32 l , uint32 r , uint32 val)
{
	if(l > r)
		return;
  update(0, NUM_OF_SEG_KHEAP_PAGES - 1, 0, l, r, val);
}

void build_seg_tree()
{
  build(0, NUM_OF_SEG_KHEAP_PAGES - 1, 0);
}

struct queryNode get_worst_fit(uint32 sz)
{
  return query_worst_fit(0, NUM_OF_SEG_KHEAP_PAGES - 1, 0, sz);
}
