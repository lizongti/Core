
#include <stdlib.h>
#include <stdio.h>

#include <ants/shared_library.h>

static int id_increase = 0;
static int service_count = 1000;
static int msg_count = 1000;
static const char *module_name = "stability_test";

struct instance
{
    int id;
};

void construct(struct context *context)
{
    struct instance *instance = malloc(sizeof(struct instance));
    instance->id = id_increase++;
    context->instance = instance;
}

void handle(struct context *context,
            struct message *message)
{
    switch (message->event)
    {
    case start_event:
        fprintf(stdout, "service stability_test_%d start event.\n",
                ((struct instance *)context->instance)->id);
        if (!((struct instance *)context->instance)->id)
        {
            for (int i = 0; i < service_count; i++)
            {
                char service_name[100];
                sprintf_s(service_name, 100, "%s_%d", module_name, i);
                start(context, module_name, service_name);
            }
            for (int i = 0; i < service_count; i++)
            {
                char service_name[100];
                sprintf_s(service_name, 100, "%s_%d", module_name, i);
                for (int j = 0; j < msg_count; j++)
                    call(context, 0, service_name, 0);
            }
        }

        break;
    case call_event:
        if (((struct instance *)context->instance)->id == 0)
        {
            exit(1);
        }
        char service_name[100];
        sprintf_s(service_name, 1000, "%s_%d", module_name,
                  rand() % service_count);
        call(context, 0, service_name, 0);
        break;
    }
}

void destroy(struct context *context)
{
    free(context->instance);
}