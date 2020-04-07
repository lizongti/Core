#ifndef ANTS_DEF_ERROR_H
#define ANTS_DEF_ERROR_H
#ifdef __cplusplus
namespace ants
{
namespace def
{
#endif

enum error
{
    ERROR_SERVICE_NOT_FOUND = 1,
    ERROR_SERVICE_QUEUE_FULL,
};

#ifdef __cplusplus
}; // namespace def
}; // namespace ants
#endif
#endif // ANTS_DEF_ERROR_H