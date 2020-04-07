
#include <stdlib.h>
#include <stdio.h>

#include <ants/def/functions.h>
#include <ants/def/event.h>

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
            int event, const char *source, void *data)
{
    switch (event)
    {
    case Start:
        fprintf(stdout, "service stability_test_%d Start.", ((struct instance *)context->instance)->id);
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
                    call(context, "", service_name, NULL);
            }
        }

        break;
    case Call:
        if (((struct instance *)context->instance)->id == 0)
        {
            exit(1);
        }
        char service_name[100];
        sprintf_s(service_name, 1000, "%s_%d", module_name, rand() % service_count);
        call(context, "", service_name, NULL);
        break;
    }
}

void destroy(struct context *context)
{
    free(context->instance);
}