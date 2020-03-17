#ifndef LOGGER_SERVICE
#define LOGGER_SERVICE

#include "../Base/BaseHeaders.h"

class RedisService
	: public Service
{
public:
	struct request
	{
		std::string fmt;
		std::vector<std::string> args;
	};
	struct request_list
	{
		std::string id;
		std::vector<command> list;
	};
	struct response
	{
		std::string content;
	};
	struct response_list
	{
		std::string id;
		std::vector<response> replies;
	};
	struct record
	{
		std::string id;
		size_t sz;
	};
public
	redis_service(){};

	virtual ~redis_service(){};

protected:
	virtual bool init(const std::string &json)
	{
		std::string password;

		timeval t;
		t.tv_sec = 3;
		t.tv_usec = 0;

		context_ = redisConnectWithTimeout(conf_.host.c_str(), conf_.port, t);
		if (context_ != NULL && context_->err)
		{
			LOG(SYS, ERROR) << boost::format(
								   "[Redis %x][%s] connecting to redis fail, error:%s.\n") %
								   this % __FUNCTION__ % context_->errstr;
		}
		else
		{
			LOG(SYS, INFO) << boost::format("[Redis %x][%s] connecting to redis %s:%hd successfully.\n") % this % __FUNCTION__ % conf_.host.c_str() %
								  conf_.port;
		}

		if (password != "")
		{
			std::string fmt = (boost::format("AUTH %s") % password).str();
			reply_ = (redisReply *)redisCommand(context_, fmt.c_str());
			freeReplyObject(reply_);
		}

		return true;
	}

	virtual bool callback(const std::string &sender, MessageType type, void *data)
	{
		if (type == MSG_TYPE_JSON)
		{
			service_manager::send(sender, )
		}
	}

	virtual bool release();

protected:
	void execute(command_list request)
	{
		record record = {.id, command_set.commands.size()};
		record_queue_.push(record);

		record record = {command_set.id, command_set.commands.size()};
		record_queue_.push(record);
		for (size_t index = 0; index < record.size(); ++index)
		{
		}
	}

	void get_reply_in_pipeline()
	{
		while (true)
		{
			Redis::ReplySet reply_set;
			if (!redis_.Read(reply_set))
			{
				return;
			}
			if (!reply_set_queue_.push(reply_set))
			{
				LOG(SYS, ERROR) << boost::format("[RedisLoop %x][%s] reply queue is full.\n") % this %
									   __FUNCTION__;
			}
		}
	}

	bool redis_append_command(const command &command)
	{
		switch (command.args.size())
		{
		case 0:
			if (REDIS_OK != redisAppendCommand(context_,
											   command.fmt.c_str()))
			{
				Reset();
				return false;
			}
			break;
		case 1:
			if (REDIS_OK != redisAppendCommand(context_,
											   command.fmt.c_str(),
											   command.args[0].c_str()))
			{
				Reset();
				return false;
			}
			break;
		case 2:
			if (REDIS_OK != redisAppendCommand(context_,
											   command.fmt.c_str(),
											   command.args[0].c_str(),
											   command.args[1].c_str()))
			{
				Reset();
				return false;
			}
			break;
		case 3:
			if (REDIS_OK != redisAppendCommand(context_,
											   command.fmt.c_str(),
											   command.args[0].c_str(),
											   command.args[1].c_str(),
											   command.args[2].c_str()))
			{
				Reset();
				return false;
			}
			break;
		case 4:
			if (REDIS_OK != redisAppendCommand(context_,
											   command.fmt.c_str(),
											   command.args[0].c_str(),
											   command.args[1].c_str(),
											   command.args[2].c_str(),
											   command.args[3].c_str()))
			{
				Reset();
				return false;
			}
			break;
		case 5:
			if (REDIS_OK != redisAppendCommand(context_,
											   command.fmt.c_str(),
											   command.args[0].c_str(),
											   command.args[1].c_str(),
											   command.args[2].c_str(),
											   command.args[3].c_str(),
											   command.args[4].c_str()))
			{
				Reset();
				return false;
			}
			break;
		case 6:
			if (REDIS_OK != redisAppendCommand(context_,
											   command.fmt.c_str(),
											   command.args[0].c_str(),
											   command.args[1].c_str(),
											   command.args[2].c_str(),
											   command.args[3].c_str(),
											   command.args[4].c_str(),
											   command.args[5].c_str()))
			{
				Reset();
				return false;
			}
			break;
		case 7:
			if (REDIS_OK != redisAppendCommand(context_,
											   command.fmt.c_str(),
											   command.args[0].c_str(),
											   command.args[1].c_str(),
											   command.args[2].c_str(),
											   command.args[3].c_str(),
											   command.args[4].c_str(),
											   command.args[5].c_str(),
											   command.args[6].c_str()))
			{
				Reset();
				return false;
			}
			break;
		case 8:
			if (REDIS_OK != redisAppendCommand(context_,
											   command.fmt.c_str(),
											   command.args[0].c_str(),
											   command.args[1].c_str(),
											   command.args[2].c_str(),
											   command.args[3].c_str(),
											   command.args[4].c_str(),
											   command.args[5].c_str(),
											   command.args[6].c_str(),
											   command.args[7].c_str()))
			{
				Reset();
				return false;
			}
			break;
		case 9:
			if (REDIS_OK != redisAppendCommand(context_,
											   command.fmt.c_str(),
											   command.args[0].c_str(),
											   command.args[1].c_str(),
											   command.args[2].c_str(),
											   command.args[3].c_str(),
											   command.args[4].c_str(),
											   command.args[5].c_str(),
											   command.args[6].c_str(),
											   command.args[7].c_str(),
											   command.args[8].c_str()))
			{
				Reset();
				return false;
			}
			break;
		}
		return true;
	}

	bool redis_get_reply(ReplySet &reply_set)
	{
		record record = record_queue_.front();
		record_queue_.pop();
		reply_set.id = record.id;

		for (size_t index = 0; index < record.size(); ++index)
		{
			Reply reply;
			if (REDIS_OK != redisGetReply(context_, (void **)&reply_))
			{
				if (context_ == nullptr || context_->err != 0)
				{
					Reset();
				}
				LOG(SYS, ERROR) << boost::format("[Redis %x][%s] execute command in pipeline fail.\n") %
									   this % __FUNCTION__;
				return false;
			}

			if (reply_ != NULL)
			{
				if (reply_->type == REDIS_REPLY_STRING && reply_->len > 0)
				{
					reply = reply_->str;

					reply_set.replies.push_back(std::move(reply));
				}
				else if (reply_->type == REDIS_REPLY_ARRAY && reply_->elements > 0)
				{
					for (size_t reply_index = 0; reply_index < reply_->elements; ++reply_index)
					{
						if (reply_->element[reply_index]->type == REDIS_REPLY_STRING &&
							reply_->element[reply_index]->len > 0)
						{
							reply = reply_->element[reply_index]->str;

							reply_set.replies.push_back(std::move(reply));
						}
						else if (reply_->element[reply_index]->type == REDIS_REPLY_INTEGER)
						{
							reply = reply_->element[reply_index]->integer;
							reply_set.replies.push_back(std::move(reply));
						}
						else
						{
							reply = "";
							reply_set.replies.push_back(std::move(reply));
						}
					}
				}
				else if (reply_->type == REDIS_REPLY_INTEGER)
				{
					reply = boost::lexical_cast<std::string>(reply_->integer);
					reply_set.replies.push_back(std::move(reply));
				}
				else
				{
					reply = "";
					reply_set.replies.push_back(std::move(reply));
				}
			}
			freeReplyObject(reply_);
		}
		return true;
	}

protected:
	redisContext *context_;
	redisReply *reply_;
	std::queue<record> record_queue_;
};
REIGSTER_SERVICE(RedisService)

#endif // !LOGGER_SERVICE
