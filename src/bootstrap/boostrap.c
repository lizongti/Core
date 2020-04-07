
#include <stdlib.h>
#include <stdio.h>

#include <ants/def/functions.h>
#include <ants/def/event.h>

struct instance
{
    int id;
};

void construct(struct context *context)
{
    struct instance *instance = malloc(sizeof(struct instance));
    instance->id = 0;

    context->instance = instance;
}

void handle(struct context *context,
            int event, const char *source, void *data)
{
}

void destroy(struct context *context)
{
    free(context->instance);
}