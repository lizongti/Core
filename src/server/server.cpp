#include "ants/core/process.hpp"

#include <iostream>

int main(int argc, char *argv[])
{
	ants::core::process::instance().run(argc, argv);

	return 0;
}
