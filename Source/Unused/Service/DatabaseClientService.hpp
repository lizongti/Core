#ifndef DATABASE_CLIENT_SERVICE_HPP
#define DATABASE_CLIENT_SERVICE_HPP

#include "../Base/BaseHeaders.h"
#include "./LoggerService.hpp"

class DatabaseClientService :
	public Service<DatabaseClientService>,
	public Singleton<DatabaseClientService>,
	public LuaLib<DatabaseClientService>
{
public:
	struct Config
	{
		RabbitMessageQueueReader::Config rabbitmq_reader;
		RabbitMessageQueueWriter::Config rabbitmq_writer;

		bool ReadConfig(const std::string& json)
		{
			CONFIG_CREATE_DOCUMENT(root, json)
				CONFIG_MOVE_OBJECT(root, "rabbitmq_reader", reader_object)
				CONFIG_READ_MEMBER(reader_object, "host", rabbitmq_reader.host)
				CONFIG_READ_MEMBER(reader_object, "port", rabbitmq_reader.port)
				CONFIG_READ_MEMBER(reader_object, "channel", rabbitmq_reader.channel)
				CONFIG_READ_MEMBER(reader_object, "username", rabbitmq_reader.username)
				CONFIG_READ_MEMBER(reader_object, "password", rabbitmq_reader.password)
				CONFIG_READ_MEMBER(reader_object, "exchange", rabbitmq_reader.exchange)
				CONFIG_READ_MEMBER(reader_object, "binding_key", rabbitmq_reader.binding_key)
				CONFIG_READ_MEMBER(reader_object, "queue_name", rabbitmq_reader.queue_name)
				CONFIG_MOVE_OBJECT(root, "rabbitmq_writer", writer_object)
				CONFIG_READ_MEMBER(writer_object, "host", rabbitmq_writer.host)
				CONFIG_READ_MEMBER(writer_object, "port", rabbitmq_writer.port)
				CONFIG_READ_MEMBER(writer_object, "channel", rabbitmq_writer.channel)
				CONFIG_READ_MEMBER(writer_object, "username", rabbitmq_writer.username)
				CONFIG_READ_MEMBER(writer_object, "password", rabbitmq_writer.password)
				CONFIG_READ_MEMBER(writer_object, "exchange", rabbitmq_writer.exchange)
				CONFIG_READ_MEMBER(writer_object, "binding_key", rabbitmq_writer.binding_key)
				CONFIG_READ_MEMBER(writer_object, "queue_name", rabbitmq_writer.queue_name)

			return true;
		}
	};
	DatabaseClientService()
	{
		this->Depends(&LoggerService::Instance());
	}
	virtual ~DatabaseClientService()
	{

	}
	virtual bool Init(const std::string& json)
	{
		bool ret = conf_.ReadConfig(json);
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[DatabaseClientService %x][%s], config json parse fail.\n") % this % __FUNCTION__;
			return false;
		}

		ret = rabbitmq_reader_.Init(conf_.rabbitmq_reader);
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[DatabaseClientService %x][%s] message queue reader init fail.\n") % this % __FUNCTION__;
			return false;
		}

		ret = rabbitmq_writer_.Init(conf_.rabbitmq_writer);
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[DatabaseClientService %x][%s] message queue writer init fail.\n") % this % __FUNCTION__;
			return false;
		}

		return true;
	}
	virtual bool Start()
	{
		bool ret = rabbitmq_reader_.Start();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[DatabaseClientService %x][%s] message queue reader start fail.\n") % this % __FUNCTION__;
			return false;
		}

		ret = rabbitmq_writer_.Start();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[DatabaseClientService %x][%s] message queue writer start fail.\n") % this % __FUNCTION__;
			return false;
		}

		return true;
	}
	virtual bool Stop()
	{
		bool ret = rabbitmq_reader_.Stop();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[DatabaseClientService %x][%s] message queue reader stop fail.\n") % this % __FUNCTION__;
			return false;
		}

		ret = rabbitmq_writer_.Stop();
		if (!ret)
		{
			LOG(SYS, ERROR) << boost::format("[DatabaseClientService %x][%s] message queue writer stop fail.\n") % this % __FUNCTION__;
			return false;
		}

		return true;
	}

	virtual bool Running()
	{
		return rabbitmq_reader_.Running() && rabbitmq_writer_.Running();
	}

	virtual bool Boot()
	{
		return Service<DatabaseClientService>::Boot();
	}

	std::string ReadJson()
	{
		std::string response;
		rabbitmq_reader_.ReadString(response);
		return response;
	}

	bool WriteJson(const std::string& request)
	{
		return rabbitmq_writer_.WriteString(request);
	}

protected:
	Config conf_;

	RabbitMessageQueueReader rabbitmq_reader_;
	RabbitMessageQueueWriter rabbitmq_writer_;
};

#endif // !DATABASE_CLIENT_SERVICE_HPP
