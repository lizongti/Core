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
#include <ants/core/message.hpp>
#include <ants/def/event.h>

namespace ants
{
namespace core
{

class service
    : public std::enable_shared_from_this<service>
{
public:
    bool load(const std::string &module_name,
              const std::string &service_name) //, void *function_array[])
    {
        module = module_loader::load(module_name);
        context = std::shared_ptr<void>(
            module->create(service_name.c_str()),
            [this](void *context) {
                this->module->destroy(context);
            });

        push(std::shared_ptr<message>(new message{
            ants::def::Event::Init, service_name, service_name, nullptr}));

        return true;
    }

    bool work()
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
            std::shared_ptr<ants::core::message> message;
            while (message = shared_queue.pop())
            {
                module->handle(static_cast<void *>(context.get()),
                               static_cast<int>(message->event()),
                               const_cast<char*>(message->source().c_str()),
                               message->data());
            }
        }

        std::lock_guard<std::mutex> lock(mutex);
        working = false;
        if (!working && outside && !shared_queue.empty())
        {
            static_shared_queue<service>::push(shared_from_this());
            outside = false;
        }

        return true;
    }

    bool push(std::shared_ptr<ants::core::message> message)
    {
        shared_queue.push(message);

        std::lock_guard<std::mutex> lock(mutex);
        if (!working && outside && !shared_queue.empty())
        {
            static_shared_queue<service>::push(shared_from_this());
            outside = false;
        }

        return true;
    }

    bool unload()
    {
        return true;
    }

private:
    std::string name;
    std::shared_ptr<void> context;
    std::shared_ptr<module> module;

    shared_queue<message> shared_queue;
    bool outside = true;
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

    static bool __cdecl send(void *context,
                             const char *source,
                             const char *destination,
                             void *data)
    {
        auto message = new ants::core::message{ants::def::Event::Send, source, destination, data};
        auto service_name = destination; // need parse
        return service_loader::push(destination, message) != nullptr;
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

        return service->load(module_name, service_name) ? service : nullptr;
    }

    static std::shared_ptr<service> push(std::string const &service_name,
                                         ants::core::message *message)
    {
        std::shared_lock<std::shared_mutex> lock(instance().shared_mutex);

        auto &service_unordered_map = instance().service_unordered_map;
        if (service_unordered_map.find(service_name) == service_unordered_map.end())
            return nullptr;

        auto service = service_unordered_map[service_name];

        return service->push(std::shared_ptr<ants::core::message>(message))
                   ? service
                   : nullptr;
    }

    static std::shared_ptr<service> unload(std::string const &service_name)
    {
        std::lock_guard<std::shared_mutex> lock(instance().shared_mutex);

        auto &service_unordered_map = instance().service_unordered_map;
        if (service_unordered_map.find(service_name) == service_unordered_map.end())
            return nullptr;

        auto service = service_unordered_map[service_name];
        service_unordered_map.erase(service_name);

        return service->unload() ? service : nullptr;
    }

protected:
    std::unordered_map<std::string, std::shared_ptr<service>> service_unordered_map;
    mutable std::shared_mutex shared_mutex;
};

}; // namespace core
}; // namespace ants

#endif // ANTS_CORE_SERVICE_HPP