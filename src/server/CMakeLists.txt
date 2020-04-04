
cmake_minimum_required(VERSION 3.10.0)
project(Server VERSION 0.1.0)
message("Running CMake for project [" ${PROJECT_NAME} "]")

include(vcpkg)

use_c_standard(99)
use_cxx_standard(17)

msvc_link(MD)
include_directories(${PROJECT_ROOT_PATH} ${VCPKG_INCLUDE})
aux_source_directory(${PROJECT_SOURCE_DIR} SOURCE_LIST)
add_executable(Server ${SOURCE_LIST})

find_package(Boost REQUIRED COMPONENTS program_options filesystem)
target_link_libraries(Server ${Boost_LIBRARIES})
message_all_status()