#ifndef PROCESS_H
#define PROCESS_H

#include "singleton.h"

class process
	: public singleton<process>
{
public:
	process &opt(int argc, char *argv[]);

	process &run();

protected:
	void init_signal();
};

#endif // !PROCESS_H