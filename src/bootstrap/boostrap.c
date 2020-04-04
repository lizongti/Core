
#include <stdlib.h>
#include <stdio.h>
struct bootstrap_data
{
    int id;
};

void *__cdecl create(const char *service_name, const char *module_name, void *function_array[])
{
    struct bootstrap_data *data = malloc(sizeof(struct bootstrap_data));
    data->id = 0;
    return data;
}
void __cdecl handle(void *context, void *message)
{
    printf("%p", message);
}
void __cdecl destroy(void *context)
{
    free(context);
}