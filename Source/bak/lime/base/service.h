#ifndef SERVICE_H
#define SERVICE_H
#include <set>
#include <string>
#include <iostream>
#include <atomic>

#include <boost/lockfree/queue.hpp>

#include "Logger.h"

class service
{
public:
	virtual ~Service() = 0;

public:
	virtual bool init(const std::string &json) = 0;

	virtual bool callback(const std::string &sender, MessageType type, void *data) = 0;

	virtual bool release() = 0;
};

// public:
// template <std::string SERVICE_NAME>
// static Service *Create(const std::string &service_config)
// {
// 	return nullptr;
// }

// static bool Send(const std::string &service_name, void *message);

#define REIGSTER_SERVICE(SERVICE_NAME)                                         \
	template <>                                                                \
	Service *Service::Create<#SERVICE_NAME>(const std::string &service_config) \
	{                                                                          \
		auto service = object_pool<SERVICE_NAME>::new ();                      \
		if (!service->Parse(service_config))                                   \
		{                                                                      \
			object_pool<SERVICE_NAME>::delete (service);                       \
			return nullptr;                                                    \
		}                                                                      \
		Resource<std::string, Service>::Insert(#SERVICE_NAME, service);        \
		return service;                                                        \
	}

#endif // !SERVICE_H