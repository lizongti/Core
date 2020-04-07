#ifndef ANTS_DEF_FUNCTIONS_H
#define ANTS_DEF_FUNCTIONS_H
#include <ants/def/context.h>
#ifdef __cplusplus
namespace ants
{
namespace def
{
#endif

#ifdef __cplusplus
inline void construct(struct context *context)
{
    (*context->construct)(context);
};

inline void handle(struct context *context, int event, const char *source, void *data)
{
    (*context->handle)(context, event, source, data);
};

inline void destory(struct context *context)
{
    (*context->destroy)(context);
};
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

#endif // ANTS_DEF_FUNCTIONS_H