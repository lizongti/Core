#ifndef CACHE_INTEGRATED_SERVICE_HPP
#define CACHE_INTEGRATED_SERVICE_HPP

#include <boost/asio/basic_streambuf.hpp>
#include <vector>
#include "../Base/BaseHeaders.h"
#include "./LoggerService.hpp"

class CacheIntegratedLine : public IntegratedRedisLoop
{
public:
    struct Config
    {
        IntegratedRedisLoop::Config redis;
    };
    CacheIntegratedLine() {}
    virtual ~CacheIntegratedLine() {}
    bool Init(const Config &conf)
    {
        conf_ = conf;

        bool ret = redis_loop_.Init(conf_.redis);
        if (!ret)
        {
            LOG(SYS, ERROR) << boost::format("[Cache %x][%s] redis loop init fail.\n") % this %
                                   __FUNCTION__;
            return false;
        }

        return true;
    }
    virtual bool Start()
    {
        bool ret = redis_loop_.Start();
        if (!ret)
        {
            LOG(SYS, ERROR) << boost::format("[Cache %x][%s] redis loop start fail.\n") % this %
                                   __FUNCTION__;
            return false;
        }

        redis_loop_.Integrate(std::bind(&CacheIntegratedLine::Reply, this));

        return true;
    }
    virtual bool Stop()
    {
        bool ret = redis_loop_.Stop();
        if (!ret)
        {
            LOG(SYS, ERROR) << boost::format("[Cache %x][%s] redis loop stop fail.\n") % this %
                                   __FUNCTION__;
            return false;
        }

        return true;
    }

    virtual bool Running() { return redis_loop_.Running(); }

    bool Command(const std::string &command_set_json)
    {
        Redis::CommandSet command_set;
        if (!DecodeRedisCommandSet(command_set_json, command_set))
        {
            LOG(SYS, ERROR) << boost::format("[Cache %x][%s] redis decode fail.\n") % this %
                                   __FUNCTION__;
            return false;
        }
        if (!redis_loop_.Write(command_set))
        {
            LOG(SYS, ERROR) << boost::format("[Cache %x][%s] redis command write fail.\n") % this %
                                   __FUNCTION__;
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
            LOG(SYS, ERROR) << boost::format("[Cache %x][%s] redis decode fail.\n") % this %
                                   __FUNCTION__;
            return "";
        }
        return reply_set_json;
    }

protected:
    bool DecodeRedisCommandSet(const std::string &command_set_json,
                               Redis::CommandSet &command_set)
    {
        rapidjson::Document document;
        document.SetObject();

        if (document.Parse<0>(command_set_json.c_str()).HasParseError())
        {
            LOG(SYS, ERROR) << boost::format("[Cache %x][%s] command set json parse fail.\n") %
                                   this % __FUNCTION__;
            return false;
        }

        if (!document.IsObject())
        {
            LOG(SYS, ERROR) << boost::format("[Cache %x][%s] command set json type error.\n") %
                                   this % __FUNCTION__;
            return false;
        }

        if (document.HasMember("id") && document["id"].IsString())
        {
            command_set.id = document["id"].GetString();
        }
        else
        {
            LOG(SYS, ERROR) << boost::format("[Cache %x][%s] command set json leak field id.\n") %
                                   this % __FUNCTION__;
            return false;
        }

        if (document.HasMember("commands") && document["commands"].IsArray())
        {
            for (size_t index = 0; index < document["commands"].Size(); ++index)
            {
                if (document["commands"][index].IsString())
                {
                    Redis::Command command;
                    command.cmd = document["commands"][index].GetString();
                    command_set.commands.push_back(std::move(command));
                }
                else if (document["commands"][index].IsObject())
                {
                    Redis::Command command;

                    if (document["commands"][index].HasMember("cmd") &&
                        document["commands"][index]["cmd"].IsString())
                    {
                        command.cmd = document["commands"][index]["cmd"].GetString();
                    }
                    else
                    {
                        LOG(SYS, ERROR)
                            << boost::format("[Cache %x][%s] command json leak field cmd.\n") %
                                   this % __FUNCTION__;
                        return false;
                    }

                    if (document["commands"][index].HasMember("args") &&
                        document["commands"][index]["args"].IsArray())
                    {
                        for (size_t index2 = 0; index2 < document["commands"][index]["args"].Size(); ++index2)
                        {
                            if (document["commands"][index]["args"][index2].IsNumber())
                            {
                                command.args.push_back(std::move(boost::lexical_cast<std::string>(
                                    document["commands"][index]["args"][index2].GetInt64())));
                            }
                            else if (document["commands"][index]["args"][index2].IsString())
                            {
                                command.args.push_back(
                                    std::move(document["commands"][index]["args"][index2].GetString()));
                            }
                        }
                    }
                    command_set.commands.push_back(std::move(command));
                }
                else
                {
                    LOG(SYS, ERROR)
                        << boost::format("[Cache %x][%s] command json type error.\n") % this %
                               __FUNCTION__;
                    return false;
                }
            }
        }
        else
        {
            LOG(SYS, ERROR) << boost::format(
                                   "[Cache %x][%s] command set json leak field commands.\n") %
                                   this % __FUNCTION__;
            return false;
        }
        return true;
    }

    bool EncodeRedisReplySet(const Redis::ReplySet &reply_set, std::string &reply_set_json)
    {
        rapidjson::Document document;
        rapidjson::Document::AllocatorType &allocator = document.GetAllocator();

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
    IntegratedRedisLoop redis_loop_;
};

class CacheIntegratedService
    : public Service
{
public:
    struct Config
    {
        std::vector<CacheIntegratedLine::Config> lines;

        bool ReadConfig(const std::string &json)
        {
            CONFIG_CREATE_DOCUMENT(json, root)
            CONFIG_MOVE_ARRAY(root, "lines", lines_array)
            CONFIG_FOREACH_OBJECT(lines_array, line_object)
            CacheIntegratedLine::Config line;
            CONFIG_MOVE_OBJECT(line_object, "redis", redis_object)
            CONFIG_READ_MEMBER(redis_object, "host", line.redis.host)
            CONFIG_READ_MEMBER(redis_object, "port", line.redis.port)
            CONFIG_READ_MEMBER(redis_object, "password", line.redis.password)
            lines.push_back(std::move(line));
            CONFIG_FOREACH_END
            return true;
        }
    };
    CacheIntegratedService() {}
    virtual ~CacheIntegratedService()
    {
        for (size_t index = 0; index < cache_lines_.size(); ++index)
        {
            object_pool<CacheIntegratedLine>::delete(cache_lines_[index]);
        }
    }
    bool Init(const std::string &json)
    {
        bool ret = conf_.ReadConfig(json);
        if (!ret)
        {
            LOG(SYS, ERROR) << boost::format(
                                   "[CacheIntegratedService %x][%s] config json parse fail.\n") %
                                   this % __FUNCTION__;
            return false;
        }

        for (size_t index = 0; index < cache_lines_.size(); ++index)
        {
            object_pool<CacheIntegratedLine>::delete(cache_lines_[index]);
        }
        cache_lines_.clear();
        for (size_t index = 0; index < conf_.lines.size(); ++index)
        {
            cache_lines_.push_back(object_pool<CacheIntegratedLine>::new());
            ret = cache_lines_[index]->Init(conf_.lines[index]);
            if (!ret)
            {
                LOG(SYS, ERROR) << boost::format(
                                       "[CacheIntegratedService %x][%s] line init fail.\n") %
                                       this % __FUNCTION__;
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
                LOG(SYS, ERROR) << boost::format(
                                       "[CacheIntegratedService %x][%s] line start fail.\n") %
                                       this % __FUNCTION__;
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
                LOG(SYS, ERROR) << boost::format(
                                       "[CacheIntegratedService %x][%s] line stop fail.\n") %
                                       this % __FUNCTION__;
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

    virtual void OpenLib(lua_State *l) {}

    bool RedisCommand(uint32_t id, const std::string &command_set_json)
    {
        return cache_lines_[id % cache_lines_.size()]->Command(command_set_json);
    }

    std::string RedisReply(uint32_t id) { return cache_lines_[id % cache_lines_.size()]->Reply(); }

protected:
    Config conf_;
    std::vector<CacheIntegratedLine *> cache_lines_;
};

#endif // !CACHE_INTEGRATED_SERVICE_HPP
