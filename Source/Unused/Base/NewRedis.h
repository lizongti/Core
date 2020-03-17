#ifndef	NEW_REDIS_HPP
#define NEW_REDIS_HPP

#include <string>
#include <queue>
#include <iostream>
#include <boost/lexical_cast.hpp>
#include <boost/format.hpp>
#include <boost/pool/pool_alloc.hpp>
#include <hiredis/hiredis.h>
#include <ctime>
#include "./BaseDatabase.h"
#include "Logger.h"
#include "./StringFun.h"
#include "./DbInfoManager.h"

class NewRedis
{
public:

	struct Config
	{
		Config()
		{};
		std::string host;
		uint16_t port;
		std::string password;
		const static uint32_t record_queue_limit = 128;
	};

	NewRedis();

	virtual bool Init(const Config& conf);

	virtual Config& Conf();

	virtual bool Start();

	virtual bool Stop();

	virtual bool Reset();

	virtual bool Running();

	bool SaveDbKey(const BaseDatabase::Command& command, BaseDatabase::Reply& reply);

	bool UpdateHashValue(const std::string& table_name, const std::string& key, const std::string& value);

	bool DelHashValue(const std::string& table_name, const std::string& key);

	bool GetRecord(const std::string& table_name, const std::string& key, vector<std::string>& result_list);

	bool GetExpire(vector<std::string>& result_list);

	bool Update(const BaseDatabase::Command& command, BaseDatabase::Reply& reply);

	bool SaveFromCommand(const BaseDatabase::Command& command, BaseDatabase::Reply& reply);

	bool SaveFromReply(const BaseDatabase::Command& command, BaseDatabase::Reply& reply);

	bool Delete(const BaseDatabase::Command& command, BaseDatabase::Reply& reply);

	bool Delete(const string& key);

	bool Ping();

	bool Load(const BaseDatabase::Command& command, BaseDatabase::Reply& reply);

	virtual bool Write(const BaseDatabase::CommandSet& command_set);

	virtual bool Read(BaseDatabase::ReplySet& reply_set);

protected:
	std::atomic_bool running_;
	Config conf_;
	redisContext* context_;
	redisReply* reply_;
};

#endif // !REDIS_HPP
