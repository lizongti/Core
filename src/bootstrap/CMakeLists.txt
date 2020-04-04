cmake_minimum_required(VERSION 3.0.0)
project(bootstrap VERSION 0.1.0)

include(CTest)
enable_testing()

include (compiler_c99)
include (compiler_cxx17)
include (linker_MD)
include (compiler_status)

aux_source_directory(${PROJECT_SOURCE_DIR} SOURCE_LIST)
add_library(bootstrap SHARED ${SOURCE_LIST})
