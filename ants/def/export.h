#ifndef ANTS_DEF_EXPORT_H
#define ANTS_DEF_EXPORT_H
#ifdef __cplusplus
namespace ants
{
namespace def
{
#endif

struct context;

/* export functions */
typedef int(export_start_function)(struct context *context, const char *module_name, const char *service_name);
typedef int(export_call_function)(struct context *context, const char *source, const char *destination, void *data);
typedef int(export_stop_function)(struct context *context, const char *service_name);

#ifdef __cplusplus
}; // namespace def
}; // namespace ants
#endif

#endif // ANTS_DEF_EXPORT_H