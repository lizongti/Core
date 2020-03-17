#ifndef REDIS_HPP
#define REDIS_HPP

#include <string>
#include <queue>
#include <iostream>
#include <boost/format.hpp>
#include <boost/pool/pool_alloc.hpp>
#include <hiredis/hiredis.h>
#include "loop.h"
#include "Logger.h"
#include "LuaState.h"

class Redis
{
public:
	struct Command
	{
		std::string cmd;
		std::vector<std::string> args;
	};
	struct CommandSet
	{
		std::string id;
		std::vector<Command> commands;
	};
	using Reply = std::string;
	struct ReplySet
	{
		std::string id;
		std::vector<Reply> replies;
	};

	struct Record
	{
		std::string id;
		uint32_t size;
	};

	struct Config
	{
		Config(){};
		std::string host;
		uint16_t port;
		std::string password;
		const static uint32_t record_queue_limit = 128;
	};

	Redis();

	virtual bool Init(Config &conf);

	virtual Config &Conf();

	virtual bool Start();

	virtual bool Stop();

	virtual bool Reset();

	virtual bool Running();

	virtual bool Execute(const CommandSet &command_set, ReplySet &reply_set);

	virtual bool Write(const CommandSet &command_set);

	virtual bool Read(ReplySet &reply_set);

protected:
	std::atomic_bool running_;
	Config conf_;
	redisContext *context_;
	redisReply *reply_;
	std::queue<Record> record_queue_;
};

class RedisLoop : public loop
{
public:
	struct Config
	{
		std::string host;
		uint16_t port;
		std::string password;
		const static uint32_t command_queue_size = 10240;
		const static uint32_t reply_queue_size = 10240;
	};

	RedisLoop();

	virtual ~RedisLoop();

	virtual bool Init(const Config &conf);

	virtual Config &Conf();

	virtual bool Start();

	virtual bool Stop();

	virtual bool Running();

	bool Write(const Redis::CommandSet &command_set);

	bool Read(Redis::ReplySet &reply_set);

protected:
	void GetReplyInPipeline();

protected:
	virtual void command_async_callback(uv_async_t *handle);

protected:
	static void static_command_async_callback(uv_async_t *handle);

protected:
	Config conf_;
	Redis redis_;

	uv_async_t command_async_;
	uv_async_cb command_async_cb_ = (uv_async_cb)&static_command_async_callback;

	boost::lockfree::spsc_queue<Redis::CommandSet, boost::lockfree::capacity<Config::command_queue_size>> command_set_queue_;
	boost::lockfree::spsc_queue<Redis::ReplySet, boost::lockfree::capacity<Config::reply_queue_size>> reply_set_queue_;
};

class IntegratedRedisLoop : public RedisLoop
{
public:
	IntegratedRedisLoop();
	virtual ~IntegratedRedisLoop();

	bool Integrate(std::function<std::string()> reply_func);

protected:
	virtual void reply_async_callback(uv_async_t *handle);

	virtual void command_async_callback(uv_async_t *handle);

protected:
	static void static_reply_async_callback(uv_async_t *handle);

	static void 
	r_callback(uv_timer_t *handle);

protected:
	uv_async_t reply_async_;
	uv_async_cb reply_async_cb_ = (uv_async_cb)&static_reply_async_callback;

	uv_timer_t timer_;
	uv_timer_cb timer_cb_ = (uv_timer_cb)&static_timer_callback;

	std::function<std::string()> reply_func_;
};

#endif // !REDIS_HPP
