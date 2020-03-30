#ifndef ANTS_CORE_CONFIGURATION_HPP
#define ANTS_CORE_CONFIGURATION_HPP

#include <iostream>
#include <vector>
#include <boost/program_options.hpp>
#include <boost/filesystem.hpp>
#include <boost/filesystem/fstream.hpp>
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/ini_parser.hpp>
#include <boost/algorithm/string.hpp>

namespace ants
{
namespace core
{
struct config
{
    uint32_t thread;
    uint32_t service;
    std::vector<std::string> path;
    std::string bootstrap;
};

class config_initializer
{
public:
    static void init_thread(boost::program_options::variables_map const &variables_map,
                            boost::property_tree::ptree const &ptree,
                            uint32_t &thread)
    {
        uint32_t max_value = std::thread::hardware_concurrency();
        uint32_t min_value = 1;
        uint32_t default_value = std::thread::hardware_concurrency();
        if (variables_map.count("thread"))
        {
            uint32_t variables_map_value = variables_map["thread"].as<uint32_t>();
            thread = std::min(std::max(variables_map_value, min_value), max_value);
        }
        else if (ptree.count("system") > 0 && ptree.get_child("system").count("thread") > 0)
        {
            uint32_t config_value = ptree.get_child("system").get<uint32_t>("thread");
            thread = std::min(std::max(config_value, min_value), max_value);
        }
        else
        {
            thread = default_value;
        }
        std::cout << "[Configuration] thread value is " << thread << std::endl;
    };
    static void init_service(boost::program_options::variables_map const &variables_map,
                             boost::property_tree::ptree const &ptree,
                             uint32_t &service)
    {
        uint32_t max_value = 65534;
        uint32_t min_value = 1;
        uint32_t default_value = 65534;
        if (variables_map.count("service"))
        {
            uint32_t variables_map_value = variables_map["thread"].as<uint32_t>();
            service = std::min(std::max(variables_map_value, min_value), max_value);
        }
        else if (ptree.count("system") > 0 && ptree.get_child("system").count("service") > 0)
        {
            uint32_t config_value = ptree.get_child("system").get<uint32_t>("service");
            service = std::min(std::max(config_value, min_value), max_value);
        }
        else
        {
            service = default_value;
        }
        std::cout << "[Configuration] service value is " << service << std::endl;
    };
    static void init_path(boost::program_options::variables_map const &variables_map,
                          boost::property_tree::ptree const &ptree,
                          std::vector<std::string> &path)
    {
        path.push_back(boost::filesystem::initial_path<boost::filesystem::path>().string());
        if (variables_map.count("path"))
        {
            std::vector<std::string> variables_map_value = variables_map["path"].as<std::vector<std::string>>();
            for (auto p : variables_map_value)
            {
                path.push_back(p);
            }
        }
        if (ptree.count("system") > 0 && ptree.get_child("system").count("bootstrap") > 0)
        {
            std::vector<std::string> config_value;
            boost::split(config_value, ptree.get_child("system").get<std::string>("bootstrap"), boost::is_any_of(";"), boost::token_compress_on);
            for (auto p : config_value)
            {
                path.push_back(p);
            }
        }
        std::cout << "[Configuration] path value is " << boost::algorithm::join(path, ";") << std::endl;
    };
    static void init_bootstrap(boost::program_options::variables_map const &variables_map,
                               boost::property_tree::ptree const &ptree,
                               std::string &bootstrap)
    {

        if (variables_map.count("bootstrap"))
        {
            std::string variables_map_value = variables_map["bootstrap"].as<std::string>();
            if (boost::filesystem::exists(variables_map_value))
            {
                bootstrap = variables_map_value;
                std::cout << "[Configuration] bootstrap value is " << bootstrap << std::endl;
                return;
            }
            else
            {
                std::cerr << "[Configuration] bootstrap file" << variables_map_value << " not found!" << std::endl;
                exit(1);
            }
        }
        if (ptree.count("system") > 0 && ptree.get_child("system").count("bootstrap") > 0)
        {
            std::string config_value = ptree.get_child("system").get<std::string>("bootstrap");
            if (boost::filesystem::exists(config_value))
            {
                bootstrap = config_value;
                std::cout << "[Configuration] bootstrap value is " << bootstrap << std::endl;
                return;
            }
            else
            {
                std::cerr << "[Configuration] bootstrap file" << config_value << " not found!" << std::endl;
                exit(1);
            }
        }
        else
        {
            std::string default_value = "bootstrap";
            if (boost::filesystem::exists(default_value))
            {
                bootstrap = default_value;
                std::cout << "[Configuration] bootstrap value is " << bootstrap << std::endl;
                return;
            }
            else
            {
                std::cerr << "[Configuration] bootstrap file " << default_value << " not found!" << std::endl;
                exit(1);
            }
        }
    };
};

class configuration
{
public:
    configuration(){};
    virtual ~configuration(){};

public:
    void options(int argc, char *argv[])
    {
        prepare_option_description();
        prepare_positional_options_description();
        generate_variables_map(argc, argv);
        process_help();
        process_config_tree();
        init_config();
    }

    config &get()
    {
        return config;
    }

protected:
    void prepare_option_description()
    {
        auto init = options_description.add_options();
        init("help,h", "Display this help and exit.");
        init("config,config", boost::program_options::value<std::string>(),
             "Set the path of the config file.");
        init("thread,t", boost::program_options::value<uint32_t>(),
             "Set the number of threads, which cannot be over default value(units of processors).");
        init("service,s", boost::program_options::value<uint32_t>(),
             "Set the max of service, which cannot be over default value(65534).");
        init("bootstrap,b", boost::program_options::value<std::string>(),
             "Set the module name of the boostrap service.");
        init("path,p", boost::program_options::value<std::vector<std::string>>(),
             "Set a list of paths for searching module.");
    }

    void prepare_positional_options_description()
    {
        positional_options_description.add("bootstrap", -1);
    }

    void generate_variables_map(int argc, char *argv[])
    {
        try
        {
            boost::program_options::store(
                boost::program_options::command_line_parser(argc, argv)
                    .options(options_description)
                    .positional(positional_options_description)
                    .run(),
                variables_map);
            boost::program_options::notify(variables_map);
        }
        catch (std::exception const &e)
        {
            std::cerr << e.what() << std::endl;
            std::cerr << "Incorrect command line syntax." << std::endl;
            std::cerr << "Use '--help' for a list of options." << std::endl;

            exit(1);
        }
    }

    void process_help()
    {
        if (variables_map.count("help"))
        {
            std::cout << "Usage: server [OPTIONS]... [boostrap]" << std::endl
                      << std::endl
                      << options_description << std::endl;
            exit(0);
        }
    }

    void process_config_tree()
    {
        std::string path;

        if (variables_map.count("config"))
        {
            path = variables_map["config"].as<std::string>();
            if (!boost::filesystem::exists(path))
            {
                std::cerr << "Config file not found in path: "
                          << path << std::endl;
                exit(1);
            }
        }
        else
        {
            path = "ants.conf";
            if (!boost::filesystem::exists(path))
            {
                return;
            }
        }

        std::cout << "Parsing config " << path << std::endl;

        try
        {
            boost::property_tree::ini_parser::read_ini(path, ptree);
        }
        catch (std::exception const &e)
        {
            std::cerr << e.what() << std::endl;
            std::cerr << "Parsing config " << path << " error" << std::endl;
        }
    }

    void init_config()
    {
        config_initializer::init_thread(variables_map, ptree, config.thread);
        config_initializer::init_service(variables_map, ptree, config.service);
        config_initializer::init_path(variables_map, ptree, config.path);
        config_initializer::init_bootstrap(variables_map, ptree, config.bootstrap);
    }

protected:
    boost::program_options::options_description options_description;
    boost::program_options::positional_options_description positional_options_description;
    boost::program_options::variables_map variables_map;
    boost::property_tree::ptree ptree;

    config config;
};

};     // namespace core
};     // namespace ants
#endif // ANTS_CORE_CONFIGURATION_HPP