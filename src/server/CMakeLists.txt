
cmake_minimum_required(VERSION 3.10.0)
project(Server VERSION 0.2.0)
include(compiler-template-1)

message_project_name()
include_directories(${PROJECT_ROOT_PATH} ${VCPKG_INCLUDE})
aux_source_directory(${PROJECT_SOURCE_DIR} SOURCE_LIST)
add_executable(${PROJECT_NAME} ${SOURCE_LIST})

link_directories(${VCPKG_LIB} ${VCPKG_BIN})
find_package(Boost REQUIRED COMPONENTS program_options filesystem)
target_link_libraries(${PROJECT_NAME} ${Boost_LIBRARIES} jemalloc)
message_all_status()