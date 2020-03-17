#include "lime/base/process.hpp"

int main(int argc, char *argv[])
{
	lime::process::instance().options(argc, argv).run();

	return 0;
}
