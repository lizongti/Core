#ifdef _WIN32
#include <Windows.h>
#else
#include <unistd.h>
#endif

#include <stdint.h>

extern "C" {
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
}

static int system_sleep(lua_State * L)
{
	int milliseconds = lua_tointeger(L, 1);
#ifdef _WIN32
	Sleep(milliseconds);
#else
	usleep(milliseconds * 1000);
#endif
	return 0;
}


#ifdef _WIN32
static void set_low(int64_t* value, int low) {
	*value &= (int64_t)0xffffffff << 32;
	*value |= (int64_t)(uint64_t)(uint32_t)low;
}

static void set_high(int64_t* value, int high) {
	*value &= (int64_t)(uint64_t)(uint32_t)0xffffffff;
	*value |= (int64_t)high << 32;
}

static int64_t int64_t_from(int h, int l) {
	int64_t result = 0;
	set_high(&result, h);
	set_low(&result, l);
	return result;
}

static int64_t  _offset = 116444736000000000;

int64_t offset() {
	return _offset;
}

int64_t igs_time()
{
	static FILETIME wt;
	GetSystemTimeAsFileTime(&wt);
	return (int64_t_from(wt.dwHighDateTime, wt.dwLowDateTime) - offset()) / 10000;
}

#else

int64_t igs_time()
{
	struct timeval tv;
	gettimeofday(&tv, NULL);
	return tv.tv_sec * (uint64_t)1000 + tv.tv_usec / 1000.0;
}

#endif


static int system_time(lua_State * L)
{
	lua_pushnumber(L, igs_time());
	return 1;
}

static const luaL_Reg lib_system[] = {
	{ "sleep", system_sleep },
	{ "time", system_time },
	{ NULL, NULL }
};

LUALIB_API int luaopen_util(lua_State *L) {
	luaL_register(L, "system", lib_system);
    return 0;
}


