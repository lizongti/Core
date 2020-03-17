
#include "RedisService.h"

RedisService::RedisService()
{
}

RedisService::~RedisService()
{
}

bool RedisService::init(const std::string &json)
{
	std::string properties;
	std::string logger;
	CONFIG_CREATE_DOCUMENT(json, root);
	CONFIG_READ_MEMBER(root, "properties", properties);
	CONFIG_READ_MEMBER(root, "logger", logger);

	log4cplus::PropertyConfigurator::doConfigure(LOG4CPLUS_TEXT(((boost::format("%s/../Config/%s/%s") %
							 Resource<std::string, std::string>::Get(STRING_WORK_DIRECTORY) %
							 Resource<std::string, std::string>::Get(STRING_ENVIROMENT_VARIABLE) %
							 properties).str()));

	logger_ = log4cplus::Logger::getInstance(LOG4CPLUS_TEXT(logger));

	return true;
}

bool RedisService::handle(void *log)
{
	assert(log);

	switch (log->level)
	{
	case log::FATAL:
		LOG4CPLUS_FATAL(logger_, log->content.c_str());
		break;
	case log::ERROR:
		LOG4CPLUS_ERROR(logger_, log->content.c_str());
		break;
	case log::WARN:
		LOG4CPLUS_WARN(logger_, log->content.c_str());
		break;
	case log::INFO:
		LOG4CPLUS_INFO(logger_, log->content.c_str());
		break;
	case log::DEBUG:
		LOG4CPLUS_DEBUG(logger_, log->content.c_str());
		break;
	}

	object_pool<log>::delete(message);
	return true;
}