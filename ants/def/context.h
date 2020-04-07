#ifndef ANTS_DEF_CONTEXT_H
#define ANTS_DEF_CONTEXT_H
#include <ants/def/import.h>
#include <ants/def/export.h>

#ifdef __cplusplus
namespace ants
{
namespace def
{
#endif

struct context
{
    void *instance;
    char **argc;
    int argv;
    import_construct_function *construct;
    import_handle_function *handle;
    import_destroy_function *destroy;
    export_start_function *start;
    export_call_function *call;
    export_stop_function *stop;
};

#ifdef __cplusplus
}; // namespace def
}; // namespace ants
#endif
#endif // ANTS_DEF_CONTEXT_H