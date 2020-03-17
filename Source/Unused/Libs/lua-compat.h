#ifndef lua_compat_h
#define lua_compat_h

#define LUA_COMPAT_APIINTCASTS
#include <lua.h>
#include <lauxlib.h>
#include <lauxlib.h>

#if defined(LUA_VERSION_NUM) && LUA_VERSION_NUM > 501

#define lua_objlen lua_rawlen

#endif

#endif