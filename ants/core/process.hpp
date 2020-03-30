#ifndef ANTS_CORE_PROCESS_HPP
#define ANTS_CORE_PROCESS_HPP

#include <iostream>
#include <thread>
#include <algorithm>
#include <vector>
#include <thread>
#include <boost/program_options.hpp>
#include <boost/filesystem.hpp>
#include "singleton.hpp"
#include "service.hpp"
#include "queue.hpp"
#include "thread.hpp"
#include "configuration.hpp"

namespace ants
{
namespace core
{

class process
	: public singleton<process>
{
public:
	process &options(int argc, char *argv[])
	{
		init_options(argc, argv);
		return *this;
	}

	process &run()
	{
		init_service_queue();
		init_threads();
		return *this;
	}

protected:
	void init_options(int argc, char *argv[])
	{
		singleton<configuration>::instance().options(argc, argv);
	}
	void init_service_queue()
	{
		auto config = singleton<configuration>::instance().get();
		singleton<queue<service>>::instance().malloc(config.service);
	}
	void init_threads()
	{
		thread_ids.push_back(std::this_thread::get_id());
		auto config = singleton<configuration>::instance().get();
		for (uint32_t i = 1; i < config.thread; ++i)
		{
			thread_ids.push_back((new thread())->get_id());
		}
		thread::work();
	}

protected:
	std::vector<std::thread::id> thread_ids;
};
};	   // namespace core
};	   // namespace ants
#endif // ANTS_CORE_PROCESS_HPP