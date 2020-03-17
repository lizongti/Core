#include "queue.h"

#include <stdlib.h>
#include <memory.h>

/* 创建一个queue*/
queue_t * q_create()
{
    queue_t * q = malloc(sizeof(queue_t));
    memset(q, 0, sizeof(*q));
    return q;
}

/* 销毁一个queue*/
void q_destroy(queue_t * q)
{
	if (!q)return;

    while(q->size){
        q_pop(q);
    }
    free(q);
}

/* 在尾部插入*/
void q_push(queue_t * q, void * val)
{
    q_node_t * n = malloc(sizeof(q_node_t));
    memset(n, 0, sizeof(*n));
    n->val = val;

    if(q->head){
        n->prev = q->tail;
        q->tail->next = n;
		q->tail = n;
    }else{
        q->head = n;
        q->tail = n;
    }
    q->size++;
}

/* 在头部插入*/
void q_jump(queue_t * q, void * val)
{
    q_node_t * n = malloc(sizeof(q_node_t));
    memset(n, 0, sizeof(*n));
    n->val = val;

    if(q->head){
        q->head->prev = n;
        n->next = q->head;
        q->head = n;
    }else{
        q->head = n;
        q->tail = n;
    }
    q->size++;
}

/* 弹出头部*/
void * q_pop(queue_t * q)
{
    q_node_t * n = q->head;
    void * val = 0;

    if(n){
		q->head = q->head->next;
		if(q->head){
			q->head->prev = 0;
		}
		val = n->val;
        free(n);
        q->size--;
    }
	if (!q->size){
		q->tail = 0;
	}
    return val;
}

/* 查看头部*/
void * q_peek(queue_t * q)
{
    if(q->head){
        return q->head->val;
    }

    return 0;
}

void * q_tail(struct queue_s * q)
{
	if (q->tail) {
		return q->tail->val;
	}

	return 0;
}

/* 获取大小*/
uint32_t q_size(struct queue_s * q)
{
	if (!q) { return 0; }
    return q->size;
}

void * q_index(struct queue_s * q, int index)
{
	q_node_t * p = q->head;
	for (int i = 0; i < index && p; ++i) {
		p = p->next;
	}
	return p->val;
}