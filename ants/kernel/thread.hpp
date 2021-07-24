#ifndef ANTS_KERNEL_THREAD_HPP
#define ANTS_KERNEL_THREAD_HPP

#include <ants/kernel/queue.hpp>
#include <ants/kernel/service.hpp>
#include <thread>
namespace ants {
namespace kernel {

class thread {
 public:
  thread() { thread_ = std::shared_ptr<std::thread>(new std::thread(run)); }
  virtual ~thread(){};

 public:
  static void run() {
    while (true) {
      auto service = unique_shared_queue<kernel::service>::pop(true);
      if (!service) {
        std::cerr << "Get empty service when working." << std::endl;
        exit(1);
      }
      if (!service->digest()) {
        std::cerr << "Service digest failed." << std::endl;
        exit(1);
      }
    }
  }

  std::thread::id get_id() { return thread_->get_id(); }

 protected:
  std::shared_ptr<std::thread> thread_;
};
};  // namespace kernel
}  // namespace ants
#endif  // ANTS_KERNEL_THREAD_HPP