#ifndef ANTS_INTERFACE_CONTEXT_H
#define ANTS_INTERFACE_CONTEXT_H
#include <ants/interface/export.h>
#include <ants/interface/import.h>
#include <ants/interface/param.h>


#ifdef __cplusplus
namespace ants {
namespace interface {
#endif

struct context {
  char *cluster_name;
  char *service_name;
  void *instance;
  struct param_data param_data;
  struct import_data import_data;
  struct export_data export_data;
};

#ifdef __cplusplus
};  // namespace interface
};  // namespace ants
#endif
#endif  // ANTS_INTERFACE_CONTEXT_H