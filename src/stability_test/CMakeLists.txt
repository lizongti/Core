cmake_minimum_required(VERSION 3.10.0)
project(stability_test VERSION 0.1.0)
include(build)

message_project_name()
include_directories(${PROJECT_ROOT_PATH})
aux_source_directory(${PROJECT_SOURCE_DIR} SOURCE_LIST)
add_library(${PROJECT_NAME} SHARED ${SOURCE_LIST})
message_all_status()
