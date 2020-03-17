#include "Mysql.h"
#include "Pool.h"

bool Mysql::Init(Config& conf)
{
	conf_ = conf;

	connection_ = object_pool<mysqlpp::Connection>::new(false);

	if (!connection_->connect("mysql", conf_.host.c_str(), conf_.username.c_str(), conf_.password.c_str(), conf_.port))
	{
		LOG(SYS, ERROR) << boost::format("[Mysql %x][%s] connecting to mysql fail.\n") % this % __FUNCTION__;
		return false;
	}


	LOG(SYS, INFO) << boost::format("[Mysql %x][%s] connecting to mysql %s:%hd %s %s successfully.\n") % this % __FUNCTION__ %
		conf_.host.c_str() % conf_.port % conf_.username.c_str() % conf_.password.c_str();

	return true;
}

Mysql::Config & Mysql::Conf()
{
	return conf_;
}

bool Mysql::Start()
{
	running_.store(true);
	return true;
}

bool Mysql::Stop()
{
	object_pool<mysqlpp::Connection>::delete(connection_);
	running_.store(false);
	return true;
}

bool Mysql::Reset()
{
	bool ret = Stop();
	if (!ret)
	{
		return ret;
	}

	ret = Init(conf_);
	if (!ret)
	{
		return ret;
	}

	ret = Start();
	if (!ret)
	{
		return ret;
	}

	return true;
}

bool Mysql::Running()
{
	return running_.load();
}

bool Mysql::Execute(const CommandSet& command_set, ReplySet& reply_set)
{
	reply_set.id = command_set.id;

	for (const Command& command : command_set.commands)
	{
		Reply reply;
		if (!Query(command, reply))
		{
			LOG(SYS, INFO) << boost::format("[mysql %x][%s] get error .\n") % this % __FUNCTION__;
			return false;
		}

		reply_set.replies.push_back(std::move(reply));
	}
	return true;
}

bool Mysql::Query(const Command& command, Reply& reply)
{
	reply.row_num = 0;
	std::vector<std::string> sql_part_set;
	boost::split(sql_part_set, command.sql, boost::is_any_of("?"), boost::token_compress_on);

	mysqlpp::Query query = connection_->query();
	bool is_heart_beat = false;
	for (size_t index = 0; index < sql_part_set.size(); ++index)
	{
		if (sql_part_set[index] == "SELECT 1")
		{
			is_heart_beat = true;
		}
		query << sql_part_set[index];
		if (index < command.args.size())
		{
			query << command.args[index];
		}
	}
	try
	{
		mysqlpp::StoreQueryResult result = query.store();

		if (result)
		{
			for (mysqlpp::StoreQueryResult::const_iterator it = result.begin(); it != result.end(); ++it)
			{
				std::vector<std::string> row_vec;
				for (size_t index = 0; index < result.field_names()->size(); ++index)
				{
					mysqlpp::Row row = *it;
					row_vec.push_back(std::move(std::string(row[index])));
				}
				reply.data_set.push_back(std::move(row_vec));
			}
			reply.row_num += reply.data_set.size();
		}
		else if (is_heart_beat) // 如果心跳失败，立即重连
		{
			Reset();
			return true;
		}

		//mysql通用Query可能包含存储过程调用，存储过程可能有更多的返回
		/*
		Return whether more results are waiting for a multi-query or stored procedure response.
		If this function returns true, you must call store_next() to fetch the next result set before you can execute more queries.
		First, when handling the result of executing multiple queries at once. (See this page in the MySQL documentation for details.)
		Second, when calling a stored procedure, MySQL can return the result as a set of results.*/
		/*不管怎样，必须consume所有的results
		In either case, you must consume all results before making another MySQL query, even if you don't care about the remaining
		results or result sets.
		*/
		for (; query.more_results();) {
			result = query.store_next();

			if (result)
			{
				for (mysqlpp::StoreQueryResult::const_iterator it = result.begin(); it != result.end(); ++it)
				{
					std::vector<std::string> row_vec;
					for (size_t index = 0; index < result.field_names()->size(); ++index)
					{
						mysqlpp::Row row = *it;
						row_vec.push_back(std::move(std::string(row[index])));
					}
					reply.data_set.push_back(std::move(row_vec));
				}
				reply.row_num += reply.data_set.size();
			}
		}

		return true;
	}
	catch (const mysqlpp::Exception& err)
	{
		reply.row_num = -1;
		LOG(SYS, ERROR) << boost::format("[Mysql %x][%s] %s query failed! %s\n") % this % __FUNCTION__ % command.sql % err.what();
		Reset();
		return true;
	}
}

MysqlLoop::MysqlLoop()
{

}

MysqlLoop::~MysqlLoop()
{
}

bool MysqlLoop::Init(const Config& conf)
{

	if (!loop::Init(true, nullptr))
	{
		return false;
	}

	uv_async_init(loop_, &command_async_, command_async_cb_);
	command_async_.data = this;

	conf_ = conf;

	Mysql::Config mysql_conf;
	mysql_conf.host = conf_.host;
	mysql_conf.port = conf_.port;
	mysql_conf.username = conf_.username;
	mysql_conf.password = conf_.password;

	if (!mysql_.Init(mysql_conf))
	{
		return false;
	}

	return true;
}

MysqlLoop::Config & MysqlLoop::Conf()
{
	return conf_;
}

bool MysqlLoop::Start()
{
	if (!mysql_.Start())
	{
		return false;
	}

	return loop::Start();
}

bool MysqlLoop::Stop()
{
	if (!mysql_.Stop())
	{
		return false;
	}
	return loop::Stop();
}

bool MysqlLoop::Running()
{
	if (!mysql_.Running())
	{
		return false;
	}

	return loop::Running();
}

bool MysqlLoop::Write(const Mysql::CommandSet& command_set)
{
	if (!command_set_queue_.push(command_set))
	{
		LOG(SYS, ERROR) << boost::format("[MysqlLoop %x][%s] command queue is full.\n") % this % __FUNCTION__;
		return false;
	}

	return (uv_async_send(&command_async_) == 0);
}

bool MysqlLoop::Read(Mysql::ReplySet& reply_set)
{
	if (!reply_set_queue_.pop(reply_set))
	{
		return false;
	}
	return true;
}

void MysqlLoop::command_async_callback(uv_async_t* handle)
{
	while (true)
	{
		Mysql::CommandSet command_set;
		if (!command_set_queue_.pop(command_set))
		{
			return;
		}
		Mysql::ReplySet reply_set;

		if (!mysql_.Execute(command_set, reply_set))
		{
			LOG(SYS, ERROR) << boost::format("[MysqlLoop %x][%s] mysql execute fail.\n") % this % __FUNCTION__;
		}

		if (!reply_set_queue_.push(reply_set))
		{
			LOG(SYS, ERROR) << boost::format("[MysqlLoop %x][%s] reply queue is full.\n") % this % __FUNCTION__;
		}
	}
}

void MysqlLoop::static_command_async_callback(uv_async_t* handle)
{
	((MysqlLoop*)handle->data)->command_async_callback(handle);
}

IntegratedMysqlLoop::IntegratedMysqlLoop() {}
IntegratedMysqlLoop::~IntegratedMysqlLoop() {}

bool IntegratedMysqlLoop::Integrate(std::function<std::string()> reply_func) {
    reply_func_ = reply_func;

	extern uv_loop_t* global_lua_loop;
    uv_async_init(global_lua_loop, &reply_async_, reply_async_cb_);
    reply_async_.data = this;

    uv_timer_init(global_lua_loop, &timer_);
    uv_timer_start(&timer_, timer_cb_, 0, 10);
    timer_.data = this;

	return true;
}

void IntegratedMysqlLoop::reply_async_callback(uv_async_t *handle) {
    std::string reply = "";
    while ((reply = reply_func_()) != "") {
		extern lua_State * global_L;
		if (global_L) {
			lua_getglobal(global_L, "OnDatabaseReply");
			LuaIntf::Lua::push(global_L, reply);
			lua_pcall(global_L, 1, 0, 0);
		}
    }
}

void IntegratedMysqlLoop::command_async_callback(uv_async_t *handle) {
    MysqlLoop::command_async_callback(handle);
    uv_async_send(&reply_async_);
}

void IntegratedMysqlLoop::static_reply_async_callback(uv_async_t *handle) {
    ((IntegratedMysqlLoop *)handle->data)->reply_async_callback(nullptr);
}

void IntegratedMysqlLoop::static_timer_callback(uv_timer_t *handle) {
    ((IntegratedMysqlLoop *)handle->data)->reply_async_callback(nullptr);
}