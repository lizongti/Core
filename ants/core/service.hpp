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
    void work()
    {
        void *message;
        while (message = queue.pop())
        {
            module->handle()(context, message);
        }
    }

protected:
    queue<void> queue;
    std::shared_ptr<module> module;
    void *context;
};

class service_function
{
public:
    static bool __cdecl start(void *context, std::string const &service_name, std::string const &module_name)
    {
        return true;
    }

    static bool __cdecl send(void *context, std::string const &source_service_name, std::string const &destination_service_name, void *message)
    {

        return true;
    }

    static bool __cdecl stop(void *context, std::string const &service_name)
    {
        return true;
    }
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
        service->context = service->module->create()(&service_function::start, &service_function::send, &service_function::stop);
    }

    static bool unload(std::string const &service_name)
    {
        std::lock_guard<std::mutex> lock_guard(instance().mutex);
        auto &service_unordered_map = instance().service_unordered_map;
        if (service_unordered_map.find(service_name) == service_unordered_map.end())
            return true;

        auto service = service_unordered_map[service_name];
        service->module->destroy()(service->context);

        return true;
    }

protected:
    std::unordered_map<std::string, std::shared_ptr<service>> service_unordered_map;
    std::mutex mutex;
};

}; // namespace core
}; // namespace ants

#endif // ANTS_CORE_SERVICE_HPP