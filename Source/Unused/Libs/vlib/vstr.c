#include "vstr.h"
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <stdio.h>
#include <stddef.h>
#include <ctype.h>

#define VSTR_INC_RATIO 2
#define VSTR_DEFAULT_CAP 4

int vstr_endswith(vstr_t * v, const char * p, int n)
{
	int l = v->len;
	int lp = n;
	
	if (l < lp) {
		return 0;
	}

	return strncmp(v->s+l-lp, p, n) == 0;
}

vstr_t * vstr_path_join(vstr_t * path_, const char * rp)
{
	vstr_t * v = vstr_alloc(VSTR_DEFAULT_CAP);
	if (path_ && path_->s) {
		char * path = path_->s;
		while (*path) {
			char c = *path++; 
			if (c == '\\') {
				c = '/';
			}
			vstr_putchar(v, c);
		}
	}
	
	if (v->len > 0 && v->s[v->len - 1] != '/') {
		vstr_putchar(v, '/');
	}

	if (rp) {
		while(rp[0] == '/') {
			rp++;
		}
		while (*rp) {
			char c = *rp++;
			if (c == '\\') {
				c = '/';
			}
			vstr_putchar(v, c);
		}
	}
	return v;
}

vstr_t * vstr_alloc(int cap)
{
	if (!cap) {
		cap = VSTR_DEFAULT_CAP;
	}

    vstr_t * v = malloc(sizeof(vstr_t));
    memset(v, 0, sizeof(vstr_t));
    v->cap = cap;

    if (cap > 0) {
        v->s = malloc(cap);
		v->s[0] = 0;
    }

    return v;
}

vstr_t * vstr_dup(const char * s)
{
	vstr_t * v = vstr_alloc(0);
	vstr_putstring(v, s);
	return v;
}

static void check_cap(vstr_t * v, int inc)
{
    if (!inc) { return v; }
    if (v->len + inc >= v->cap) {
		while (v->cap <= v->len + inc) {
			v->cap *= VSTR_INC_RATIO;
		}
        v->s = realloc(v->s, v->cap);
    }
}

vstr_t * vstr_putbytes(vstr_t * v, const char * b, int len)
{
	check_cap(v, len);
	memcpy(v->s + v->len, b, len);
	v->len = v->len + len;
	return v;
} 

#ifdef _WIN32
int vasprintf(char **strp, const char *fmt, va_list ap) {
	int len = _vscprintf(fmt, ap);
	if (len == -1) {
		return -1;
	}
	size_t size = (size_t)len + 1;
	char *str = malloc(size);
	if (!str) {
		return -1;
	}
	int r = vsprintf(str, fmt, ap);
	if (r == -1) {
		free(str);
		return -1;
	}
	str[r] = 0;
	*strp = str;
	return r;
}
#endif

vstr_t * vstr_putfstring(vstr_t * v, const char * fmt, ...)
{
	if (!fmt) {
		return v;
	}

	char * ps = 0;
	char * p = 0;

	va_list ap;
	va_start(ap, fmt);

	int r = vasprintf(&ps, fmt, ap);

	if (r == -1) {
		return 0;
	}
	
	va_end(ap);

	p = ps;
	while (*p) {
		vstr_putchar(v, *p++);
	}

	free(ps);
	return v;
}

vstr_t * vstr_putstring(vstr_t * v, const char * s)
{
	if (!s) {
		return v;
	}

	char * ps = s;

	while (*ps) {
		vstr_putchar(v, *ps++);
	}

	return v;
}

vstr_t * vstr_putlstring(vstr_t * v, const char * s, int len)
{
	if (!s) {
		return v;
	}

	char * ps = s;

	for(int i=0; i<len; ++i) {
		vstr_putchar(v, *ps++);
	}

	return v;
}

vstr_t * vstr_set(vstr_t * v, const char * s)
{
	v->len = 0;
	vstr_putstring(v, s);
	return v;
}

vstr_t * vstr_putchar(vstr_t * v, char c)
{
    check_cap(v, 1);
    v->s[v->len++] = c;
	v->s[v->len] = 0;
    return v;
}

//[l,r)
vstr_t * vstr_replace(vstr_t * v, size_t l, size_t r, vstr_t * rep)
{
	int gap = r - l;

	if(rep->len < gap){
		int dt = gap - rep->len;
		memcpy(v->s+l, rep->s, rep->len);
		memmove(v->s + l + rep->len, v->s + r, v->len - r);
	}else if(rep->len == gap){
		memcpy(v->s + l, rep->s, gap);
	}else{
		int dt = rep->len - gap;
		check_cap(v, dt);
		memmove(v->s + r + dt, v->s + r, v->len-r);
		memcpy(v->s + l, rep->s, rep->len);
	} 

	v->len = v->len - gap + rep->len;
	v->s[v->len] = 0;
	return v;
}

vstr_t * vstr_clear(vstr_t * v)
{
	v->len = 0;
	return v;
}

vstr_t * vstr_trim(vstr_t * v)
{
	if (!v->len) {
		return v;
	}

	char * p = v->s;

	while (isspace(*p))++p;
	int l = p - v->s;
	memmove(v->s, v->s + l, v->len-l);
	v->len -= l;

	while (isspace(v->s[v->len - 1])) {
		v->len--;
	}
	
	v->s[v->len] = 0;

	return v;
}

void vstr_free(vstr_t * v)
{
	if (!v) {
		return;
	}

    free(v->s);
    memset(v, 0, sizeof(vstr_t));
    free(v);
}
