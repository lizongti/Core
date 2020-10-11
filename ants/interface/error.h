#ifndef ANTS_INTERFACE_ERROR_H
#define ANTS_INTERFACE_ERROR_H
#ifdef __cplusplus
namespace ants {
namespace interface {
#endif

enum error {
  ERROR_SERVICE_NOT_FOUND = 1,
  ERROR_SERVICE_QUEUE_FULL,
};

#ifdef __cplusplus
};  // namespace interface
};  // namespace ants
#endif
#endif  // ANTS_INTERFACE_ERROR_H