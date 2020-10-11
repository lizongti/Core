#ifndef ANTS_INTERFACE_PARAM_H
#define ANTS_INTERFACE_PARAM_H
#ifdef __cplusplus
namespace ants {
namespace interface {
#endif
struct param_data {
  char **argv;
  int argc;
};
#ifdef __cplusplus
};  // namespace interface
};  // namespace ants
#endif
#endif  // ANTS_INTERFACE_PARAM_H
