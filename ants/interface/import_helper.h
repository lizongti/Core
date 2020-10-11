#ifndef ANTS_INTERFACE_IMPORT_HELPER_H
#define ANTS_INTERFACE_IMPORT_HELPER_H
#include <ants/interface/context.h>
#ifdef __cplusplus
namespace ants {
namespace interface {
#endif

#ifdef __import
inline void construct(struct context *context) {
  (*context->import_data.construct)(context);
};

inline void handle(struct context *context, struct message *message) {
  (*context->import_data.handle)(context, message);
};

inline void destroy(struct context *context) {
  (*context->import_data.destroy)(context);
};
#endif

#ifdef __cplusplus
};  // namespace interface
};  // namespace ants
#endif

#endif  // ANTS_INTERFACE_IMPORT_HELPER_H