#include "threadloop.h"
#include "vlib/hash.h"

static hash_t * h = 0;

uv_loop_t *get_thread_loop(uv_thread_t *t)
{
	uv_loop_t * l = hash_get(h, *t);
    return l;
}

void set_thread_loop(uv_thread_t *t, uv_loop_t *l)
{
	if (!h) {
		h = hash_create();
	}

	hash_put(h, *t, l);
}
