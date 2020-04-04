
cmake_minimum_required(VERSION 3.0.0)
project(Server VERSION 0.1.0)
message("Running cmake in " ${PROJECT_SOURCE_DIR})

include(CTest)
enable_testing()

include (compiler_c99)
include (compiler_cxx17)
include (linker_MD)
include (compiler_status)
include (vcpkg)

include_directories(${PROJECT_ROOT_PATH} ${VCPKG_INCLUDE})
aux_source_directory(${PROJECT_SOURCE_DIR} SOURCE_LIST)
add_executable(Server ${SOURCE_LIST})

find_package(Boost REQUIRED COMPONENTS program_options filesystem)
target_link_libraries(Server ${Boost_LIBRARIES})