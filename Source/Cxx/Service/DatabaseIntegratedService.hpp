
#ifndef DATABASE_INTEGRATED_SERVICE_HPP
#define DATABASE_INTEGRATED_SERVICE_HPP

#include <boost/asio/basic_streambuf.hpp>
#include <vector>
#include "../Base/BaseHeaders.h"
#include "./LoggerService.hpp"

class DatabaseIntegratedLine : public IntegratedMysqlLoop
{
public:
    struct Config
    {
        MysqlLoop::Config mysql;
    };
    DatabaseIntegratedLine() {}
    virtual ~DatabaseIntegratedLine() {}
    bool Init(const Config &conf)
    {
        conf_ = conf;

        bool ret = mysql_loop_.Init(conf_.mysql);
        if (!ret)
        {
            LOG(SYS, ERROR) << boost::format("[Database %x][%s] mysql init fail.\n") % this %
                                   __FUNCTION__;
            return false;
        }

        return true;
    }
    virtual bool Start()
    {
        bool ret = mysql_loop_.Start();
        if (!ret)
        {
            LOG(SYS, ERROR) << boost::format("[Database %x][%s] mysql start fail.\n") % this %
                                   __FUNCTION__;
            return false;
        }

        mysql_loop_.Integrate(std::bind(&DatabaseIntegratedLine::Reply, this));

        return true;
    }
    virtual bool Stop()
    {
        bool ret = mysql_loop_.Stop();
        if (!ret)
        {
            LOG(SYS, ERROR) << boost::format("[Database %x][%s] mysql stop fail.\n") % this %
                                   __FUNCTION__;
            return false;
        }

        return true;
    }

    virtual bool Running() { return mysql_loop_.Running(); }

    bool Command(const std::string &command_set_json)
    {
        Mysql::CommandSet command_set;
        if (!DecodeMysqlCommandSet(command_set_json, command_set))
        {
            LOG(SYS, ERROR) << boost::format("[Database %x][%s] mysql decode fail.\n") % this %
                                   __FUNCTION__;
            return false;
        }
        if (!mysql_loop_.Write(command_set))
        {
            LOG(SYS, ERROR) << boost::format("[Database %x][%s] mysql command write fail.\n") %
                                   this % __FUNCTION__;
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
            LOG(SYS, ERROR) << boost::format("[Database %x][%s] mysql decode fail.\n") % this %
                                   __FUNCTION__;
            return "";
        }
        return reply_set_json;
    }

protected:
    bool DecodeMysqlCommandSet(const std::string &command_set_json,
                               Mysql::CommandSet &command_set)
    {
        rapidjson::Document document;
        document.SetObject();

        if (document.Parse<0>(command_set_json.c_str()).HasParseError())
        {
            LOG(SYS, ERROR) << boost::format("[Database %x][%s] command set json parse fail.\n") %
                                   this % __FUNCTION__;
            return false;
        }

        if (!document.IsObject())
        {
            LOG(SYS, ERROR) << boost::format("[Database %x][%s] command set json type error.\n") %
                                   this % __FUNCTION__;
            return false;
        }

        if (document.HasMember("id") && document["id"].IsString())
        {
            command_set.id = document["id"].GetString();
        }
        else
        {
            LOG(SYS, ERROR) << boost::format(
                                   "[Database %x][%s] command set json leak field id.\n") %
                                   this % __FUNCTION__;
            return false;
        }

        if (document.HasMember("commands") && document["commands"].IsArray())
        {
            for (size_t index = 0; index < document["commands"].Size(); ++index)
            {
                if (document["commands"][index].IsString())
                {
                    Mysql::Command command;
                    command.sql = document["commands"][index].GetString();
                    command_set.commands.push_back(std::move(command));
                }
                else if (document["commands"][index].IsObject())
                {
                    Mysql::Command command;

                    if (document["commands"][index].HasMember("sql") &&
                        document["commands"][index]["sql"].IsString())
                    {
                        command.sql = document["commands"][index]["sql"].GetString();
                    }
                    else
                    {
                        LOG(SYS, ERROR)
                            << boost::format("[Database %x][%s] command json leak field sql.\n") %
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
                        << boost::format("[Database %x][%s] command json type error.\n") % this %
                               __FUNCTION__;
                    return false;
                }
            }
        }
        else
        {
            LOG(SYS, ERROR) << boost::format(
                                   "[Database %x][%s] command set json leak field commands.\n") %
                                   this % __FUNCTION__;
            return false;
        }
        return true;
    }

    bool EncodeMysqlReplySet(const Mysql::ReplySet &reply_set, std::string &reply_set_json)
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

                for (size_t index3 = 0; index3 < reply_set.replies[index].data_set[index2].size();
                     ++index3)
                {
                    rapidjson::Value field;
                    field.SetString(rapidjson::StringRef(
                        reply_set.replies[index].data_set[index2][index3].c_str()));
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
    IntegratedMysqlLoop mysql_loop_;
};

class DatabaseIntegratedService
    : public Service
{
public:
    struct Config
    {
        std::vector<DatabaseIntegratedLine::Config> lines;

        bool ReadConfig(const std::string &json)
        {
            CONFIG_CREATE_DOCUMENT(json, root)
            CONFIG_MOVE_ARRAY(root, "lines", lines_array)
            CONFIG_FOREACH_OBJECT(lines_array, line_object)
            DatabaseIntegratedLine::Config line;
            CONFIG_MOVE_OBJECT(line_object, "mysql", mysql_object)
            CONFIG_READ_MEMBER(mysql_object, "host", line.mysql.host)
            CONFIG_READ_MEMBER(mysql_object, "port", line.mysql.port)
            CONFIG_READ_MEMBER(mysql_object, "username", line.mysql.username)
            CONFIG_READ_MEMBER(mysql_object, "password", line.mysql.password)
            lines.push_back(std::move(line));
            CONFIG_FOREACH_END

            return true;
        }
    };
    DatabaseIntegratedService() {}
    virtual ~DatabaseIntegratedService()
    {
        for (size_t index = 0; index < database_lines_.size(); ++index)
        {
            object_pool<DatabaseIntegratedLine>::delete(database_lines_[index]);
        }
    }
    bool Init(const std::string &json)
    {
        bool ret = conf_.ReadConfig(json);
        if (!ret)
        {
            LOG(SYS, ERROR) << boost::format(
                                   "[DatabaseIntegratedService %x][%s] config json parse fail.\n") %
                                   this % __FUNCTION__;
            return false;
        }

        for (size_t index = 0; index < database_lines_.size(); ++index)
        {
            object_pool<DatabaseIntegratedLine>::delete(database_lines_[index]);
        }
        database_lines_.clear();
        for (size_t index = 0; index < conf_.lines.size(); ++index)
        {
            database_lines_.push_back(object_pool<DatabaseIntegratedLine>::new());
            ret = database_lines_[index]->Init(conf_.lines[index]);
            if (!ret)
            {
                LOG(SYS, ERROR) << boost::format(
                                       "[DatabaseIntegratedService %x][%s] line init fail.\n") %
                                       this % __FUNCTION__;
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
                LOG(SYS, ERROR) << boost::format(
                                       "[DatabaseIntegratedService %x][%s] line start fail.\n") %
                                       this % __FUNCTION__;
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
                LOG(SYS, ERROR) << boost::format(
                                       "[DatabaseIntegratedService %x][%s] line stop fail.\n") %
                                       this % __FUNCTION__;
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

    bool MysqlCommand(uint32_t id, const std::string &command_set_json)
    {
        return database_lines_[id % database_lines_.size()]->Command(command_set_json);
    }

    std::string MysqlReply(unsigned int id)
    {
        return database_lines_[id % database_lines_.size()]->Reply();
    }

protected:
    Config conf_;
    std::vector<DatabaseIntegratedLine *> database_lines_;
};

#endif // !DATABASE_INTEGRATED_SERVICE_HPP