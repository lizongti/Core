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
#include <ants/def/context.h>
#include <ants/def/import_helper.h>

namespace ants
{
namespace core
{

class export_function
{
public:
    static int start(struct ants::def::context *context, const char *module_name,
                     const char *service_name);
    static int send(struct ants::def::context *context, const char *source,
                    const char *destination, void *data);
    static int stop(struct ants::def::context *context, const char *service_name);
};

class service
    : public std::enable_shared_from_this<service>
{
public:
    bool load(const std::string &module_name,
              const std::string &service_name)
    {
        name = service_name;
        module = module_loader::load(module_name);
        if (!module)
        {
            std::cerr << "Module " << module_name << " load failed!" << std::endl;
            return false;
        }
        context = std::shared_ptr<ants::def::context>(new ants::def::context{
            nullptr, nullptr, 0,
            module->construct, module->handle, module->destroy,
            export_function::start, export_function::send, export_function::stop});
        ants::def::construct(context.get());
        instance = std::shared_ptr<void>(context->instance, [&](void *instance) {
            (*context->destroy)(context.get());
        });

        push(std::shared_ptr<message>(new message{
            ants::def::Event::Start, service_name, service_name, nullptr}));

        std::cout << "Service " << service_name << " load ok" << std::endl;
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
            if (size > 65536)
                std::cerr << "Queue size is larger than 65536 in service "
                          << name << std::endl;
        }

        while (size--)
        {
            std::shared_ptr<ants::core::message> message;
            while (message = shared_queue.pop())
            {
                ants::def::handle(context.get(),
                                  message->event(),
                                  message->source().c_str(),
                                  message->data());
            }
        }

        std::lock_guard<std::mutex> lock(mutex);
        working = false;
        if (!working && outside && !shared_queue.empty())
        {
            unique_shared_queue<service>::push(shared_from_this());
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
            unique_shared_queue<service>::push(shared_from_this());
            outside = false;
        }

        // {
        //     static uint64_t count = 0;
        //     if (++count % 10000000 == 0)
        //     {
        //         std::cout << count / 10000000 << " " << time(0) << " "
        //         << unique_shared_queue<service>::size() << std::endl;
        //     }
        // }

        return true;
    }

    bool unload()
    {
        return true;
    }

private:
    std::string name;
    std::shared_ptr<ants::core::module> module;
    std::shared_ptr<ants::def::context> context;
    std::shared_ptr<void> instance;

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
                                         std::shared_ptr<ants::core::message> message)
    {
        std::shared_lock<std::shared_mutex> lock(instance().shared_mutex);

        auto &service_unordered_map = instance().service_unordered_map;
        if (service_unordered_map.find(service_name) == service_unordered_map.end())
            return nullptr;

        auto service = service_unordered_map[service_name];

        return service->push(message) ? service : nullptr;
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

int export_function::start(struct ants::def::context *context, const char *module_name,
                           const char *service_name)
{
    return service_loader::load(module_name, service_name) != nullptr ? 1 : 0;
}

int export_function::send(struct ants::def::context *context, const char *source,
                          const char *destination, void *data)
{
    auto message = std::shared_ptr<ants::core::message>(new ants::core::message{
        ants::def::Event::Call, source, destination, data});

    auto service_name = destination; // need parse
    return service_loader::push(service_name, message) != nullptr ? 1 : 0;
}

int export_function::stop(struct ants::def::context *context, const char *service_name)
{
    return service_loader::unload(service_name) != nullptr ? 1 : 0;
}

}; // namespace core
}; // namespace ants

#endif // ANTS_CORE_SERVICE_HPP