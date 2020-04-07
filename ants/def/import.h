#ifndef ANTS_DEF_IMPORT_H
#define ANTS_DEF_IMPORT_H
#ifdef __cplusplus
namespace ants
{
namespace def
{
#endif

struct context;

/* import functions */
typedef void(import_construct_function)(struct context *context);
typedef void(import_handle_function)(struct context *context, int event, const char *source, void *data);
typedef void(import_destroy_function)(struct context *context);

#ifdef __cplusplus
}; // namespace def
}; // namespace ants
#endif

#endif // ANTS_DEF_IMPORT_H