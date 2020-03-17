#include "Session.h"
#include "TCPConnection.h"
#include "Pool.h"
#include "Pool.h"

extern "C"
{
#include "tolua++.h"
}

Session::Session(int id)
	: read_stream_buff_((std::numeric_limits<std::size_t>::max)()), write_stream_buff_((std::numeric_limits<std::size_t>::max)()), read_element_(true, nullptr), session_id(id)
{
}

Session::~Session()
{
}

Session *Session::Construct(int id)
{
	return object_pool<Session>::new(id);
}

void Session::Destroy(Session *session)
{
	object_pool<Session>::delete(session);
}

bool Session::BindConnection(TCPConnection *tcp_connection)
{
	bool ret = !tcp_connection->ConsumerRunning();
	if (ret)
	{
		tcp_connection_ = tcp_connection;
		tcp_connection_->SetConsumerRunning(true);
		tcp_connection_->SetSession(this);
	}

	return ret;
}

bool Session::UnbindConnection()
{
	bool ret = tcp_connection_->ConsumerRunning();
	if (ret)
	{
		//LOG(SYS, INFO) << boost::format("[Session %x][%s] unbind session %x.\n") % this % __FUNCTION__ % tcp_connection_;

		tcp_connection_->SetConsumerRunning(false);
		tcp_connection_ = nullptr;
	}

	return ret;
}

bool Session::StopConnection()
{
	bool ret = tcp_connection_->Stop();
	if (ret)
	{
		//LOG(SYS, INFO) << boost::format("[Session %x][%s] stop connection %x.\n") % this % __FUNCTION__ % tcp_connection_;
	}
	return ret;
}

bool Session::PushReadStream(uv_buf_t &buf)
{
	read_stream_buff_.sputn(buf.base, buf.len);
	TCPConnection::FreeBuff(buf);

	while (true)
	{
		if (boost::get<0>(read_element_) == true)
		{
			read_element_ = boost::make_tuple(false, nullptr);
		}

		if (boost::get<1>(read_element_) == nullptr && read_stream_buff_.size() >= sizeof(uint16_t))
		{
			uint16_t size = 0;
			read_stream_buff_.sgetn((char *)&size, sizeof(uint16_t));
			boost::get<1>(read_element_) = (Packet *)memory_pool::malloc(size);
			boost::get<1>(read_element_)->size = size;
			//客户端的包最大为1024，处理size小于18的情况
			if (size > 1024 || size < 18)
			{
				LOG(SYS, ERROR) << boost::format("[Session %x][%s] packet size false %d.\n") % this % __FUNCTION__ % (int32_t)size;
				if (tcp_connection_)
				{
					tcp_connection_->Stop();
					return false;
				}
			}
		}
		if (boost::get<1>(read_element_) != nullptr && read_stream_buff_.size() >= boost::get<1>(read_element_)->size - sizeof(uint16_t))
		{
			read_stream_buff_.sgetn((char *)boost::get<1>(read_element_) + sizeof(uint16_t), (boost::get<1>(read_element_))->size - sizeof(uint16_t));
			boost::get<0>(read_element_) = true;
		}

		bool ret = boost::get<0>(read_element_);

		if (ret)
		{
			Packet *packet = boost::get<1>(read_element_);
			OnNewPacket(packet);
		}
		else
		{
			break;
		}
	}

	return true;
}

bool Session::WritePacket(Packet *packet)
{
	if (!packet)
	{
		return false;
	}

	tcp_connection_->WritePacket(packet);
	return true;
}

void Session::OnNewPacket(Packet *packet)
{
	extern lua_State *global_L;
	if (global_L)
	{
		lua_getglobal(global_L, "OnNewPacket");
		lua_pushnumber(global_L, session_id);
		tolua_pushusertype(global_L, packet, "Packet");
		lua_pcall(global_L, 2, 0, 0);
	}
}
