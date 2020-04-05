
#include <stdlib.h>
#include <stdio.h>
struct bootstrap_context
{
    int id;
};

void *__cdecl create(const char *service_name, const char *module_name)
{
    struct bootstrap_context *context = malloc(sizeof(struct bootstrap_context));
    context->id = 0;
    return context;
}
void __cdecl handle(void *context,
                    int event, 
                    const char *source,
                    void *data)
{
    int id = ((struct bootstrap_context *)context)->id;
    printf("%d", id);
}
void __cdecl destroy(void *context)
{
    free(context);
}