#ifndef ANTS_INTERFACE_MESSAGE_H
#define ANTS_INTERFACE_MESSAGE_H

#include <ants/interface/event.h>

#ifndef __cplusplus
#include <stdlib.h>
#include <string.h>
#endif

#ifdef __cplusplus
namespace ants {
namespace interface {
#endif

struct address {
  char *cluster_name;
  char *service_name;
};

struct message {
#ifdef __cplusplus
  enum interface::event event;
#else
  enum event event;
#endif
  struct address *source;
  struct address *destionation;
  void *data;
};

inline struct address *new_address(const char *cluster_name,
                                   const char *service_name) {
  struct address *address = (struct address *)malloc(sizeof(struct address));
  address->cluster_name = (char *)malloc(strlen(cluster_name) + 1);
  memcpy(address->cluster_name, cluster_name, strlen(cluster_name) + 1);
  address->service_name = (char *)malloc(strlen(service_name) + 1);
  memcpy(address->service_name, service_name, strlen(service_name) + 1);
  return address;
}

inline void delete_address(struct address *address) {
  free(address->cluster_name);
  free(address->service_name);
  free(address);
}
#ifdef __cplusplus
};  // namespace interface
};  // namespace ants
#endif
#endif  // ANTS_INTERFACE_MESSAGE_H