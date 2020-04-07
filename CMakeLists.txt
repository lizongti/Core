
cmake_minimum_required(VERSION 3.10.0)
project(subdirectories VERSION 0.1.0)

set(PROJECT_ROOT_PATH ${PROJECT_SOURCE_DIR})
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${PROJECT_ROOT_PATH}/cmake)
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_ROOT_PATH}/bin)
set(LIBRARY_OUTPUT_PATH ${PROJECT_ROOT_PATH}/bin)

include(CTest)
include(CPack)
include(os)
include(status)
include(vcpkg)

file(GLOB children RELATIVE ${PROJECT_ROOT_PATH}/src ${PROJECT_ROOT_PATH}/src/*)
foreach(child ${children})
    if(IS_DIRECTORY ${PROJECT_ROOT_PATH}/src/${child})
        add_subdirectory(${PROJECT_ROOT_PATH}/src/${child})
    endif()
endforeach()