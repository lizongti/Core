#ifndef TCP_SERVER_H
#define TCP_SERVER_H

#include <thread>
#include <string>
#include <atomic>
#include <iostream>
#include <boost/lockfree/spsc_queue.hpp>
#include <boost/pool/pool_alloc.hpp>
#include <array>
#include <list>
#include <iostream>
#include "loop.h"
#include "Logger.h"
#include "TCPConnection.h"
#include "LuaState.h"

class TCPServer : public LuaLoop
{
public:
	struct Config
	{
		Config(){};
		std::string host;
		uint16_t port;
		LuaLoop::Config lua;
		const static int32_t backlog = 1024;
		const static uint32_t max_connection_count = 2000; //单服设置1000用户,保证单线程cpu在百分之五十以下。
	};

	TCPServer();

	virtual ~TCPServer();

	virtual bool Init(const Config &conf = Config());

	virtual Config &Conf();

	virtual bool Start();

	virtual bool Stop();

	virtual bool Running();

protected:
	virtual void connection_callback(uv_stream_t *tcp_server, int status);

	static void static_connection_callback(uv_stream_t *tcp_server, int status);

protected:
	virtual void event_callback(uv_timer_t *handle);

	static void static_event_callback(uv_timer_t *handle);

protected:
	Config conf_;
	uv_tcp_t tcp_server_;
	uv_timer_t event_timer_;
	uv_timer_cb event_timer_cb_ = (uv_timer_cb)&static_event_callback;
	sockaddr_in addr_;
	uv_connection_cb conn_cb_ = (uv_connection_cb)&static_connection_callback;
	std::list<TCPConnection *> free_connections_;
	std::vector<TCPConnection *> connections_;
};

#endif // !TCP_SERVER_H