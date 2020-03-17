#include "Redis.h"
#include <boost/lexical_cast.hpp>

Redis::Redis() {
    running_.store(false);
}

bool Redis::Init(Config &conf) {
    conf_ = conf;

    timeval t;
    t.tv_sec = 3;
    t.tv_usec = 0;

    bool isConnected = false;
    while (isConnected == false) {
        context_ = redisConnectWithTimeout(conf_.host.c_str(), conf_.port, t);
        if (context_ != NULL && context_->err) {
            LOG(SYS, ERROR) << boost::format(
                                   "[Redis %x][%s] connecting to redis fail, error:%s.\n") %
                                   this % __FUNCTION__ % context_->errstr;
			return false;
        } else {
			LOG(SYS, INFO) << boost::format("[Redis %x][%s] connecting to redis %s:%hd successfully.\n") % this %  __FUNCTION__ %  conf_.host.c_str() %
				conf_.port;
            isConnected = true;
        }
    }

    if (conf_.password != "") {
        std::string cmd = (boost::format("AUTH %s") % conf_.password).str();
        reply_ = (redisReply *)redisCommand(context_, cmd.c_str());
        freeReplyObject(reply_);
    }
    return true;
}

Redis::Config &Redis::Conf() {
    return conf_;
}

bool Redis::Start() {
    running_.store(true);
    return true;
}

bool Redis::Stop() {
    redisFree(context_);
    running_.store(false);
    return true;
}

bool Redis::Reset() {
    bool ret = Stop();
    if (!ret) {
        return ret;
    }

    ret = Init(conf_);
    if (!ret) {
        return ret;
    }

    ret = Start();
    if (!ret) {
        return ret;
    }

    return true;
}

bool Redis::Running() {
    return running_.load();
}

bool Redis::Execute(const CommandSet &command_set, ReplySet &reply_set) {
    reply_set.id = command_set.id;

    for (size_t index = 0; index < command_set.commands.size(); ++index) {
		switch (command_set.commands[index].args.size())
		{
		case 0:
			if (REDIS_OK != redisAppendCommand(context_, command_set.commands[index].cmd.c_str())) {
				Reset();
				return false;
			}
			break;
		case 1:
			if (REDIS_OK != redisAppendCommand(context_, command_set.commands[index].cmd.c_str(), command_set.commands[index].args[0].c_str())) {
				Reset();
				return false;
			}
			break;
		case 2:
			if (REDIS_OK != redisAppendCommand(context_, command_set.commands[index].cmd.c_str(), command_set.commands[index].args[0].c_str(),
				command_set.commands[index].args[1].c_str())) {
				Reset();
				return false;
			}
			break;
		case 3:
			if (REDIS_OK != redisAppendCommand(context_, command_set.commands[index].cmd.c_str(), command_set.commands[index].args[0].c_str(),
				command_set.commands[index].args[1].c_str(), command_set.commands[index].args[2].c_str())) {
				Reset();
				return false;
			}
			break;
		case 4:
			if (REDIS_OK != redisAppendCommand(context_, command_set.commands[index].cmd.c_str(), command_set.commands[index].args[0].c_str(),
				command_set.commands[index].args[1].c_str(), command_set.commands[index].args[2].c_str(), command_set.commands[index].args[3].c_str())) {
				Reset();
				return false;
			}
			break;
		case 5:
			if (REDIS_OK != redisAppendCommand(context_, command_set.commands[index].cmd.c_str(), command_set.commands[index].args[0].c_str(),
				command_set.commands[index].args[1].c_str(), command_set.commands[index].args[2].c_str(), command_set.commands[index].args[3].c_str(),
				command_set.commands[index].args[4].c_str())) {
				Reset();
				return false;
			}
			break;
		case 6:
			if (REDIS_OK != redisAppendCommand(context_, command_set.commands[index].cmd.c_str(), command_set.commands[index].args[0].c_str(),
				command_set.commands[index].args[1].c_str(), command_set.commands[index].args[2].c_str(), command_set.commands[index].args[3].c_str(),
				command_set.commands[index].args[4].c_str(), command_set.commands[index].args[5].c_str())) {
				Reset();
				return false;
			}
			break;
		case 7:
			if (REDIS_OK != redisAppendCommand(context_, command_set.commands[index].cmd.c_str(), command_set.commands[index].args[0].c_str(),
				command_set.commands[index].args[1].c_str(), command_set.commands[index].args[2].c_str(), command_set.commands[index].args[3].c_str(),
				command_set.commands[index].args[4].c_str(), command_set.commands[index].args[5].c_str(), command_set.commands[index].args[6].c_str())) {
				Reset();
				return false;
			}
			break;
		case 8:
			if (REDIS_OK != redisAppendCommand(context_, command_set.commands[index].cmd.c_str(), command_set.commands[index].args[0].c_str(),
				command_set.commands[index].args[1].c_str(), command_set.commands[index].args[2].c_str(), command_set.commands[index].args[3].c_str(),
				command_set.commands[index].args[4].c_str(), command_set.commands[index].args[5].c_str(), command_set.commands[index].args[6].c_str(),
				command_set.commands[index].args[7].c_str())) {
				Reset();
				return false;
			}
			break;
		case 9:
			if (REDIS_OK != redisAppendCommand(context_, command_set.commands[index].cmd.c_str(), command_set.commands[index].args[0].c_str(),
				command_set.commands[index].args[1].c_str(), command_set.commands[index].args[2].c_str(), command_set.commands[index].args[3].c_str(),
				command_set.commands[index].args[4].c_str(), command_set.commands[index].args[5].c_str(), command_set.commands[index].args[6].c_str(),
				command_set.commands[index].args[7].c_str(), command_set.commands[index].args[8].c_str())) {
				Reset();
				return false;
			}
			break;
		}

    }

    for (size_t index = 0; index < command_set.commands.size(); ++index) {
        Reply reply;
        if (REDIS_OK != redisGetReply(context_, (void **)&reply_)) {
            if (context_ == nullptr || context_->err != 0) {
                Reset();
            }
            LOG(SYS, ERROR) << boost::format("[Redis %x][%s] execute command in pipeline fail.\n") %
                                   this % __FUNCTION__;
            return false;
        } else {
            if (reply_ != NULL) {
                if (reply_->type == REDIS_REPLY_STRING && reply_->len > 0) {
                    reply = reply_->str;

                    reply_set.replies.push_back(std::move(reply));
                } else if (reply_->type == REDIS_REPLY_ARRAY && reply_->elements > 0) {
                    for (size_t reply_index = 0; reply_index < reply_->elements; ++reply_index) {
                        if (reply_->element[reply_index]->type == REDIS_REPLY_STRING &&
                            reply_->element[reply_index]->len > 0) {
                            reply = reply_->element[reply_index]->str;

                            reply_set.replies.push_back(std::move(reply));
                        } else if (reply_->element[reply_index]->type == REDIS_REPLY_INTEGER) {
                            reply = reply_->element[reply_index]->integer;
                            reply_set.replies.push_back(std::move(reply));
                        } else {
                            reply = "";
                            reply_set.replies.push_back(std::move(reply));
                        }
                    }
                } else if (reply_->type == REDIS_REPLY_INTEGER) {
                    reply = boost::lexical_cast<std::string>(reply_->integer);
                    reply_set.replies.push_back(std::move(reply));
                } else {
                    reply = "";
                    reply_set.replies.push_back(std::move(reply));
                }
            }
        }
        freeReplyObject(reply_);
    }
    return true;
}

bool Redis::Write(const CommandSet &command_set) {
    Record record;
    record.id = command_set.id;
    record.size = command_set.commands.size();
    record_queue_.push(record);
	for (size_t index = 0; index < command_set.commands.size(); ++index) {
		switch (command_set.commands[index].args.size())
		{
		case 0:
			if (REDIS_OK != redisAppendCommand(context_, command_set.commands[index].cmd.c_str())) {
				Reset();
				return false;
			}
			break;
		case 1:
			if (REDIS_OK != redisAppendCommand(context_, command_set.commands[index].cmd.c_str(), command_set.commands[index].args[0].c_str())) {
				Reset();
				return false;
			}
			break;
		case 2:
			if (REDIS_OK != redisAppendCommand(context_, command_set.commands[index].cmd.c_str(), command_set.commands[index].args[0].c_str(),
				command_set.commands[index].args[1].c_str())) {
				Reset();
				return false;
			}
			break;
		case 3:
			if (REDIS_OK != redisAppendCommand(context_, command_set.commands[index].cmd.c_str(), command_set.commands[index].args[0].c_str(),
				command_set.commands[index].args[1].c_str(), command_set.commands[index].args[2].c_str())) {
				Reset();
				return false;
			}
			break;
		case 4:
			if (REDIS_OK != redisAppendCommand(context_, command_set.commands[index].cmd.c_str(), command_set.commands[index].args[0].c_str(),
				command_set.commands[index].args[1].c_str(), command_set.commands[index].args[2].c_str(), command_set.commands[index].args[3].c_str())) {
				Reset();
				return false;
			}
			break;
		case 5:
			if (REDIS_OK != redisAppendCommand(context_, command_set.commands[index].cmd.c_str(), command_set.commands[index].args[0].c_str(),
				command_set.commands[index].args[1].c_str(), command_set.commands[index].args[2].c_str(), command_set.commands[index].args[3].c_str(),
				command_set.commands[index].args[4].c_str())) {
				Reset();
				return false;
			}
			break;
		case 6:
			if (REDIS_OK != redisAppendCommand(context_, command_set.commands[index].cmd.c_str(), command_set.commands[index].args[0].c_str(),
				command_set.commands[index].args[1].c_str(), command_set.commands[index].args[2].c_str(), command_set.commands[index].args[3].c_str(),
				command_set.commands[index].args[4].c_str(), command_set.commands[index].args[5].c_str())) {
				Reset();
				return false;
			}
			break;
		case 7:
			if (REDIS_OK != redisAppendCommand(context_, command_set.commands[index].cmd.c_str(), command_set.commands[index].args[0].c_str(),
				command_set.commands[index].args[1].c_str(), command_set.commands[index].args[2].c_str(), command_set.commands[index].args[3].c_str(),
				command_set.commands[index].args[4].c_str(), command_set.commands[index].args[5].c_str(), command_set.commands[index].args[6].c_str())) {
				Reset();
				return false;
			}
			break;
		case 8:
			if (REDIS_OK != redisAppendCommand(context_, command_set.commands[index].cmd.c_str(), command_set.commands[index].args[0].c_str(),
				command_set.commands[index].args[1].c_str(), command_set.commands[index].args[2].c_str(), command_set.commands[index].args[3].c_str(),
				command_set.commands[index].args[4].c_str(), command_set.commands[index].args[5].c_str(), command_set.commands[index].args[6].c_str(),
				command_set.commands[index].args[7].c_str())) {
				Reset();
				return false;
			}
			break;
		case 9:
			if (REDIS_OK != redisAppendCommand(context_, command_set.commands[index].cmd.c_str(), command_set.commands[index].args[0].c_str(),
				command_set.commands[index].args[1].c_str(), command_set.commands[index].args[2].c_str(), command_set.commands[index].args[3].c_str(),
				command_set.commands[index].args[4].c_str(), command_set.commands[index].args[5].c_str(), command_set.commands[index].args[6].c_str(),
				command_set.commands[index].args[7].c_str(), command_set.commands[index].args[8].c_str())) {
				Reset();
				return false;
			}
			break;
		}

	}
    return record_queue_.size() < Config::record_queue_limit;
}

bool Redis::Read(ReplySet &reply_set) {
    if (record_queue_.size() <= 0) {
        return false;
    }
    Record record = record_queue_.front();
    record_queue_.pop();
    reply_set.id = record.id;

    for (size_t index = 0; index < record.size; ++index) {
        Reply reply;
        if (REDIS_OK != redisGetReply(context_, (void **)&reply_)) {
            if (context_ == nullptr || context_->err != 0) {
                Reset();
            }
            LOG(SYS, ERROR) << boost::format("[Redis %x][%s] execute command in pipeline fail.\n") %
                                   this % __FUNCTION__;
            return false;
        } else {
            if (reply_ != NULL) {
                if ((reply_->type == REDIS_REPLY_STRING
					|| reply_->type == REDIS_REPLY_STATUS
					|| reply_->type == REDIS_REPLY_ERROR
					)&& reply_->len > 0) {
                    reply = reply_->str;

                    reply_set.replies.push_back(std::move(reply));
                } else if (reply_->type == REDIS_REPLY_ARRAY && reply_->elements > 0) {
                    for (size_t reply_index = 0; reply_index < reply_->elements; ++reply_index) {
                        if (reply_->element[reply_index]->type == REDIS_REPLY_STRING &&
                            reply_->element[reply_index]->len > 0) {
                            reply = reply_->element[reply_index]->str;

                            reply_set.replies.push_back(std::move(reply));
                        } else if (reply_->element[reply_index]->type == REDIS_REPLY_INTEGER) {
                            reply = reply_->element[reply_index]->integer;
                            reply_set.replies.push_back(std::move(reply));
                        } else {
                            reply = "";
                            reply_set.replies.push_back(std::move(reply));
                        }
                    }
                } else if (reply_->type == REDIS_REPLY_INTEGER) {
                    reply = boost::lexical_cast<std::string>(reply_->integer);
                    reply_set.replies.push_back(std::move(reply));
                } else {
                    reply = "";
                    reply_set.replies.push_back(std::move(reply));
                }
            }
        }
        freeReplyObject(reply_);
    }
    return true;
}

RedisLoop::RedisLoop() {

}
RedisLoop::~RedisLoop() {}

bool RedisLoop::Init(const Config &conf) {
	if (!loop::Init(true, nullptr))
	{
		return false;
	}

	uv_async_init(loop_, &command_async_, command_async_cb_);
	command_async_.data = this;

    conf_ = conf;

    Redis::Config redis_conf;
    redis_conf.host = conf_.host;
    redis_conf.port = conf_.port;
    redis_conf.password = conf_.password;

    if (!redis_.Init(redis_conf)) {
        return false;
    }

    return true;
}

RedisLoop::Config &RedisLoop::Conf() {
    return conf_;
}

bool RedisLoop::Start() {
    if (!redis_.Start()) {
        return false;
    }

    return loop::Start();
}

bool RedisLoop::Stop() {
    if (!redis_.Stop()) {
        return false;
    }

    return loop::Stop();
}

bool RedisLoop::Running() {
    if (!redis_.Running()) {
        return false;
    }

    return loop::Running();
}

bool RedisLoop::Write(const Redis::CommandSet &command_set) {
    if (!command_set_queue_.push(command_set)) {
        LOG(SYS, ERROR) << boost::format("[RedisLoop %x][%s] command queue is full.\n") % this %
                               __FUNCTION__;
        return false;
    }

    return (uv_async_send(&command_async_) == 0);
}

bool RedisLoop::Read(Redis::ReplySet &reply_set) {
    if (!reply_set_queue_.pop(reply_set)) {
        return false;
    }
    return true;
}

void RedisLoop::GetReplyInPipeline() {

}

void RedisLoop::command_async_callback(uv_async_t *handle) {
    while (true) {
        Redis::CommandSet command_set;
        if (!command_set_queue_.pop(command_set)) {
            GetReplyInPipeline();
            break;
        }
        if (!redis_.Write(command_set)) {
            GetReplyInPipeline();
        }
    }
}

void RedisLoop::static_command_async_callback(uv_async_t *handle) {
    ((RedisLoop *)handle->data)->command_async_callback(handle);
}

IntegratedRedisLoop::IntegratedRedisLoop() {}
IntegratedRedisLoop::~IntegratedRedisLoop() {}

bool IntegratedRedisLoop::Integrate(std::function<std::string()> reply_func) {
    reply_func_ = reply_func;

	extern uv_loop_t* global_lua_loop;
    uv_async_init(global_lua_loop, &reply_async_, reply_async_cb_);
    reply_async_.data = this;

    uv_timer_init(global_lua_loop, &timer_);
    uv_timer_start(&timer_, timer_cb_, 0, 10);
    timer_.data = this;

	return true;
}

void IntegratedRedisLoop::reply_async_callback(uv_async_t *handle) {
    std::string reply = "";
    while ((reply = reply_func_()) != "") {
		extern lua_State * global_L;
		if (global_L)
		{
			lua_getglobal(global_L, "OnCacheReply");
			LuaIntf::Lua::push(global_L, reply);
			lua_pcall(global_L, 1, 0, 0);
		}
    }
}

void IntegratedRedisLoop::command_async_callback(uv_async_t *handle) {
    RedisLoop::command_async_callback(handle);
    uv_async_send(&reply_async_);
}

void IntegratedRedisLoop::static_reply_async_callback(uv_async_t *handle) {
    ((IntegratedRedisLoop *)handle->data)->reply_async_callback(nullptr);
}

void IntegratedRedisLoop::static_timer_callback(uv_timer_t *handle) {
    ((IntegratedRedisLoop *)handle->data)->reply_async_callback(nullptr);
}