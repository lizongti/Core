#ifndef SESSION_HPP
#define SESSION_HPP

#include <iostream>
#include <boost/pool/pool_alloc.hpp>
#include <boost/asio/basic_streambuf.hpp>
#include <boost/scope_exit.hpp>
#include <boost/tuple/tuple.hpp>
#include "Packet.h"
#include "Logger.h"

class TCPConnection;

class Session
{
public:
	Session(int id);

	~Session();

	static Session *Construct(int id);

	static void Destroy(Session *session);

	bool BindConnection(TCPConnection *tcp_connection);

	bool UnbindConnection();

	bool StopConnection();

	bool PushReadStream(uv_buf_t &buf);

	Packet *ReadPacket();

	bool WritePacket(Packet *packet);

	void OnNewPacket(Packet *packet);

protected:
	boost::asio::basic_streambuf<> read_stream_buff_;
	boost::asio::basic_streambuf<> write_stream_buff_;
	TCPConnection *tcp_connection_ = 0;
	boost::tuple<bool, Packet *> read_element_;
	int session_id;
};

#endif