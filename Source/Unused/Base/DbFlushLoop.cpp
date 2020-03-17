#include "DbFlushLoop.h"

DbFlushLoop::DbFlushLoop()
{
}

DbFlushLoop::~DbFlushLoop()
{
}

bool DbFlushLoop::Init(const DBInterface::Config& mysql_conf, const NewRedis::Config& redis_conf)
{
	cout << static_cast<long int>(time(NULL)) << " mysql Init begin" << endl;
	if (!mysql_.Connect(mysql_conf))
	{
		cout << static_cast<long int>(time(NULL)) << "mysql connect failed!" << endl;
		return false;
	}

	if (!redis_.Init(redis_conf))
	{
		return false;
	}

	uv_timer_init(loop_, &timer_);


	return Loop::Init(false, nullptr);
}

bool DbFlushLoop::Start()
{
	if (!redis_.Start())
	{
		return false;
	}

	cout << "DbFlushLoop Start" << endl;
	uv_timer_start(&timer_, timer_cb_, 0, 60000);
	timer_.data = this;

	InitRecord();

	return Loop::Start();
}

bool DbFlushLoop::Stop()
{
	if (!mysql_.Stop())
	{
		return false;
	}
	if (!redis_.Stop())
	{
		return false;
	}

	return Loop::Stop();
}

bool DbFlushLoop::Running()
{
	if (!mysql_.Running())
	{
		return false;
	}

	if (!redis_.Running())
	{
		return false;
	}

	return Loop::Running();
}

bool DbFlushLoop::InitRecord()
{
	vector<std::string> result_list;
	redis_.GetExpire(result_list);
	if (result_list.size() < 2)
	{
		return false;
	}

	for (int index = 0; index < result_list.size(); index += 2)
	{
		long int value = 0;
		stringstream stream(result_list[index + 1]);
		stream >> value;

		std::string key = result_list[index];

		DbInfoManager::instance()->AddRecord(key, value);
	}
	return true;
}

void DbFlushLoop::timer_callback(uv_timer_t* handle)
{
	std::lock_guard<std::mutex> lock(DbInfoManager::instance()->GetRecordMutex());

	//cout << "timer_callback 22" << endl;
	//LOG(SYS, INFO) << boost::format("[DbFlushLoop %x][%s] timer callback.\n") % this % __FUNCTION__;

	long int current_time = static_cast<long int>(time(NULL));
	map<std::string, long int> record_map = DbInfoManager::instance()->GetRecord();

	for (map<std::string, long int>::iterator ite = record_map.begin(); ite != record_map.end(); ++ite)
	{
		//cout << "timer_callback 33" << endl;
		std::string key = ite->first;
		//LOG(SYS, INFO) << boost::format("[DbFlushLoop %x][%s] current_time %ld, action time: %ld.\n") % this % __FUNCTION__ % current_time % ite->second;
		if (current_time - ite->second < 600)
		{
			continue;
		}

		//LOG(SYS, INFO) << boost::format("[DbFlushLoop %x][%s] begin flush data.\n") % this % __FUNCTION__;
		ite->second = 0;

		vector<std::string> name_list;
		CStrFun::split(name_list, key.c_str(), '[');
		std::string table_name = name_list[0];

		vector<std::string> first_key_list;
		CStrFun::split(first_key_list, name_list[1].c_str(), ']');


		vector<string> key_info;
		vector<ColumnInfo> column_info;
		vector<string> db_key_list;
		vector<string> key_list;

		vector<string> result_list;
		redis_.GetRecord(table_name, "key_info", result_list);
		if (result_list.size() > 0)
		{
			CStrFun::split(key_info, result_list[0].c_str(), '|');
		}

		result_list.clear();
		redis_.GetRecord(table_name, "column_info", result_list);
		if (result_list.size() > 0)
		{
			vector<string> item_list;
			CStrFun::split(item_list, result_list[0].c_str(), '$');
			for (vector<string>::iterator sub_ite = item_list.begin(); sub_ite != item_list.end(); ++sub_ite)
			{
				string item = *sub_ite;
				vector<string> info_list;
				CStrFun::split(info_list, item.c_str(), '|');
				ColumnInfo column;
				column.name = info_list[0];
				column.type = info_list[1];
				column_info.push_back(column);
			}
		}

		result_list.clear();
		redis_.GetRecord(key, "db_key_list", result_list);
		if (result_list.size() > 0)
		{
			CStrFun::split(db_key_list, result_list[0].c_str(), '|');
		}

		result_list.clear();
		redis_.GetRecord(key, "key_list", result_list);
		if (result_list.size() > 0)
		{
			CStrFun::split(key_list, result_list[0].c_str(), '|');
		}

		redis_.UpdateHashValue(key, "db_key_list", result_list[0]);


		for (int index = 0; index != key_list.size(); ++index)
		{
			BaseDatabase::Command command;
			BaseDatabase::Reply reply;
			command.name = table_name;

			command.keylist = key_info;
			command.primary_keys = key_info;
			for (vector<ColumnInfo>::iterator column_index = column_info.begin(); column_index != column_info.end(); ++column_index)
			{
				BaseDatabase::CommandContent content;
				content.column_name = column_index->name;
				content.type = column_index->type;

				string hash_key = "";
				hash_key += table_name;
				hash_key += "[";
				hash_key += key_list[index];
				hash_key += "]";
				hash_key += ".";
				hash_key += column_index->name;


				result_list.clear();
				redis_.GetRecord(key, hash_key, result_list);
				content.value = result_list[0];

				command.contents.push_back(content);
			}
			//redis有，数据库没有，将redis的数据添加到数据库
			if (find(db_key_list.begin(), db_key_list.end(), key_list[index]) == db_key_list.end())
			{
				//添加
				command.action = "save";
				mysql_.Save(command, reply);
				//cout << "timer_callback 44" << endl;
			}
			else
			{
				//更新
				command.action = "udpate";
				mysql_.Update(command, reply);
				//cout << "timer_callback 55" << endl;
			}
		}

		//数据库有，redis没有，将数据库的数据删除
		for (int index = 0; index != db_key_list.size(); ++index)
		{
			BaseDatabase::Command command;
			BaseDatabase::Reply reply;
			command.name = table_name;

			command.keylist = key_info;
			command.primary_keys = key_info;

			for (vector<ColumnInfo>::iterator column_index = column_info.begin(); column_index != column_info.end(); ++column_index)
			{
				if (column_index->name == key_info[0])
				{
					BaseDatabase::CommandContent content;
					content.column_name = column_index->name;
					content.type = column_index->type;

					content.value = first_key_list[0];

					command.contents.push_back(content);
				}
				else if (column_index->name == key_info[1])
				{
					BaseDatabase::CommandContent content;
					content.column_name = column_index->name;
					content.type = column_index->type;

					content.value = db_key_list[index];

					command.contents.push_back(content);
				}

			}

			if (find(key_list.begin(), key_list.end(), db_key_list[index]) == key_list.end())
			{
				//删除
				command.action = "delete";
				mysql_.Delete(command, reply);
				//cout << "timer_callback 66" << endl;
			}
		}
		redis_.Delete(key);
	}


	for (map<std::string, long int>::iterator ite = record_map.begin(); ite != record_map.end();)
	{
		if (ite->second == 0)
		{
			//LOG(SYS, INFO) << boost::format("[DbFlushLoop %x][%s] delete map begin.\n") % this % __FUNCTION__;
			redis_.DelHashValue("expire", ite->first);
			record_map.erase(ite++);
		}
		else
		{
			ite++;
		}
		//cout << "timer_callback 77" << endl;
	}

	DbInfoManager::instance()->SetRecord(record_map);

}
