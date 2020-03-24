#include "ants/core/headers.h"

#include <iostream>

int main(int argc, char *argv[])
{
	ants::core::process::instance()
		.options(argc, argv)
		.run();

	return 0;
}
