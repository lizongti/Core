#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <assert.h>
#include <stdint.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#define CARD short
#define MAX_RECURSE_COUNT 4000
#define MAX_CARD_COUNT 20

#ifdef _WIN32
#include <Windows.h>

#define inline __inline

static int tick()
{
	SYSTEMTIME time;
	GetSystemTime(&time);
	int millis = (time.wSecond * 1000) + time.wMilliseconds;
	return millis;
}

#else
#include <sys/time.h>

static int64_t tick()
{
	struct timeval time;
	gettimeofday(&time, NULL);
	long millis = (time.tv_sec * 1000) + (time.tv_usec / 1000);
	return millis;
}

#endif

#define printf //printf

static const char * NAME[] = { "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A", "2", "JB", "JR" };

enum Card {
	C3,
	C4,
	C5,
	C6,
	C7,
	C8,
	C9,
	C10,
	CJ,
	CQ,
	CK,
	CA,
	C2,
};

enum ScoreType {
	ST_SINGLE = 3,	//
	ST_PAIR = 4,	//
	ST_THREE = 5,	//
	ST_ONESTRAIGHT = 8,	//
	ST_PAIRSTRAIGHT = 9,	//
	ST_THREESTRAIGHT = 10,	//
	ST_BOMB = 2,		//
	ST_ROCKET = 1,
};

enum ScoreDefault {
	SINGLE = 0,
	PAIR = 3,
	THREE = 5,
	ONESTRAIGHT = 20,
	ONESTRAIGHTADD = 10,
	PAIRSTRAIGHT = 20,
	PAIRSTRAIGHTADD = 10,
	THREESTRAIGHT = 15,
	THREESTRAIGHTADD = 6,
	BOMB = 40,
	ROCKET = 50,
};

typedef struct poker_s {
	CARD poker[20];
	char len;
} poker_t;

typedef struct poker_map_s
{
	char map[13];
	char len;
} poker_map_t;

typedef struct node_s
{
	struct node_s * next;
	struct node_s * prev;
	poker_t * poker;
	float score;
	int type;
} node_t;

typedef struct list_s
{
	node_t * head;
	node_t * tail;
	int len;
} list_t;

typedef struct value_s {
	float score;
	list_t * l;
} value_t;

static list_t * weights = 0;

static void poker_print(poker_t * poker);
static list_t * list_create();

static void init_weights()
{
	weights = list_create();
}

static int get_node_weight(poker_t * poker, int type)
{
	for (node_t * p = weights->head; p; p = p->next) {
		poker_t * pk = p->poker;
		if (p->type == type && pk->len == poker->len) {
			if (memcmp(pk->poker, poker->poker, sizeof(CARD)* pk->len) == 0) {
				return p->score;
			}
		}
	}
	printf("error poker weight\n");
	poker_print(poker);
	return 0;
}

static node_t * node_create(poker_t * poker, float score)
{
	node_t * n = (node_t*)malloc(sizeof(node_t));
	memset(n, 0, sizeof(node_t));
	n->poker = poker;
	n->score = score;
	return n;
}

static list_t * list_create()
{
	list_t * l = (list_t*)malloc(sizeof(list_t));
	memset(l, 0, sizeof(list_t));
	return l;
}

static void list_add(list_t * l, node_t * n)
{
	if (!l->head) {
		l->head = n;
		l->tail = n;
	}
	else {
		node_t * p = l->tail;
		p->next = n;
		l->tail = n;
	}
	l->len++;
}

static poker_t * poker_create(CARD * poker, int len)
{
	poker_t * p = (poker_t*)malloc(sizeof(poker_t));
	memset(p, 0, sizeof(poker_t));

	for (int i = 0; i < len; ++i) {
		p->poker[i] = poker[i];
	}

	p->len = len;
	return p;
}

static void poker_add(poker_t * poker, CARD value, int count)
{
	for (int i = 0; i < count; ++i) {
		poker->poker[poker->len++] = value;
	}
}

static poker_t * poker_get(poker_t * poker, CARD value, int count)
{
	poker_t * p = poker_create(0, 0);

	for (int i = 0; i < poker->len; ++i) {
		if (poker->poker[i] == value) {
			poker_add(p, poker->poker[i], 1);
			if (--count == 0) {
				break;
			}
		}
	}
	return p;
}

static poker_map_t * poker_map(poker_t * poker)
{
	poker_map_t * map = (poker_map_t*)malloc(sizeof(poker_map_t));
	memset(map, 0, sizeof(poker_map_t));
	map->len = 13;

	for (int i = 0; i < poker->len; ++i) {
		map->map[poker->poker[i]]++;
	}
	return map;
}

static void poker_map_free(poker_map_t * map)
{
	free(map);
}

static list_t * poker_create_set_single(poker_t * poker)
{
	poker_map_t * pm = poker_map(poker);

	list_t * set = list_create();

	for (int i = 0; i < pm->len; ++i) {
		if (pm->map[i] >= 1) {
			poker_t * rem = poker_get(poker, i, 1);
			node_t * n = node_create(rem, get_node_weight(rem, ST_SINGLE));
			list_add(set, n);
		}
	}

	poker_map_free(pm);

	return set;
}

static list_t * poker_create_set_pair(poker_t * poker)
{
	poker_map_t * pm = poker_map(poker);

	list_t * set = list_create();

	for (int i = 0; i < pm->len; ++i) {
		if (pm->map[i] >= 2) {
			poker_t * rem = poker_get(poker, i, 2);
			node_t * n = node_create(rem, get_node_weight(rem, ST_PAIR));
			list_add(set, n);
		}
	}

	poker_map_free(pm);

	return set;
}

static list_t * poker_create_set(poker_t * poker)
{
	poker_map_t * pm = poker_map(poker);

	list_t * set = list_create();

	for (int i = 0; i < pm->len; ++i) {
		if (pm->map[i] >= 3) {
			poker_t * rem = poker_get(poker, i, 3);
			node_t * n = node_create(rem, get_node_weight(rem, ST_THREE));
			list_add(set, n);
		}
		if (pm->map[i] >= 4) {
			poker_t * rem = poker_get(poker, i, 4);
			node_t * n = node_create(rem, get_node_weight(rem, ST_BOMB));
			list_add(set, n);
		}
	}
	//顺子
	for (int i = 0; i < pm->len; ++i) {
		const int min_seq = 5;
		int point = i;
		for (int j = i + 1; j < pm->len; ++j) {
			if (pm->map[j] >= 1 && pm->map[j - 1] >= 1 && j != 12) {
				point = j;
			}
			else {
				break;
			}
		}
		int len = point - i + 1;
		if (len >= min_seq) {
			for (int m = point - (len - min_seq); m <= point; ++m) {
				poker_t * v = poker_create(0, 0);
				for (int k = i; k <= m; ++k) {
					poker_add(v, k, 1);
				}
				float score = get_node_weight(v, ST_ONESTRAIGHT);
				node_t * n = node_create(v, score);
				list_add(set, n);
			}
		}
	}
	//2顺子
	for (int i = 0; i < pm->len; ++i) {
		const int min_seq = 3;
		const int width = 2;
		int point = i;
		for (int j = i + 1; j < pm->len; ++j) {
			if (pm->map[j] >= width && pm->map[j - 1] >= width && j != 12) {
				point = j;
			}
			else {
				break;
			}
		}
		int len = point - i + 1;
		if (len >= min_seq) {
			for (int m = point - (len - min_seq); m <= point; ++m) {
				poker_t * v = poker_create(0, 0);
				for (int k = i; k <= m; ++k) {
					poker_add(v, k, 2);
				}
				float score = get_node_weight(v, ST_PAIRSTRAIGHT);
				node_t * n = node_create(v, score);
				list_add(set, n);
			}
		}
	}
	//3顺子
	for (int i = 0; i < pm->len; ++i) {
		const int min_seq = 2;
		const int width = 3;
		int point = i;
		for (int j = i + 1; j < pm->len; ++j) {
			if (pm->map[j] >= width && pm->map[j - 1] >= width && j != 12) {
				point = j;
			}
			else {
				break;
			}
		}
		int len = point - i + 1;
		if (len >= min_seq) {
			for (int m = point - (len - min_seq); m <= point; ++m) {
				poker_t * v = poker_create(0, 0);
				for (int k = i; k <= m; ++k) {
					poker_add(v, k, 3);
				}
				float score = get_node_weight(v, ST_THREESTRAIGHT);
				node_t * n = node_create(v, score);
				list_add(set, n);
			}
		}
	}

	poker_map_free(pm);

	return set;
}

static poker_t * poker_copy(poker_t * poker)
{
	poker_t * p = (poker_t*)malloc(sizeof(poker_t));
	memcpy(p, poker, sizeof(poker_t));
	return p;
}

static void poker_print(poker_t * poker)
{
	for (int i = 0; i < poker->len; ++i) {
		printf("%s ", NAME[poker->poker[i]]);
	}
	printf("\n");
}

static void poker_remove(poker_t * poker, CARD value, int count)
{
	for (int i = 0; i < poker->len; ++i) {
		if (poker->poker[i] == value) {
			int size = sizeof(CARD) * (poker->len - i - count);
			memmove(poker->poker + i, poker->poker + (i + count), size);
			break;
		}
	}
	poker->len -= count;
}

static void poker_free(poker_t * poker)
{
	free(poker);
}

static void node_free(node_t * n)
{
	poker_free(n->poker);
	free(n);
}

static void list_free(list_t * l)
{
	for (node_t * i = l->head; i; ) {
		node_t * p = i;
		i = i->next;
		node_free(p);
	}
	free(l);
}

static value_t poker_value(poker_t * poker_, int * count) {
	value_t ret;
	if (poker_->len <= 0 || *count > MAX_RECURSE_COUNT) {
		ret.score = 0;
		ret.l = list_create();
		return ret;
	}

	(*count)++;

	list_t * set = poker_create_set(poker_);
	if (set == 0 || set->len == 0) {
		ret.score = 0;
		ret.l = list_create();
		list_free(set);
		return ret;
	}

	float max = 0;
	float discard_score = 0;
	poker_t * discard = 0;
	list_t * max_seq = 0;

	//动态规划，树形结构的宽度决定了复杂度的数量级
	for (node_t * i = set->head; i; i = i->next) {
		poker_t * poker = poker_copy(poker_);
		poker_t * discard_poker = poker_copy(i->poker);
		float score = i->score;

		for (int j = 0; j < discard_poker->len; ++j) {
			poker_remove(poker, discard_poker->poker[j], 1);
		}

		value_t val = poker_value(poker, count);
		float v = score + val.score;

		if (max < v) {
			max = v;
			if (discard) {
				poker_free(discard);
				list_free(max_seq);
			}
			discard = discard_poker;
			discard_score = i->score;
			max_seq = val.l;
		}
		else {
			list_free(val.l);
			poker_free(discard_poker);
		}
		poker_free(poker);
	}

	list_free(set);

	node_t * n = node_create(discard, discard_score);
	list_add(max_seq, n);
	ret.l = max_seq;
	ret.score = max;

	return ret;
}

static int cmp(const void * a, const void * b)
{
	return (*(CARD*)a - *(CARD*)b);
}

static void create_card(CARD card[20], int seed)
{
	srand(seed);

	CARD table_cards[52];
	for (int i = 0; i < 52; ++i) {
		table_cards[i] = i % 13 + 3;
	}
	for (int i = 0; i < 52; ++i) {
		CARD v = rand() % 52;

		if (i != v) {
			table_cards[i] ^= table_cards[v];
			table_cards[v] ^= table_cards[i];
			table_cards[i] ^= table_cards[v];
		}

	}
	for (int i = 0; i < 20; ++i) {
		card[i] = table_cards[i];
		assert(card[i] >= 3);
	}
	qsort(card, 20, sizeof(CARD), cmp);
}

/*
扑克进一步分牌：分出对子和单个
*/
static void poker_split_single_pair(poker_t * poker_, value_t * val)
{
	poker_t * poker = poker_copy(poker_);

	for (node_t * p = val->l->head; p; p = p->next) {
		for (int i = 0; i < p->poker->len; ++i) {
			poker_remove(poker, p->poker->poker[i], 1);
		}
	}

	//pairs
	list_t * pairs = poker_create_set_pair(poker);
	for (node_t * p = pairs->head; p; p = p->next) {
		int value = 0;
		for (int i = 0; i < p->poker->len; ++i) {
			value = p->poker->poker[i];
			poker_remove(poker, p->poker->poker[i], 1);
		}
		poker_t * poker = poker_copy(p->poker);
		node_t * n = node_create(poker, get_node_weight(poker, ST_PAIR));
		list_add(val->l, n);
	}
	list_free(pairs);

	//single
	list_t * singles = poker_create_set_single(poker);
	for (node_t * p = singles->head; p; p = p->next) {
		int value = 0;
		for (int i = 0; i < p->poker->len; ++i) {
			value = p->poker->poker[i];
			poker_remove(poker, p->poker->poker[i], 1);
		}
		poker_t * poker = poker_copy(p->poker);
		node_t * n = node_create(poker, get_node_weight(poker, ST_SINGLE));
		list_add(val->l, n);
	}
	list_free(singles);
	poker_free(poker);
}

static int ddz_set_score(lua_State * L) {
	int n = lua_tointeger(L, 1);
	if (n < 0 || n > ST_ROCKET) {
		printf("Error type.Should between 0 and 10");
		return 0;
	}
	int score = lua_tointeger(L, 2);
	return 0;
}

static int ddz_set_weight(lua_State * L) {
	int type = lua_tointeger(L, 2);
	int weight = lua_tointeger(L, 3);

	int tl = lua_objlen(L, 1);
	poker_t * p = poker_create(0, 0);

	for (int i = 0; i < tl; ++i) {
		lua_pushinteger(L, i + 1);
		lua_gettable(L, 1);
		poker_add(p, lua_tointeger(L, -1)-3, 1);
		lua_pop(L, 1);
	}
	
	node_t * node = node_create(p, weight);
	node->type = type;
	list_add(weights, node);

	printf("poker %d %d %d\n", type, weight, tl);
	poker_print(p);
	return 0;
}

static int ddz_get_score(lua_State * L) {
	int n = lua_tointeger(L, 1);
	
	if (n < 0 || n > ST_ROCKET) {
		printf("Error type.Should between 0 and 10");
		return 0;
	}

	lua_pushinteger(L, 0);
	return 1;
}

static int ddz_split(lua_State * L) {
	int argc = lua_objlen(L, 1);

	CARD cards[MAX_CARD_COUNT];

	for (int i = 0; i < argc; ++i) {
		lua_pushinteger(L, i + 1); //set key
		lua_gettable(L, 1);	//get table with the key
		cards[i] = lua_tointeger(L, -1) - 3; //get value
		lua_pop(L, 1);	//remove the result
	}

	poker_t * poker = poker_create(cards, argc);

	int count = 0;
	value_t val = poker_value(poker, &count);
	poker_split_single_pair(poker, &val);
	float total_score = 0;

	for (node_t * p = val.l->head; p; p = p->next) {
		poker_t * poker = p->poker;
		total_score += p->score;
	}

	val.score = total_score;

	// print
	printf("----------------\nsplit score %d\n", (int)total_score);
	for (node_t * p = val.l->head; p; p = p->next) {
		poker_t * poker = p->poker;
		printf("(%d) ", (int)p->score);
		poker_print(poker);
	}
	printf("----------------\n");
	// 分数
	lua_pushinteger(L, (int)total_score);
	// 新建并压入一个表
	lua_createtable(L, val.l->len, 0);
	int k = 1;

	for (node_t * p = val.l->head; p; p = p->next) {
		lua_pushinteger(L, k++);
		lua_createtable(L, 0, 0);
		poker_t * poker = p->poker;
		for (int i = 0; i < poker->len; ++i) {
			lua_pushinteger(L, i + 1);
			lua_pushnumber(L, poker->poker[i] + 3);
			lua_settable(L, -3);
		}
		lua_settable(L, -3);
	}

	list_free(val.l);
	poker_free(poker);
	return 2;
}

static const struct luaL_reg poker_ddz[] = {
	{ "split", ddz_split },
	{ "set_weight", ddz_set_weight },
	{ NULL, NULL }
};

LUA_API int luaopen_DDZCPoker(lua_State *L)
{
	init_weights();
	luaL_register(L, "cpoker", poker_ddz);
	return 0;
}

