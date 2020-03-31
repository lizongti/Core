#ifndef ANTS_CORE_SERVICE_HPP
#define ANTS_CORE_SERVICE_HPP

#include <ants/core/queue.hpp>
#include <ants/core/module.hpp>
#include <ants/core/singleton.hpp>

namespace ants
{
namespace core
{

class service
{
    friend class service_loader;

public:
    void start(std::string const &service_name){

        // module->init()(service_name);
        //check service name, check module name
        // get file name
    };

    void work()
    {
        void *message;
        while (message = queue.pop())
        {
            // module.work(message);
        }
    }

    void stop()
    {
        //thread_safe
    }

protected:
    queue<void> queue;
    std::shared_ptr<module> module;
};

class service_loader
    : public singleton<service_loader>
{
public:
    static std::shared_ptr<service> load(std::string const &service_name, std::string const &module_name)
    {
        std::lock_guard<std::mutex> lock_guard(instance().mutex);
        auto &service_unordered_map = instance().service_unordered_map;
        if (service_unordered_map.find(service_name) != service_unordered_map.end())
            return service_unordered_map[service_name];

        auto service = std::shared_ptr<ants::core::service>(new ants::core::service());
        service_unordered_map[service_name] = service;

        service->module = module_loader::load(module_name);
        service->module->init()();
    }

protected:
    std::unordered_map<std::string, std::shared_ptr<service>> service_unordered_map;
    std::mutex mutex;
};

class service_function
{
public:
    static bool send(service *service, uint32_t base_id, uint32_t service_id, void *message)
    {
    }
};

}; // namespace core
}; // namespace ants

#endif // ANTS_CORE_SERVICE_HPP