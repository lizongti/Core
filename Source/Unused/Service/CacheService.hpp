#ifndef CACHE_SERVICE_HPP
#define CACHE_SERVICE_HPP

#include <vector>
#include "../Base/BaseHeaders.h"
#include "./LoggerService.hpp"

class CacheLine
{
public:
	struct Config
	{
		RabbitMessageQueueReader::Config rabbitmq_reader;
		RabbitMessageQueueWriter::Config rabbitmq_writer;
		RedisLoop::Config redis;
		LuaLoop::Config lua;
	};
	CacheLine()
	{
	}
	virtual ~CacheLine()
	{
	}
	bool Init(const Config& conf)
	{
		conf_ = conf;

		bool ret = rabbitmq_reader_.Init(conf_.rabbitmq_reader);
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Cache %x][%s] message queue reader init fail.\n") % this % __FUNCTION__;
			return false;
		}
		
		ret = rabbitmq_writer_.Init(conf_.rabbitmq_writer);
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Cache %x][%s] message queue writer init fail.\n") % this % __FUNCTION__;
			return false;
		}
		
		ret = redis_loop_.Init(conf_.redis);
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Cache %x][%s] redis loop init fail.\n") % this % __FUNCTION__;
			return false;	
		}
		
		ret = lua_loop_.Init(conf_.lua);
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Cache %x][%s] lua loop init fail.\n") % this % __FUNCTION__;
			return false;	
		}
		
		return true;
	}
	virtual bool Start()
	{
		bool ret = rabbitmq_reader_.Start();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Cache %x][%s] message queue reader start fail.\n") % this % __FUNCTION__;
			return false;
		}
		
		ret = rabbitmq_writer_.Start();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Cache %x][%s] message queue writer start fail.\n") % this % __FUNCTION__;
			return false;		
		}
		
		ret = redis_loop_.Start();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Cache %x][%s] redis loop start fail.\n") % this % __FUNCTION__;
			return false;	
		}
		
		ret = lua_loop_.Start();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Cache %x][%s] lua loop start fail.\n") % this % __FUNCTION__;
			return false;	
		}
		
		return true;
	}
	virtual bool Stop()
	{
		bool ret = rabbitmq_reader_.Stop();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Cache %x][%s] message queue reader stop fail.\n") % this % __FUNCTION__;
			return false;
		}
		
		ret = rabbitmq_writer_.Stop();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Cache %x][%s] message queue writer stop fail.\n") % this % __FUNCTION__;
			return false;		
		}
		
		ret = redis_loop_.Stop();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Cache %x][%s] redis loop stop fail.\n") % this % __FUNCTION__;
			return false;	
		}
		
		ret = lua_loop_.Stop();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Cache %x][%s] lua loop stop fail.\n") % this % __FUNCTION__;
			return false;	
		}
		
		return true;
	}
	
	virtual bool Running()
	{
		return rabbitmq_reader_.Running()
			&& rabbitmq_writer_.Running() 
			&& redis_loop_.Running() 
			&& lua_loop_.Running();
	}
	
	std::string Read()
	{
		std::string request;
		rabbitmq_reader_.ReadString(request);
		return request;
	}
	
	bool Write(const std::string& response)
	{
		return rabbitmq_writer_.WriteString(response);
	}
	
	bool Command(const std::string& command_set_json)
	{
		Redis::CommandSet command_set;
		if (!DecodeRedisCommandSet(command_set_json, command_set))
		{
			LOG(SYS, ERROR) << boost::format("[Cache %x][%s] redis decode fail.\n") % this % __FUNCTION__;
			return false;
		}
		if (!redis_loop_.Write(command_set))
		{
			LOG(SYS, ERROR) << boost::format("[Cache %x][%s] redis command write fail.\n") % this % __FUNCTION__;
			return false;			
		}
		return true;
	}
	
	std::string Reply()
	{
		Redis::ReplySet reply_set;
		if (!redis_loop_.Read(reply_set))
		{
			return "";
		}
		std::string reply_set_json;
		if (!EncodeRedisReplySet(reply_set, reply_set_json))
		{
			LOG(SYS, ERROR) << boost::format("[Cache %x][%s] redis decode fail.\n") % this % __FUNCTION__;
			return "";
		}
		return reply_set_json;
	}
	
protected:
	bool DecodeRedisCommandSet(const std::string& command_set_json, Redis::CommandSet& command_set)
	{
		rapidjson::Document document;
		document.SetObject();
		
		if (document.Parse<0>(command_set_json.c_str()).HasParseError())  
		{  
			LOG(SYS, ERROR) << boost::format("[Cache %x][%s] command set json parse fail.\n") % this % __FUNCTION__;
			return false;
		}
		
		if (!document.IsObject())
		{
			LOG(SYS, ERROR) << boost::format("[Cache %x][%s] command set json type error.\n") % this % __FUNCTION__;
			return false;
		}
		
		if (document.HasMember("id") && document["id"].IsString())
		{
			command_set.id = document["id"].GetString();
		}
		else
		{
			LOG(SYS, ERROR) << boost::format("[Cache %x][%s] command set json leak field id.\n") % this % __FUNCTION__;
			return false;
		}
		
		if (document.HasMember("commands") && document["commands"].IsArray())
		{
			for (size_t index = 0; index < document["commands"].Size(); ++index)
			{
				if (!document["commands"][index].IsString())
				{
					LOG(SYS, ERROR) << boost::format("[Cache %x][%s] command json type error.\n") % this % __FUNCTION__;
					return false;
				}
				Redis::Command command = document["commands"][index].GetString();
				command_set.commands.push_back(std::move(command));
			}
		}
		else
		{
			LOG(SYS, ERROR) << boost::format("[Cache %x][%s] command set json leak field commands.\n") % this % __FUNCTION__;
			return false;
		}
		return true;
	}
	
	bool EncodeRedisReplySet(const Redis::ReplySet& reply_set, std::string& reply_set_json)
	{
		rapidjson::Document document;
		rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
		
		rapidjson::Value root;
		root.SetObject();
		
		rapidjson::Value id;
		id.SetString(rapidjson::StringRef(reply_set.id.c_str()));
		root.AddMember("id", id.Move(), allocator);
		
		rapidjson::Value replies;
		replies.SetArray();
		
		for (size_t index = 0; index < reply_set.replies.size(); ++index)
		{
			rapidjson::Value reply;
			reply.SetString(rapidjson::StringRef(reply_set.replies[index].c_str()));
			
			replies.PushBack(reply.Move(), allocator);	
		}
		root.AddMember("replies", replies.Move(), allocator);
		
		rapidjson::StringBuffer buffer;  
		rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
		root.Accept(writer); 
		reply_set_json = buffer.GetString(); 
		
		return true;
	}
	
protected:
	Config conf_;
	
	RabbitMessageQueueReader rabbitmq_reader_;
	RabbitMessageQueueWriter rabbitmq_writer_;
	RedisLoop redis_loop_;
	LuaLoop lua_loop_;
};

class CacheService : 
	public Service<CacheService>, 
	public Singleton<CacheService>, 
	public LuaLib<CacheService>
{
public:
	struct Config
	{
		std::vector<CacheLine::Config> lines;

		bool ReadConfig(const std::string& json)
		{
			CONFIG_CREATE_DOCUMENT(root, json) 
				CONFIG_MOVE_ARRAY(root, "lines", lines_array)
					CONFIG_FOREACH_OBJECT(lines_array, line_object)
						CacheLine::Config line;
						CONFIG_MOVE_OBJECT(line_object, "rabbitmq_reader", reader_object)
							CONFIG_READ_MEMBER(reader_object, "host", line.rabbitmq_reader.host)
							CONFIG_READ_MEMBER(reader_object, "port", line.rabbitmq_reader.port)
							CONFIG_READ_MEMBER(reader_object, "channel", line.rabbitmq_reader.channel)
							CONFIG_READ_MEMBER(reader_object, "username", line.rabbitmq_reader.username)
							CONFIG_READ_MEMBER(reader_object, "password", line.rabbitmq_reader.password)
							CONFIG_READ_MEMBER(reader_object, "exchange", line.rabbitmq_reader.exchange)
							CONFIG_READ_MEMBER(reader_object, "binding_key", line.rabbitmq_reader.binding_key)
							CONFIG_READ_MEMBER(reader_object, "queue_name", line.rabbitmq_reader.queue_name)
						CONFIG_MOVE_OBJECT(line_object, "rabbitmq_writer", writer_object)
							CONFIG_READ_MEMBER(writer_object, "host", line.rabbitmq_writer.host)
							CONFIG_READ_MEMBER(writer_object, "port", line.rabbitmq_writer.port)
							CONFIG_READ_MEMBER(writer_object, "channel", line.rabbitmq_writer.channel)
							CONFIG_READ_MEMBER(writer_object, "username", line.rabbitmq_writer.username)
							CONFIG_READ_MEMBER(writer_object, "password", line.rabbitmq_writer.password)
							CONFIG_READ_MEMBER(writer_object, "exchange", line.rabbitmq_writer.exchange)
							CONFIG_READ_MEMBER(writer_object, "binding_key", line.rabbitmq_writer.binding_key)
							CONFIG_READ_MEMBER(writer_object, "queue_name", line.rabbitmq_writer.queue_name)
						CONFIG_MOVE_OBJECT(line_object, "redis", redis_object)
							CONFIG_READ_MEMBER(redis_object, "host", line.redis.host)
							CONFIG_READ_MEMBER(redis_object, "port", line.redis.port)
							CONFIG_READ_MEMBER(redis_object, "password", line.redis.password)
						CONFIG_MOVE_OBJECT(line_object, "lua", lua_object)
							CONFIG_READ_MEMBER(lua_object, "id", line.lua.id)
							CONFIG_READ_MEMBER(lua_object, "concurrency", line.lua.concurrency)
							CONFIG_READ_MEMBER(lua_object, "file", line.lua.file)
							CONFIG_READ_MEMBER(lua_object, "frame", line.lua.frame)							
						lines.push_back(std::move(line));
					CONFIG_FOREACH_END
			return true;
		}
	};
	CacheService()
	{
		this->Depends(&LoggerService::Instance());
	}
	virtual ~CacheService()
	{
		for (size_t index = 0; index < cache_lines_.size(); ++index)
		{
			ObjectPool<CacheLine>::Delete(cache_lines_[index]);
		}
	}
	bool Init(const std::string& json)
	{
		bool ret = conf_.ReadConfig(json);
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[CacheService %x][%s] config json parse fail.\n") % this % __FUNCTION__;
			return false;
		}
		
		for (size_t index = 0; index < cache_lines_.size(); ++index)
		{
			ObjectPool<CacheLine>::Delete(cache_lines_[index]);
		}
		cache_lines_.clear();
		for (size_t index = 0; index < conf_.lines.size(); ++index)
		{
			cache_lines_.push_back(ObjectPool<CacheLine>::New());
			ret = cache_lines_[index]->Init(conf_.lines[index]);
			if (!ret)
			{
				LOG(SYS, ERROR) << boost::format("[CacheService %x][%s] line init fail.\n") % this % __FUNCTION__;
				return false;
			}
		}
		
		return true;
	}
	virtual bool Start()
	{
		for (size_t index = 0; index < cache_lines_.size(); ++index)
		{
			if (!cache_lines_[index]->Start())
			{
				LOG(SYS, ERROR) << boost::format("[CacheService %x][%s] line start fail.\n") % this % __FUNCTION__;
				return false;
			}
		}
		
		return true;
	}
	virtual bool Stop()
	{
		for (size_t index = 0; index < cache_lines_.size(); ++index)
		{
			if (!cache_lines_[index]->Stop())
			{
				LOG(SYS, ERROR) << boost::format("[CacheService %x][%s] line stop fail.\n") % this % __FUNCTION__;
				return false;
			}
		}
		
		return true;
	}
	virtual bool Running()
	{
		if (!cache_lines_.size())
		{
			return false;
		}
		for (size_t index = 0; index < cache_lines_.size(); ++index)
		{
			if (!cache_lines_[index]->Running())
			{
				return false;
			}
		}
		return true;
	}
	
	virtual bool Boot()
	{
		return Service<CacheService>::Boot();
	}
	
	virtual void OpenLib(lua_State* l)
	{
		
	}
	
	std::string ReadJson(uint32_t id)
	{
		if (id >= cache_lines_.size())
		{
			return "";
		}
		return cache_lines_[id]->Read();
	}
	
	bool WriteJson(uint32_t id, const std::string& response)
	{
		if (id >= cache_lines_.size())
		{
			return false;
		}
		return cache_lines_[id]->Write(response);
	}
	
	bool RedisCommand(uint32_t id, const std::string& command_set_json)
	{
		if (id >= cache_lines_.size())
		{
			return false;
		}
		return cache_lines_[id]->Command(command_set_json);
	}
	
	std::string RedisReply(uint32_t id)
	{
		if (id >= cache_lines_.size())
		{
			return "";
		}
		return cache_lines_[id]->Reply();
	}

protected:
	Config conf_;
	
	std::vector<CacheLine*> cache_lines_;
};

#endif // !CACHE_SERVICE_HPP
