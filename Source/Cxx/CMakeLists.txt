
cmake_minimum_required(VERSION 2.7)
project(Server)

set(CMAKE_C_COMPILER "C:/mingw64/bin/gcc.exe")
set(CMAKE_CXX_COMPILER "C:/mingw64/bin/g++.exe")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -w -static-libgcc -std=gnu99")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -g -ggdb -D__DEBUG")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO} -O3 -g -ggdb -D__RELWITHDEBINFO")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O3 -g -ggdb -D__RELEASE")

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -w -static-libgcc -std=gnu++11")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g -ggdb -D__DEBUG")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} -O3 -g -ggdb -D__RELWITHDEBINFO")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -g -ggdb -D__RELEASE")

include_directories("." "C:/Program Files/vcpkg/installed/x64-windows/include")
link_directories("C:/Program Files/vcpkg/installed/x64-windows/lib")
add_executable(Server server/server.cpp)
# target_link_libraries(Server boost_program_options-vc140-mt boost_system-vc140-mt)
target_link_libraries(Server boost_program_options-vc140-mt boost_system-vc140-mt)