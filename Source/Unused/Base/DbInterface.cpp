#include "DbInterface.h"
#include "Logger.h"

void DBQuery ::Clear()
{
	memset(m_SqlStr, 0, MAX_SQL_LENGTH);
	len = 0;
}

void DBQuery ::Parse(const char* pTemplate, ...)
{
	va_list argptr;
	va_start(argptr, pTemplate);
	int nchars  = vsnprintf((char*)m_SqlStr, MAX_SQL_LENGTH, pTemplate, argptr);
	va_end(argptr);

	if (nchars == -1 || nchars > MAX_SQL_LENGTH)
	{
		return;
	}

	len = nchars;
}

DBInterface::DBInterface( )
{
	m_pMysql  = NULL;
	m_pStmt   = NULL;
	m_bIsOpen = false;
	m_QueryStuct.Clear();
}

DBInterface::~DBInterface(void)
{
	Stop();
}

bool DBInterface::Connect()
{
	return Connect(_config);
}

bool DBInterface::Connect(const DBInterface::Config& config)
{
	Stop();

	m_pMysql = mysql_init(NULL);


	m_pMysql = mysql_real_connect(m_pMysql, config.host.c_str(), config.username.c_str(), config.password.c_str(), config.dbname.c_str(), config.port, 0, 0);
	if (!m_pMysql)
	{
		m_bIsOpen = false;
		return false;
	}

	m_pStmt = mysql_stmt_init(m_pMysql);
	if (!m_pStmt)
	{
		return false;
	}

	mysql_query(m_pMysql, "set names utf8");

	m_bIsOpen = true;

	_config = config;

	return true;
}

bool DBInterface::Stop()
{
	m_bIsOpen   = false;

	if (m_pStmt)
	{
		mysql_stmt_close(m_pStmt);
		m_pStmt = NULL;
	}

	if (m_pMysql)
	{
		mysql_close(m_pMysql);

		m_pMysql = NULL;
	}

	return true;
}

bool DBInterface::Prepare()
{
	if (!m_pMysql)
	{
		LOG(SYS, INFO) << boost::format("[Prepare %x][%s] m_pMysql is null\n") % this % __FUNCTION__;
		return false;
	}

	if (!m_pStmt)
	{
		LOG(SYS, INFO) << boost::format("[Prepare %x][%s] m_pStmt is null\n") % this % __FUNCTION__;
		return false;
	}
	int res = mysql_stmt_prepare(m_pStmt, m_QueryStuct.m_SqlStr, strlen(m_QueryStuct.m_SqlStr));
	if (res != 0)
	{
		const char * msg = mysql_stmt_error(m_pStmt);
		printf("[Sandbox]### mysql_stmt_prepare error msg:%s %s\n", msg, m_QueryStuct.m_SqlStr);
		LOG(SYS, ERROR) << boost::format("[Prepare %x][%s] error:%d, msg:%s m_SqlStr is %s\n") % this % __FUNCTION__ % res % msg % m_QueryStuct.m_SqlStr;
		return false;
	}

	return true;
}


void DBInterface::BindParams(MYSQL_BIND* params)
{
	if (mysql_stmt_bind_param(m_pStmt, params) != 0)
	{
		printf("bind error: %s\n", mysql_stmt_error(m_pStmt));
	}
}

void DBInterface::BindResult(MYSQL_BIND* params)
{
	if (mysql_stmt_bind_result(m_pStmt, params) != 0)
	{
		printf("bind result error: %s\n", mysql_stmt_error(m_pStmt));
	}
}

void DBInterface::StoreResult()
{
	mysql_stmt_store_result(m_pStmt);
}

bool DBInterface::Running()
{
	return m_bIsOpen;
}

int DBInterface::EffectRows()
{
	return mysql_stmt_num_rows(m_pStmt);
}

int DBInterface::Fetch()
{
	return mysql_stmt_fetch(m_pStmt);
}


int DBInterface::MySqlPing()
{
	if (m_bIsOpen)
	{
		if (m_pMysql != NULL)
		{
			return mysql_ping(m_pMysql);
		}
	}

	return -1;
}

DBQuery &	DBInterface::GetQuery()
{
	return m_QueryStuct;
}

bool	DBInterface::IsPrepare()
{
	return Running();
}

bool DBInterface::StmtExecute(MYSQL_BIND* inParams, MYSQL_BIND* outParams)
{
	if (!IsPrepare())
	{
		cout << "not prepare" << endl;
		return false;
	}

	bool res = Prepare();
	if (!res)
	{
		res = Connect();
		if (!res)
		{
			cout << " connect error" << endl;
			return res;
		}
		res = Prepare();
		if (!res)
		{
			LOG(SYS, INFO) << boost::format("[Prepare %x][%s] prepare error\n") % this % __FUNCTION__;
			return res;
		}
	}

	if (inParams != NULL)
	{
		BindParams(inParams);
	}
	if (mysql_stmt_execute(m_pStmt) != 0)
	{
		printf("excute error: %s\n", mysql_stmt_error(m_pStmt));
	}
	if (outParams != NULL)
	{
		BindResult(outParams);

		StoreResult();
	}

	return res;
}

void  DBInterface::Snprintf(char* source, int len, char* format, int value)
{
	snprintf(source, len, format, value); //linux下是snprintf
}

void DBInterface::Snprintf(char* source, int len, char* format, string value)
{
	snprintf(source, len, format, value.c_str()); //linux下是snprintf
}
