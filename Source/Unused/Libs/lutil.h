#ifndef lutil_h
#define lutil_h
#include <lua.h>
#include <stdint.h>
#include <string.h>
#include "vlib/vstr.h"

int push_f(lua_State* L, int f);

int lcall(lua_State* L, int f, int argn);

const char * lcallstr(lua_State* L, int f, int argn);

vstr_t * lua_sprintf(lua_State * L, int idx);

int64_t v8_time();

vstr_t * v8_shell(const char * cmd);

#ifdef _WIN32
char * strndup(char * p, int l);
#endif

#endif


