#ifndef BASE_DATABASE_HPP
#define BASE_DATABASE_HPP

#include <string>
#include <queue>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <iostream>
#include "Logger.h"
using namespace std;


class BaseDatabase
{
public:
	struct Record
	{
		std::string id;
		uint32_t size;
	};
	struct CommandContent
	{
		string column_name;
		string value;
		string type;
	};
	struct Command
	{
		string name;
		string action;
		vector<string> keylist;
		vector<string> primary_keys;
		vector<CommandContent> contents;
	};
	struct CommandSet
	{
		string id;
		vector<Command> commands;
	};
	struct ReplyContent
	{
		string column_name;
		string value;
	};
	struct Reply
	{
		Reply()
		{
			Clear();
		}
		uint32_t row_num;
		string name;
		std::vector<std::vector<ReplyContent> > data_set;
		void Clear()
		{
			data_set.clear();
			row_num = 0;
		}
		void Print()
		{
			LOG(SYS, INFO) << boost::format("[Reply %x][%s] row_num:%d, name is:%s.\n") % this % __FUNCTION__% row_num % name.c_str();
			for (int index = 0; index < data_set.size(); ++index)
			{
				for (int reply_index = 0; reply_index < data_set[index].size(); ++reply_index)
				{
					ReplyContent& reply_content = data_set[index][reply_index];
					LOG(SYS, INFO) << boost::format("[Reply %x][%s] column_name:%s, value is:%s.\n") % this % __FUNCTION__% reply_content.column_name % reply_content.value;
				}
			}
		}
	};
	struct ReplySet
	{
		string id;
		vector<Reply> replies;
	};
};



#endif