#ifndef ANTS_DEF_IMPORT_HELPER_H
#define ANTS_DEF_IMPORT_HELPER_H
#include <ants/def/context.h>
#ifdef __cplusplus
namespace ants
{
namespace def
{
#endif

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

#ifdef __cplusplus
}; // namespace def
}; // namespace ants
#endif

#endif // ANTS_DEF_IMPORT_HELPER_H