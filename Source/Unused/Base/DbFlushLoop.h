#ifndef _DBFLUSHLOOP_H_
#define _DBFLUSHLOOP_H_
#include <rapidjson/document.h>
#include <rapidjson/writer.h>
#include <rapidjson/stringbuffer.h>
#include <memory>
#include <stdio.h>
#include <cstdlib>
#include "./NewMysql.h"
#include "./NewRedis.h"
#include "Loop.h"
#include "Logger.h"
#include <sstream>

class DbFlushLoop : public Loop
{
public:
	class ColumnInfo
	{
	public:
		string name;
		string type;
	};
	DbFlushLoop();

	virtual ~DbFlushLoop();

	virtual bool Init(const DBInterface::Config& mysql_conf, const NewRedis::Config& redis_conf);

	virtual bool Start();

	virtual bool Stop();

	virtual bool Running();

	bool InitRecord();

protected:
	virtual void timer_callback(uv_timer_t* handle);

protected:
	NewMysql mysql_;

	NewRedis redis_;


};

#endif
