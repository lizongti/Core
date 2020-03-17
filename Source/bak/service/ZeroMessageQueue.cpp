#include "ZeroMessageQueue.h"
#include "Pool.h"
#include "Pool.h"

ZeroMessageQueue::ZeroMessageQueue()
{
	running_.store(false);
}
ZeroMessageQueue::~ZeroMessageQueue()
{
}

bool ZeroMessageQueue::Init(Config &conf)
{
	conf_ = conf;
	addr_ = (boost::format("tcp://%s:%d") % conf_.host % conf_.port).str();

	return true;
}

bool ZeroMessageQueue::Start()
{
	running_.store(true);
	message_ = object_pool<zmq::message_t>::new();
	context_ = object_pool<zmq::context_t>::new(1);
	if (conf_.is_server)
	{
		try
		{
			socket_ = object_pool<zmq::socket_t>::new<zmq::context_t &, int>(*context_, ZMQ_ROUTER);
			if (!socket_)
			{
				LOG(SYS, ERROR) << boost::format("[ZeroMessageQueue %s][%s]error in zmq_socket: %s\n") % addr_ % __FUNCTION__ % zmq_strerror(errno);
				return false;
			}
			socket_->setsockopt(ZMQ_SNDTIMEO, &conf_.timeout, sizeof(conf_.timeout));
			socket_->setsockopt(ZMQ_RCVHWM, &conf_.recv_buf_count, sizeof(conf_.recv_buf_count));
			socket_->setsockopt(ZMQ_SNDHWM, &conf_.send_buf_count, sizeof(conf_.send_buf_count));

			socket_->bind((boost::format("tcp://0.0.0.0:%d") % conf_.port).str());
		}
		catch (...)
		{
			LOG(SYS, ERROR) << boost::format("[ZeroMessageQueue %s][%s]error in zmq_socket: %s\n") % addr_ % __FUNCTION__ % zmq_strerror(errno);
			return false;
		}
	}
	else
	{
		try
		{
			socket_ = object_pool<zmq::socket_t>::new<zmq::context_t &, int>(*context_, ZMQ_DEALER);
			if (!socket_)
			{
				LOG(SYS, ERROR) << boost::format("[ZeroMessageQueue %s][%s]error in zmq_socket: %s\n") % addr_ % __FUNCTION__ % zmq_strerror(errno);
				return false;
			}
			socket_->setsockopt(ZMQ_SNDTIMEO, &conf_.timeout, sizeof(conf_.timeout));
			socket_->setsockopt(ZMQ_RCVHWM, &conf_.recv_buf_count, sizeof(conf_.recv_buf_count));
			socket_->setsockopt(ZMQ_SNDHWM, &conf_.send_buf_count, sizeof(conf_.send_buf_count));
			socket_->setsockopt(ZMQ_IDENTITY, "S", 1);

			socket_->connect(addr_);
		}
		catch (...)
		{
			LOG(SYS, ERROR) << boost::format("[ZeroMessageQueue %s][%s]error in zmq_socket: %s\n") % addr_ % __FUNCTION__ % zmq_strerror(errno);
			return false;
		}
	}

	return true;
}

bool ZeroMessageQueue::Stop()
{
	if (conf_.is_server)
	{
		socket_->unbind(addr_);
	}
	else
	{
		socket_->disconnect(addr_);
	}

	context_->close();
	socket_->close();

	object_pool<zmq::message_t>::delete(message_);
	object_pool<zmq::context_t>::delete(context_);
	object_pool<zmq::socket_t>::delete(socket_);

	context_ = nullptr;
	socket_ = nullptr;

	return true;
}

bool ZeroMessageQueue::Running()
{
	return running_.load();
}

bool ZeroMessageQueue::ReadBuff(uv_buf_t &buf)
{
	if (!socket_)
	{
		return false;
	}
	while (true)
	{
		message_->rebuild();
		if (!socket_->recv(message_, ZMQ_DONTWAIT))
		{
			return false;
		}
		if (message_->size() == 1)
		{
			continue;
		}
		buf = uv_buf_init((char *)memory_pool::malloc(message_->size()), message_->size());
		std::memcpy(buf.base, (char *)message_->data(), message_->size());
		return true;
	}
}

bool ZeroMessageQueue::ReadString(std::string &str)
{
	uv_buf_t buf;
	if (!ReadBuff(buf))
	{
		return false;
	}
	str = std::string(buf.base, buf.len);
	memory_pool::free(buf.base);
	return true;
}

Packet *ZeroMessageQueue::ReadPacket()
{
	Packet *packet = nullptr;

	uv_buf_t buf;
	if (!ReadBuff(buf))
	{
		return packet;
	}
	packet = (Packet *)buf.base;

	return packet;
}

bool ZeroMessageQueue::WriteBuff(const uv_buf_t &buf)
{
	if (!socket_)
	{
		return false;
	}

	message_->rebuild(buf.base, buf.len);

	if (conf_.is_server)
	{
		if (!socket_->send("S", 1, ZMQ_DONTWAIT | ZMQ_SNDMORE))
		{
			LOG(SYS, ERROR) << boost::format("[ZeroMessageQueue %s][%s] send buff fail!\n") % addr_ % __FUNCTION__;
			return false;
		}
	}

	if (!socket_->send(*message_, ZMQ_DONTWAIT))
	{
		LOG(SYS, ERROR) << boost::format("[ZeroMessageQueue %s][%s] send buff fail!\n") % addr_ % __FUNCTION__;
		return false;
	}

	memory_pool::free(buf.base);

	return true;
}

bool ZeroMessageQueue::WriteString(const std::string &str)
{
	uv_buf_t buf = uv_buf_init((char *)memory_pool::malloc(str.size()), str.size());
	std::memcpy(buf.base, str.c_str(), str.size());
	return WriteBuff(buf);
}

bool ZeroMessageQueue::WritePacket(Packet *packet)
{
	uv_buf_t buf = uv_buf_init((char *)packet, packet->size);

	return WriteBuff(buf);
}