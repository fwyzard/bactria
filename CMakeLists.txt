# Copyright 2021 Jan Stephan
#
# Licensed under the EUPL, Version 1.2 or - as soon they will be approved by
# the European Commission - subsequent versions of the EUPL (the “Licence”).
# You may not use this work except in compliance with the Licence.
# You may obtain a copy of the Licence at:
#
#     http://ec.europa.eu/idabc/eupl.html
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the Licence is distributed on an “AS IS” basis, WITHOUT
#  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#  Licence permissions and limitations under the Licence.

cmake_minimum_required(VERSION 3.18)

project("bactria" VERSION       0.0.1
                  DESCRIPTION   "The bactria library is a header-only C++14 library for profiling and tracing."
                  HOMEPAGE_URL  "https://www.github.com/alpaka-group/bactria"
                  LANGUAGES     CXX)

include(CMakeDependentOption)
include(CMakePackageConfigHelpers)
include(FetchContent)
include(GNUInstallDirs)

###############################################################################
# Options and variants (not useful for installed version)
###############################################################################

option(bactria_BUILD_DOCUMENTATION "Generate the Doxygen documentation" OFF)
option(bactria_BUILD_EXAMPLES "Build examples" ON)
option(bactria_BUILD_PLUGINS "Build bactria's plugins" ON)

cmake_dependent_option(bactria_CUDA_PLUGINS "Build the CUDA toolkit plugins" OFF bactria_BUILD_PLUGINS OFF)
cmake_dependent_option(bactria_STDOUT_PLUGINS "Build the STDOUT plugins" ON bactria_BUILD_PLUGINS OFF)
cmake_dependent_option(bactria_SYSTEM_FMT "Use your local installation of {fmt}" ON bactria_STDOUT_PLUGINS OFF)
cmake_dependent_option(bactria_SYSTEM_TOML11 "Use your local installation of toml11" ON bactria_BUILD_PLUGINS OFF)
cmake_dependent_option(bactria_JSON_PLUGINS "Build the JSON plugins" ON bactria_BUILD_PLUGINS OFF)
cmake_dependent_option(bactria_SYSTEM_JSON "Use your local installation of nlohmann-json" ON bactria_JSON_PLUGINS OFF)
cmake_dependent_option(bactria_ROCM_PLUGINS "Build the ROCm plugins" OFF bactria_BUILD_PLUGINS OFF)
cmake_dependent_option(bactria_SCOREP_PLUGINS "Build the Score-P plugins" OFF bactria_BUILD_PLUGINS OFF)
cmake_dependent_option(bactria_STDOUT_PLUGINS "Build the STDOUT plugins" ON bactria_BUILD_PLUGINS OFF)

###############################################################################
# Internal variables
###############################################################################

# This file's directory.
set(_BACTRIA_ROOT_DIR ${CMAKE_CURRENT_LIST_DIR})
# Normalize the path (Remove ../).
get_filename_component(_BACTRIA_ROOT_DIR ${_BACTRIA_ROOT_DIR} ABSOLUTE)

# Add module search path.
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${_BACTRIA_ROOT_DIR}/cmake/modules)

# Set include directory.
set(_BACTRIA_INCLUDE_DIRECTORY ${_BACTRIA_ROOT_DIR}/include)

# Set plugin installation directory.
set(_BACTRIA_INSTALL_PLUGINDIR ${CMAKE_INSTALL_LIBDIR}/bactria/plugins)

include(${_BACTRIA_ROOT_DIR}/cmake/bactriaCommon.cmake)

# Used by subdirectories during installation
macro(bactria_install_plugin targetName)
    install(TARGETS ${targetName}
            ARCHIVE DESTINATION ${_BACTRIA_INSTALL_PLUGINDIR}
            LIBRARY DESTINATION ${_BACTRIA_INSTALL_PLUGINDIR}
            RUNTIME DESTINATION ${_BACTRIA_INSTALL_PLUGINDIR})
endmacro()

if(bactria_BUILD_DOCUMENTATION)
    add_subdirectory("docs")
endif()

if(bactria_BUILD_EXAMPLES)
    add_subdirectory("examples")
endif()

if(bactria_BUILD_PLUGINS)
    if(bactria_SYSTEM_TOML11)
        find_package(toml11 REQUIRED)
    else()
        message(STATUS "Downloading dependency toml11.")
        FetchContent_Declare(toml_eleven
            GIT_REPOSITORY https://github.com/ToruNiina/toml11.git
            GIT_TAG v3.7.0)
        FetchContent_MakeAvailable(toml_eleven)
    endif()

    if(bactria_CUDA_PLUGINS)
        find_package(CUDAToolkit REQUIRED)
    endif()

    if(bactria_JSON_PLUGINS)
        if(bactria_SYSTEM_JSON)
            find_package(nlohmann_json REQUIRED)
        else()
            message(STATUS "Downloading dependency nlohmann_json.")
            FetchContent_Declare(json
                GIT_REPOSITORY https://github.com/nlohmann/json.git
                GIT_TAG v3.9.1)
            FetchContent_GetProperties(json)
            if(NOT json_POPULATED)
                FetchContent_Populate(json)
                set(JSON_BuildTests OFF CACHE INTERNAL "")
                add_subdirectory(${json_SOURCE_DIR} ${json_BINARY_DIR} EXCLUDE_FROM_ALL)
            endif()
        endif()
    endif()

    if(bactria_ROCM_PLUGINS)
        find_package(rocTracer REQUIRED)
    endif()

    if(bactria_STDOUT_PLUGINS)
        if(bactria_SYSTEM_FMT)
            find_package(fmt REQUIRED)
        else()
            message(STATUS "Downloading dependency {fmt}.")
            FetchContent_Declare(fmtlib
                GIT_REPOSITORY https://github.com/fmtlib/fmt.git
                GIT_TAG 8.0.1)
            FetchContent_MakeAvailable(fmtlib)
        endif()
    endif()

    add_subdirectory("src")
endif()

###############################################################################
# Installation
###############################################################################

# Do not install if bactria is used as a CMake subdirectory
if(${CMAKE_PROJECT_NAME} STREQUAL ${PROJECT_NAME})
    set(_BACTRIA_INSTALL_CMAKEDIR ${CMAKE_INSTALL_LIBDIR}/cmake/bactria)

    write_basic_package_version_file(
        bactriaConfigVersion.cmake
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY SameMinorVersion)

    configure_package_config_file(
        ${_BACTRIA_ROOT_DIR}/cmake/bactriaConfig.cmake.in
        ${PROJECT_BINARY_DIR}/bactriaConfig.cmake
        INSTALL_DESTINATION ${_BACTRIA_INSTALL_CMAKEDIR})

    install(FILES ${PROJECT_BINARY_DIR}/bactriaConfig.cmake
                  ${PROJECT_BINARY_DIR}/bactriaConfigVersion.cmake
            DESTINATION ${_BACTRIA_INSTALL_CMAKEDIR})

    install(DIRECTORY ${_BACTRIA_ROOT_DIR}/include/bactria
            DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

    install(FILES ${_BACTRIA_ROOT_DIR}/cmake/bactriaCommon.cmake
            DESTINATION ${_BACTRIA_INSTALL_CMAKEDIR})
endif()
