#ifndef CONTEST_CLIENT_SERVICE_HPP
#define CONTEST_CLIENT_SERVICE_HPP

#include "../Base/BaseHeaders.h"
#include "./LoggerService.hpp"

class ContestClientService : 
	public Service<ContestClientService>, 
	public LuaLib<ContestClientService>
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

	static ContestClientService * Create()
	{
		return new ContestClientService();
	}

	ContestClientService()
	{
		this->Depends(&LoggerService::Instance());
	}

	virtual ~ContestClientService()
	{
		
	}
	bool Init(const std::string& json)
	{
		bool ret = conf_.ReadConfig(json);
		if(!ret)
		{
			LOG(SYS, ERROR) << boost::format("[ContestClientService %x][%s] config json parse fail.\n") % this % __FUNCTION__;
			return false ;
		}
		
		ret = zeromq_.Init(conf_.zeromq);
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[ContestClientService %x][%s] message queue init fail.\n") % this % __FUNCTION__;
			return false;
		}
		
		return true;
	}
	
	virtual bool Start()
	{
		bool ret = zeromq_.Start();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[ContestClientService %x][%s] message queue start fail.\n") % this % __FUNCTION__;
			return false;
		}
		
		return true;
	}
	
	virtual bool Stop()
	{
		bool ret = zeromq_.Stop();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[ContestClientService %x][%s] message queue stop fail.\n") % this % __FUNCTION__;
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
		return Service<ContestClientService>::Boot();
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

#endif // !CONTEST_CLIENT_SERVICE_HPP
