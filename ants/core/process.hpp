#ifndef ANTS_CORE_PROCESS_HPP
#define ANTS_CORE_PROCESS_HPP

#include <iostream>
#include <thread>
#include <algorithm>
#include <vector>
#include <thread>
#include <boost/program_options.hpp>
#include <boost/filesystem.hpp>
#include <ants/core/singleton.hpp>
#include <ants/core/service.hpp>
#include <ants/core/queue.hpp>
#include <ants/core/thread.hpp>
#include <ants/core/configuration.hpp>

namespace ants
{
namespace core
{

class process
	: public singleton<process>,
	  private boost::noncopyable
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
		configuration_loader::load(argc, argv);
	}
	void init_service_queue()
	{
		unique_queue<service>::malloc(configuration::service());
	}
	void init_threads()
	{
		thread_ids.push_back(std::this_thread::get_id());
		for (uint32_t i = 1; i < configuration::thread(); ++i)
		{
			thread_ids.push_back((new thread())->get_id());
		}
		service_loader::load("bootstrap", configuration::bootstrap());
		thread::work();
	}

protected:
	std::vector<std::thread::id> thread_ids;
};
};	   // namespace core
};	   // namespace ants
#endif // ANTS_CORE_PROCESS_HPP