#include "DbInfoManager.h"

DbInfoManager::DbInfoManager()
{
}

DbInfoManager::~DbInfoManager()
{
}

DbInfoManager* DbInfoManager::instance()
{
	static DbInfoManager inst;
	return &inst;
}

void DbInfoManager::AddRecord(std::string name, long int update_time)
{
	std::lock_guard<std::mutex> lock(record_mutex_);
	//cout << "map name is:" << name << endl;
	if (name.size() > 0)
	{
		record_map_[name] = update_time;
	}

}

map<std::string, long int> DbInfoManager::GetRecord()
{
	return record_map_;
}

void DbInfoManager::SetRecord(map<std::string, long int>& record_map)
{

	record_map_ = record_map;
}

bool DbInfoManager::NeedLoad(const BaseDatabase::Command& command)
{
	int count = command.contents.size();

	vector<string> key_value_list;
	for (size_t index = 0; index < command.keylist.size(); ++index)
	{
		for (int sub_index = 0; sub_index < count; ++sub_index)
		{
			if (command.contents[sub_index].column_name == command.keylist[index])
			{
				key_value_list.push_back(command.contents[sub_index].value);
			}

		}
	}

	string name = command.name;
	name += "[";
	name += key_value_list[0];
	name += "]";

	std::lock_guard<std::mutex> lock(record_mutex_);
	if (record_map_.find(name) == record_map_.end())
	{
		return true;
	}
	return false;
}

std::mutex& DbInfoManager::GetRecordMutex()
{
	return record_mutex_;
}

bool DbInfoManager::IsExistTableName(string name)
{
	std::lock_guard<std::mutex> lock(table_name_mutex_);
	if (table_name_set_.find(name) != table_name_set_.end())
	{
		return true;
	}

	table_name_set_.insert(name);

	return false;
}