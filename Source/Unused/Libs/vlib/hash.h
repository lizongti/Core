#ifndef hash_h
#define hash_h

#include <stdint.h>

struct hash_node_s;

typedef struct hash_s {
    struct hash_node_s** buckets;
    uint32_t capacity;
	uint32_t size;
} hash_t;

struct queue_s;

extern hash_t * hash_create();

extern void hash_destroy(hash_t * h);

extern int hash_put(hash_t * h, int key, void * val);

extern int hash_remove(hash_t * h, int key);

extern int hash_size(hash_t * h);

extern struct queue_s *  hash_values(hash_t * h);

extern void * hash_get(hash_t * h, int key);

extern int hash_put_s(hash_t * h, const char * key, void * val);

extern int hash_remove_s(hash_t * h, const char * key);

extern void * hash_get_s(hash_t * h, const char * key);

#endif