cmake_minimum_required(VERSION 3.10.0)
project(bootstrap VERSION 0.1.0)
message_project_name()

if(WINDOWS)
    msvc_export_symbols()
    msvc_link(MD)
endif()

use_c_standard(99)
use_cxx_standard(17)

include_directories(${PROJECT_ROOT_PATH})
aux_source_directory(${PROJECT_SOURCE_DIR} SOURCE_LIST)
add_library(bootstrap SHARED ${SOURCE_LIST})
message_all_status()
