#ifndef ANTS_KERNEL_PROCESS_HPP
#define ANTS_KERNEL_PROCESS_HPP

#include <algorithm>
#include <ants/detail/singleton.hpp>
#include <ants/kernel/configuration.hpp>
#include <ants/kernel/service.hpp>
#include <ants/kernel/thread.hpp>
#include <boost/noncopyable.hpp>
#include <iostream>
#include <thread>
#include <vector>

namespace ants {
namespace kernel {

class process : public detail::singleton<process>, private boost::noncopyable {
 public:
  void run(int argc, char *argv[]) {
    init_options(argc, argv);
    init_threads();
  }

 protected:
  void init_options(int argc, char *argv[]) {
    configuration_loader::load(argc, argv);
  }

  void init_bootstrap() {
    auto service =
        service_loader::load(configuration::bootstrap(), "bootstrap");
    if (!service) {
      std::cerr << "Bootstrap service load failed." << std::endl;
      exit(1);
    }
  }
  void init_threads() {
    thread_ids.push_back(std::this_thread::get_id());
    for (uint32_t i = 1; i < configuration::thread(); ++i)
      thread_ids.push_back((new thread())->get_id());

    init_bootstrap();
    thread::work();
  }

 protected:
  std::vector<std::thread::id> thread_ids;
};
};      // namespace kernel
};      // namespace ants
#endif  // ANTS_KERNEL_PROCESS_HPP