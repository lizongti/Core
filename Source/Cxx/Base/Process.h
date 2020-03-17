#ifndef PROCESS_H
#define PROCESS_H

#include "singleton.h"

class Process
	: public singleton<Process>
{
public:
	Process &Opt(int argc, char *argv[]);

	Process &Prepare(std::function<bool(void)> initialize,
					 std::function<bool(void)> run,
					 std::function<bool(void)> finalize);

	Process &Run();

protected:
	void Initialize();

	void Serve();

	void Finalize();

protected:
	void InitSignal();

protected:
	std::function<bool(void)> initialize_;
	std::function<bool(void)> serve_;
	std::function<bool(void)> finalize_;
};

#endif // !PROCESS_H