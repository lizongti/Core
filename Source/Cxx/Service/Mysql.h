#ifndef MYSQL_HPP
#define MYSQL_HPP

#include <mysql++/mysql++.h>
#include <boost/algorithm/string/classification.hpp>
#include <boost/algorithm/string/split.hpp>
#include <boost/format.hpp>
#include <iostream>
#include <vector>
#include "Logger.h"
#include "loop.h"
#include "LuaState.h"

class Mysql
{
public:
  struct Command
  {
    std::string sql;
    std::vector<std::string> args;
  };
  struct CommandSet
  {
    std::string id;
    std::vector<Command> commands;
  };
  struct Reply
  {
    uint32_t row_num;
    std::vector<std::vector<std::string>> data_set;
  };
  struct ReplySet
  {
    std::string id;
    std::vector<Reply> replies;
  };

  struct Config
  {
    Config(){};
    std::string host;
    uint16_t port;
    std::string username;
    std::string password;
  };

  virtual bool Init(Config &conf);

  virtual Config &Conf();

  virtual bool Start();

  virtual bool Stop();

  virtual bool Reset();

  virtual bool Running();

  virtual bool Execute(const CommandSet &command_set, ReplySet &reply_set);

protected:
  bool Query(const Command &command, Reply &reply);

protected:
  Config conf_;
  std::atomic_bool running_;
  mysqlpp::Connection *connection_;
};

class MysqlLoop : public loop
{
public:
  struct Config
  {
    std::string host;
    uint16_t port;
    std::string username;
    std::string password;
    const static uint32_t command_queue_size = 10240;
    const static uint32_t reply_queue_size = 10240;
  };

  MysqlLoop();

  virtual ~MysqlLoop();

  virtual bool Init(const Config &conf);

  virtual Config &Conf();

  virtual bool Start();

  virtual bool Stop();

  virtual bool Running();

  bool Write(const Mysql::CommandSet &command_set);

  bool Read(Mysql::ReplySet &reply_set);

protected:
  virtual void command_async_callback(uv_async_t *handle);

protected:
  static void static_command_async_callback(uv_async_t *handle);

protected:
  Config conf_;
  Mysql mysql_;

  uv_async_t command_async_;
  uv_async_cb command_async_cb_ = (uv_async_cb)&static_command_async_callback;

  boost::lockfree::spsc_queue<Mysql::CommandSet,
                              boost::lockfree::capacity<Config::command_queue_size>>
      command_set_queue_;
  boost::lockfree::spsc_queue<Mysql::ReplySet,
                              boost::lockfree::capacity<Config::reply_queue_size>>
      reply_set_queue_;
};

class IntegratedMysqlLoop : public MysqlLoop
{
public:
  IntegratedMysqlLoop();
  virtual ~IntegratedMysqlLoop();

  bool Integrate(std::function<std::string()> reply_func);

protected:
  virtual void reply_async_callback(uv_async_t *handle);

  virtual void command_async_callback(uv_async_t *handle);

protected:
  static void static_reply_async_callback(uv_async_t *handle);

  static void static_timer_callback(uv_timer_t *handle);

protected:
  uv_async_t reply_async_;
  uv_async_cb reply_async_cb_ = (uv_async_cb)&static_reply_async_callback;

  uv_timer_t timer_;
  uv_timer_cb timer_cb_ = (uv_timer_cb)&static_timer_callback;

  std::function<std::string()> reply_func_;
};
#endif // !MYSQL_HPP
