cmake_minimum_required(VERSION 3.0.0)
project(bootstrap VERSION 0.1.0)
message("Running CMake for project [" ${PROJECT_NAME} "]")

use_c_standard(99)
use_cxx_standard(17)

if(WINDOWS)
    msvc_link(MD)
    add_definitions("-DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=TRUE")
endif()

aux_source_directory(${PROJECT_SOURCE_DIR} SOURCE_LIST)
add_library(bootstrap SHARED ${SOURCE_LIST})
message_all_status()
