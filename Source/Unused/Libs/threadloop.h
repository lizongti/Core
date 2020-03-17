#ifndef thread_loop_h
#define thread_loop_h

#include <uv.h>

uv_loop_t * get_thread_loop(uv_thread_t * t);

void set_thread_loop(uv_thread_t * t, uv_loop_t * l);

#endif


