#include "../Base/BaseHeaders.h"
#include "../Service/MainService.hpp"

int main(int argc, char *argv[])
{
	Process::Instance()
		.Opt(argc, argv)
		.Prepare([]() { return singleton<MainService>::Instance().Init(); },
				 []() { return singleton<MainService>::Instance().Start(); },
				 []() { return singleton<MainService>::Instance().Stop(); })
		.Run();

	return 0;
}
