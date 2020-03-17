#ifndef NOTIFICATION_CLIENT_SERVICE_HPP
#define NOTIFICATION_CLIENT_SERVICE_HPP

#include "../Base/BaseHeaders.h"
#include "./LoggerService.hpp"

class NotificationClientService : 
	public Service<NotificationClientService>, 
	public Singleton<NotificationClientService>, 
	public LuaLib<NotificationClientService>
{
public:
	struct Config
	{
		ZeroMessageQueue::Config zeromq;
		
		bool ReadConfig(const std::string& json)
		{
			CONFIG_CREATE_DOCUMENT(root, json)
				CONFIG_MOVE_OBJECT(root, "zeromq", zeromq_object)
					CONFIG_READ_MEMBER(zeromq_object, "host", zeromq.host)
					CONFIG_READ_MEMBER(zeromq_object, "port", zeromq.port)
					CONFIG_READ_MEMBER(zeromq_object, "is_server", zeromq.is_server)
			return true;
		}
	};
	NotificationClientService()
	{
		this->Depends(&LoggerService::Instance());
	}
	virtual ~NotificationClientService()
	{
		
	}
	bool Init(const std::string& json)
	{
		bool ret = conf_.ReadConfig(json);
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[NotificationClientService %x][%s] config json parse fail.\n") % this % __FUNCTION__;
			return false ;
		}
		
		ret = zeromq_.Init(conf_.zeromq);
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[NotificationClientService %x][%s] message queue init fail.\n") % this % __FUNCTION__;
			return false;
		}
		
		return true;
	}
	
	virtual bool Start()
	{
		bool ret = zeromq_.Start();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[NotificationClientService %x][%s] message queue start fail.\n") % this % __FUNCTION__;
			return false;
		}
		
		return true;
	}
	
	virtual bool Stop()
	{
		bool ret = zeromq_.Stop();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[NotificationClientService %x][%s] message queue stop fail.\n") % this % __FUNCTION__;
			return false;
		}
		
		return true;
	}
	
	virtual bool Running()
	{
		bool ret = zeromq_.Running();
		if (!ret)
		{
			return false;
		}
		
		return true;
	}
	
	virtual bool Boot()
	{
		return Service<NotificationClientService>::Boot();
	}

	Packet* ReadPacket()
	{	
		return zeromq_.ReadPacket();
	}
	
	bool WritePacket(Packet* packet)
	{
		return zeromq_.WritePacket(packet);
	}
	
protected:
	Config conf_;
	
	ZeroMessageQueue zeromq_;
};

#endif // !NOTIFICATION_CLIENT_SERVICE_HPP
