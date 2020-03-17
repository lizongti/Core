#include "StringFun.h"

CStrFun::CStrFun(void)
{

}
CStrFun::~CStrFun(void)
{

}

void CStrFun::split(std::vector<std::string>& vectorstr, const char * const pstr, const char ch)
{
	if ( 0 == pstr )
	{
		return;
	}
	vectorstr.clear();
	const char * pstart = pstr;
	for (const char * pchr = pstr; ; pchr++)
	{
		if ( '\0' == * pchr)
		{
			if (pchr != pstart)
			{
				vectorstr.push_back( std::string(pstart , pchr - pstart ) );
			}
			return ;
		}
		else if ( ch == (*pchr) )
		{
			if ( pchr != pstart )
			{
				vectorstr.push_back( std::string(pstart , pchr - pstart ) );
			}
			pstart = pchr + 1 ;
		}
	}
}
