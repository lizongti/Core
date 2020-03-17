#include "Service.h"

Service::Service() {}

~Service::Service() {}

bool Service::Send(const std::string &service_name, void *message)
{
	auto service = Resource<std::string, Service>::Find(service_name);
	if (!service)
	{
		return false;
	}
	if (!service->push(message))
	{
		return false;
	}
	return true;
}

bool Service::callback(MessageType type, void *data)
{
	return true;
}

bool Service::Init(uv_loop_t *loop, const std::string &json)
{
	std::lock_guard<std::mutex> lock(mutex_);

	return init(json);
};

bool Service::Close()
{
	std::lock_guard<std::mutex> lock(mutex_);
	return close();
}

bool Service::Running() const
{
	return running();
}

bool Service::init(const std::string &json)
{
	return true;
};

void Service::static_async_push_callback(uv_async_t *handle)
{
	((loop *)handle->data)->async_push_callback(handle);
}

void Service::async_push_callback(uv_async_t *handle)
{
	void *msg = nullptr;
	while (channel_.pop(msg))
	{
		handle(msg);
	}
}

#endif // !SERVICE_HPP

// bool Service::push(void *message)
// {
// 	if (!channel_.push(message))
// 	{
// 		return false;
// 	}
// 	uv_async_send(async_push_);
// 	return true;
// }