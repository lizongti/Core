#include <assert.h>
#include <time.h>
#include "lua-compat.h"

#include <uv.h>
#include <stdlib.h>
#include "tolua/tolua_fix.h"
#include <hiredis/hiredis.h>
#include "vlib/vstr.h"
#include "lutil.h"
#include "vlib/queue.h"
#include "tolua/tolua_fix.h"

/*
@TODO
创建一个专用线程用于写入，因为写入数据不需要任何状态，处理起来没有顾虑，也不需要考虑返回。
添加缓冲区，每隔一秒或者当数据超过某个阀值时写入。
*/

#define LUA_REDISLIBNAME "redis_client"

#define REDIS_POOL_SIZE 32

static uv_mutex_t lock;

typedef struct redis_connection_s {
	redisContext * c;
	int locked;
	uv_mutex_t mutex;
}redis_connection_t;

typedef struct redis_cmd_s {
	lua_State * L;
	queue_t * commands;
	redis_connection_t * rcon;
	int need_response;
}redis_cmd_t;

typedef struct redis_s {
	redis_connection_t * clients[REDIS_POOL_SIZE];
}redis_t;

static redis_connection_t * free_context(redis_t * r)
{
	for (int i = 0; i < REDIS_POOL_SIZE; ++i) {
		if (!r->clients[i]->locked) {
			return r->clients[i];
		}
	}

	int rd = rand() % REDIS_POOL_SIZE;
	return r->clients[rd];
}

static void release_context(redis_connection_t * r)
{
	r->locked--;
	assert(r->locked >= 0);
}

static void lock_context(redis_connection_t * r) {
	r->locked++;
}

static redisContext * _redis_connect(const char * host, int port, const char * auth)
{
	struct timeval t;
	t.tv_sec = 3;
	t.tv_usec = 0;

	redisContext * context_ = 0;
	int isConnected = 0;
	while (isConnected == 0) {
		context_ = redisConnectWithTimeout(host, port, t);
		if (context_ != NULL && context_->err)
		{
			printf("[Redis][%s] connecting to redis fail, error:%s.\n", __FUNCTION__, context_->errstr);
		}
		else
		{
			printf("[Redis][%s] connecting to redis success.\n", __FUNCTION__);
			isConnected = 1;
		}
	}

	if (context_ == NULL || context_->err) {
		return 0;
	}

	if (auth && auth[0]) {
		redisReply * r = (redisReply*)redisCommand(context_, "AUTH %s", auth);
		if (r) {
			freeReplyObject(r);
		}
		return 0;
	}

	return context_;
}

static int redis_connect(lua_State * L) {
	size_t l;
	char * ip = "127.0.0.1";

	if (lua_gettop(L) >= 1) {
		ip = luaL_checklstring(L, 1, &l);
	}

	int port = 6379;

	if (lua_gettop(L) >= 2) {
		port = luaL_checkint(L, 2);
	}

	char * auth = "";

	if (lua_gettop(L) >= 3) {
		auth = luaL_checklstring(L, 3, &l);
	}

	redis_t * r = lua_newuserdata(L, sizeof(redis_t));
	luaL_getmetatable(L, "redis_meta.ctx");
	lua_setmetatable(L, -2);

	for (int i = 0; i < REDIS_POOL_SIZE; ++i) {
		r->clients[i] = malloc(sizeof(redis_connection_t));
		r->clients[i]->c = _redis_connect(ip, port, auth);
		r->clients[i]->locked = 0;
		uv_mutex_init(&(r->clients[i]->mutex));
	}

	return 1;
}

static void push_data(lua_State * L, redisReply * reply)
{
	//返回类型-字符串
	if (reply->type == REDIS_REPLY_STRING && reply->len > 0) {
		lua_pushstring(L, reply->str);
	}
	else if (reply->type == REDIS_REPLY_STATUS) {
		lua_pushinteger(L, reply->integer);
	}
	else if (reply->type == REDIS_REPLY_NIL) {
		lua_pushstring(L, "");
	}
	else if (reply->type == REDIS_REPLY_INTEGER) {
		lua_pushinteger(L, reply->integer);
	}
	else if (reply->type == REDIS_REPLY_ARRAY) {
		if (reply->elements > 1) {
			lua_createtable(L, 0, 0);
			for (int i = 0; i < reply->elements; ++i) {
				redisReply * r = reply->element[i];
				if (r->type == REDIS_REPLY_STRING) {
					lua_pushinteger(L, i + 1);
					lua_pushstring(L, r->str);
					lua_settable(L, -3);
				}
				else if (r->type == REDIS_REPLY_INTEGER) {
					lua_pushinteger(L, i + 1);
					lua_pushinteger(L, r->integer);
					lua_settable(L, -3);
				}
				else {
					lua_pushinteger(L, i + 1);
					lua_pushstring(L, "");
					lua_settable(L, -3);
				}
			}
		}
		else if(reply->elements == 1){
			for (int i = 0; i < reply->elements; ++i) {
				redisReply * r = reply->element[i];
				if (r->type == REDIS_REPLY_STRING) {
					lua_pushstring(L, r->str);
				}
				else if (r->type == REDIS_REPLY_INTEGER) {
					lua_pushinteger(L, r->integer);
				}
				else {
					lua_pushstring(L, "");
				}
			}
		}
		else {
			lua_pushstring(L, "");
		}
	}
	else {
		lua_pushstring(L, "");
	}
}

extern uv_loop_t * get_thread_loop(uv_thread_t * t);

static int redis_cmd(lua_State * L) {
	redis_t * r = lua_touserdata(L, 1);

	if (!r) {
		return 0;
	}

	redis_connection_t * rc = free_context(r);
	redisContext * c = rc->c;

	lock_context(rc);

	assert(lua_istable(L, 2));
	size_t len = lua_objlen(L, 2);

	//批量压入所有的redis命令
	for (size_t i = 0; i < len; ++i) {
		lua_pushnumber(L, i + 1);
		lua_gettable(L, -2);
		const char * cmd = lua_tostring(L, -1);
		redisAppendCommand(c, cmd);
		lua_pop(L, 1);
	}
	//批量获取所有的数据，并且返回一个table
	lua_createtable(L, 0, 0);
	for (size_t i = 0; i < len; ++i)
	{
		redisReply * reply;
		int ret = redisGetReply(c, &reply);

		if (ret != 0) {
			return 0;
		}

		lua_pushinteger(L, i + 1);
		push_data(L, reply);
		lua_settable(L, -3);
		freeReplyObject(reply);
	}

	release_context(rc);
	return 1;
}

static int redis_close(lua_State * L) {

	return 0;
}

static void thread_work(uv_work_t * req)
{
	redis_cmd_t * rc = req->data;
	int len = rc->commands->size;
	lua_State * L = rc->L;

	if (rc->rcon->locked) {
		while (uv_mutex_trylock(&(rc->rcon->mutex))) {
			
		}
	}

	for (int i = 0; i < len; ++i) {
		char * v = (char*)q_pop(rc->commands);
		redisAppendCommand(rc->rcon->c, v);
		free(v);
	}

	for (size_t i = 0; i < len; ++i)
	{
		redisReply * reply;
		int ret = redisGetReply(rc->rcon->c, &reply);
		if (ret) {
			return;
		}
		q_push(rc->commands, reply);
	}

	if (rc->rcon->locked) {
		uv_mutex_unlock(&(rc->rcon->mutex));
	}
}

static void redis_cmd_free(redis_cmd_t * rc)
{
	while (q_size(rc->commands)) {
		redisReply * reply = q_pop(rc->commands);
		freeReplyObject(reply);
	}

	q_destroy(rc->commands);

	free(rc);
}

static void thread_work_back(uv_work_t * req)
{
	redis_cmd_t * rc = req->data;

	if (!rc->need_response) {
		release_context(rc->rcon);
		redis_cmd_free(rc);
		free(req);
		return;
	}

	int len = rc->commands->size;
	lua_State * L = rc->L;

	//批量获取所有的数据，并且返回一个table
	lua_createtable(L, len, 0);
	assert(lua_istable(L, -1));

	for (size_t i = 0; i < len; ++i)
	{
		redisReply * reply = q_pop(rc->commands);
		lua_pushinteger(L, i + 1);
		assert(lua_istable(L, -2));
		push_data(L, reply);
		assert(lua_istable(L, -3));
		lua_settable(L, -3);
		freeReplyObject(reply);
	}

#if defined(LUA_VERSION_NUM) && LUA_VERSION_NUM >= 503
	int r = lua_resume(L, 0, 1);
#else
	int r = lua_resume(L, 1);
#endif
	
	if (r != LUA_YIELD && r != 0) {
		lua_gettop(L); 
		const char * s = lua_tostring(L, -1);
		lua_getglobal(L, "Debug");
		assert(lua_istable(L, -1));
		lua_pushstring(L, "error");
		lua_gettable(L, -2);
		lua_pushstring(L, s);
		lua_pcall(L, 1, 0, 0);
		assert(lua_istable(L, -1));
		lua_pop(L, 1);
		assert(lua_isstring(L, -1));
		lua_pop(L, 1);
	}
	
	release_context(rc->rcon);
	redis_cmd_free(rc);
	free(req);
}

static int redis_cmd_asyn(lua_State * L) {
	uv_thread_t thread = uv_thread_self();
	uv_loop_t * loop = uv_default_loop();//get_thread_loop(&thread);

	redis_t * r = lua_touserdata(L, 1);

	if (!r) {
		return 0;
	}

	queue_t * q = q_create();
	size_t len = lua_objlen(L, 2);
	//批量压入所有的redis命令
	for (size_t i = 0; i < len; ++i) {
		lua_pushnumber(L, i + 1);
		lua_gettable(L, 2);
		const char * cmd = strdup(lua_tostring(L, -1));
		q_push(q, cmd);
		lua_pop(L, 1);
	}

	redis_connection_t * rcon = free_context(r);
	lock_context(rcon);

	redis_cmd_t * rc = malloc(sizeof(redis_cmd_t));
	rc->rcon = rcon;
	rc->L = L;
	rc->commands = q;
	rc->need_response = 1;

	uv_work_t * req = malloc(sizeof(uv_work_t));
	req->data = rc;

	uv_queue_work(loop, req, thread_work, thread_work_back);
	return 0;
}

static int redis_cmd_write(lua_State * L) {
	uv_thread_t thread = uv_thread_self();
	uv_loop_t * loop = uv_default_loop();//get_thread_loop(&thread);

	redis_t * r = lua_touserdata(L, 1);

	if (!r) {
		return 0;
	}

	queue_t * q = q_create();
	size_t len = lua_objlen(L, 2);
	//批量压入所有的redis命令
	for (size_t i = 0; i < len; ++i) {
		lua_pushnumber(L, i + 1);
		lua_gettable(L, 2);
		const char * cmd = strdup(lua_tostring(L, -1));
		q_push(q, cmd);
		lua_pop(L, 1);
	}

	redis_connection_t * rcon = free_context(r);
	lock_context(rcon);
	redis_cmd_t * rc = malloc(sizeof(redis_cmd_t));
	rc->rcon = rcon;
	rc->L = L;
	rc->commands = q;
	rc->need_response = 0;

	uv_work_t * req = malloc(sizeof(uv_work_t));
	req->data = rc;

	uv_queue_work(loop, req, thread_work, thread_work_back);
	return 0;
}

static const luaL_Reg redis_lib[] = {
	{ "connect",   redis_connect },
	{ "close", redis_close },
	{ NULL, NULL }
};

static const luaL_Reg redis_metalib[] = {
	{ "cmd", redis_cmd },
	{ "cmd_asyn", redis_cmd_asyn },
	{ "cmd_write", redis_cmd_write},
	{ NULL, NULL }
};

static int lua_widget_gc(lua_State *L) {
	assert(0);
	return 0;
}


static void idle_cb()
{

}

static void create_redis_thread()
{

}

LUALIB_API int (luaopen_redis)(lua_State *L) {
	luaL_register(L, LUA_REDISLIBNAME, redis_lib);

	//create_redis_thread();
	uv_mutex_init(&lock);

	luaL_newmetatable(L, "redis_meta.ctx");
	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);
	lua_settable(L, -3);

	lua_pushstring(L, "__gc");
	lua_pushcfunction(L, lua_widget_gc);
	lua_settable(L, -3);

	luaL_register(L, NULL, redis_metalib);
	return 0;
}



