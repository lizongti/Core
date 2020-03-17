#include "TCPServer.h"
#include "Packet.h"
#include "Session.h"
#include "Pool.h"

TCPServer::TCPServer()
{
}

TCPServer::~TCPServer()
{
	for (uint32_t idx = 0; idx < connections_.size(); ++idx)
	{
		object_pool<TCPConnection>::delete(connections_[idx]);
	}
}

bool TCPServer::Init(const Config &conf)
{
	conf_ = conf;

	LuaLoop::Init(conf_.lua);

	uv_tcp_init(loop_, &tcp_server_);
	uv_tcp_nodelay(&tcp_server_, 1);
	tcp_server_.data = this;

	uv_timer_init(loop_, &event_timer_);
	uv_timer_start(&event_timer_, event_timer_cb_, 0, 1000);
	event_timer_.data = this;

	uv_ip4_addr(conf_.host.c_str(), conf_.port, &addr_);

	return true;
}

TCPServer::Config &TCPServer::Conf()
{
	return conf_;
}

bool TCPServer::Start()
{
	uv_tcp_bind(&tcp_server_, (const struct sockaddr *)&addr_, 0);
	int32_t uv_ret = uv_listen((uv_stream_t *)&tcp_server_, Config::backlog, conn_cb_);
	bool ret = (uv_ret == 0);
	if (!ret)
	{
		LOG(SYS, ERROR) << boost::format("[TCPServer %x][%s] error %s %s.\n") % this % __FUNCTION__ % uv_strerror(uv_ret) % uv_err_name(uv_ret);
		return ret;
	}

	return LuaLoop::Start();
}

bool TCPServer::Stop()
{
	return LuaLoop::Stop();
}

bool TCPServer::Running()
{
	return LuaLoop::Running();
}

static void close_cb(uv_handle_t *tcp_client)
{
	object_pool<uv_tcp_t>::delete(tcp_client);
}

void TCPServer::connection_callback(uv_stream_t *tcp_server, int status)
{
	if (status == -1)
	{
		LOG(SYS, ERROR) << boost::format("[TCPServer %x][%s] on_new_connection TCPConnection, status %d.\n") % this % __FUNCTION__ % status;
		return;
	}

	if (free_connections_.size() == 0)
	{
		if (connections_.size() < Config::max_connection_count)
		{
			TCPConnection *conn = object_pool<TCPConnection>::new();
			conn->SetIndex(connections_.size());
			connections_.push_back(conn);
			free_connections_.push_back(conn);
		}
		else
		{
			uv_tcp_t *tcp_client = object_pool<uv_tcp_t>::new();
			uv_tcp_init(loop_, tcp_client);

			if (uv_accept((uv_stream_t *)tcp_server, (uv_stream_t *)tcp_client) == 0)
			{
				if (!uv_is_closing((uv_handle_t *)tcp_client))
				{
					uv_close((uv_handle_t *)tcp_client, close_cb);
				}
			}

			LOG(SYS, WARN) << boost::format("[TCPServer %x][%s] on_new_connection TCPConnection, no free connection space.\n") % this % __FUNCTION__;
			return;
		}
	}

	TCPConnection *tcp_connection = free_connections_.front();
	free_connections_.pop_front();
	tcp_connection->SetFree(false);

	uv_tcp_t *tcp_client = &tcp_connection->Tcp();
	uv_tcp_init(loop_, tcp_client);

	if (uv_accept((uv_stream_t *)tcp_server, (uv_stream_t *)tcp_client) == 0)
	{
		tcp_connection->Init([=]() {
			if (std::find(free_connections_.begin(), free_connections_.end(), tcp_connection) == free_connections_.end())
			{
				free_connections_.push_back(tcp_connection);
				tcp_connection->SetFree(true);
				LOG(SYS, INFO) << boost::format("[TCPServer %x][%s]TCPConnection %x recycle, now free connections %lld.\n") % this % __FUNCTION__ % tcp_connection % free_connections_.size();
			}
			else
			{
				LOG(SYS, INFO) << boost::format("[TCPServer %x][%s]TCPConnection %x repeated recycle, now free connections %lld.\n") % this % __FUNCTION__ % tcp_connection % free_connections_.size();
			}
		});
		tcp_connection->Start();
	}
	else
	{
		uv_close((uv_handle_t *)tcp_client, nullptr);
		free_connections_.push_back(tcp_connection);
	}
}

void TCPServer::static_connection_callback(uv_stream_t *tcp_server, int status)
{
	((TCPServer *)tcp_server->data)->connection_callback(tcp_server, status);
}

void TCPServer::event_callback(uv_timer_t *handle)
{
	for (auto it = connections_.begin(); it != connections_.end(); ++it)
	{
		(*it)->OnConnectionEvent();
	}
}

void TCPServer::static_event_callback(uv_timer_t *handle)
{
	((TCPServer *)handle->data)->event_callback(handle);
}