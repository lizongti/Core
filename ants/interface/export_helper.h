#ifndef ANTS_INTERFACE_EXPORT_HELPER_H
#define ANTS_INTERFACE_EXPORT_HELPER_H
#include <ants/interface/context.h>
#ifdef __cplusplus
namespace ants
{
namespace interface
{
#endif

#ifdef __export
inline int start(struct context *context,
                 const char *service_name,
                 const char *module_name)
{
    return (*context->export_data.start)(context,
                                         service_name,
                                         module_name);
};

inline int call(struct context *context,
                const char *cluster_name,
                const char *service_name,
                void *data)
{
    return (*context->export_data.call)(context,
                                        cluster_name,
                                        service_name,
                                        data);
};

inline int stop(struct context *context,
                const char *service_name)
{
    return (*context->export_data.stop)(context,
                                        service_name);
};
#endif

#ifdef __cplusplus
}; // namespace interface
}; // namespace ants
#endif

#endif // ANTS_INTERFACE_EXPORT_HELPER_H