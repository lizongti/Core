#ifndef ANTS_INTERFACE_IMPORT_H
#define ANTS_INTERFACE_IMPORT_H
#ifdef __cplusplus
namespace ants {
namespace interface {
#endif

struct context;

/* import functions */
typedef void(import_construct_function)(struct context *context);
typedef void(import_handle_function)(struct context *context,
                                     struct message *message);
typedef void(import_destroy_function)(struct context *context);

struct import_data {
  import_construct_function *construct;
  import_handle_function *handle;
  import_destroy_function *destroy;
};

#ifdef __cplusplus
};  // namespace interface
};  // namespace ants
#endif

#endif  // ANTS_INTERFACE_IMPORT_H