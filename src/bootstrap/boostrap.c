
#include <ants/shared_library.h>
#include <stdio.h>
#include <stdlib.h>


struct instance {
  int id;
};

void construct(struct context *context) {
  struct instance *instance = malloc(sizeof(struct instance));
  instance->id = 0;

  context->instance = instance;
}

void handle(struct context *context, struct message *message) {}

void destroy(struct context *context) { free(context->instance); }