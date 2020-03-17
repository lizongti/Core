#ifndef PROCESS_HPP
#define PROCESS_HPP

#include <iostream>
#include <boost/program_options.hpp>
#include "lime/base/singleton.hpp"

namespace lime
{
struct configuration
{
	uint16_t thread;
	std::string service;
};

class process
	: public singleton<process>
{
public:
	process &options(int argc, char *argv[])
	{
		boost::program_options::variables_map variables_map;
		boost::program_options::options_description option_description("options");
		option_description.add_options()("help,h", "describe arguments")("thread,t", boost::program_options::value<uint16_t>(), "thread")("service,s", boost::program_options::value<std::string>(), "service");
		boost::program_options::positional_options_description positional_options_description;
		positional_options_description.add("service", -1);

		try
		{
			boost::program_options::store(boost::program_options::command_line_parser(argc, argv).options(option_description).positional(positional_options_description).run(), variables_map);
			boost::program_options::notify(variables_map);
		}
		catch (std::exception const &)
		{
			std::cerr << "Incorrect command line syntax." << std::endl;
			std::cerr << "Use '--help' for a list of options." << std::endl;
			exit(-1);
		}

		if (variables_map.count("thread"))
			config.thread = variables_map["thread"].as<uint16_t>();
		if (variables_map.count("service"))
			config.service = variables_map["service"].as<std::string>();

		return *this;
	}

	process &run()
	{
		return *this;
	}

protected:
	configuration config;
};
};	 // namespace lime
#endif // !PROCESS_HPP