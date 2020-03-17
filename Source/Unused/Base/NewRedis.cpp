#include "NewRedis.h"

NewRedis::NewRedis()
{
	running_.store(false);
}

bool NewRedis::Init(const Config& conf)
{
	conf_ = conf;

	context_ = redisConnect(conf_.host.c_str(), conf_.port);
	if (context_ != NULL && context_->err)
	{
		LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] connecting to redis fail, error:%s.\n") % this % __FUNCTION__ % context_->errstr;
	}
	else
	{
		//LOG(SYS, INFO) << boost::format("[NewRedis %x][%s] connecting to redis success.\n") % this % __FUNCTION__;
	}

	if (conf_.password != "")
	{
		std::string cmd = (boost::format("AUTH %s") % conf_.password).str();
		reply_ = (redisReply*)redisCommand(context_, cmd.c_str());
		freeReplyObject(reply_);
	}
	return true;
}

NewRedis::Config & NewRedis::Conf()
{
	return conf_;
}

bool NewRedis::Start()
{
	running_.store(true);
	return true;
}

bool NewRedis::Stop()
{
	redisFree(context_);
	running_.store(false);
	return true;
}

bool NewRedis::Reset()
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

bool NewRedis::Running()
{
	return running_.load();
}

bool NewRedis::SaveDbKey(const BaseDatabase::Command& command, BaseDatabase::Reply& reply)
{
	string key_str = "";
	vector<string> cache_key_list;
	vector<string> hash_key_list;
	for (int index = 0; index < reply.data_set.size(); ++index)
	{
		for (size_t sub_index = 0; sub_index < reply.data_set[index].size(); ++sub_index)
		{
			if (reply.data_set[index][sub_index].column_name == command.keylist[0])
			{
				cache_key_list.push_back(reply.data_set[index][sub_index].value);
			}

			if (reply.data_set[index][sub_index].column_name == command.keylist[1])
			{
				key_str += string(reply.data_set[index][sub_index].value);
				key_str += "|";
			}
		}
	}

	{
		string sql = "HMSET ";

		sql += " ";
		sql += command.name;
		sql += "[";
		sql += cache_key_list[0];
		sql += "] ";

		sql += "db_key_list ";

		sql += key_str;

		//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();

		if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
		{
			Reset();
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
			return false;
		}
	}

	if (REDIS_OK != redisGetReply(context_, (void**)&reply_))
	{
		if (context_ == nullptr || context_->err != 0)
		{
			Reset();
		}
		LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute command in pipeline fail.\n") % this % __FUNCTION__;
		return false;
	}
	freeReplyObject(reply_);


	return true;
}

bool NewRedis::Ping()
{
	string sql = "PING";

	if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
	{
		Reset();
		LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
		return false;
	}
	if (REDIS_OK != redisGetReply(context_, (void**)&reply_))
	{
		if (context_ == nullptr || context_->err != 0)
		{
			Reset();
		}
		LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute command in pipeline fail.\n") % this % __FUNCTION__;
		return false;
	}
	freeReplyObject(reply_);
	return true;
}

bool NewRedis::UpdateHashValue(const std::string& table_name, const std::string& key, const std::string& value)
{
	string sql = "HMSET ";

	sql += " ";
	sql += table_name;

	sql += " ";

	sql += key;

	sql += " ";

	sql += value;

	if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
	{
		Reset();
		LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
		return false;
	}
	if (REDIS_OK != redisGetReply(context_, (void**)&reply_))
	{
		if (context_ == nullptr || context_->err != 0)
		{
			Reset();
		}
		LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute command in pipeline fail.\n") % this % __FUNCTION__;
		return false;
	}
	freeReplyObject(reply_);
	return true;
}

bool NewRedis::DelHashValue(const std::string& table_name, const std::string& key)
{
	string sql = "HDEL ";

	sql += " ";
	sql += table_name;

	sql += " ";

	sql += key;

	LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();

	if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
	{
		Reset();
		LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
		return false;
	}
	if (REDIS_OK != redisGetReply(context_, (void**)&reply_))
	{
		if (context_ == nullptr || context_->err != 0)
		{
			Reset();
		}
		LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute command in pipeline fail.\n") % this % __FUNCTION__;
		return false;
	}
	freeReplyObject(reply_);
	return true;
}

bool NewRedis::GetRecord(const std::string& table_name, const std::string& key, vector<std::string>& result_list)
{
	string sql = "hmget ";
	sql += table_name;
	sql += " ";
	sql += key;

	//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();
	if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
	{
		Reset();
		LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
		return false;
	}
	if (REDIS_OK != redisGetReply(context_, (void**)&reply_))
	{
		if (context_ == nullptr || context_->err != 0)
		{
			Reset();
		}
		LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute command in pipeline fail.\n") % this % __FUNCTION__;
		return false;
	}

	if (reply_ != NULL)
	{
		string content_value;
		if (reply_->type == REDIS_REPLY_STRING && reply_->len > 0)
		{

			content_value = reply_->str;

			result_list.push_back(content_value);
		}
		else if (reply_->type == REDIS_REPLY_ARRAY && reply_->elements > 0)
		{
			for (size_t reply_index = 0; reply_index < reply_->elements; ++reply_index)
			{
				if (reply_->element[reply_index]->type == REDIS_REPLY_STRING && reply_->element[reply_index]->len > 0)
				{
					content_value = reply_->element[reply_index]->str;
				}
				else if (reply_->element[reply_index]->type == REDIS_REPLY_INTEGER)
				{
					content_value = reply_->element[reply_index]->integer;
				}
				else
				{
					content_value = "";
				}
				result_list.push_back(content_value);
			}
		}
		else if (reply_->type == REDIS_REPLY_INTEGER)
		{
			content_value = boost::lexical_cast<std::string>(reply_->integer);
			result_list.push_back(content_value);
		}
		else
		{
			content_value = "";
			result_list.push_back(content_value);
		}


	}
	freeReplyObject(reply_);
	return true;
}

bool NewRedis::GetExpire(vector<std::string>& result_list)
{
	string sql = "hgetall expire";

	LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();
	if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
	{
		Reset();
		LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
		return false;
	}
	if (REDIS_OK != redisGetReply(context_, (void**)&reply_))
	{
		if (context_ == nullptr || context_->err != 0)
		{
			Reset();
		}
		LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute command in pipeline fail.\n") % this % __FUNCTION__;
		return false;
	}

	if (reply_ != NULL)
	{
		string content_value;
		if (reply_->type == REDIS_REPLY_STRING && reply_->len > 0)
		{

			content_value = reply_->str;

			result_list.push_back(content_value);
		}
		else if (reply_->type == REDIS_REPLY_ARRAY && reply_->elements > 0)
		{

			for (size_t reply_index = 0; reply_index < reply_->elements; ++reply_index)
			{
				if (reply_->element[reply_index]->type == REDIS_REPLY_STRING && reply_->element[reply_index]->len > 0)
				{
					content_value = reply_->element[reply_index]->str;
				}
				else if (reply_->element[reply_index]->type == REDIS_REPLY_INTEGER)
				{
					content_value = reply_->element[reply_index]->integer;
				}
				else
				{
					content_value = "";
				}
				result_list.push_back(content_value);
			}
		}
		else if (reply_->type == REDIS_REPLY_INTEGER)
		{
			content_value = boost::lexical_cast<std::string>(reply_->integer);
			result_list.push_back(content_value);
		}
		else
		{
			content_value = "";
			result_list.push_back(content_value);
		}


	}
	freeReplyObject(reply_);
	return true;
}

bool NewRedis::Update(const BaseDatabase::Command& command, BaseDatabase::Reply& reply)
{
	int command_num = 0;
	vector<string> cache_key_list;
	vector<string> hash_key_list;

	for (int index = 0; index < command.contents.size(); ++index)
	{
		if (command.contents[index].column_name == command.keylist[0])
		{
			cache_key_list.push_back(command.contents[index].value);
		}

		if (command.contents[index].column_name == command.keylist[1])
		{
			hash_key_list.push_back(command.contents[index].value);
		}
	}
	if (cache_key_list.size() != hash_key_list.size())
	{
		return false;
	}

	string key_str = "";
	{
		string sql = "HMGET ";

		sql += " ";
		sql += command.name;
		sql += "[";
		sql += cache_key_list[0];
		sql += "]";

		sql += " ";
		sql += "key_list";

		//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();

		if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
		{
			Reset();
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
			return false;
		}
		if (REDIS_OK != redisGetReply(context_, (void**)&reply_))
		{
			if (context_ == nullptr || context_->err != 0)
			{
				Reset();
			}
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute command in pipeline fail.\n") % this % __FUNCTION__;
			return false;
		}
		if (reply_ != NULL)
		{
			string content_value;
			if (reply_->type == REDIS_REPLY_STRING && reply_->len > 0)
			{
				content_value = reply_->str;
			}
			else if (reply_->type == REDIS_REPLY_ARRAY && reply_->elements > 0)
			{

				size_t reply_index = 0;

				if (reply_->element[reply_index]->type == REDIS_REPLY_STRING && reply_->element[reply_index]->len > 0)
				{
					content_value = reply_->element[reply_index]->str;
				}
				else if (reply_->element[reply_index]->type == REDIS_REPLY_INTEGER)
				{
					content_value = reply_->element[reply_index]->integer;
				}
				else
				{
					content_value = "";
				}
			}
			else if (reply_->type == REDIS_REPLY_INTEGER)
			{
				content_value = boost::lexical_cast<std::string>(reply_->integer);
			}
			else
			{
				content_value = "";
			}
			vector<std::string> value_list;
			CStrFun::split(value_list, content_value.c_str(), '|');
			bool is_exist = false;
			for (int index = 0; index < value_list.size(); ++index)
			{
				if (value_list[index] == hash_key_list[0])
				{
					is_exist = true;
				}
			}
			if (!is_exist)
			{
				value_list.push_back(hash_key_list[0]);
			}
			for (int index = 0; index < value_list.size(); ++index)
			{
				key_str += value_list[index];
				key_str += "|";
			}
		}
		freeReplyObject(reply_);
	}

	{
		string sql = "HMSET ";

		sql += "expire ";

		string record_name = "";
		record_name += command.name;
		record_name += "[";
		record_name += cache_key_list[0];
		record_name += "]";

		sql += record_name;
		sql += " ";

		long int current_time = static_cast<long int>(time(NULL));
		sql +=  std::to_string(current_time);

		++command_num;

		//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();

		if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
		{
			Reset();
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
			return false;
		}

		DbInfoManager::instance()->AddRecord(record_name, static_cast<long int>(time(NULL)));
	}

	for (int index = 0; index < command.contents.size(); ++index)
	{
		string sql = "HMSET ";

		sql += " ";
		sql += command.name;
		sql += "[";
		sql += cache_key_list[0];
		sql += "] ";

		sql += " ";
		sql += command.name;
		sql += "[";
		sql += hash_key_list[0];
		sql += "]";

		sql += ".";
		sql += command.contents[index].column_name;
		sql += " ";

		sql += command.contents[index].value;

		//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();
		++command_num;
		if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
		{
			Reset();
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
			return false;
		}
	}

	{
		string sql = "HMSET ";

		sql += " ";
		sql += command.name;
		sql += "[";
		sql += cache_key_list[0];
		sql += "] ";

		sql += "key_list ";

		sql += key_str;

		++command_num;
		//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();
		if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
		{
			Reset();
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
			return false;
		}
	}

	//BaseDatabase::Reply reply;
	for (int index = 0; index < command_num; ++index)
	{
		if (REDIS_OK != redisGetReply(context_, (void**)&reply_))
		{
			if (context_ == nullptr || context_->err != 0)
			{
				Reset();
			}
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute command in pipeline fail.\n") % this % __FUNCTION__;
			return false;
		}
		freeReplyObject(reply_);
	}

	return true;
}



bool NewRedis::SaveFromCommand(const BaseDatabase::Command& command, BaseDatabase::Reply& reply)
{
	//cout << static_cast<long int>(time(NULL)) << "save redis begin" << endl;

	int command_num = 0;
	string key_str = "";
	vector<string> cache_key_list;
	vector<string> hash_key_list;

	for (int index = 0; index < command.contents.size(); ++index)
	{
		if (command.contents[index].column_name == command.keylist[0])
		{
			cache_key_list.push_back(command.contents[index].value);
		}

		if (command.contents[index].column_name == command.keylist[1])
		{
			hash_key_list.push_back(command.contents[index].value);

			key_str += string(command.contents[index].value);
			key_str += "|";
		}
	}
	if (cache_key_list.size() != hash_key_list.size())
	{
		return false;
	}

	{
		string sql = "HMGET ";

		sql += " ";
		sql += command.name;
		sql += "[";
		sql += cache_key_list[0];
		sql += "]";

		sql += " ";
		sql += "key_list";

		//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();

		if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
		{
			Reset();
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
			return false;
		}
		if (REDIS_OK != redisGetReply(context_, (void**)&reply_))
		{
			if (context_ == nullptr || context_->err != 0)
			{
				Reset();
			}
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute command in pipeline fail.\n") % this % __FUNCTION__;
			return false;
		}
		if (reply_ != NULL)
		{
			string content_value;
			if (reply_->type == REDIS_REPLY_STRING && reply_->len > 0)
			{

				content_value = reply_->str;


			}
			else if (reply_->type == REDIS_REPLY_ARRAY && reply_->elements > 0)
			{

				size_t reply_index = 0;

				if (reply_->element[reply_index]->type == REDIS_REPLY_STRING && reply_->element[reply_index]->len > 0)
				{
					content_value = reply_->element[reply_index]->str;
				}
				else if (reply_->element[reply_index]->type == REDIS_REPLY_INTEGER)
				{
					content_value = reply_->element[reply_index]->integer;
				}
				else
				{
					content_value = "";
				}
			}
			else if (reply_->type == REDIS_REPLY_INTEGER)
			{
				content_value = boost::lexical_cast<std::string>(reply_->integer);
			}
			else
			{
				content_value = "";
			}
			cout << static_cast<long int>(time(NULL)) << " content_value is : " << content_value << endl;
			key_str += content_value;
		}
		freeReplyObject(reply_);
	}

	//bool is_exist_table = DbInfoManager::instance()->IsExistTableName(command.name);

	//if (!is_exist_table)
	{
		string sql = "HMSET ";

		sql += " ";
		sql += command.name;

		sql += " key_info ";
		for (int index = 0; index < command.keylist.size(); ++index)
		{
			string key_name = command.keylist[index];
			sql += key_name;
			//if (index != command.keylist.size() - 1)
			//{
			sql += "|";
			//}
		}

		++command_num;

		//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();

		if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
		{
			Reset();
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
			return false;
		}
	}

	//if (!is_exist_table)
	{
		string sql = "HMSET ";

		sql += " ";
		sql += command.name;

		sql += " column_info ";
		for (int index = 0; index < command.contents.size(); ++index)
		{
			BaseDatabase::CommandContent command_content = command.contents[index];

			sql += command_content.column_name;
			sql += "|";
			sql += command_content.type;
			if (index != command.contents.size() - 1)
			{
				sql += "$";
			}

		}

		++command_num;
		//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();
		if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
		{
			Reset();
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
			return false;
		}
	}

	{
		string sql = "HMSET ";

		sql += "expire ";

		string record_name = "";
		record_name += command.name;
		record_name += "[";
		record_name += cache_key_list[0];
		record_name += "]";

		sql += record_name;
		sql += " ";

		long int current_time = static_cast<long int>(time(NULL));
		sql +=  std::to_string(current_time);


		++command_num;
		//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();
		if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
		{
			Reset();
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
			return false;
		}

		DbInfoManager::instance()->AddRecord(record_name, static_cast<long int>(time(NULL)));
	}

	{
		string sql = "HMSET ";

		sql += " ";
		sql += command.name;
		sql += "[";
		sql += cache_key_list[0];
		sql += "] ";

		sql += "key_list ";

		sql += key_str;

		//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();

		++command_num;
		if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
		{
			Reset();
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
			return false;
		}
	}

	for (int index = 0; index < command.contents.size(); ++index)
	{
		string sql = "HMSET ";

		sql += " ";
		sql += command.name;
		sql += "[";
		sql += cache_key_list[0];
		sql += "] ";

		sql += " ";
		sql += command.name;
		sql += "[";
		sql += hash_key_list[0];
		sql += "]";

		sql += ".";
		sql += command.contents[index].column_name;
		sql += " ";

		sql += command.contents[index].value;

		++command_num;
		//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();
		if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
		{
			Reset();
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
			return false;
		}
	}



	//BaseDatabase::Reply reply;
	for (int index = 0; index < command_num; ++index)
	{
		if (REDIS_OK != redisGetReply(context_, (void**)&reply_))
		{
			if (context_ == nullptr || context_->err != 0)
			{
				Reset();
			}
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute command in pipeline fail.\n") % this % __FUNCTION__;
			return false;
		}
		freeReplyObject(reply_);
	}

	return true;
}

bool NewRedis::SaveFromReply(const BaseDatabase::Command& command, BaseDatabase::Reply& reply)
{
	//cout << static_cast<long int>(time(NULL)) <<"save redis begin" << endl;

	//vector<string> key_value_list;
	int command_num = 0;
	string key_str = "";
	vector<string> cache_key_list;
	vector<string> hash_key_list;
	for (int index = 0; index < reply.data_set.size(); ++index)
	{
		for (size_t sub_index = 0; sub_index < reply.data_set[index].size(); ++sub_index)
		{
			if (reply.data_set[index][sub_index].column_name == command.keylist[0])
			{
				cache_key_list.push_back(reply.data_set[index][sub_index].value);
			}

			if (reply.data_set[index][sub_index].column_name == command.keylist[1])
			{
				hash_key_list.push_back(reply.data_set[index][sub_index].value);
				key_str += string(reply.data_set[index][sub_index].value);
				key_str += "|";
			}
		}
	}
	if (cache_key_list.size() != hash_key_list.size())
	{
		return false;
	}

	//bool is_exist_table = DbInfoManager::instance()->IsExistTableName(command.name);

	//if (!is_exist_table)
	{
		string sql = "HMSET ";

		sql += " ";
		sql += command.name;

		sql += " key_info ";
		for (int index = 0; index < command.keylist.size(); ++index)
		{
			string key_name = command.keylist[index];
			sql += key_name;
			//if (index != command.keylist.size() - 1)
			//{
			sql += "|";
			//}
		}
		//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();

		++command_num;
		if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
		{
			Reset();
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
			return false;
		}
	}

	//if (!is_exist_table)
	{
		string sql = "HMSET ";

		sql += " ";
		sql += command.name;

		sql += " column_info ";
		for (int index = 0; index < command.contents.size(); ++index)
		{
			BaseDatabase::CommandContent command_content = command.contents[index];

			sql += command_content.column_name;
			sql += "|";
			sql += command_content.type;
			if (index != command.contents.size() - 1)
			{
				sql += "$";
			}

		}

		++command_num;

		//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();
		if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
		{
			Reset();
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
			return false;
		}
	}

	{
		string sql = "HMSET ";

		sql += "expire ";

		string record_name = "";
		record_name += command.name;
		record_name += "[";
		record_name += cache_key_list[0];
		record_name += "]";

		sql += record_name;
		sql += " ";

		long int current_time = static_cast<long int>(time(NULL));
		sql +=  std::to_string(current_time);

		++command_num;
		//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();
		if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
		{
			Reset();
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
			return false;
		}

		DbInfoManager::instance()->AddRecord(record_name, static_cast<long int>(time(NULL)));
	}

	{
		string sql = "HMSET ";

		sql += " ";
		sql += command.name;
		sql += "[";
		sql += cache_key_list[0];
		sql += "] ";

		sql += "key_list ";

		sql += key_str;

		++command_num;
		//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();
		if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
		{
			Reset();
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
			return false;
		}
	}

	for (int cache_index = 0; cache_index < cache_key_list.size(); ++cache_index)
	{
		for (int sub_index = 0; sub_index < reply.data_set[cache_index].size(); ++sub_index)
		{
			string sql = "HMSET ";

			sql += " ";
			sql += command.name;
			sql += "[";
			sql += cache_key_list[cache_index];
			sql += "] ";

			sql += " ";
			sql += command.name;
			sql += "[";
			sql += hash_key_list[cache_index];
			sql += "]";

			sql += ".";
			sql += reply.data_set[cache_index][sub_index].column_name;
			sql += " ";

			sql += reply.data_set[cache_index][sub_index].value;

			++command_num;
			//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();
			if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
			{
				Reset();
				LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
				return false;
			}
		}

	}

	//BaseDatabase::Reply reply;
	for (int index = 0; index < command_num; ++index)
	{
		if (REDIS_OK != redisGetReply(context_, (void**)&reply_))
		{
			if (context_ == nullptr || context_->err != 0)
			{
				Reset();
			}
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute command in pipeline fail.\n") % this % __FUNCTION__;
			return false;
		}
		freeReplyObject(reply_);
	}

	return true;
}

bool NewRedis::Delete(const BaseDatabase::Command& command, BaseDatabase::Reply& reply)
{
	int count = command.contents.size();

	vector<string> key_value_list;
	std::vector<string> column_name_list;

	for (size_t index = 0; index < command.keylist.size(); ++index)
	{
		for (int sub_index = 0; sub_index < count; ++sub_index)
		{
			if (command.contents[sub_index].column_name == command.keylist[index])
			{
				key_value_list.push_back(command.contents[sub_index].value);
			}

			if (find(column_name_list.begin(), column_name_list.end(), command.contents[sub_index].column_name) == column_name_list.end())
			{
				column_name_list.push_back(command.contents[sub_index].column_name);
			}
		}
	}

	vector<string> hash_key_list;
	if (key_value_list.size() > 1)
	{
		string sql = "HMGET ";

		sql += " ";
		sql += command.name;
		sql += "[";
		sql += key_value_list[0];
		sql += "]";

		sql += " ";
		sql += "key_list";

		cout << " del redis11 sql is:" << sql << endl;
		//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();
		if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
		{
			Reset();
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
			return false;
		}
		if (REDIS_OK != redisGetReply(context_, (void**)&reply_))
		{
			if (context_ == nullptr || context_->err != 0)
			{
				Reset();
			}
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute command in pipeline fail.\n") % this % __FUNCTION__;
			return false;
		}
		if (reply_ != NULL)
		{
			string content_value;
			if (reply_->type == REDIS_REPLY_STRING && reply_->len > 0)
			{

				content_value = reply_->str;


			}
			else if (reply_->type == REDIS_REPLY_ARRAY && reply_->elements > 0)
			{

				size_t reply_index = 0;

				if (reply_->element[reply_index]->type == REDIS_REPLY_STRING && reply_->element[reply_index]->len > 0)
				{
					content_value = reply_->element[reply_index]->str;
				}
				else if (reply_->element[reply_index]->type == REDIS_REPLY_INTEGER)
				{
					content_value = reply_->element[reply_index]->integer;
				}
				else
				{
					content_value = "";
				}
			}
			else if (reply_->type == REDIS_REPLY_INTEGER)
			{
				content_value = boost::lexical_cast<std::string>(reply_->integer);
			}
			else
			{
				content_value = "";
			}
			CStrFun::split(hash_key_list, content_value.c_str(), '|');
		}
		freeReplyObject(reply_);
	}
	vector<string>::iterator ite = find(hash_key_list.begin(), hash_key_list.end(), key_value_list[1]);
	if (ite != hash_key_list.end())
	{
		hash_key_list.erase(ite);
	}

	string key_str = "";

	for (int index = 0; index < hash_key_list.size(); ++index)
	{
		key_str += hash_key_list[index];
		key_str += "|";
	}

	int command_num = 0;

	if (hash_key_list.size() > 0)
	{
		string sql = "HMSET ";

		sql += " ";
		sql += command.name;
		sql += "[";
		sql += key_value_list[0];
		sql += "] ";

		sql += "key_list ";

		sql += key_str;


		++command_num;
		cout << " del redis22 sql is:" << sql << endl;
		//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();
		if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
		{
			Reset();
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
			return false;
		}
	}
	else
	{
		{
			string sql = "HDEL ";

			sql += " ";
			sql += command.name;
			sql += "[";
			sql += key_value_list[0];
			sql += "] ";

			sql += "key_list";

			++command_num;
			cout << " del redis33 sql is:" << sql << endl;
			//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();
			if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
			{
				Reset();
				LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
				return false;
			}
		}
		{
			string sql = "HDEL ";

			sql += " ";
			sql += command.name;
			sql += "[";
			sql += key_value_list[0];
			sql += "] ";

			sql += "db_key_list";

			cout << " del redis44 sql is:" << sql << endl;
			++command_num;
			//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();
			if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
			{
				Reset();
				LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
				return false;
			}
		}
	}

	for (int index = 0; index < column_name_list.size(); ++index)
	{
		string sql = "HDEL ";

		sql += " ";
		sql += command.name;
		sql += "[";
		sql += key_value_list[0];
		sql += "]";

		sql += " ";
		sql += command.name;
		sql += "[";
		sql += key_value_list[1];
		sql += "]";

		sql += ".";
		sql += column_name_list[index];


		cout << " del redis55 sql is:" << sql << endl;
		++command_num;
		//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();
		if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
		{
			Reset();
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
			return false;
		}
	}

	for (int index = 0; index < command_num; ++index)
	{
		if (REDIS_OK != redisGetReply(context_, (void**)&reply_))
		{
			if (context_ == nullptr || context_->err != 0)
			{
				Reset();
			}
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute command in pipeline fail.\n") % this % __FUNCTION__;
			return false;
		}
		freeReplyObject(reply_);
	}

	return true;
}

bool NewRedis::Delete(const string& key)
{

	{
		string sql = "del ";

		sql += " ";
		sql += key;

		cout << " del redis sql is:" << sql << endl;
		if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
		{
			Reset();
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
			return false;
		}
		if (REDIS_OK != redisGetReply(context_, (void**)&reply_))
		{
			if (context_ == nullptr || context_->err != 0)
			{
				Reset();
			}
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute command in pipeline fail.\n") % this % __FUNCTION__;
			return false;
		}
		freeReplyObject(reply_);
	}


	return true;
}

bool NewRedis::Load(const BaseDatabase::Command& command, BaseDatabase::Reply& reply)
{
	int count = command.contents.size();

	vector<string> key_value_list;
	std::vector<string> column_name_list;

	//for (size_t sub_index = 0; sub_index < command.keylist.size(); ++sub_index)
	//{
	for (int index = 0; index < count; ++index)
	{
		if (command.contents[index].column_name == command.keylist[0])
		{
			key_value_list.push_back(command.contents[index].value);
		}
		if (find(column_name_list.begin(), column_name_list.end(), command.contents[index].column_name) == column_name_list.end())
		{
			column_name_list.push_back(command.contents[index].column_name);
		}
	}
	//}

	vector<string> hash_key_list;

	{
		string sql = "HMGET ";

		sql += " ";
		sql += command.name;
		sql += "[";
		sql += key_value_list[0];
		sql += "]";

		sql += " ";
		sql += "key_list";

		//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();
		if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
		{
			Reset();
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
			return false;
		}
		if (REDIS_OK != redisGetReply(context_, (void**)&reply_))
		{
			if (context_ == nullptr || context_->err != 0)
			{
				Reset();
			}
			LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute command in pipeline fail.\n") % this % __FUNCTION__;
			return false;
		}
		if (reply_ != NULL)
		{
			string content_value;
			if (reply_->type == REDIS_REPLY_STRING && reply_->len > 0)
			{

				content_value = reply_->str;

			}
			else if (reply_->type == REDIS_REPLY_ARRAY && reply_->elements > 0)
			{
				size_t reply_index = 0;

				if (reply_->element[reply_index]->type == REDIS_REPLY_STRING && reply_->element[reply_index]->len > 0)
				{
					content_value = reply_->element[reply_index]->str;
				}
				else if (reply_->element[reply_index]->type == REDIS_REPLY_INTEGER)
				{
					content_value = reply_->element[reply_index]->integer;
				}
				else
				{
					content_value = "";
				}
			}
			else if (reply_->type == REDIS_REPLY_INTEGER)
			{
				content_value = boost::lexical_cast<std::string>(reply_->integer);
			}
			else
			{
				content_value = "";
			}
			CStrFun::split(hash_key_list, content_value.c_str(), '|');
		}
		freeReplyObject(reply_);
	}

	for (int key_index = 0; key_index < hash_key_list.size(); ++key_index)
	{
		for (vector<string>::iterator ite = column_name_list.begin(); ite != column_name_list.end(); ++ite)
		{
			string sql = "HMGET ";

			sql += " ";
			sql += command.name;
			sql += "[";
			sql += key_value_list[0];
			sql += "]";

			sql += " ";
			sql += command.name;
			sql += "[";
			sql += hash_key_list[key_index];
			sql += "]";

			sql += ".";
			sql += *ite;

			//LOG(SYS, INFO) << boost::format("[Redis %x][%s] execute sql %s.\n") % this % __FUNCTION__ % sql.c_str();
			if (REDIS_OK != redisAppendCommand(context_, sql.c_str()))
			{
				Reset();
				LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute append command fail.\n") % this % __FUNCTION__;
				return false;
			}

		}
		vector<BaseDatabase::ReplyContent> reply_content_list;

		for (int index = 0; index < column_name_list.size(); ++index)
		{
			if (REDIS_OK != redisGetReply(context_, (void**)&reply_))
			{
				if (context_ == nullptr || context_->err != 0)
				{
					Reset();
				}
				LOG(SYS, ERROR) << boost::format("[NewRedis %x][%s] execute command in pipeline fail.\n") % this % __FUNCTION__;
				return false;
			}

			if (reply_ != NULL)
			{
				BaseDatabase::ReplyContent content;
				content.column_name = column_name_list[index];
				if (reply_->type == REDIS_REPLY_STRING && reply_->len > 0)
				{

					content.value = reply_->str;

				}
				else if (reply_->type == REDIS_REPLY_ARRAY && reply_->elements > 0)
				{
					size_t reply_index = 0;

					if (reply_->element[reply_index]->type == REDIS_REPLY_STRING && reply_->element[reply_index]->len > 0)
					{
						content.value = reply_->element[reply_index]->str;
					}
					else if (reply_->element[reply_index]->type == REDIS_REPLY_INTEGER)
					{
						content.value = reply_->element[reply_index]->integer;
					}
					else
					{
						content.value = "";
					}

				}
				else if (reply_->type == REDIS_REPLY_INTEGER)
				{
					content.value = boost::lexical_cast<std::string>(reply_->integer);
				}
				else
				{
					content.value = "";
				}
				reply_content_list.push_back(content);

			}
			freeReplyObject(reply_);
		}

		reply.data_set.push_back(reply_content_list);
	}
	reply.row_num = reply.data_set.size();

	return true;
}

bool NewRedis::Write(const BaseDatabase::CommandSet& command_set)
{
	return true;
}

bool NewRedis::Read(BaseDatabase::ReplySet& reply_set)
{
	return true;
}
