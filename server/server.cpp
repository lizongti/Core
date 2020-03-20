#include "lime/core/headers.h"

#include <iostream>

int main(int argc, char *argv[])
{
	lime::core::process::instance().options(argc, argv).run();

	return 0;
}
