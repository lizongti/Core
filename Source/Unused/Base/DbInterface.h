#ifndef _DB_INTERFACE_H_
#define _DB_INTERFACE_H_
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <mysql++/mysql++.h>
#ifdef _WIN32
//#include <mysql/mysql.h>
#else
#endif
#include <iostream>
using namespace std;

#define MAX_SQL_LENGTH					8192
#define MAX_ERROR_MSG_LENGHT			255

struct DBQuery
{
	char m_SqlStr[MAX_SQL_LENGTH];	
	int len;

	void Clear();

	void Parse(const char* pTemplate, ...);
};

class DBInterface
{
public:
	struct Config
	{
		std::string host;
		uint16_t port;
		std::string username;
		std::string password;
		std::string dbname;
		const static uint32_t command_queue_size = 10240;
		const static uint32_t reply_queue_size = 10240;
	};
	
	DBInterface();
	
	virtual ~DBInterface(void);

public:
	bool Connect();
	
	bool Connect(const DBInterface::Config& config);
	
	bool Stop();
	
	bool Prepare();

	void BindParams(MYSQL_BIND* params);
	
	void BindResult(MYSQL_BIND* params);

	void StoreResult();
	
	bool Running();
	
	int EffectRows();
	
	int Fetch();

	int MySqlPing();


	DBQuery & GetQuery();

	bool	IsPrepare();

	bool StmtExecute(MYSQL_BIND* inParams = NULL, MYSQL_BIND* outParams = NULL);

	void  Snprintf(char* source, int len, char* format, int value);

	void Snprintf(char* source, int len, char* format, string value);
	
public:
	MYSQL* GetMYSQL() {return m_pMysql;}

	DBQuery m_QueryStuct;							//查询结构体

public:
	bool m_idle;

protected:
	MYSQL*     m_pMysql;

	MYSQL_STMT* m_pStmt;

	bool       m_bIsOpen;
private:
	Config _config;
};

#endif