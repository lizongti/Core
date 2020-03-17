#ifndef queue_h
#define queue_h

#include <stdint.h>

typedef struct q_node_s{
    struct q_node_s * next;
    struct q_node_s * prev;
    void * val;
}q_node_t;

typedef struct queue_s{
    uint32_t size;
    struct q_node_s * head;
    struct q_node_s * tail;
}queue_t;

/* 创建一个queue*/
struct queue_s * q_create();

/* 销毁一个queue*/
void q_destroy(struct queue_s * q);

/* 在尾部插入*/
void q_push(struct queue_s * q, void * val);

/* 在头部插入*/
void q_jump(struct queue_s * q, void * val);

/* 弹出头部*/
void * q_pop(struct queue_s * q);

void * q_index(struct queue_s * q, int index);

/* 查看头部*/
void * q_peek(struct queue_s * q);

void * q_tail(struct queue_s * q);

/* 获取大小*/
uint32_t q_size(struct queue_s * q);

#endif