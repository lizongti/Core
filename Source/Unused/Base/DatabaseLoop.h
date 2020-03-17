#ifndef _DATABASELOOP_H_
#define _DATABASELOOP_H_
#include <rapidjson/document.h>
#include <rapidjson/writer.h>
#include <rapidjson/stringbuffer.h>
#include <memory>
#include <stdio.h>
#include <cstdlib>
#include "./NewMysql.h"
#include "./NewRedis.h"
#include "Loop.h"
#include "Logger.h"

class DatabaseLoop : public Loop
{
public:
	DatabaseLoop();

	virtual ~DatabaseLoop();

	virtual bool Init(const DBInterface::Config& mysql_conf, const NewRedis::Config& redis_conf);

	virtual bool Start();

	virtual bool Stop();

	virtual bool Running();

	bool Write(const BaseDatabase::CommandSet& command_set);

	bool Read(BaseDatabase::ReplySet& reply_set);

protected:
	bool Execute(const BaseDatabase::Command& command, BaseDatabase::Reply& reply);

	virtual void command_async_callback(uv_async_t* handle);

protected:
	static void static_command_async_callback(uv_async_t* handle);

protected:
	//Config conf_;
	NewMysql mysql_;

	NewRedis redis_;

	uv_async_t command_async_;
	uv_async_cb command_async_cb_ = (uv_async_cb)&static_command_async_callback;

	boost::lockfree::spsc_queue<BaseDatabase::CommandSet, boost::lockfree::capacity<1024>> command_set_queue_;
	boost::lockfree::spsc_queue<BaseDatabase::ReplySet, boost::lockfree::capacity<1024>> reply_set_queue_;

	std::mutex mutex_;

};

#endif
