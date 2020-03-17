#ifndef vstring_h
#define vstring_h

#include <stddef.h>
#include <stdint.h>

typedef struct vstr_s{
	char * s;
	int32_t len;
	int cap;
}vstr_t;

int vstr_endswith(vstr_t * v, const char * p, int n);

vstr_t * vstr_path_join(vstr_t * path, const char * rp);

/*create a string*/
vstr_t * vstr_alloc(int cap);

vstr_t * vstr_dup(const char * s);

vstr_t * vstr_trim(vstr_t * v);

vstr_t * vstr_clear(vstr_t * v);

/*add one character to then end*/
vstr_t * vstr_putchar(vstr_t * v, char c);

vstr_t * vstr_putfstring(vstr_t * v, const char * s, ...);

vstr_t * vstr_putstring(vstr_t * v, const char * s);

vstr_t * vstr_putlstring(vstr_t * v, const char * s, int len);

vstr_t * vstr_putbytes(vstr_t * v, const char * b, int len);

vstr_t * vstr_set(vstr_t * v, const char * s);

vstr_t * vstr_replace(vstr_t * v, size_t l, size_t r, vstr_t * rep);

/*free the string memory*/
void vstr_free(vstr_t * v);

#endif