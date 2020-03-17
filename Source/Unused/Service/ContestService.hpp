#ifndef CONTEST_SERVICE_HPP
#define CONTEST_SERVICE_HPP

#include "../Base/BaseHeaders.h"
#include "./LoggerService.hpp"
#include "./ManagerClientService.hpp"
#include "./CacheClientService.hpp"
#include "./DbCacheClientService.hpp"

class ContestService : 
	public Service<ContestService>,
	public Singleton<ContestService>,
	public LuaLib<ContestService>
{
public:
	struct Config
	{
		std::vector<ZeroMessageQueue::Config> zeromqs;
		LuaLoop::Config lua;
		
		bool ReadConfig(const std::string& json)
		{
			CONFIG_CREATE_DOCUMENT(root, json)
				CONFIG_MOVE_ARRAY(root, "zeromqs", zeromqs_array)
					CONFIG_FOREACH_OBJECT(zeromqs_array, zeromq_object)
						ZeroMessageQueue::Config zeromq;
						CONFIG_READ_MEMBER(zeromq_object, "host", zeromq.host)
						CONFIG_READ_MEMBER(zeromq_object, "port", zeromq.port)
						CONFIG_READ_MEMBER(zeromq_object, "is_server", zeromq.is_server)
						zeromqs.push_back(std::move(zeromq));
					CONFIG_FOREACH_END
				CONFIG_MOVE_OBJECT(root, "lua", lua_object)
					CONFIG_READ_MEMBER(lua_object, "id", lua.id)
					CONFIG_READ_MEMBER(lua_object, "concurrency", lua.concurrency)
					CONFIG_READ_MEMBER(lua_object, "file", lua.file)
					CONFIG_READ_MEMBER(lua_object, "frame", lua.frame)
			
			return true;
		}
	};
	ContestService()
	{
		this->Depends(&LoggerService::Instance())
			->Depends(&ManagerClientService::Instance())
			->Depends(&CacheClientService::Instance())
			->Depends(&DbCacheClientService::Instance());
	}
	virtual ~ContestService()
	{
		for (size_t index = 0; index < zeromqs_.size(); ++index)
		{
			ObjectPool<ZeroMessageQueue>::Delete(zeromqs_[index]);
		}
	}
	bool Init(const std::string& json)
	{
		bool ret = conf_.ReadConfig(json);
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Contest1Service %x][%s] config json parse fail.\n") % this % __FUNCTION__;
			return false;
		}
		
		for (size_t index = 0; index < zeromqs_.size(); ++index)
		{
			ObjectPool<ZeroMessageQueue>::Delete(zeromqs_[index]);
		}
		zeromqs_.clear();
		for (size_t index = 0; index < conf_.zeromqs.size(); ++index)
		{
			zeromqs_.push_back(ObjectPool<ZeroMessageQueue>::New());
			ret = zeromqs_[index]->Init(conf_.zeromqs[index]);
			if (!ret)
			{
				LOG(SYS, ERROR) << boost::format("[Contest1Service %x][%s] message queue init fail.\n") % this % __FUNCTION__;
				return false;
			}
		}
		
		ret = lua_loop_.Init(conf_.lua);
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Contest1Service %x][%s] lua loop init fail.\n") % this % __FUNCTION__;
			return false;
		}
		
		InitBaseModule();
		
		return true;
	}
	virtual bool Start()
	{
		bool ret;
		for (size_t index = 0; index < zeromqs_.size(); ++index)
		{
			ret = zeromqs_[index]->Start();
			if (!ret)
			{
				LOG(SYS, ERROR) << boost::format("[Contest1Service %x][%s] message queue start fail.\n") % this % __FUNCTION__;
				return false;
			}
		}
		
		ret = lua_loop_.Start();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Contest1Service %x][%s] lua loop start fail.\n") % this % __FUNCTION__;
			return false ;
		}
		
		return true;
	}
	virtual bool Stop()
	{
		bool ret;
		for (size_t index = 0; index < zeromqs_.size(); ++index)
		{
			ret = zeromqs_[index]->Stop();
			if (!ret)
			{
				LOG(SYS, ERROR) << boost::format("[Contest1Service %x][%s] message queue stop fail.\n") % this % __FUNCTION__;
				return false;
			}
		}
		
		ret = lua_loop_.Stop();
		if(!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Contest1Service %x][%s] lua loop stop fail.\n") % this % __FUNCTION__ ;
			return false ;
		}
		
		return true;
	}
	
	virtual bool Running()
	{
		if (!zeromqs_.size())
		{
			return false;
		}
		
		bool ret;
		for (size_t index = 0; index < zeromqs_.size(); ++index)
		{
			ret = zeromqs_[index]->Running();
			if (!ret)
			{
				return false;
			}
		}
		
		ret = lua_loop_.Running();
		if (!ret)
		{
			return false ;
		}
		
		return true;
	}
	
	virtual bool Boot()
	{
		return Service<ContestService>::Boot();
	}
	
	Packet* ReadPacket(uint32_t id)
	{
		if (id >= zeromqs_.size())
		{
			return nullptr;
		}
		return zeromqs_[id]->ReadPacket();
	}
	
	bool WritePacket(uint32_t id, Packet* packet)
	{
		if (id >= zeromqs_.size())
		{
			return false;
		}
		return zeromqs_[id]->WritePacket(packet);
	}
protected:	
	void InitBaseModule()
	{
		LuaIntf::LuaBinding(lua_loop_.State())
			.beginModule("Base")
				.beginModule("Enviroment")
					.addConstant("client_count", zeromqs_.size())
				.endModule()
			.endModule();
	}
	
protected:
	Config conf_;
	
	std::vector<ZeroMessageQueue*> zeromqs_;
	LuaLoop lua_loop_;
};

#endif // !CONTEST_SERVICE_HPP
