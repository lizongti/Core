#ifndef _NEW_MYSQL_H_
#define _NEW_MYSQL_H_
#include <rapidjson/document.h>
#include <rapidjson/writer.h>
#include <rapidjson/stringbuffer.h>
#include <memory>
#include <stdio.h>
#include <cstdlib>
#include "./BaseDatabase.h"
#include "./DbInterface.h"
#include "Logger.h"

class NewMysql : public DBInterface
{
public:

	NewMysql();

	~NewMysql();

public:
	void BindParams(const BaseDatabase::Command& command, MYSQL_BIND* params, int index1, int index2);

	string GetResult(MYSQL_BIND& param);

	void PrintParams(MYSQL_BIND* params, int count);

	bool Load(const BaseDatabase::Command& command, BaseDatabase::Reply& reply);

	bool Update(const BaseDatabase::Command& command, BaseDatabase::Reply& reply);

	bool Save(const BaseDatabase::Command& command, BaseDatabase::Reply& reply);

	bool Delete(const BaseDatabase::Command& command, BaseDatabase::Reply& reply);
};

#endif
