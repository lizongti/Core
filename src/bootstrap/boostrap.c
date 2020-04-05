
#include <stdlib.h>
#include <stdio.h>

static int(__cdecl *start)(const char *module_name,
                           const char *service_name);
static int(__cdecl *send)(void *context,
                          const char *source,
                          const char *destination,
                          void *data);
static int(__cdecl *stop)(const char *service_name);

struct bootstrap_context
{
    int id;
};

void *__cdecl create(const char *service_name, void *function_array[])
{
    start = function_array[0];
    send = function_array[1];
    stop = function_array[2];

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