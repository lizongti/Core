/*
@desc 服务器专用shell命令服务插件
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

static lua_State * L = 0;
static uv_loop_t * loop = 0;
static uv_tcp_t tcp_server;

#define ALLOC_SIZE 1024

static void alloc_buffer(uv_handle_t* handle, size_t suggested_size, uv_buf_t* buf)
{
	static char base[ALLOC_SIZE];
	memset(base, 0, ALLOC_SIZE);

	buf->base = base;
	buf->len = sizeof(base);
}

static void on_close(uv_handle_t * handle)
{

}

static void write_cb(uv_write_t* req, int status)
{
	free(req);
}

static void on_tcp_recv(uv_stream_t * stream, ssize_t nread, const uv_buf_t* buf)
{
	if (nread < 0)
	{
		uv_close((uv_handle_t *)stream, on_close);
		return;
	}

	int l = strlen(buf->base);

	for (int i = l - 1; i >= 0; --i) {
		if (isspace(buf->base[i])) {
			buf->base[i] = 0;
		}
		else {
			break;
		}
	}

	char cmd[10240];
	sprintf(cmd, "if shell and shell.cmd then return shell.cmd('%s') else return 'shell.cmd is null' end", buf->base);
	luaL_dostring(L, cmd);
	const char * str = lua_tostring(L, -1);

	if (str) {
		int l = strlen(str);
		char * buf = malloc(l + 2);
		strcpy(buf, str);
		buf[l] = '\n';
		buf[l + 1] = 0;
		uv_buf_t sbuf = uv_buf_init(buf, l + 2);
		uv_write_t * req = malloc(sizeof(uv_write_t));
		req->data = stream;
		uv_write(req, stream, &sbuf, 1, write_cb);
		free(buf);
	}
}

static void on_tcp_listen(uv_stream_t* server, int status)
{
	if (status < 0)
	{
		return;
	}

	uv_tcp_t * peer_tcp = (uv_tcp_t*)calloc(1, sizeof(uv_tcp_t));

	if (uv_tcp_init(loop, peer_tcp))
	{
		uv_close((uv_handle_t *)peer_tcp, NULL);
	}

	if (uv_accept(server, (uv_stream_t *)peer_tcp) == 0)
	{
		if (uv_read_start((uv_stream_t *)peer_tcp, alloc_buffer, on_tcp_recv))
		{
			uv_close((uv_handle_t *)peer_tcp, NULL);
		}
	}
	else
	{
		uv_close((uv_handle_t *)peer_tcp, NULL);
	}
}

static void set_up_tcp_server(uv_loop_t * loop, const char * ip, int port)
{
	struct sockaddr_in addr;
	uv_ip4_addr(ip, port, &addr);

	if (uv_tcp_init(loop, &tcp_server))
	{
		printf("shell tcp init error.\n");
		return;
	}

	if (uv_tcp_bind(&tcp_server, (const struct sockaddr*) &addr, 0))
	{
		printf("shell tcp bind error.\n");
		return;
	}

	if (uv_listen((uv_stream_t*)&tcp_server, SOMAXCONN, on_tcp_listen))
	{
		printf("shell tcp listen error.\n");
		return;
	}

	printf("shell start ok.The port is %d.Use telnet to send message!\n", port);
}

static int start(lua_State * L) {
	int port = lua_tointeger(L, 1);

	if (port == 0) {
		printf("shell create error.port is 0\n");
		return 0;
	}

	loop = uv_loop_new();
	uv_loop_init(loop);
	set_up_tcp_server(loop, "0.0.0.0", port);
	return 0;
}

static int stop(lua_State * L) {
	if (loop) {
		uv_close((uv_handle_t*)(&tcp_server), 0);
		uv_loop_close(loop);
	}
	return 0;
}

static int run(lua_State * L) {
	if (loop) {
		uv_run(loop, UV_RUN_NOWAIT);
	}
	return 0;
}

static const struct luaL_reg lib_shell[] = {
	{ "start", start },
	{ "stop", stop },
	{ "run", run },
	{ NULL, NULL }
};

LUA_API int luaopen_shell(lua_State *L_)
{
	L = L_;
	luaL_register(L, "shell", lib_shell);
	return 0;
}

