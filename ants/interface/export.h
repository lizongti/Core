#ifndef ANTS_INTERFACE_EXPORT_H
#define ANTS_INTERFACE_EXPORT_H
#ifdef __cplusplus
namespace ants
{
namespace interface
{
#endif

struct context;

/* export functions */
typedef int(export_start_function)(struct context *context,
                                   const char *module_name,
                                   const char *service_name);

typedef int(export_call_function)(struct context *context,
                                  const char *cluster_name,
                                  const char *service_name,
                                  void *data);

typedef int(export_stop_function)(struct context *context,
                                  const char *service_name);

struct export_data
{
    export_start_function *start;
    export_call_function *call;
    export_stop_function *stop;
};

#ifdef __cplusplus
}; // namespace interface
}; // namespace ants
#endif

#endif // ANTS_INTERFACE_EXPORT_H