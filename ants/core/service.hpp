#ifndef ANTS_CORE_SERVICE_HPP
#define ANTS_CORE_SERVICE_HPP

#include <array>
#include <unordered_map>
#include <ants/core/queue.hpp>
#include <ants/core/module.hpp>
#include <ants/core/singleton.hpp>
#include <ants/core/error.hpp>

namespace ants
{
namespace core
{

class service
{
public:
    bool create(std::string const &module_name, std::string const &service_name, void *function_array[])
    {
        module = module_loader::load(module_name);
        context = module->create()(service_name.c_str(), function_array);
        return true;
    }

    void work()
    {
        void *message;
        while (message = queue.pop())
        {
            module->handle()(context, message);
        }
    }

    bool push(void *message)
    {
        return queue.push(message);
    }

    bool destroy()
    {
        module->destroy()(context);
        return true;
    }

protected:
    std::string name;
    void *context;

    queue<void> queue;
    std::shared_ptr<module> module;
};

class service_loader
    : public singleton<service_loader>,
      private boost::noncopyable
{
    class service_function
    {
    public:
        static bool __cdecl start(const char *source_service_name,
                                  const char *destination_service_name,
                                  const char *destination_module_name)
        {
            auto service = service_loader::load(destination_service_name, destination_module_name);
            return true;
        }

        static bool __cdecl send(const char *source_service_name,
                                 const char *destination_service_name,
                                 void *message)
        {
            auto service = service_loader::find(destination_service_name);
            if (!service)
                return false;
            return service->push(message);
        }

        static bool __cdecl stop(const char *source_service_name,
                                 const char *destination_service_name)
        {
            service_loader::unload(destination_service_name);
            return true;
        }
    };

public:
    static std::shared_ptr<service> load(std::string const &service_name,
                                         std::string const &module_name)
    {
        std::lock_guard<std::shared_mutex> _(instance().shared_mutex);

        auto &service_unordered_map = instance().service_unordered_map;
        if (service_unordered_map.find(service_name) != service_unordered_map.end())
            return service_unordered_map[service_name];

        auto service = std::shared_ptr<ants::core::service>(new ants::core::service());
        service_unordered_map[service_name] = service;

        void *function_array[] = {&service_function::start,
                                  &service_function::send,
                                  &service_function::stop};

        service->create(module_name, service_name, function_array);

        return service;
    }

    static std::shared_ptr<service> find(std::string const &service_name)
    {
        std::shared_lock<std::shared_mutex> _(instance().shared_mutex);

        auto &service_unordered_map = instance().service_unordered_map;
        if (service_unordered_map.find(service_name) != service_unordered_map.end())
            return service_unordered_map[service_name];

        return nullptr;
    }

    static bool unload(std::string const &service_name)
    {
        std::lock_guard<std::shared_mutex> _(instance().shared_mutex);

        auto &service_unordered_map = instance().service_unordered_map;
        if (service_unordered_map.find(service_name) == service_unordered_map.end())
            return true;

        auto service = service_unordered_map[service_name];

        service->destroy();

        service_unordered_map.erase(service_name);

        return true;
    }

protected:
    std::unordered_map<std::string, std::shared_ptr<service>> service_unordered_map;
    mutable std::shared_mutex shared_mutex;
};

}; // namespace core
}; // namespace ants

#endif // ANTS_CORE_SERVICE_HPP