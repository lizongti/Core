#include "lutil.h"
#include <lua.h>
#include <lauxlib.h>
#include <assert.h>
#include <stdint.h>
#include <time.h>

#ifdef _WIN32
#include <Windows.h>
#else
#include <sys/time.h>
#endif

#define LUA_INTFRMLEN           "l"
#define LUA_INTFRM_T            long

#define L_ESC		'%'
#define SPECIALS	"^$*+?.([%-"
#define MAX_ITEM	512
#define FLAGS	"-+ #0"
#define MAX_FORMAT	(sizeof(FLAGS) + sizeof(LUA_INTFRMLEN) + 10)
#define uchar(c)        ((unsigned char)(c))

static const char *scanformat(lua_State *L, const char *strfrmt, char *form) {
	const char *p = strfrmt;
	while (*p != '\0' && strchr(FLAGS, *p) != NULL) p++;  /* skip flags */
	if ((size_t)(p - strfrmt) >= sizeof(FLAGS))
		luaL_error(L, "invalid format (repeated flags)");
	if (isdigit(uchar(*p))) p++;  /* skip width */
	if (isdigit(uchar(*p))) p++;  /* (2 digits at most) */
	if (*p == '.') {
		p++;
		if (isdigit(uchar(*p))) p++;  /* skip precision */
		if (isdigit(uchar(*p))) p++;  /* (2 digits at most) */
	}
	if (isdigit(uchar(*p)))
		luaL_error(L, "invalid format (width or precision too long)");
	*(form++) = '%';
	strncpy(form, strfrmt, p - strfrmt + 1);
	form += p - strfrmt + 1;
	*form = '\0';
	return p;
}

static void addintlen(char *form) {
	size_t l = strlen(form);
	char spec = form[l - 1];
	strcpy(form + l - 1, LUA_INTFRMLEN);
	form[l + sizeof(LUA_INTFRMLEN) - 2] = spec;
	form[l + sizeof(LUA_INTFRMLEN) - 1] = '\0';
}

static void addquoted(lua_State *L, luaL_Buffer *b, int arg) {
	size_t l;
	const char *s = luaL_checklstring(L, arg, &l);
	luaL_addchar(b, '"');
	while (l--) {
		switch (*s) {
		case '"': case '\\': case '\n': {
			luaL_addchar(b, '\\');
			luaL_addchar(b, *s);
			break;
		}
		case '\r': {
			luaL_addlstring(b, "\\r", 2);
			break;
		}
		case '\0': {
			luaL_addlstring(b, "\\000", 4);
			break;
		}
		default: {
			luaL_addchar(b, *s);
			break;
		}
		}
		s++;
	}
	luaL_addchar(b, '"');
}

vstr_t * lua_sprintf(lua_State * L, int idx)
{
	int top = lua_gettop(L);
	int arg = idx;
	size_t sfl;
	const char *strfrmt = luaL_checklstring(L, arg, &sfl);
	const char *strfrmt_end = strfrmt + sfl;
	vstr_t * b = vstr_alloc(0);
	while (strfrmt < strfrmt_end) {
		if (*strfrmt != L_ESC)
			vstr_putchar(b, *strfrmt++);
		else if (*++strfrmt == L_ESC)
			vstr_putchar(b, *strfrmt++);
		else { /* format item */
			char form[MAX_FORMAT];  /* to store the format (`%...') */
			char buff[MAX_ITEM];  /* to store the formatted item */
			if (++arg > top)
				luaL_argerror(L, arg, "no value");
			strfrmt = scanformat(L, strfrmt, form);
			switch (*strfrmt++) {
			case 'c': {
				sprintf(buff, form, (int)luaL_checknumber(L, arg));
				break;
			}
			case 'd':  case 'i': {
				addintlen(form);
				sprintf(buff, form, (LUA_INTFRM_T)luaL_checknumber(L, arg));
				break;
			}
			case 'o':  case 'u':  case 'x':  case 'X': {
				addintlen(form);
				sprintf(buff, form, (unsigned LUA_INTFRM_T)luaL_checknumber(L, arg));
				break;
			}
			case 'e':  case 'E': case 'f':
			case 'g': case 'G': {
				sprintf(buff, form, (double)luaL_checknumber(L, arg));
				break;
			}
			case 'q': {
				addquoted(L, &b, arg);
				continue;  /* skip the 'addsize' at the end */
			}
			case 's': {
				size_t l;
				const char *s = luaL_checklstring(L, arg, &l);
				if (!strchr(form, '.') && l >= 100) {
					vstr_putlstring(b, s, l);
					continue;  /* skip the `addsize' at the end */
				}
				else {
					sprintf(buff, form, s);
					break;
				}
			}
			default: {  /* also treat cases `pnLlh' */
				return luaL_error(L, "invalid option " LUA_QL("%%%c") " to "
					LUA_QL("format"), *(strfrmt - 1));
			}
			}
			vstr_putlstring(b, buff, strlen(buff));
		}
	}

	return b;
}

#ifdef _WIN32
char * strndup(char * p, int l)
{
	char * n = malloc(l + 1);
	memcpy(n, p, l);
	n[l] = 0;
	return n;
}
#endif

static int _traceback(lua_State *L) {
#if defined(LUA_VERSION_NUM) && LUA_VERSION_NUM >= 503
	lua_getglobal(L, "debug");
#else
	lua_getfield(L, LUA_GLOBALSINDEX, "debug");
#endif
	lua_getfield(L, -1, "traceback");
	lua_pushvalue(L, 1);
	lua_pushinteger(L, 2);
	lua_call(L, 2, 1);
	fprintf(stderr, "%s\n", lua_tostring(L, -1));
	return 1;
}

static int call_f(lua_State * L, int argn)
{
	int idx = -(argn + 1);
	if (!lua_isfunction(L, idx))
	{
		return 0;
	}

	int error = 0;
	error = lua_pcall(L, argn, 1, 0);

	if (error)
	{
		fprintf(stderr, "[lua][error]%s\n", lua_tostring(L, -1));
		_traceback(L);
		return 0;
	}

	int ret = 0;

	int type = lua_type(L, -1);

	if (lua_isnumber(L, -1))
	{
		ret = lua_tointeger(L, -1);
	}
	else if (lua_isboolean(L, -1))
	{
		ret = lua_toboolean(L, -1);
	}

	lua_pop(L, 1);
	return ret;
}

static const char * call_f_str(lua_State * L, int argn)
{
	int idx = -(argn + 1);
	if (!lua_isfunction(L, idx))
	{
		return 0;
	}

	int error = 0;
	error = lua_pcall(L, argn, 1, 0);

	if (error)
	{
		printf("[lua][error]%s\n", lua_tostring(L, -1));
		const char * msg = lua_tostring(L, -1);
		_traceback(L);
		return msg;
	}

	const char * ret = 0;

	if (lua_isstring(L, -1))
	{
		ret = lua_tostring(L, -1);
	}

	lua_pop(L, 1);

	return ret;
}

int push_f(lua_State * L, int f)
{
	toluafix_get_function_by_refid(L, f);
	if (!lua_isfunction(L, -1))
	{
		assert(0);
		lua_pop(L, 1);
		return 0;
	}
	return 1;
}

int lcall(lua_State* L, int f, int argn)
{
	int ret = 0;
	if (push_f(L, f))
	{
		if (argn > 0)
		{
			lua_insert(L, -(argn + 1));
		}
		ret = call_f(L, argn);
	}
	lua_settop(L, 0);
	return ret;
}

const char * lcallstr(lua_State* L, int f, int argn)
{
	const char * ret = 0;
	if (push_f(L, f))
	{
		if (argn > 0)
		{
			lua_insert(L, -(argn + 1));
		}
		ret = call_f_str(L, argn);
	}
	lua_settop(L, 0);
	return ret;
}

char * load_file(const char * path)
{
	char * buf = NULL;
	int size, len;
	FILE * fp = fopen(path, "r");

	if (!fp) return 0;

	fseek(fp, 0, SEEK_END);
	size = ftell(fp);
	rewind(fp);

	buf = (char*)malloc(size + 1);

	len = fread(buf, 1, size, fp);

	if (size != len)
	{
		free(buf);
		buf = NULL;
	}
	
	buf[len] = 0;
	fclose(fp);
	return buf;
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

extern int64_t v8_time()
{
	return igs_time();
}

vstr_t * v8_shell(const char * cmd)
{
	vstr_t * v = vstr_alloc(0);
#ifdef _WIN32
	FILE * fp = _popen(cmd, "r");
#else
	FILE * fp = popen(cmd, "r");
#endif
	char buf[1024];
	while (1) {
		int r = fread(buf, 1, 1024, fp);
		if (r <= 0) {
			break;
		}
		vstr_putlstring(v, buf, r);
	}
	fclose(fp);
	vstr_trim(v);
	return v;
}




