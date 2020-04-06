
#include <stdlib.h>
#include <stdio.h>

#include <ants/def/functions.h>
#include <ants/def/event.h>

struct context
{
    int id;
};
static int inited = 0;
void *__cdecl create(const char *service_name, void *function_array[])
{
    init_function_array(function_array);

    struct context *context = malloc(sizeof(struct context));
    context->id = inited;
    return context;
}
void __cdecl handle(struct context *context, int event, const char *source, void *data)
{
    int service_count = 1000;
    switch (event)
    {
    case Init:
        if (!inited)
        {
            inited++;
            for (int i = 0; i < service_count; i++)
            {
                char service_name[100];
                sprintf_s(service_name, 100, "bootstrap%d", i);
                start("bootstrap.dll", service_name);
            }
            for (int i = 0; i < service_count; i++)
            {
                char service_name[100];
                sprintf_s(service_name, 100, "bootstrap%d", i);
                for (int j = 0; i < 1000; j++)
                    send(context, "", service_name, NULL);
            }
        }

        break;
    case Call:
        if (context->id == 0)
        {
            exit(1);
        }
        char service_name[100];
        sprintf_s(service_name, 1000, "bootstrap%d", rand() % (service_count - 1));
        send(context, "", service_name, NULL);
        break;
    }
}
void __cdecl destroy(void *context)
{
    free(context);
}