#include "hash.h"

#include <assert.h>
#include <string.h>
#include <stdlib.h>

#include "queue.h"

#define HASH_NODE_KEY_INT 0
#define HASH_NODE_KEY_STRING 1
#define HASH_NODE_KEY_POINT 2

#define HASH_INIT_SIZE 1023

#define FNV32_BASE ((unsigned int) 0x811c9dc5)
#define FNV32_PRIME ((unsigned int) 0x01000193)

/**
	hash表算法说明：
	1、key的类型问题，参考git源码，git支持字符串、指针类型，本代码实现暂时只支持int、字符串类型，
	考虑性能和简易问题
	2、字符串hashcode生成采用FNV32算法
	3、rehash采用直接realloc原地址，直接在原表上进行操作，在内存方面会好些
*/

typedef struct hash_node_s
{
	unsigned rehash: 1;
	int8_t key_type;
	int key;
	char * key_s;
	void * val;
	struct hash_node_s* prev;
	struct hash_node_s* next;
} hash_node_t;


static void delink(hash_node_t * p)
{
	if (p->next) {
		p->next->prev = p->prev;
	}
	if (p->prev) {
		p->prev->next = p->next;
	}
}

static uint32_t hash_int(hash_t * h, size_t key)
{
	key = ((key >> 16) ^ key) * 0x45d9f3b;
	key = ((key >> 16) ^ key) * 0x45d9f3b;
	key = (key >> 16) ^ key;
	return ((uint32_t)key) % h->capacity;
}

static size_t hash_str(hash_t * h, const char* str)
{
	unsigned int c, hash = FNV32_BASE;
	while ((c = (unsigned char) * str++))
		hash = (hash * FNV32_PRIME) ^ c;
	return hash % h->capacity;
}

static size_t hash_code(hash_t * h , hash_node_t * p)
{
	if (p->key_type == HASH_NODE_KEY_INT) {
		return hash_int(h, p->key);
	} else if (p->key_type == HASH_NODE_KEY_STRING) {
		return hash_str(h, p->key_s);
	}
	assert(0);
	return 0;
}

static void bucket_link(hash_t* h, int hc, hash_node_t * node)
{
	hash_node_t * p = h->buckets[hc];
	if (p) {
		node->next = p;
		node->prev = 0;
		p->prev = node;
	}

	h->buckets[hc] = node;
}

hash_t * hash_create()
{
	hash_t * h = malloc(sizeof(hash_t));
	memset(h, 0, sizeof(hash_t));
	h->capacity = HASH_INIT_SIZE;
	h->buckets = malloc(HASH_INIT_SIZE * sizeof(hash_node_t*));
	if (!h->buckets) {
		free(h);
		return 0;
	}
	memset(h->buckets, 0, HASH_INIT_SIZE * sizeof(hash_node_t*));
	return h;
}

void hash_destroy(hash_t * h)
{
	for (size_t i = 0; i < h->capacity; ++i) {
		if (h->buckets[i]) {
			if (h->buckets[i]->key_type == HASH_NODE_KEY_STRING) {
				free(h->buckets[i]->key_s);
			}
			free(h->buckets[i]);
		}
	}
	free(h->buckets);
	memset(h, 0, sizeof(*h));
	free(h);
}

static void resize(hash_t* h)
{
	for (size_t i = 0; i < h->capacity; ++i) {
		if (!h->buckets[i]) {
			return;
		}
	}
	int old_size = h->capacity;
	int size = ((h->capacity + 1) * 2 - 1);
	h->buckets = realloc(h->buckets, (sizeof(hash_node_t)) * size);
	memset(h->buckets + h->capacity * (sizeof(hash_node_t)), 0, size - h->capacity);
	h->capacity = size;

	//rehash for new size
	for (size_t i = 0; i < old_size; ++i) {
		hash_node_t * p = h->buckets[i];
		while (p) {
			if (p->rehash) {
				p = p->next;
				continue;
			}
			hash_node_t * next = p->next;
			delink(p);
			int hc = hash_code(h, p);
			bucket_link(h, hc, p);
			p->rehash = 1;
			p = p->next;
		}
	}

	for (size_t i = 0; i < h->capacity; ++i) {
		hash_node_t * p = h->buckets[i];
		while (p) {
			p->rehash = 0;
			p = p->next;
		}
	}
}

static hash_node_t * _hash_get(hash_t * h, int key)
{
	int hc = hash_int(h, key);
	hash_node_t * p = h->buckets[hc];

	while (p) {
		if (p->key == key) {
			return p;
		}
		p = p->next;
	}

	return 0;
}

int hash_size(hash_t * h)
{
	return h->size;
}

int hash_put(hash_t * h, int key, void * val)
{
	hash_node_t * t = _hash_get(h, key);
	if (t) {
		t->val = val;
		return 1;
	}
	resize(h);
	int hc = hash_int(h, key);
	hash_node_t * node = malloc(sizeof(hash_node_t));
	memset(node, 0, sizeof(hash_node_t));
	bucket_link(h, hc, node);
	node->val = val;
	node->key = key;
	node->key_type = HASH_NODE_KEY_INT;
	h->size++;
	return 0;
}

int hash_remove(hash_t * h, int key)
{
	int hc = hash_int(h, key);
	hash_node_t * p = h->buckets[hc];

	while (p) {
		if (p->key == key) {
			if (h->buckets[hc] == p) {
				h->buckets[hc] = 0;
			}
			delink(p);
			free(p);
			h->size--;
			return 1;
		}
		p = p->next;
	}
	return 0;
}

void * hash_get(hash_t * h, int key)
{
	if (!h) {
		return 0;
	}
	hash_node_t * p = _hash_get(h, key);
	if (p) {
		return p->val;
	}
	return 0;
}

static hash_node_t * _hash_get_s(hash_t * h, const char * key)
{
	int hc = hash_str(h, key);
	hash_node_t * p = h->buckets[hc];

	while (p) {
		if (!strcmp(p->key_s, key)) {
			return p;
		}
		p = p->next;
	}

	return 0;
}

int hash_put_s(hash_t * h, const char * key, void * val)
{
	hash_node_t * t = _hash_get_s(h, key);
	if (t) {
		t->val = val;
		return 0;
	}

	resize(h);

	int hc = hash_str(h, key);
	hash_node_t * p = h->buckets[hc];

	hash_node_t * new_bucket = malloc(sizeof(hash_node_t));
	memset(new_bucket, 0, sizeof(hash_node_t));

	if (p) {
		new_bucket->next = p;
		new_bucket->prev = 0;
		p->prev = new_bucket;
	}

	h->buckets[hc] = new_bucket;

	new_bucket->val = val;
	new_bucket->key_type = HASH_NODE_KEY_STRING;
	new_bucket->key_s = malloc(strlen(key) + 1);
	strcpy(new_bucket->key_s, key);
	return 1;
}

int hash_remove_s(hash_t * h, const char * key)
{
	int hc = hash_str(h, key);
	hash_node_t * p = h->buckets[hc];

	while (p) {
		if (!strcmp(p->key_s, key)) {
			if (h->buckets[hc] == p) {
				h->buckets[hc] = 0;
			}
			if (p->next) {
				p->next->prev = p->prev;
			}
			if (p->prev) {
				p->prev->next = p->next;
			}
			free(p->key_s);
			free(p);
			return 1;
		}
		p = p->next;
	}
	return 0;
}

void * hash_get_s(hash_t * h, const char * key)
{
	hash_node_t * p = _hash_get_s(h, key);
	if (p) {
		return p->val;
	}
	return 0;
}

struct queue_s *  hash_values(hash_t * h)
{
	queue_t * q = q_create();
	for (uint32_t i = 0; i < h->capacity; ++i) {
		if (h->buckets[i] != 0) {
			hash_node_t * p = h->buckets[i];
			while (p) {
				q_push(q, p->val);
				p = p->next;
			}
		}
	}
	return q;
}