static int(__cdecl *start)(const char *module_name,
                           const char *service_name);
static int(__cdecl *send)(void *context,
                          const char *source,
                          const char *destination,
                          void *data);
static int(__cdecl *stop)(const char *service_name);

void init_function_array(void *function_array[])
{
    start = function_array[0];
    send = function_array[1];
    stop = function_array[2];
}