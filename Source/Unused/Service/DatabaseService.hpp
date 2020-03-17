
#ifndef DATABASE_SERVICE_HPP
#define DATABASE_SERVICE_HPP

#include "../Base/BaseHeaders.h"
#include "./LoggerService.hpp"

class DatabaseLine 
{
public:
	struct Config
	{
		RabbitMessageQueueReader::Config rabbitmq_reader;
		RabbitMessageQueueWriter::Config rabbitmq_writer;
		MysqlLoop::Config mysql;
		LuaLoop::Config lua;
	};
	DatabaseLine()
	{
	}
	virtual ~DatabaseLine()
	{		
	}
	bool Init(const Config& conf)
	{
		conf_ = conf;
		
		bool ret = rabbitmq_reader_.Init(conf_.rabbitmq_reader);
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Database %x][%s] message queue reader init fail.\n") % this % __FUNCTION__;
			return false;
		}

		ret = rabbitmq_writer_.Init(conf_.rabbitmq_writer);
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Database %x][%s] message queue writer init fail.\n") % this % __FUNCTION__;
			return false;
		}

		ret = mysql_loop_.Init(conf_.mysql);
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Database %x][%s] mysql init fail.\n") % this % __FUNCTION__;
			return false;
		}
		
		ret = lua_loop_.Init(conf_.lua);
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Database %x][%s] lua loop init fail.\n") % this % __FUNCTION__;
			return false;	
		}		
		
		return true;
	}
	virtual bool Start()
	{		
		bool ret = rabbitmq_reader_.Start();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Database %x][%s] message queue reader start fail.\n") % this % __FUNCTION__;
			return false;
		}

		ret = rabbitmq_writer_.Start();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Database %x][%s] message queue writer start fail.\n") % this % __FUNCTION__;
			return false;
		}

		ret = mysql_loop_.Start();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Database %x][%s] mysql start fail.\n") % this % __FUNCTION__;
			return false;
		}
		
		ret = lua_loop_.Start();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Database %x][%s] lua loop start fail.\n") % this % __FUNCTION__;
			return false;	
		}
		
		return true;
	}
	virtual bool Stop()
	{
		bool ret = rabbitmq_reader_.Stop();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Database %x][%s] message queue reader stop fail.\n") % this % __FUNCTION__;
			return false;
		}

		ret = rabbitmq_writer_.Stop();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Database %x][%s] message queue writer stop fail.\n") % this % __FUNCTION__;
			return false;
		}

		ret = mysql_loop_.Stop();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Database %x][%s] mysql stop fail.\n") % this % __FUNCTION__;
			return false;	
		}
		
		ret = lua_loop_.Stop();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[Database %x][%s] lua loop stop fail.\n") % this % __FUNCTION__;
			return false;	
		}
		
		return true;
	}
	
	virtual bool Running()
	{
		return rabbitmq_reader_.Running()
			&& rabbitmq_writer_.Running()
			&& mysql_loop_.Running()
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
		Mysql::CommandSet command_set;
		if (!DecodeMysqlCommandSet(command_set_json, command_set))
		{
			LOG(SYS, ERROR) << boost::format("[Database %x][%s] mysql decode fail.\n") % this % __FUNCTION__;
			return false;
		}
		if (!mysql_loop_.Write(command_set))
		{
			LOG(SYS, ERROR) << boost::format("[Database %x][%s] mysql command write fail.\n") % this % __FUNCTION__;
			return false;
		}
		return true;
	}

	std::string Reply()
	{
		Mysql::ReplySet reply_set;
		if (!mysql_loop_.Read(reply_set))
		{
			return "";
		}
		std::string reply_set_json;
		if (!EncodeMysqlReplySet(reply_set, reply_set_json))
		{
			LOG(SYS, ERROR) << boost::format("[Database %x][%s] mysql decode fail.\n") % this % __FUNCTION__;
			return "";
		}
		return reply_set_json;
	}

protected:	
	bool DecodeMysqlCommandSet(const std::string& command_set_json, Mysql::CommandSet& command_set)
	{
		rapidjson::Document document;
		document.SetObject();
		
		if (document.Parse<0>(command_set_json.c_str()).HasParseError())  
		{  
			LOG(SYS, ERROR) << boost::format("[Database %x][%s] command set json parse fail.\n") % this % __FUNCTION__;
			return false;
		}
		
		if (!document.IsObject())
		{
			LOG(SYS, ERROR) << boost::format("[Database %x][%s] command set json type error.\n") % this % __FUNCTION__;
			return false;
		}
		
		if (document.HasMember("id") && document["id"].IsString())
		{
			command_set.id = document["id"].GetString();
		}
		else
		{
			LOG(SYS, ERROR) << boost::format("[Database %x][%s] command set json leak field id.\n") % this % __FUNCTION__;
			return false;
		}
		
		if (document.HasMember("commands") && document["commands"].IsArray())
		{
			for (size_t index = 0; index < document["commands"].Size(); ++index)
			{
				if (!document["commands"][index].IsObject())
				{
					LOG(SYS, ERROR) << boost::format("[Database %x][%s] command json type error.\n") % this % __FUNCTION__;
					return false;
				}
				Mysql::Command command;
				
				if (document["commands"][index].HasMember("sql") && document["commands"][index]["sql"].IsString())
				{
					command.sql = document["commands"][index]["sql"].GetString();
				}
				else
				{
					LOG(SYS, ERROR) << boost::format("[Database %x][%s] command json leak field sql.\n") % this % __FUNCTION__;
					return false;
				}
				
				if (document["commands"][index].HasMember("args") && document["commands"][index]["args"].IsArray())
				{
					for (size_t index2 = 0; index2 < document["commands"].Size(); ++index2)
					{
						if (document["commands"][index]["args"][index2].IsNumber())
						{
							command.args.push_back(std::move(boost::lexical_cast<std::string>(document["commands"][index]["args"][index2].GetInt64())));
						}
						else if (document["commands"][index]["args"][index2].IsString())
						{
							command.args.push_back(std::move(document["commands"][index]["args"][index2].GetString()));
						}
					}
				}

				command_set.commands.push_back(std::move(command));
			}
		}
		else
		{
			LOG(SYS, ERROR) << boost::format("[Database %x][%s] command set json leak field commands.\n") % this % __FUNCTION__;
			return false;
		}
		return true;
	}
	
	bool EncodeMysqlReplySet(const Mysql::ReplySet& reply_set, std::string& reply_set_json)
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
			reply.SetObject();
			
			rapidjson::Value row_num;
			row_num.SetInt(reply_set.replies[index].row_num);
			reply.AddMember("row_num", row_num.Move(), allocator);
			
			rapidjson::Value data_set;
			data_set.SetArray();
			for (size_t index2 = 0; index2 < reply_set.replies[index].data_set.size(); ++index2)
			{
				rapidjson::Value row;
				row.SetArray();
				
				for (size_t index3 = 0; index3 < reply_set.replies[index].data_set[index2].size(); ++index3)
				{
					rapidjson::Value field;
					field.SetString(rapidjson::StringRef(reply_set.replies[index].data_set[index2][index3].c_str()));
					row.PushBack(field.Move(), allocator);
				}
				
				data_set.PushBack(row.Move(), allocator);
			}
			reply.AddMember("data_set", data_set.Move(), allocator);
		
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
	MysqlLoop mysql_loop_;
	LuaLoop lua_loop_;
};


class DatabaseService : 
	public Service<DatabaseService>, 
	public Singleton<DatabaseService>, 
	public LuaLib<DatabaseService>
{
public:
	struct Config
	{
		std::vector<DatabaseLine::Config> lines;
		
		bool ReadConfig(const std::string& json)
		{
			CONFIG_CREATE_DOCUMENT(root, json) 
			CONFIG_MOVE_ARRAY(root, "lines", lines_array)
				CONFIG_FOREACH_OBJECT(lines_array, line_object)
					DatabaseLine::Config line;
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
					CONFIG_MOVE_OBJECT(line_object, "mysql", mysql_object)
						CONFIG_READ_MEMBER(mysql_object, "host", line.mysql.host)
						CONFIG_READ_MEMBER(mysql_object, "port", line.mysql.port)
						CONFIG_READ_MEMBER(mysql_object, "username", line.mysql.username)
						CONFIG_READ_MEMBER(mysql_object, "password", line.mysql.password)
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
	DatabaseService()
	{
		this->Depends(&LoggerService::Instance());
	}
	virtual ~DatabaseService()
	{
		for (size_t index = 0; index < database_lines_.size(); ++index)
		{
			ObjectPool<DatabaseLine>::Delete(database_lines_[index]);
		}		
	}
	bool Init(const std::string& json)
	{
		bool ret = conf_.ReadConfig(json);
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[DatabaseService %x][%s] config json parse fail.\n") % this % __FUNCTION__;
			return false ;
		}

		for (size_t index = 0; index < database_lines_.size(); ++index)
		{
			ObjectPool<DatabaseLine>::Delete(database_lines_[index]);
		}
		database_lines_.clear();
		for (size_t index = 0; index < conf_.lines.size(); ++index)
		{
			database_lines_.push_back(ObjectPool<DatabaseLine>::New());
			ret = database_lines_[index]->Init(conf_.lines[index]);
			if (!ret)
			{
				LOG(SYS, ERROR) << boost::format("[DatabaseService %x][%s] line init fail.\n") % this % __FUNCTION__;
				return false;
			}
		}
		
		return true;
	}
	virtual bool Start()
	{
		bool ret;
		for (size_t index = 0; index < database_lines_.size(); ++index)
		{
			ret = database_lines_[index]->Start();
			if (!ret)
			{
				LOG(SYS, ERROR) << boost::format("[DatabaseService %x][%s] line start fail.\n") % this % __FUNCTION__;
				return false;
			}
		}
		
		return true;
	}
	virtual bool Stop()
	{
		bool ret;
		for (size_t index = 0; index < database_lines_.size(); ++index)
		{
			ret = database_lines_[index]->Stop();
			if (!ret)
			{
				LOG(SYS, ERROR) << boost::format("[DatabaseService %x][%s] line stop fail.\n") % this % __FUNCTION__;
				return false;
			}
		}
		
		return true;
	}
	virtual bool Running()
	{
		if (!database_lines_.size())
		{
			return false;
		}
		
		bool ret;
		for (size_t index = 0; index < database_lines_.size(); ++index)
		{
			ret = database_lines_[index]->Running();
			if (!ret)
			{
				return false;
			}
		}
		return true;
	}
	
	virtual bool Boot()
	{
		return Service<DatabaseService>::Boot();
	}

	std::string ReadJson(uint32_t id)
	{
		if (id >= database_lines_.size())
		{
			return "";
		}
		return database_lines_[id]->Read();
	}

	bool WriteJson(uint32_t id, const std::string& response)
	{
		if (id >= database_lines_.size())
		{
			return false;
		}
		return database_lines_[id]->Write(response);
	}

	bool MysqlCommand(uint32_t id, const std::string& command_set_json)
	{
		if (id >= database_lines_.size())
		{
			return false;
		}
		return database_lines_[id]->Command(command_set_json);
	}
	
	std::string MysqlReply(unsigned int id)
	{
		if (id >= database_lines_.size())
		{
			return "";
		}
		return database_lines_[id]->Reply();
	}
	
protected:
	Config conf_;
	
	std::vector<DatabaseLine*> database_lines_;
};

#endif // !DATABASE_SERVICE_HPP