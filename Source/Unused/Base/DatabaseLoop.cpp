#include "DatabaseLoop.h"

DatabaseLoop::DatabaseLoop()
{
	uv_async_init(loop_, &command_async_, command_async_cb_);
	command_async_.data = this;
}

DatabaseLoop::~DatabaseLoop()
{
}

bool DatabaseLoop::Init(const DBInterface::Config& mysql_conf, const NewRedis::Config& redis_conf)
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

	return Loop::Init(false, nullptr);
}

bool DatabaseLoop::Start()
{
	if (!redis_.Start())
	{
		return false;
	}


	return Loop::Start();
}

bool DatabaseLoop::Stop()
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

bool DatabaseLoop::Running()
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

bool DatabaseLoop::Write(const BaseDatabase::CommandSet& command_set)
{
	if (!command_set_queue_.push(command_set))
	{
		LOG(SYS, ERROR) << boost::format("[DatabaseLoop %x][%s] command queue is full.\n") % this % __FUNCTION__;
		return false;
	}

	return (uv_async_send(&command_async_) == 0);
}

bool DatabaseLoop::Read(BaseDatabase::ReplySet& reply_set)
{
	if (!reply_set_queue_.pop(reply_set))
	{
		return false;
	}
	return true;
}

bool DatabaseLoop::Execute(const BaseDatabase::Command& command, BaseDatabase::Reply& reply)
{
	if (command.name == "heart_beat")
	{
		mysql_.Load(command, reply);
		redis_.Ping();
		return true;
	}
	if (command.action == "update")
	{
		//BaseDatabase::Reply mysql_reply = reply;
		//mysql_.Update(command, mysql_reply);

		//BaseDatabase::Reply redis_reply = reply;
		if (DbInfoManager::instance()->NeedLoad(command))
		{
			mysql_.Load(command, reply);
			if (reply.row_num > 0)
			{
				redis_.SaveDbKey(command, reply);
				redis_.SaveFromReply(command, reply);
			}
		}
		redis_.Update(command, reply);
		return true;
	}
	if (command.action == "load")
	{
		redis_.Load(command, reply);
		if (reply.row_num == 0)
		{
			mysql_.Load(command, reply);
			if (reply.row_num > 0)
			{
				redis_.SaveDbKey(command, reply);
				redis_.SaveFromReply(command, reply);
			}
		}

		return true;
	}
	if (command.action == "save")
	{
		//LOG(SYS, INFO) << boost::format("[DatabaseLoop %x][%s] execute sql save begin1.\n") % this % __FUNCTION__;
		if (DbInfoManager::instance()->NeedLoad(command))
		{
			//LOG(SYS, INFO) << boost::format("[DatabaseLoop %x][%s] execute sql save begin2.\n") % this % __FUNCTION__;
			mysql_.Load(command, reply);
			if (reply.row_num > 0)
			{
				//LOG(SYS, INFO) << boost::format("[DatabaseLoop %x][%s] execute sql save begin3.\n") % this % __FUNCTION__;
				redis_.SaveDbKey(command, reply);
				redis_.SaveFromReply(command, reply);
			}
			else
			{
				mysql_.Save(command, reply);
				mysql_.Load(command, reply);
				if (reply.row_num > 0)
				{
					redis_.SaveDbKey(command, reply);
					redis_.SaveFromReply(command, reply);
				}
			}
		}
		//LOG(SYS, INFO) << boost::format("[DatabaseLoop %x][%s] execute sql save begin4.\n") % this % __FUNCTION__;
		//redis_.SaveFromCommand(command, reply);

		return true;
	}
	if (command.action == "delete")
	{
		if (DbInfoManager::instance()->NeedLoad(command))
		{
			mysql_.Load(command, reply);
			if (reply.row_num > 0)
			{
				redis_.SaveDbKey(command, reply);
				redis_.SaveFromReply(command, reply);
			}
		}
		//mysql_.Delete(command, reply);
		redis_.Delete(command, reply);
		return true;
	}
	return false;
}

void DatabaseLoop::command_async_callback(uv_async_t* handle)
{
	//cout << "command_async_callback begin:" << static_cast<long int>(time(NULL)) << endl;
	while (true)
	{
		BaseDatabase::CommandSet command_set;
		if (!command_set_queue_.pop(command_set))
		{
			//cout << "command_async_callback 11" << endl;
			return;
		}
		//cout << "command_async_callback 22 id:" << command_set.id << endl;
		/*
		for (int index = 0; index < command_set.commands.size(); ++index)
		{
			cout << "name is:" << command_set.commands[index].name << "action is:" << command_set.commands[index].action << endl;
		}
		*/
		BaseDatabase::ReplySet reply_set;
		reply_set.id = command_set.id;

		for (unsigned int index = 0; index < command_set.commands.size(); ++index)
		{
			BaseDatabase::Command& command = command_set.commands[index];
			for (vector<string>::iterator iteM = command.primary_keys.begin(); iteM != command.primary_keys.end(); ++iteM)
			{
				string key = *iteM;
			}
			for (vector<BaseDatabase::CommandContent>::iterator iteM = command.contents.begin(); iteM != command.contents.end(); ++iteM)
			{
				BaseDatabase::CommandContent& content = *iteM;
			}

			BaseDatabase::Reply reply;
			if (!Execute(command, reply))
			{
				LOG(SYS, ERROR) << boost::format("[DatabaseLoop %x][%s] mysql execute fail.\n") % this % __FUNCTION__;
			}
			reply_set.replies.push_back(reply);
		}

		if (!reply_set_queue_.push(reply_set))
		{
			LOG(SYS, ERROR) << boost::format("[DatabaseLoop %x][%s] reply queue is full.\n") % this % __FUNCTION__;
		}
	}
}

void DatabaseLoop::static_command_async_callback(uv_async_t* handle)
{
	((DatabaseLoop*)handle->data)->command_async_callback(handle);
}

