
#include "ants/executable.hpp"

#include <iostream>

int main(int argc, char *argv[])
{
    ants::kernel::process::instance().run(argc, argv);

    return 0;
}
