/*
@desc lua性能辅助函数
@author dansen
*/

#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <assert.h>
#include <stdint.h>
#include <ctype.h>

#include <uv.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <lstate.h>

static int memory(lua_State * L) {
	global_State *g = G(L);
	lua_pushinteger(L, g->totalbytes);
	return 1;
}

static const struct luaL_reg lib_profiler[] = {
	{ "memory", memory },
	{ NULL, NULL }
};

LUA_API int luaopen_profiler(lua_State *L)
{
	luaL_register(L, "profiler", lib_profiler);
	return 0;
}

