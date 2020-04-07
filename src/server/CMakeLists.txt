
cmake_minimum_required(VERSION 3.10.0)
project(Server VERSION 0.2.0)
message_project_name()

use_c_standard(99)
use_cxx_standard(17)

msvc_link(MD)
include_directories(${PROJECT_ROOT_PATH} ${VCPKG_INCLUDE})
link_directories(${VCPKG_LIB} ${VCPKG_BIN})
aux_source_directory(${PROJECT_SOURCE_DIR} SOURCE_LIST)
add_executable(Server ${SOURCE_LIST})

find_package(Boost REQUIRED COMPONENTS program_options filesystem)
target_link_libraries(Server ${Boost_LIBRARIES} jemalloc)
link_directories()
message_all_status()