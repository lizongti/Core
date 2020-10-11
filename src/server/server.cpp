
#include <iostream>

#include "ants/executable.hpp"

int main(int argc, char *argv[]) {
  ants::kernel::process::instance().run(argc, argv);

  return 0;
}
