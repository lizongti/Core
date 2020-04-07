#ifndef ANTS_DEF_EXPORT_HELPER_H
#define ANTS_DEF_EXPORT_HELPER_H
#include <ants/def/context.h>
#ifdef __cplusplus
namespace ants
{
namespace def
{
#endif

inline int start(struct context *context, const char *module_name, const char *service_name)
{
    return (*context->start)(context, module_name, service_name);
};

inline int call(struct context *context, const char *source, const char *destination, void *data)
{
    return (*context->call)(context, source, destination, data);
};

inline int stop(struct context *context, const char *service_name)
{
    return (*context->stop)(context, service_name);
};
#ifdef __cplusplus
}; // namespace def
}; // namespace ants
#endif

#endif // ANTS_DEF_EXPORT_HELPER_H