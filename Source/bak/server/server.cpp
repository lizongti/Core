#include "lime/base/process.h"
#include "lime/base/singleton"

int main(int argc, char *argv[])
{
	lime::process::instance().opt(argc, argv).run();

	return 0;
}
