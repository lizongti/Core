#ifndef TCP_HPP
#define TCP_HPP

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
#include "LuaState.h"

class Session;
class Packet;

class TCPConnection
{
public:
	struct Config
	{
		Config(){};
		const static uint32_t write_queue_size = 3000; // 1M
	};

	TCPConnection();

	virtual ~TCPConnection();

	bool Init(std::function<void()> recycle_func);

	bool Start();

	bool Stop();

	bool Running();

	bool ConsumerRunning();

	bool IsFree();

	void SetFree(bool free);

	void SetConsumerRunning(bool consumer_running);

	void OnConnectionEvent();

	void SetSession(Session *session);

	uv_tcp_t &Tcp();

	std::string Ip();

	uint16_t Port();

	bool ReadBuff(uv_buf_t &buf);

	static uv_buf_t MallocBuff(const int size);

	static void FreeBuff(uv_buf_t buf);

	void WritePacket(Packet *packet);

	void SetIndex(uint32_t index);

protected:
	virtual void alloc_callback(uv_handle_t *handle, size_t suggested_size, uv_buf_t *buf);

	virtual void read_callback(uv_stream_t *handle, ssize_t nread, const uv_buf_t *buf);

	virtual void write_callback(uv_write_t *handle, int status);

protected:
	static void static_alloc_callback(uv_handle_t *handle, size_t suggested_size, uv_buf_t *buf);

	static void static_read_callback(uv_stream_t *handle, ssize_t nread, const uv_buf_t *buf);

	static void static_write_callback(uv_write_t *handle, int status);

protected:
	uv_tcp_t tcp_;
	uv_alloc_cb alloc_cb_ = (uv_alloc_cb)&static_alloc_callback;
	uv_read_cb read_cb_ = (uv_read_cb)&static_read_callback;
	uv_write_cb write_cb_ = (uv_write_cb)&static_write_callback;
	std::function<void()> recycle_func_;
	bool running_;
	bool consumer_running_;
	bool is_free;
	std::string ip_;
	uint16_t port_;
	Session *session_;
	uint32_t index_;
	boost::lockfree::spsc_queue<uv_buf_t, boost::lockfree::capacity<Config::write_queue_size>> write_queue_;
	boost::lockfree::spsc_queue<uv_buf_t, boost::lockfree::capacity<Config::write_queue_size>> write_cb_queue_;
};

#endif // !TCP_CONNECTION_H