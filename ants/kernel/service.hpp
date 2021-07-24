#ifndef ANTS_KERNEL_SERVICE_HPP
#define ANTS_KERNEL_SERVICE_HPP

#include <ants/interface/context.h>
#include <ants/interface/event.h>
#include <ants/interface/import_helper.h>
#include <ants/interface/message.h>

#include <ants/detail/queue.hpp>
#include <ants/detail/singleton.hpp>
#include <ants/kernel/module.hpp>
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
  bool start(const std::string &module_name, const std::string &service_name) {
    module = module_loader::load(module_name);
    if (!module) {
      std::cerr << "Module " << module_name << " load failed!" << std::endl;
      return false;
    }
    context = std::shared_ptr<interface::context>(new interface::context{
        cluster::name().c_str(), service_name.c_str(), nullptr,
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

    cluster::join(shared_from_this());

    auto message = std::shared_ptr<interface::message>(
        new interface::message{
            interface::event::start_event,
            interface::new_address(context.cluster_name.c_str(),
                                   service_name.c_str()),
            interface::new_address(context.cluster_name.c_str(),
                                   service_name.c_str()),
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

  bool digest() {
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

  bool stop() {
    // TODO:
    // 1. wait for work finish
    // 2. call stop_event

    auto message = std::shared_ptr<interface::message>(
        new interface::message{
            interface::event::stop_event,
            interface::new_address(context.cluster_name.c_str(),
                                   service_name.c_str()),
            interface::new_address(context.cluster_name.c_str(),
                                   service_name.c_str()),
            nullptr},
        [](interface::message *message) {
          interface::delete_address(message->source);
          interface::delete_address(message->destionation);
          delete message;
        });
    push(message);

    return true;
  }

 protected:
  bool push(std::shared_ptr<interface::message> message) {
    shared_queue.push(message);

    std::lock_guard<std::mutex> lock(mutex);
    if (!working && outside && !shared_queue.empty()) {
      unique_shared_queue<service>::push(shared_from_this());
      outside = false;
    }

    return true;
  }

 private:
  std::shared_ptr<kernel::module> module;
  std::shared_ptr<interface::context> context;
  std::shared_ptr<void> instance;

  detail::shared_queue<interface::message> shared_queue;
  bool outside = true;
  bool working = false;
  mutable std::mutex mutex;
};

class service_factory : public detail::singleton<service_factory>,
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

    auto ok = service->start(module_name, service_name);

    return ok ? service : nullptr;
  }

  static std::shared_ptr<service> push(
      std::string const &cluster_name, std::string const &service_name,
      std::shared_ptr<interface::message> message) {
    std::shared_lock<std::shared_mutex> lock(instance().shared_mutex);

    auto &service_unordered_map = instance().service_unordered_map;
    if (service_unordered_map.find(service_name) == service_unordered_map.end())
      return nullptr;

    auto service = service_unordered_map[service_name];

    auto ok = service->push(message) ? service : nullptr;
  }

  static std::shared_ptr<service> unload(std::string const &service_name) {
    std::lock_guard<std::shared_mutex> lock(instance().shared_mutex);

    auto &service_unordered_map = instance().service_unordered_map;
    if (service_unordered_map.find(service_name) == service_unordered_map.end())
      return nullptr;

    auto service = service_unordered_map[service_name];
    service_unordered_map.erase(service_name);

    cluster::leave(shared_from_this());

    return service->stop() ? service : nullptr;
  }

 protected:
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

 protected:
  std::unordered_map<std::string, std::shared_ptr<service>>
      service_unordered_map;
  mutable std::shared_mutex shared_mutex;
};

int export_function::start(struct interface::context *context,
                           const char *module_name, const char *service_name) {
  if (service_factory::load(module_name, service_name) != nullptr) {
    return 0;
  }
  if (!cluster::join(service_name)) {
  }
}
? 1 : 0;
}

int export_function::send(struct interface::context *context,
                          const char *cluster_name, const char *service_name,
                          void *data) {
  auto message = std::shared_ptr<interface::message>(
      new interface::message{
          interface::event::call_event,
          interface::new_address(context->cluster_name, context->service_name),
          interface::new_address(cluster_name, service_name), nullptr},
      [](interface::message *message) {
        interface::delete_address(message->source);
        interface::delete_address(message->destionation);
        delete message;
      });
  auto service = cluster::get(cluster_name, service_name);
  service != nullptr ? service::push(cluster_name, service_name, message);

  return 0;
}

int export_function::stop(struct interface::context *context,
                          const char *service_name) {
  return service_factory::unload(service_name) != nullptr ? 1 : 0;
}
};  // namespace kernel
}
;  // namespace ants

#endif  // ANTS_KERNEL_SERVICE_HPP