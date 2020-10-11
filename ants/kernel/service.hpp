#ifndef ANTS_KERNEL_SERVICE_HPP
#define ANTS_KERNEL_SERVICE_HPP

#include <ants/interface/context.h>
#include <ants/interface/event.h>
#include <ants/interface/import_helper.h>
#include <ants/interface/message.h>

#include <ants/detail/singleton.hpp>
#include <ants/kernel/module.hpp>
#include <ants/kernel/queue.hpp>
#include <array>
#include <atomic>
#include <boost/noncopyable.hpp>
#include <mutex>
#include <shared_mutex>
#include <unordered_map>

namespace ants {
namespace kernel {
class export_function {
 public:
  static int start(struct interface::context *context, const char *module_name,
                   const char *service_name);

  static int send(struct interface::context *context, const char *source,
                  const char *destination, void *data);
                  
  static int stop(struct interface::context *context, const char *service_name);
};

class service : public std::enable_shared_from_this<service> {
 public:
  bool load(const std::string &module_name, const std::string &service_name) {
    name = service_name;
    module = module_loader::load(module_name);
    if (!module) {
      std::cerr << "Module " << module_name << " load failed!" << std::endl;
      return false;
    }
    context = std::shared_ptr<interface::context>(new interface::context{
        nullptr, nullptr, nullptr,
        interface::param_data{
            nullptr,
            0,
        },
        interface::import_data{module->construct, module->handle,
                               module->destroy},
        interface::export_data{export_function::start, export_function::send,
                               export_function::stop}});
    interface::construct(context.get());
    instance = std::shared_ptr<void>(context->instance, [&](void *instance) {
      interface::destroy(context.get());
    });

    auto message = std::shared_ptr<interface::message>(
        new interface::message{interface::event::start_event,
                               interface::new_address("", service_name.c_str()),
                               interface::new_address("", service_name.c_str()),
                               nullptr},
        [](interface::message *message) {
          interface::delete_address(message->source);
          interface::delete_address(message->destionation);
          delete message;
        });
    push(message);

    std::cout << "Service " << service_name << " load ok" << std::endl;
    return true;
  }

  bool work() {
    decltype(shared_queue.size()) size;
    {
      std::lock_guard<std::mutex> lock(mutex);
      outside = true;
      working = true;
      size = shared_queue.size();
    }

    while (size--) {
      std::shared_ptr<interface::message> message;
      while (message = shared_queue.pop()) {
        interface::handle(context.get(), message.get());
      }
    }

    std::lock_guard<std::mutex> lock(mutex);
    working = false;
    if (!working && outside && !shared_queue.empty()) {
      unique_shared_queue<service>::push(shared_from_this());
      outside = false;
    }

    return true;
  }

  bool push(std::shared_ptr<interface::message> message) {
    shared_queue.push(message);

    std::lock_guard<std::mutex> lock(mutex);
    if (!working && outside && !shared_queue.empty()) {
      unique_shared_queue<service>::push(shared_from_this());
      outside = false;
    }

    return true;
  }

  bool unload() { return true; }

 private:
  std::string name;
  std::shared_ptr<kernel::module> module;
  std::shared_ptr<interface::context> context;
  std::shared_ptr<void> instance;

  shared_queue<interface::message> shared_queue;
  bool outside = true;
  bool working = false;
  mutable std::mutex mutex;
};

class service_loader : public detail::singleton<service_loader>,
                       private boost::noncopyable {
 public:
  static std::shared_ptr<service> load(std::string const &module_name,
                                       std::string const &service_name) {
    std::lock_guard<std::shared_mutex> lock(instance().shared_mutex);

    auto &service_unordered_map = instance().service_unordered_map;
    if (service_unordered_map.find(service_name) != service_unordered_map.end())
      return service_unordered_map[service_name];

    auto service = std::shared_ptr<kernel::service>(new kernel::service());
    service_unordered_map[service_name] = service;

    return service->load(module_name, service_name) ? service : nullptr;
  }

  static std::shared_ptr<service> push(
      std::string const &service_name,
      std::shared_ptr<interface::message> message) {
    std::shared_lock<std::shared_mutex> lock(instance().shared_mutex);

    auto &service_unordered_map = instance().service_unordered_map;
    if (service_unordered_map.find(service_name) == service_unordered_map.end())
      return nullptr;

    auto service = service_unordered_map[service_name];

    return service->push(message) ? service : nullptr;
  }

  static std::shared_ptr<service> unload(std::string const &service_name) {
    std::lock_guard<std::shared_mutex> lock(instance().shared_mutex);

    auto &service_unordered_map = instance().service_unordered_map;
    if (service_unordered_map.find(service_name) == service_unordered_map.end())
      return nullptr;

    auto service = service_unordered_map[service_name];
    service_unordered_map.erase(service_name);

    return service->unload() ? service : nullptr;
  }

 protected:
  std::unordered_map<std::string, std::shared_ptr<service>>
      service_unordered_map;
  mutable std::shared_mutex shared_mutex;
};

int export_function::start(struct interface::context *context,
                           const char *module_name, const char *service_name) {
  return service_loader::load(module_name, service_name) != nullptr ? 1 : 0;
}

int export_function::send(struct interface::context *context,
                          const char *cluster_name, const char *service_name,
                          void *data) {
  if (!cluster_name || std::string(cluster_name) == "") {
    auto message = std::shared_ptr<interface::message>(
        new interface::message{interface::event::call_event,
                               interface::new_address("", service_name),
                               interface::new_address("", service_name),
                               nullptr},
        [](interface::message *message) {
          interface::delete_address(message->source);
          interface::delete_address(message->destionation);
          delete message;
        });
    return service_loader::push(service_name, message) != nullptr ? 1 : 0;
  } else
    return 1;
}

int export_function::stop(struct interface::context *context,
                          const char *service_name) {
  return service_loader::unload(service_name) != nullptr ? 1 : 0;
}

};  // namespace kernel
};  // namespace ants

#endif  // ANTS_KERNEL_SERVICE_HPP