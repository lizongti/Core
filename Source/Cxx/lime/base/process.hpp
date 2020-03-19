#ifndef PROCESS_HPP
#define PROCESS_HPP

#include <iostream>
#include <thread>
#include <algorithm>
#include <vector>
#include <boost/program_options.hpp>

#include "lime/base/singleton.hpp"
#include "lime/base/service_queue.hpp"

namespace lime
{
struct configuration
{
	uint32_t thread;
	uint32_t service_limit;
	std::string bootstrap;
};

class process
	: public singleton<process>
{
public:
	process &options(int argc, char *argv[])
	{
		boost::program_options::variables_map variables_map;
		boost::program_options::options_description option_description("options");
		option_description.add_options()("help,h", "describe arguments")("thread,t", boost::program_options::value<uint32_t>(), "thread")("service_limit,sl", boost::program_options::value<uint32_t>(), "service_limit")("bootstrap,s", boost::program_options::value<std::string>(), "bootstrap");
		boost::program_options::positional_options_description positional_options_description;
		positional_options_description.add("bootstrap", -1);

		try
		{
			boost::program_options::store(boost::program_options::command_line_parser(argc, argv).options(option_description).positional(positional_options_description).run(), variables_map);
			boost::program_options::notify(variables_map);
		}
		catch (std::exception const &)
		{
			std::cerr << "Incorrect command line syntax." << std::endl;
			std::cerr << "Use '--help' for a list of options." << std::endl;
			exit(1);
		}

		config.thread = variables_map.count("thread") ? std::min(variables_map["thread"].as<uint32_t>(), std::thread::hardware_concurrency()) : std::thread::hardware_concurrency();
		config.service_limit = variables_map.count("service_limit") ? variables_map["service_limit"].as<uint32_t>() : 65536;
		config.bootstrap = variables_map.count("bootstrap") ? variables_map["bootstrap"].as<std::string>() : "bootstrap";

		return *this;
	}

	process &run()
	{
		service_queue::instance().reserve(config.service_limit);
		for (auto i = 0; i < config.thread; ++i)
		{
			threads.push_back(std::shared_ptr<std::thread>(new std::thread([]() {
				while (true)
				{
					auto service = service_queue::instance().pop();
					if (service)
					{
						service->work();
					}
					else
					{
						std::this_thread::sleep_for(std::chrono::milliseconds(1));
					}
				}
			})));
		}
		for (auto thread : threads)
		{
			thread->join();
		}
		return *this;
	}

protected:
	configuration config;
	std::vector<std::shared_ptr<std::thread>> threads;
};
};	 // namespace lime
#endif // !PROCESS_HPP