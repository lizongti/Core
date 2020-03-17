#include "TCPConnection.h"
#include "Packet.h"
#include "Session.h"
#include "Pool.h"
#include "Pool.h"

extern "C"
{
#include "tolua++.h"
}

TCPConnection::TCPConnection()
{
	tcp_.data = this;
	running_ = false;
	consumer_running_ = false;
	is_free = true;
}

TCPConnection::~TCPConnection()
{
}

bool TCPConnection::Init(std::function<void()> recycle_func)
{
	uv_buf_t buf;
	while (write_cb_queue_.pop(buf) || write_queue_.pop(buf))
	{
		FreeBuff(buf);
	}

	running_ = false;
	consumer_running_ = false;
	recycle_func_ = recycle_func;
	uv_tcp_nodelay(&tcp_, 1);
	sockaddr_in sock_addr;
	int32_t len = sizeof(sock_addr);

	if (uv_tcp_getpeername(&tcp_, (sockaddr *)&sock_addr, &len) == 0)
	{
		char addr[16];
		uv_inet_ntop(AF_INET, &sock_addr.sin_addr, addr, sizeof(addr));
		ip_ = addr;
		port_ = ntohs(sock_addr.sin_port);
		LOG(SYS, INFO) << boost::format("[Connection %x][%s] TCPConnection from %s:%d.\n") % this % __FUNCTION__ % ip_ % port_;
	}

	return true;
}

bool TCPConnection::Start()
{
	running_ = true;
	LOG(SYS, INFO) << boost::format("[Connection %x][%s] start running.\n") % this % __FUNCTION__;

	OnConnectionEvent();
	return true;
}

bool TCPConnection::Stop()
{
	running_ = false;
	LOG(SYS, INFO) << boost::format("[Connection %x][%s] stop running.\n") % this % __FUNCTION__;

	OnConnectionEvent();
	return true;
}

bool TCPConnection::Running()
{
	return running_;
}

bool TCPConnection::ConsumerRunning()
{
	return consumer_running_;
}

bool TCPConnection::IsFree()
{
	return is_free;
}

void TCPConnection::SetFree(bool free)
{
	this->is_free = free;
}

void TCPConnection::OnConnectionEvent()
{
	std::string event;
	if (running_ && !consumer_running_)
	{
		event = "Construct";
	}
	else if (running_ && consumer_running_)
	{
		event = "Update";
	}
	else if (!running_ && consumer_running_)
	{
		event = "Destroy";
	}
	else
	{
		return;
	}

	extern lua_State *global_L;
	if (global_L)
	{
		lua_getglobal(global_L, "OnConnectionEvent");
		lua_pushnumber(global_L, index_);
		tolua_pushusertype(global_L, this, "TCPConnection");
		lua_pushstring(global_L, event.c_str());
		lua_pcall(global_L, 3, 0, 0);
	}
}

void TCPConnection::SetConsumerRunning(bool consumer_running)
{
	consumer_running_ = consumer_running;
	if (consumer_running)
	{
		uv_read_start((uv_stream_t *)&tcp_, alloc_cb_, read_cb_);
		LOG(SYS, INFO) << boost::format("[Connection %x][%s] consumer start running.\n") % this % __FUNCTION__;
	}
	else
	{
		if (!uv_is_closing((uv_handle_t *)&tcp_))
		{
			uv_close((uv_handle_t *)&tcp_, nullptr);
		}

		uv_buf_t buf;
		while (write_cb_queue_.pop(buf) || write_queue_.pop(buf))
		{
			FreeBuff(buf);
		}

		recycle_func_();
		LOG(SYS, INFO) << boost::format("[Connection %x][%s] consumer stop running.\n") % this % __FUNCTION__;
	}

	OnConnectionEvent();
}

void TCPConnection::SetSession(Session *session)
{
	session_ = session;
}

uv_tcp_t &TCPConnection::Tcp()
{
	return tcp_;
}

std::string TCPConnection::Ip()
{
	return ip_;
}

uint16_t TCPConnection::Port()
{
	return port_;
}

bool TCPConnection::ReadBuff(uv_buf_t &buf) /* for consumer */
{
	if (!running_ || !consumer_running_)
	{
		return false;
	}

	return true;
}

uv_buf_t TCPConnection::MallocBuff(const int size)
{
	return uv_buf_init((char *)memory_pool::malloc(size), size);
}

void TCPConnection::FreeBuff(uv_buf_t buf)
{
	if (buf.base)
	{
		memory_pool::free(buf.base);
	}
}

// libuv 保证先write先发送，能保证write内容的顺序，能保证write_callback的次数等于write的次数，但是不能保证write_callback的顺序
void TCPConnection::write_callback(uv_write_t *handle, int status)
{
	uv_buf_t cb_buf;
	if (write_cb_queue_.pop(cb_buf))
	{
		FreeBuff(cb_buf);
	}
	object_pool<uv_write_t>::delete (handle);

	uv_buf_t buf;
	if (write_queue_.pop(buf))
	{
		uv_write_t *write = object_pool<uv_write_t>::new ();
		write->data = this;
		uv_write(write, (uv_stream_t *)&tcp_, &buf, 1, write_cb_);
		write_cb_queue_.push(buf);
	}

	if (status != 0)
	{
		LOG(SYS, ERROR) << boost::format("[Connection][%s]tcp write error:%d %s\n") % __FUNCTION__ % status % uv_strerror(status);
		Stop();
	}
}

void TCPConnection::static_write_callback(uv_write_t *handle, int status)
{
	((TCPConnection *)handle->data)->write_callback(handle, status);
}

void TCPConnection::WritePacket(Packet *packet)
{
	uint32_t send_len = 0;
	while (packet->size > send_len)
	{
		uint32_t sz = (packet->size - send_len < 536) ? packet->size - send_len : 536;
		uv_buf_t buf;
		buf.base = (char *)memory_pool::malloc(sz);
		buf.len = sz;
		std::memcpy(buf.base, (char *)packet + send_len, sz);
		send_len += sz;
		write_queue_.push(buf);
	}

	uv_buf_t buf;
	if (write_queue_.pop(buf))
	{
		uv_write_t *write = object_pool<uv_write_t>::new ();
		write->data = this;
		uv_write(write, (uv_stream_t *)&tcp_, &buf, 1, write_cb_);
		write_cb_queue_.push(buf);
	}

	memory_pool::free(packet);
}

#define ALLOC_SIZE 1024 * 64

//libuv需要一个内存区来读取数据，默认64k
void TCPConnection::alloc_callback(uv_handle_t *handle, size_t suggested_size, uv_buf_t *buf)
{
	*buf = MallocBuff(ALLOC_SIZE);
}

void TCPConnection::SetIndex(uint32_t index)
{
	index_ = index;
}

void TCPConnection::read_callback(uv_stream_t *handle, ssize_t nread, const uv_buf_t *buf)
{
	if (nread > 0)
	{
		uv_buf_t b = MallocBuff(nread);
		memcpy(b.base, buf->base, nread);

		if (session_->PushReadStream(b))
		{
			FreeBuff(*buf);
			return;
		}
		else
		{
			LOG(SYS, ERROR) << boost::format("[Connection %x][%s] read queue is full, close client.\n") % this % __FUNCTION__;
		}
	}
	else if (nread == 0)
	{
		FreeBuff(*buf);
		return;
	}
	else
	{
		if (nread == UV_EOF)
		{
			LOG(SYS, INFO) << boost::format("[Connection %x][%s] client disconnected as FIN received.\n") % this % __FUNCTION__;
		}
		else if (nread == UV_ECONNRESET)
		{
			LOG(SYS, INFO) << boost::format("[Connection %x][%s] client disconnected as RST received.\n") % this % __FUNCTION__;
		}
		else
		{
			LOG(SYS, ERROR) << boost::format("[Connection %x][%s] error %d %s %s.\n") % this % __FUNCTION__ % (int32_t)nread % uv_strerror(-1 * nread) % uv_err_name(-1 * nread);
		}
	}

	Stop();
	FreeBuff(*buf);
	return;
}

void TCPConnection::static_alloc_callback(uv_handle_t *handle, size_t suggested_size, uv_buf_t *buf)
{
	((TCPConnection *)handle->data)->alloc_callback(handle, suggested_size, buf);
}

void TCPConnection::static_read_callback(uv_stream_t *handle, ssize_t nread, const uv_buf_t *buf)
{
	((TCPConnection *)handle->data)->read_callback(handle, nread, buf);
}