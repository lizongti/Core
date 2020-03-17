#ifndef ZERO_MESSAGE_QUEUE_HPP
#define ZERO_MESSAGE_QUEUE_HPP

#include <zmq.hpp>
#include <string>
#include <iostream>

#ifdef _WIN32
#define ZMQ_HAVE_WINDOWS
#else
#include <unistd.h>
#endif

#include <time.h>
#include <uv.h>
#include <boost/format.hpp>
#include <boost/lockfree/spsc_queue.hpp>
#include "loop.h"
#include "Packet.h"

class ZeroMessageQueue
{
public:
	struct Config
	{
		std::string host = "0.0.0.0";
		uint16_t port = 8801;
		uint16_t is_server = 1;
		uint32_t recv_buf_count = 1024;
		uint32_t send_buf_count = 1024;
		uint32_t timeout = 0;
	};
	ZeroMessageQueue();

	virtual ~ZeroMessageQueue();

	bool Init(Config &conf);

	bool Start();

	bool Stop();

	bool Running();

	bool ReadBuff(uv_buf_t &buf);

	bool ReadString(std::string &str);

	Packet *ReadPacket();

	bool WriteBuff(const uv_buf_t &buf);

	bool WriteString(const std::string &str);

	bool WritePacket(Packet *packet);

protected:
	Config conf_;
	std::atomic_bool running_;
	std::string addr_;

	zmq::context_t *context_;
	zmq::socket_t *socket_;
	zmq::message_t *message_;
};
#endif