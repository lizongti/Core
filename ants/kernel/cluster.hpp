#ifndef ANTS_INTERFACE_CONTEXT_H
#define ANTS_INTERFACE_CONTEXT_H

#include <ants/detail/singleton.hpp>
#include <boost/noncopyable.hpp>

namespace ants {
namespace kernel {

class cluster : public detail::singleton<cluster>, private boost::noncopyable {
 public:
  bool join(*service);
  bool leave(*service);
  std::string name();
};

};      // namespace kernel
};      // namespace ants
#endif  // ANTS_KERNEL_PROCESS_HPP