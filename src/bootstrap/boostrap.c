
#include <stdlib.h>
#include <stdio.h>

#include <ants/def/functions.h>

struct bootstrap_context
{
    int id;
};

void *__cdecl create(const char *service_name, void *function_array[])
{
    init_functions(function_array);
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
    start("bootstrap.dll", "bootstrap2");
}
void __cdecl destroy(void *context)
{
    free(context);
}