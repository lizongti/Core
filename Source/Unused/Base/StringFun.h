#ifndef _STRING_FUN_
#define _STRING_FUN_
#include <vector>
#include <string>
using namespace std;

class CStrFun
{
public:
	CStrFun(void);
	
	~CStrFun(void);

	static void split(std::vector<std::string>& vectorstr, const char * const pstr, const char ch);
	
};

#endif