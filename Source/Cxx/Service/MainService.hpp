#ifndef MAIN_SERVICE_HPP
#define MAIN_SERVICE_HPP

#include "../Base/BaseHeaders.h"
#include "../Service/DispatcherService.hpp"
#include <stdlib.h>
#include <cstdlib>

class MainService
	: public Service
{
public:
	struct Config
	{
		Config(){};
		std::string file = "main";
	};
	MainService()
	{
	}

	virtual ~MainService()
	{
	}

	bool Init(Config conf = Config())
	{
		conf.file = Resource<std::string, std::string>::Get(STRING_INSTANCE_NAME);
		conf_ = conf;

		if (!loop::Init(false, nullptr))
		{
			return false;
		}

		uv_async_init(loop_, &boot_finished_async_, boot_finished_async_cb_);
		boot_finished_async_.data = this;

		return true;
	}

	bool Start()
	{
		std::string path_file = (boost::format("%s/../Config/%s.lua") %
								 Resource<std::string, std::string>::Get(STRING_WORK_DIRECTORY) %
								 conf_.file)
									.str();

		LOG(SYS, INFO) << boost::format("[MainService %x][%s]path_file:%s\n") % this % __FUNCTION__ % path_file.c_str();

		if (!lua_state_.Init(path_file))
		{
			return false;
		}

		if (!lua_state_.Start())
		{
			return false;
		}

		if (!loop::Start())
		{
			return false;
		}

		uv_async_send(&boot_finished_async_);
		while (true)
		{
			uv_run(uv_default_loop(), UV_RUN_ONCE);
		}

		return true;
	}

	bool Stop()
	{
		if (!lua_state_.Stop())
		{
			return false;
		}
		if (!loop::Stop())
		{
			return false;
		}
		return true;
	}

	bool Running()
	{
		if (!lua_state_.Running())
		{
			return false;
		}
		if (!loop::Running())
		{
			return false;
		}
		return true;
	}

protected:
	virtual void boot_finished_async_callback(uv_async_t *handle)
	{
		if (Resource<uv_loop_t *>::Count() > 0)
		{
			uv_async_send(&boot_finished_async_);
		}
		else
		{
			Service *logger_service = Resource<std::string, Service>::Find("LoggerService");
			if (logger_service != nullptr)
			{
				((LoggerService *)logger_service)->BootFinish();
			}
		}
	}

protected:
	static void static_boot_finished_async_callback(uv_async_t *handle)
	{
		((MainService *)handle->data)->boot_finished_async_callback(handle);
	}

protected:
	LuaState lua_state_;
	Config conf_;
	uv_async_t boot_finished_async_;
	uv_async_cb boot_finished_async_cb_ = &static_boot_finished_async_callback;
};

#endif // !MAIN_SERVICE_HPP