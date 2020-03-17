#ifndef LOG_H
#define LOG_H

#include <string>
#include <iostream>

namespace lime
{
struct log
{
	enum level
	{
		FATAL = 1,
		ERROR,
		WARN,
		INFO,
		DEBUG
	};
	level level;
	std::string content;
};

class stream_log
	: public std::basic_stringstream<char,
									 std::char_traits<char>>
{
public:
	stream_log(log::level level, const std::string &logger_name = "system")
	{
		log_ = pool::new<Log>();
		log_->level = level;
		service_name_ = (boost::format("logger.") % logger_name).str();
	};

	virtual ~StreamLog()
	{
		m_Log->content = str();
		service::send(service_name_, service::MSG_TYPE_PTR, log_, stream_log::default_handler);
	};

	static void default_handler(service::message_type msg_type, void *data)
	{
		if (msg_type == service::MSG_TYPE_PTR)
		{
			auto l = reinterpret_cast<log *>(data);
			if (l->level == log::ERROR || l->level == log::FATAL)
			{
				std::cerr << l->content << std::endl;
			}
			else
			{
				std::cout << l->content << std::endl;
			}
		}
	}

private:
	log *log_;
	std::string service_name_;
};

#define LOG(LOGGER, LEVEL) StreamLog(log::LEVEL, #LOGGER)
#define LOG(LEVEL) StreamLog(log::LEVEL)
} // namespace lime
#endif // !LOG_HPP
