#ifndef ANTS_CORE_SERVICE_HPP
#define ANTS_CORE_SERVICE_HPP

#include <array>
#include <atomic>
#include <mutex>
#include <unordered_map>
#include <shared_mutex>
#include <boost/noncopyable.hpp>
#include <ants/core/queue.hpp>
#include <ants/core/module.hpp>
#include <ants/core/singleton.hpp>
#include <ants/core/error.hpp>

namespace ants
{
namespace core
{

class service
    : public std::enable_shared_from_this<service>
{
public:
    void create(const std::string &module_name,
                const std::string &service_name) //, void *function_array[])
    {
        module = module_loader::load(module_name);
        context = std::shared_ptr<void>(
            module->create()(service_name.c_str()),
            [this](void *context) {
                this->module->destroy()(context);
            });
    }

    void work()
    {
        decltype(shared_queue.size()) size;
        {
            std::lock_guard<std::mutex> lock(mutex);
            outside = true;
            working = true;
            size = shared_queue.size();
        }

        while (size--)
        {
            std::shared_ptr<void> message;
            while (message = shared_queue.pop())
            {
                module->handle()(static_cast<void *>(context.get()),
                                 static_cast<void *>(message.get()));
            }
        }

        std::lock_guard<std::mutex> lock(mutex);
        working = false;
        if (!working && outside && !shared_queue.empty())
        {
            static_shared_queue<ants::core::service>::push(shared_from_this());
            outside = false;
        }
    }

    void push(void *message)
    {
        shared_queue.push(std::shared_ptr<void>(message, [](void *message) {
            free(message);
        }));

        std::lock_guard<std::mutex> lock(mutex);
        if (!working && outside && !shared_queue.empty())
        {
            static_shared_queue<ants::core::service>::push(shared_from_this());
            outside = false;
        }
    }

    void destroy() {}

private:
    std::string name;
    std::shared_ptr<void> context;
    std::shared_ptr<module> module;

    shared_queue<void> shared_queue;
    bool outside = false;
    bool working = false;
    mutable std::mutex mutex;
};

class service_loader
    : public singleton<service_loader>,
      private boost::noncopyable
{

public:
    static bool __cdecl start(const char *module_name,
                              const char *service_name)
    {
        return service_loader::load(module_name, service_name) != nullptr;
    }

    static bool __cdecl send(const char *service_name,
                             void *message)
    {
        return service_loader::push(service_name, message) != nullptr;
    }

    static bool __cdecl stop(const char *service_name)
    {
        return service_loader::unload(service_name) != nullptr;
    }

    static std::shared_ptr<service> load(std::string const &module_name,
                                         std::string const &service_name)
    {
        std::lock_guard<std::shared_mutex> lock(instance().shared_mutex);

        auto &service_unordered_map = instance().service_unordered_map;
        if (service_unordered_map.find(service_name) != service_unordered_map.end())
            return service_unordered_map[service_name];

        auto service = std::shared_ptr<ants::core::service>(new ants::core::service());
        service_unordered_map[service_name] = service;

        service->create(module_name, service_name);

        return service;
    }

    static std::shared_ptr<service> push(std::string const &service_name,
                                         void *message)
    {
        std::shared_lock<std::shared_mutex> lock(instance().shared_mutex);

        auto &service_unordered_map = instance().service_unordered_map;
        if (service_unordered_map.find(service_name) == service_unordered_map.end())
            return nullptr;

        auto service = service_unordered_map[service_name];

        service->push(message);

        return service;
    }

    static std::shared_ptr<service> unload(std::string const &service_name)
    {
        std::lock_guard<std::shared_mutex> lock(instance().shared_mutex);

        auto &service_unordered_map = instance().service_unordered_map;
        if (service_unordered_map.find(service_name) == service_unordered_map.end())
            return nullptr;

        auto service = service_unordered_map[service_name];
        service_unordered_map.erase(service_name);

        service->destroy();

        return service;
    }

protected:
    std::unordered_map<std::string, std::shared_ptr<service>> service_unordered_map;
    mutable std::shared_mutex shared_mutex;
};

}; // namespace core
}; // namespace ants

#endif // ANTS_CORE_SERVICE_HPP