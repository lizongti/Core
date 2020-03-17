#include "NewMysql.h"

NewMysql::NewMysql()
{
}

NewMysql::~NewMysql()
{
}

void NewMysql::BindParams(const BaseDatabase::Command& command, MYSQL_BIND* params, int index1, int index2)
{
	string sql_type = command.contents[index2].type;

	if (sql_type.find("tinyint") != std::string::npos)
	{

		params[index1].buffer_type = MYSQL_TYPE_TINY;
		char *value = (char *)malloc(sizeof(char));
		params[index1].buffer = value;
		*value = atoi(command.contents[index2].value.c_str());
	}
	else if (sql_type.find("smallint") != std::string::npos)
	{
		params[index1].buffer_type = MYSQL_TYPE_SHORT;
		short int *value = (short int *)malloc(sizeof(short int));
		params[index1].buffer = value;

		*value = atoi(command.contents[index2].value.c_str());
	}
	else if (sql_type.find("bigint") != std::string::npos)
	{
		params[index1].buffer_type = MYSQL_TYPE_LONGLONG;
		long long int *value = (long long int *)malloc(sizeof(long long int));
		params[index1].buffer = value;

		*value = strtol(command.contents[index2].value.c_str(), NULL, 10);
	}
	else if (sql_type.find("int") != std::string::npos)
	{
		params[index1].buffer_type = MYSQL_TYPE_LONG;
		int *value = (int *)malloc(sizeof(int));
		params[index1].buffer = value;

		*value = atoi(command.contents[index2].value.c_str());
	}
	else if (sql_type.find("float") != std::string::npos)
	{
		params[index1].buffer_type = MYSQL_TYPE_FLOAT;
		float *value = (float *)malloc(sizeof(float));
		params[index1].buffer = value;

		*value = atof(command.contents[index2].value.c_str());
	}
	else if (sql_type.find("double") != std::string::npos)
	{
		params[index1].buffer_type = MYSQL_TYPE_DOUBLE;
		double *value = (double *)malloc(sizeof(double));
		params[index1].buffer = value;

		*value = atof(command.contents[index2].value.c_str());
	}
	else if (sql_type.find("varchar") != std::string::npos)
	{
		int begin_pos =  sql_type.find("(");
		int end_pos =  sql_type.find(")");
		int num = end_pos - begin_pos - 1;
		string number_str = sql_type.substr(begin_pos + 1, num);
		int number = stoi(number_str);
		char *value = (char *)malloc(sizeof(char) * number);
		memset(value, 0, sizeof(char) * number);

		params[index1].buffer_type = MYSQL_TYPE_VAR_STRING;
		params[index1].buffer = value;
		params[index1].buffer_length = number;

		int size = command.contents[index2].value.size() > sizeof(char) * number ? sizeof(char) * number : command.contents[index2].value.size();
		memcpy(value, command.contents[index2].value.c_str(), size);
	}
	else if (sql_type.find("char") != std::string::npos)
	{
		int begin_pos =  sql_type.find("(");
		int end_pos =  sql_type.find(")");
		int num = end_pos - begin_pos - 1;
		string number_str = sql_type.substr(begin_pos + 1, num);
		int number = stoi(number_str);
		char *value = (char *)malloc(sizeof(char) * number);
		memset(value, 0, sizeof(char) * number);

		params[index1].buffer_type = MYSQL_TYPE_STRING;
		params[index1].buffer = value;
		params[index1].buffer_length = number;


		int size = command.contents[index2].value.size() > sizeof(char) * number ? sizeof(char) * number : command.contents[index2].value.size();
		memcpy(value, command.contents[index2].value.c_str(), size);
	}
	else if (sql_type.find("tinyblob") != std::string::npos)
	{
		int begin_pos =  sql_type.find("(");
		int end_pos =  sql_type.find(")");
		int num = end_pos - begin_pos - 1;
		string number_str = sql_type.substr(begin_pos + 1, num);
		int number = 10240;
		char *value = (char *)malloc(sizeof(char) * number);
		memset(value, 0, sizeof(char) * number);

		params[index1].buffer_type = MYSQL_TYPE_TINY_BLOB;
		params[index1].buffer = value;
		params[index1].buffer_length = number;

		int size = command.contents[index2].value.size() > sizeof(char) * number ? sizeof(char) * number : command.contents[index2].value.size();
		memcpy(value, command.contents[index2].value.c_str(), size);
	}
	else if (sql_type.find("tinytext") != std::string::npos)
	{
		int begin_pos =  sql_type.find("(");
		int end_pos =  sql_type.find(")");
		int num = end_pos - begin_pos - 1;
		string number_str = sql_type.substr(begin_pos + 1, num);
		int number = 10240;
		char *value = (char *)malloc(sizeof(char) * number);
		memset(value, 0, sizeof(char) * number);

		params[index1].buffer_type = MYSQL_TYPE_TINY_BLOB;
		params[index1].buffer = value;
		params[index1].buffer_length = number;

		int size = command.contents[index2].value.size() > sizeof(char) * number ? sizeof(char) * number : command.contents[index2].value.size();
		memcpy(value, command.contents[index2].value.c_str(), size);
	}
	else if (sql_type.find("mediumblob") != std::string::npos)
	{
		int begin_pos =  sql_type.find("(");
		int end_pos =  sql_type.find(")");
		int num = end_pos - begin_pos - 1;
		string number_str = sql_type.substr(begin_pos + 1, num);
		int number = 65535;
		char *value = (char *)malloc(sizeof(char) * number);
		memset(value, 0, sizeof(char) * number);

		params[index1].buffer_type = MYSQL_TYPE_MEDIUM_BLOB;
		params[index1].buffer = value;
		params[index1].buffer_length = number;

		int size = command.contents[index2].value.size() > sizeof(char) * number ? sizeof(char) * number : command.contents[index2].value.size();
		memcpy(value, command.contents[index2].value.c_str(), size);
	}
	else if (sql_type.find("mediumtext") != std::string::npos)
	{
		int begin_pos =  sql_type.find("(");
		int end_pos =  sql_type.find(")");
		int num = end_pos - begin_pos - 1;
		string number_str = sql_type.substr(begin_pos + 1, num);
		int number = 65535;
		char *value = (char *)malloc(sizeof(char) * number);
		memset(value, 0, sizeof(char) * number);

		params[index1].buffer_type = MYSQL_TYPE_MEDIUM_BLOB;
		params[index1].buffer = value;
		params[index1].buffer_length = number;

		int size = command.contents[index2].value.size() > sizeof(char) * number ? sizeof(char) * number : command.contents[index2].value.size();
		memcpy(value, command.contents[index2].value.c_str(), size);
	}
	else if (sql_type.find("longblob") != std::string::npos)
	{
		int begin_pos =  sql_type.find("(");
		int end_pos =  sql_type.find(")");
		int num = end_pos - begin_pos - 1;
		string number_str = sql_type.substr(begin_pos + 1, num);
		int number = 65535;
		char *value = (char *)malloc(sizeof(char) * number);
		memset(value, 0, sizeof(char) * number);

		params[index1].buffer_type = MYSQL_TYPE_LONG_BLOB;
		params[index1].buffer = value;
		params[index1].buffer_length = number;

		int size = command.contents[index2].value.size() > sizeof(char) * number ? sizeof(char) * number : command.contents[index2].value.size();
		memcpy(value, command.contents[index2].value.c_str(), size);
	}
	else if (sql_type.find("longtext") != std::string::npos)
	{
		int begin_pos =  sql_type.find("(");
		int end_pos =  sql_type.find(")");
		int num = end_pos - begin_pos - 1;
		string number_str = sql_type.substr(begin_pos + 1, num);
		int number = 65535;
		char *value = (char *)malloc(sizeof(char) * number);
		memset(value, 0, sizeof(char) * number);

		params[index1].buffer_type = MYSQL_TYPE_LONG_BLOB;
		params[index1].buffer = value;
		params[index1].buffer_length = number;

		int size = command.contents[index2].value.size() > sizeof(char) * number ? sizeof(char) * number : command.contents[index2].value.size();
		memcpy(value, command.contents[index2].value.c_str(), size);
	}
	else if (sql_type.find("blob") != std::string::npos)
	{
		int begin_pos =  sql_type.find("(");
		int end_pos =  sql_type.find(")");
		int num = end_pos - begin_pos - 1;
		string number_str = sql_type.substr(begin_pos + 1, num);
		int number = 65535;
		char *value = (char *)malloc(sizeof(char) * number);
		memset(value, 0, sizeof(char) * number);

		params[index1].buffer_type = MYSQL_TYPE_BLOB;
		params[index1].buffer = value;
		params[index1].buffer_length = number;

		int size = command.contents[index2].value.size() > sizeof(char) * number ? sizeof(char) * number : command.contents[index2].value.size();
		memcpy(value, command.contents[index2].value.c_str(), size);
	}
	else if (sql_type.find("text") != std::string::npos)
	{
		int begin_pos =  sql_type.find("(");
		int end_pos =  sql_type.find(")");
		int num = end_pos - begin_pos - 1;
		//string number_str = sql_type.substr(begin_pos + 1, num);
		int number = 65535;
		char *value = (char *)malloc(sizeof(char) * number);
		memset(value, 0, sizeof(char) * number);

		params[index1].buffer_type = MYSQL_TYPE_BLOB;
		params[index1].buffer = value;
		params[index1].buffer_length = number;

		int size = command.contents[index2].value.size() > sizeof(char) * number ? sizeof(char) * number : command.contents[index2].value.size();
		memcpy(value, command.contents[index2].value.c_str(), size);
	}
}

string NewMysql::GetResult(MYSQL_BIND& param)
{
	stringstream stream;
	if (param.buffer_type == MYSQL_TYPE_TINY)
	{
		stream << (char)(*(char*)(param.buffer));
	}
	else if (param.buffer_type == MYSQL_TYPE_SHORT)
	{
		stream << (short int)(*(short int*)(param.buffer));
	}
	else if (param.buffer_type == MYSQL_TYPE_LONGLONG)
	{
		stream << (long long int)(*(long long int*)(param.buffer));
	}
	else if (param.buffer_type == MYSQL_TYPE_LONG)
	{
		stream << (int)(*(int*)(param.buffer));
	}
	else if (param.buffer_type == MYSQL_TYPE_FLOAT)
	{
		stream << (float)(*(float*)(param.buffer)) ;
	}
	else if (param.buffer_type == MYSQL_TYPE_DOUBLE)
	{
		stream << (double)(*(double*)(param.buffer));
	}
	else if (param.buffer_type == MYSQL_TYPE_VAR_STRING)
	{
		stream << (char*)param.buffer;
	}
	else if (param.buffer_type == MYSQL_TYPE_STRING)
	{
		stream << (char*)param.buffer;
	}
	else if (param.buffer_type == MYSQL_TYPE_TINY_BLOB)
	{
		stream << (char*)param.buffer;
	}
	else if (param.buffer_type == MYSQL_TYPE_MEDIUM_BLOB)
	{
		stream << (char*)param.buffer;
	}
	else if (param.buffer_type == MYSQL_TYPE_LONG_BLOB)
	{
		stream << (char*)param.buffer;
	}
	else if (param.buffer_type == MYSQL_TYPE_BLOB)
	{
		stream << (char*)param.buffer;
	}
	return stream.str();
}

void NewMysql::PrintParams(MYSQL_BIND* params, int count)
{

}

bool NewMysql::Load(const BaseDatabase::Command& command, BaseDatabase::Reply& reply)
{
	DBQuery &query = GetQuery();

	query.Clear();

	string sql = "select ";

	int count = command.contents.size();
	MYSQL_BIND* out_params = (MYSQL_BIND*)malloc(sizeof(MYSQL_BIND) * count);
	
	memset(out_params, 0, sizeof(MYSQL_BIND) * count);

	MYSQL_BIND* in_params = (MYSQL_BIND*)malloc(sizeof(MYSQL_BIND) * 1);

	memset(in_params, 0, sizeof(MYSQL_BIND) * 1);

	vector<string> key_name_list;
	vector<int> key_index_list;
	for (int index = 0; index < count; ++index)
	{
		sql += command.contents[index].column_name;
		if (index != count - 1)
		{
			sql += " ,";
		}

		if (command.contents[index].column_name == command.keylist[0])
		{
			key_index_list.push_back(index);
			key_name_list.push_back(command.contents[index].column_name);
		}

		BindParams(command, out_params, index, index);
	}

	BindParams(command, in_params, 0, key_index_list[0]);



	sql += " from ";
	sql += command.name;
	sql += " where ";
	for (size_t index = 0; index < key_name_list.size(); ++index)
	{

		if (index > 0)
		{
			sql += " and ";
		}
		sql += key_name_list[index];
		sql += " = ?";
	}

	query.Parse(sql.c_str());
	StmtExecute(in_params, out_params);
	int effectRows = EffectRows();
	reply.row_num = effectRows;
	if (effectRows == 0)
	{
		return false;
	}
	//LOG(SYS, INFO) << boost::format("[Mysql %x][%s] execute effectRows %d.\n") % this % __FUNCTION__ % effectRows;
	for (int i = 0; i < effectRows; ++i)
	{
		if (Fetch() == 0)
		{
			PrintParams(out_params, count);
			vector<BaseDatabase::ReplyContent> reply_content_list;
			for (int index = 0; index < count; ++index)
			{
				BaseDatabase::ReplyContent content;
				content.column_name = command.contents[index].column_name;
				content.value = GetResult(out_params[index]);
				//LOG(SYS, INFO) << boost::format("[Mysql %x][%s] execute column_name %s value %d.\n") % this % __FUNCTION__ % content.column_name.c_str() % content.value;
				reply_content_list.push_back(content);
			}
			reply.data_set.push_back(reply_content_list);
		}
	}


	for (int index = 0; index < count; ++index)
	{
		free(out_params[index].buffer);
	}

	free(out_params);


	free(in_params[0].buffer);


	free(in_params);

	return true;
}

bool NewMysql::Update(const BaseDatabase::Command& command, BaseDatabase::Reply& reply)
{
	DBQuery &query = GetQuery();

	query.Clear();

	string sql = "update ";
	sql += command.name;
	sql += " set ";

	int count = command.contents.size();
	MYSQL_BIND* params = (MYSQL_BIND*)malloc(sizeof(MYSQL_BIND) * (count + command.primary_keys.size()));
	memset(params, 0, sizeof(MYSQL_BIND) * (count + command.primary_keys.size()));

	vector<string> key_name_list;
	vector<int> key_index_list;
	for (int index = 0; index < count; ++index)
	{
		sql += command.contents[index].column_name;
		if (index != count - 1)
		{

			sql += " = ?,";
		}
		else
		{
			sql += " = ?";
		}

		for (size_t sub_index = 0; sub_index < command.primary_keys.size(); ++sub_index)
		{
			if (command.contents[index].column_name == command.primary_keys[sub_index])
			{
				key_index_list.push_back(index);
				key_name_list.push_back(command.contents[index].column_name);
			}
		}

		BindParams(command, params, index, index);
	}

	for (size_t index = count; index < count + key_index_list.size(); ++index)
	{
		BindParams(command, params, index, key_index_list[index - count]);
	}
	//BindParams(command, params, count, key_index);

	sql += " where ";

	for (size_t index = 0; index < key_name_list.size(); ++index)
	{

		if (index > 0)
		{
			sql += " and ";
		}
		sql += key_name_list[index];
		sql += " = ?";
	}

	//LOG(SYS, INFO) << boost::format("[Mysql %x][%s] execute udpate %s.\n") % this % __FUNCTION__ % sql.c_str();
	query.Parse(sql.c_str());

	StmtExecute(params);

	for (size_t index = 0; index < count + command.primary_keys.size(); ++index)
	{
		free(params[index].buffer);
	}

	free(params);

	reply.row_num = 0;

	return true;
}

bool NewMysql::Save(const BaseDatabase::Command& command, BaseDatabase::Reply& reply)
{
	DBQuery &query = GetQuery();

	query.Clear();

	string sql = "insert into ";
	sql += command.name;
	sql += " (";

	int count = command.contents.size();
	MYSQL_BIND* params = (MYSQL_BIND*)malloc(sizeof(MYSQL_BIND) * count);
	memset(params, 0, sizeof(MYSQL_BIND) * count);

	for (int index = 0; index < count; ++index)
	{
		sql += command.contents[index].column_name;
		if (index != count - 1)
		{

			sql += ",";
		}
	}

	sql += ") values(";
	for (int index = 0; index < count; ++index)
	{
		if (index != count - 1)
		{
			sql += "?,";
		}
		else
		{
			sql += "?";
		}
		BindParams(command, params, index, index);
	}
	sql += ")";

	//LOG(SYS, INFO) << boost::format("[Mysql %x][%s] execute save %s.\n") % this % __FUNCTION__ % sql.c_str();

	query.Parse(sql.c_str());

	StmtExecute(params);

	for (int index = 0; index < count; ++index)
	{
		free(params[index].buffer);
	}

	free(params);

	reply.row_num = 0;

	return true;
}

bool NewMysql::Delete(const BaseDatabase::Command& command, BaseDatabase::Reply& reply)
{
	DBQuery &query = GetQuery();

	query.Clear();

	string sql = "delete from ";
	sql += command.name;
	sql += " where ";

	int count = command.contents.size();
	MYSQL_BIND* params = (MYSQL_BIND*)malloc(sizeof(MYSQL_BIND) * command.primary_keys.size());
	memset(params, 0, sizeof(MYSQL_BIND) * command.primary_keys.size());

	vector<string> key_name_list;
	vector<int> key_index_list;
	for (int index = 0; index < count; ++index)
	{
		for (size_t sub_index = 0; sub_index < command.primary_keys.size(); ++sub_index)
		{
			if (command.contents[index].column_name == command.primary_keys[sub_index])
			{
				key_index_list.push_back(index);
				key_name_list.push_back(command.contents[index].column_name);
			}
		}
	}

	for (size_t index = 0; index < key_name_list.size(); ++index)
	{

		if (index > 0)
		{
			sql += " and ";
		}
		sql += key_name_list[index];
		sql += " = ?";
	}

	for (size_t index = 0; index < key_index_list.size(); ++index)
	{
		BindParams(command, params, index, key_index_list[index]);
	}
	////LOG(SYS, INFO) << boost::format("[Mysql %x][%s] execute delete %s.\n") % this % __FUNCTION__ % sql.c_str();
	query.Parse(sql.c_str());

	StmtExecute(params);

	for (size_t index = 0; index < command.primary_keys.size(); ++index)
	{
		free(params[index].buffer);
	}

	free(params);

	reply.row_num = 0;
	return true;
}