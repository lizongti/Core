#ifndef ANTS_INTERFACE_EVENT_H
#define ANTS_INTERFACE_EVENT_H

#ifdef __cplusplus
namespace ants {
namespace interface {
#endif
enum event {
  start_event = 1,
  call_event = 2,
  stop_event = 3,
};
#ifdef __cplusplus
};  // namespace interface
};  // namespace ants
#endif
#endif  // ANTS_INTERFACE_EVENT_H