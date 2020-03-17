#include <stdio.h>
#include <string>

#include <boost/filesystem.hpp>
#include <boost/format.hpp>

#ifdef __linux__
// call sigaction
#include <signal.h>
#endif

#ifdef _WIN32
// call SetConsoleOutputCP
#include <windows.h>
#include <stdio.h>
#include <iostream>

// call signal
#include <signal.h>

// add library deps for libuv
#pragma comment(lib, "IPHLPAPI.lib")
#pragma comment(lib, "Psapi.lib")
#pragma comment(lib, "ws2_32.lib")
#pragma comment(lib, "Userenv.lib")
#endif

#include "process.h"

process &process::opt(int argc, char *argv[])
{
	if (argc > 1)
	{
		Resource<std::string, std::string>::Set(STRING_INSTANCE_NAME, argv[1]);
		Resource<std::string, std::string>::Set(STRING_ENVIROMENT_VARIABLE, std::getenv(STRING_OS_ENV));
		Resource<std::string, std::string>::Set(STRING_WORK_DIRECTORY, boost::filesystem::initial_path<boost::filesystem::path>().string());
	}

	return *this;
}

process &process::Prepare(std::function<bool(void)> initialize,
						  std::function<bool(void)> serve,
						  std::function<bool(void)> finalize)
{
	initialize_ = initialize;
	serve_ = serve;
	finalize_ = finalize;
	return *this;
}

process &process::Run()
{
	Initialize();
	Serve();
	Finalize();
	return *this;
};

void process::Initialize()
{
#ifdef _WIN32
	// utf-8 => GBK
	SetConsoleOutputCP(65001);
#endif

	InitSignal();

	if (!initialize_())
	{
		fprintf(stderr, "process initializes error, exiting process.");
		exit(1);
	}
}

void process::Serve()
{
	if (!serve_())
	{
		fprintf(stderr, "process serves error, exiting process.");
		exit(1);
	}
}

void process::Finalize()
{
	if (!finalize_())
	{
		fprintf(stderr, "process finalizes error, exiting process.");
		exit(1);
	}
}

void process::InitSignal()
{
	// #ifdef __linux__
	// 	struct sigaction sa;
	// 	sa.sa_flags = 0;
	// 	sa.sa_handler = (void (*)(int))([](int) {
	// 		process::Instance().Finalize();
	// 	});
	// 	sigemptyset(&sa.sa_mask);
	// 	if (sigaction(SIGTERM, &sa, 0) != 0)
	// 	{
	// 		fprintf(stderr, "set handler for signal SIGTERM error");
	// 		exit(1);
	// 	}
	// #endif
	// #ifdef _WIN32
	// 	signal(SIGTERM, [](int) {
	// 		process::Instance().Finalize();
	// 	});
	// #endif
}