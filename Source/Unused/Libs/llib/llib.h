#ifndef llib_h
#define llib_h

extern "C" {
    extern int luaopen_base64(lua_State *L);
	extern int luaopen_pb(lua_State *L);
    extern int luaopen_lpeg(lua_State *L);
	extern int luaopen_DDZCPoker(lua_State *L);
	extern int luaopen_shell(lua_State *L);
	extern int luaopen_profiler(lua_State *L);
}

extern int luaopen_json(lua_State *L);
extern int luaopen_rapidjson(lua_State* L);

#endif