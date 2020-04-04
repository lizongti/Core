
cmake_minimum_required(VERSION 3.0.0)
project(Server VERSION 0.1.0)
message("project source dir: ${PROJECT_SOURCE_DIR}")
set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}" "${PROJECT_SOURCE_DIR}/cmake/")

include(CTest)
enable_testing()

include (compiler_c99)
include (compiler_cxx17)
include (linker_MD)
include (compiler_status)
include (vcpkg)

set(EXECUTABLE_OUTPUT_PATH "${PROJECT_SOURCE_DIR}/bin")
find_package(Boost REQUIRED COMPONENTS program_options filesystem)
aux_source_directory(${PROJECT_SOURCE_DIR}/server SOURCE_LIST)
include_directories(${PROJECT_SOURCE_DIR} ${VCPKG_INCLUDE})
add_executable(Server ${SOURCE_LIST})
target_link_libraries(Server ${Boost_LIBRARIES})