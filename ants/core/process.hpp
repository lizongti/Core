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

namespace ants
{
namespace core
{
struct configuration
{
	uint32_t thread;
	uint32_t service;
	std::string bootstrap;
	std::string path;
};

class process
	: public singleton<process>
{
public:
	process &options(int argc, char *argv[])
	{
		std::cout << "Working directory is " << boost::filesystem::initial_path<boost::filesystem::path>().string() << std::endl;
		boost::program_options::variables_map variables_map;
		boost::program_options::options_description option_description("Allowed options");
		option_description.add_options()("help,h", "describe arguments");
		option_description.add_options()("thread,t", boost::program_options::value<uint32_t>(), "The number of threads that current process would run. It can be no more than the number of processors.");
		option_description.add_options()("service,s", boost::program_options::value<uint32_t>(), "The limit of service that the process could run. It can be no more than 65534.");
		option_description.add_options()("bootstrap,", boost::program_options::value<std::string>(), "The first service which would init from `bootstrap` module.");
		// option_description.add_options()("path,p", boost::program_options::value<std::vector<std::string>>(), "path");
		boost::program_options::positional_options_description positional_options_description;
		positional_options_description.add("bootstrap", -1);
		try
		{
			boost::program_options::store(boost::program_options::command_line_parser(argc, argv).options(option_description).positional(positional_options_description).run(), variables_map);
			boost::program_options::notify(variables_map);
		}
		catch (std::exception const &e)
		{
			std::cerr << e.what() << std::endl;
			std::cerr << "Incorrect command line syntax." << std::endl;
			std::cerr << "Use '--help' for a list of options." << std::endl;

			exit(1);
		}

		config.thread = variables_map.count("thread") ? std::min(variables_map["thread"].as<uint32_t>(), std::thread::hardware_concurrency()) : std::thread::hardware_concurrency();
		config.service = variables_map.count("service") ? std::min(variables_map["service"].as<uint32_t>(), uint32_t(65534)) : 65534;
		config.bootstrap = variables_map.count("bootstrap") ? variables_map["bootstrap"].as<std::string>() : "bootstrap";

		std::cout << "Configuration thread is " << config.thread << std::endl;
		std::cout << "Configuration service is " << config.service << std::endl;
		std::cout << "Configuration bootstrap is " << config.bootstrap << std::endl;

		return *this;
	}

	process &run()
	{
		init_service_queue();
		init_threads();
		join_threads();
		return *this;
	}

protected:
	void init_service_queue()
	{
		singleton<queue<service>>::instance().malloc(config.service);
	}
	void init_threads()
	{
		for (uint32_t i = 0; i < config.thread; ++i)
		{
			threads.push_back(std::shared_ptr<thread>(new thread()));
		}
	}
	void join_threads()
	{
		for (auto thread : threads)
		{
			thread->join();
		}
	}

protected:
	configuration config;
	std::vector<std::shared_ptr<thread>> threads;
};
};	   // namespace core
};	   // namespace ants
#endif // ANTS_CORE_PROCESS_HPP