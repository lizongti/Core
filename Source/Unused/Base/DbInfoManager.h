#ifndef DBINFOMANAGER_HPP
#define DBINFOMANAGER_HPP
#include <memory>
#include <stdio.h>
#include <cstdlib>
#include <map>
#include <mutex>
#include <set>
#include "./BaseDatabase.h"
using namespace std;

class DbInfoManager
{
public:
	DbInfoManager();

	~DbInfoManager();
	
	static DbInfoManager* instance();
	
	void AddRecord(std::string name, long int update_time);
	
	map<std::string, long int> GetRecord();
	
	void SetRecord(map<std::string, long int>& record_map);
	
	bool NeedLoad(const BaseDatabase::Command& command);
	
	std::mutex& GetRecordMutex();

	bool IsExistTableName(string name);

private:
	map<std::string, long int> record_map_;
	std::mutex record_mutex_;
	
	std::mutex table_name_mutex_;
	std::set<string> table_name_set_;
};

#endif // !CONFIG_HPP
