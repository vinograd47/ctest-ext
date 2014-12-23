##################################################################################
# The MIT License (MIT)
#
# Copyright (c) 2014 Vladislav Vinogradov <vlad.vinogradov47@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
##################################################################################

cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)

if(DEFINED CTEST_EXT_INCLUDED)
    return()
endif()
set(CTEST_EXT_INCLUDED TRUE)
set(CTEST_EXT_VERSION  0.2)

include(CMakeParseArguments)

#
# Check functions
#

function(set_ifndef VAR)
    if(NOT DEFINED ${VAR})
        set(${VAR} "${ARGN}" PARENT_SCOPE)
    endif()
endfunction()

function(check_vars_def)
    foreach(var ${ARGN})
        if(NOT DEFINED ${var})
            message(FATAL_ERROR "${var} is not defined")
        endif()
    endforeach()
endfunction()

function(check_vars_exist)
    check_vars_def(${ARGN})

    foreach(var ${ARGN})
        if(NOT EXISTS "${${var}}")
            message(FATAL_ERROR "${var} = ${${var}} is not exist")
        endif()
    endforeach()
endfunction()

function(check_if_matches VAR)
    check_vars_def(${VAR})

    set(found FALSE)
    foreach(regexp ${ARGN})
        if(${VAR} MATCHES "${regexp}")
            set(found TRUE)
            break()
        endif()
    endforeach()

    if(NOT found)
        message(FATAL_ERROR "${VAR} must match one from ${ARGN} list")
    endif()
endfunction()

function(ctest_info)
    message("[CTEST EXT INFO] ${ARGN}")
endfunction()

#
# System functions
#

function(create_tmp_dir OUT_VAR)
    if(NOT DEFINED CTEST_TMP_DIR)
        foreach(dir "$ENV{TEMP}" "$ENV{TMP}" "$ENV{TMPDIR}" "/tmp")
            if (EXISTS "${dir}")
                set(CTEST_TMP_DIR "${dir}")
            endif()
        endforeach()
    endif()

    check_vars_exist(CTEST_TMP_DIR)

    string(RANDOM rand_name)
    while(EXISTS "${CTEST_TMP_DIR}/${rand_name}")
        string(RANDOM rand_name)
    endwhile(condition)

    set(tmp_dir "${CTEST_TMP_DIR}/${rand_name}")

    ctest_info("Create temporary directory : ${tmp_dir}")
    file(MAKE_DIRECTORY "${tmp_dir}")

    set(${OUT_VAR} "${tmp_dir}" PARENT_SCOPE)
endfunction()

#
# git repo control functions
#

function(checkout_git_repo GIT_URL GIT_DEST_DIR)
    set(options "")
    set(oneValueArgs "BRANCH")
    set(multiValueArgs "")
    cmake_parse_arguments(GIT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    check_vars_exist(CTEST_GIT_COMMAND)

    if(GIT_BRANCH)
        ctest_info("Clone git repository ${GIT_URL} (branch ${GIT_BRANCH}) to ${GIT_DEST_DIR}")
        execute_process(COMMAND "${CTEST_GIT_COMMAND}" clone -b ${GIT_BRANCH} -- ${GIT_URL} ${GIT_DEST_DIR})
    else()
        ctest_info("Clone git repository ${GIT_URL} to ${GIT_DEST_DIR}")
        execute_process(COMMAND "${CTEST_GIT_COMMAND}" clone ${GIT_URL} ${GIT_DEST_DIR})
    endif()
endfunction()

function(update_git_repo GIT_REPO_DIR)
    set(options "")
    set(oneValueArgs "REMOTE" "BRANCH" "UPDATE_COUNT_OUTPUT")
    set(multiValueArgs "")
    cmake_parse_arguments(GIT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # TODO : use FETCH_HEAD
    set_ifndef(GIT_REMOTE "origin")
    check_vars_def(GIT_BRANCH)

    check_vars_exist(CTEST_GIT_COMMAND)

    ctest_info("Fetch git remote repository ${GIT_REMOTE} (branch ${GIT_BRANCH}) in ${GIT_REPO_DIR}")
    execute_process(COMMAND "${CTEST_GIT_COMMAND}" fetch
        WORKING_DIRECTORY "${GIT_REPO_DIR}")

    if(GIT_UPDATE_COUNT_OUTPUT)
        ctest_info("Compare git local repository with ${GIT_REMOTE}/${GIT_BRANCH} state in ${GIT_REPO_DIR}")
        execute_process(COMMAND "${CTEST_GIT_COMMAND}" diff HEAD "${GIT_REMOTE}/${GIT_BRANCH}"
            WORKING_DIRECTORY "${GIT_REPO_DIR}"
            OUTPUT_VARIABLE diff_output)

        string(LENGTH "${diff_output}" update_count)
        set(${GIT_UPDATE_COUNT_OUTPUT} "${update_count}" PARENT_SCOPE)
    endif()

    ctest_info("Reset git local repository to ${GIT_REMOTE}/${GIT_BRANCH} state in ${GIT_REPO_DIR}")
    execute_process(COMMAND "${CTEST_GIT_COMMAND}" reset --hard "${GIT_REMOTE}/${GIT_BRANCH}"
        WORKING_DIRECTORY "${GIT_REPO_DIR}")
endfunction()

function(get_git_repo_info GIT_REPO_DIR BRANCH_OUT_VAR REVISION_OUT_VAR)
    if(CTEST_GIT_COMMAND)
        execute_process(COMMAND "${CTEST_GIT_COMMAND}" rev-parse --abbrev-ref HEAD
            WORKING_DIRECTORY "${GIT_REPO_DIR}"
            OUTPUT_VARIABLE branch
            OUTPUT_STRIP_TRAILING_WHITESPACE)

        execute_process(COMMAND "${CTEST_GIT_COMMAND}" rev-parse HEAD
            WORKING_DIRECTORY "${GIT_REPO_DIR}"
            OUTPUT_VARIABLE revision
            OUTPUT_STRIP_TRAILING_WHITESPACE)
    else()
        set(branch "unknown")
        set(revision "unknown")
    endif()

    set(${BRANCH_OUT_VAR} ${branch} PARENT_SCOPE)
    set(${REVISION_OUT_VAR} ${revision} PARENT_SCOPE)
endfunction()

#
# CMake configuration functions
#

function(add_cmake_option NAME TYPE VALUE)
    if(NOT CTEST_CMAKE_OPTIONS MATCHES "-D${NAME}")
        string(REPLACE ";" " " VALUE "${VALUE}")
        list(APPEND CTEST_CMAKE_OPTIONS "-D${NAME}:${TYPE}=${VALUE}")
    endif()

    set(CTEST_CMAKE_OPTIONS ${CTEST_CMAKE_OPTIONS} PARENT_SCOPE)
endfunction()

#
# gcovr coverage report
#

function(run_gcovr)
    set(options "XML" "HTML" "VERBOSE")
    set(oneValueArgs "OUTPUT_BASE_NAME" "REPORT_BASE_DIR")
    set(multiValueArgs "OPTIONS")
    cmake_parse_arguments(GCOVR "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    check_vars_exist(CTEST_GCOVR_EXECUTABLE)

    set_ifndef(GCOVR_OUTPUT_BASE_NAME "coverage")
    if(NOT DEFINED GCOVR_REPORT_BASE_DIR)
        check_vars_def(CTEST_GCOVR_REPORT_DIR)
        set(GCOVR_REPORT_BASE_DIR "${CTEST_GCOVR_REPORT_DIR}")
    endif()

    list(APPEND GCOVR_COMMAND_LINE "${CTEST_GCOVR_EXECUTABLE}" "${CTEST_BINARY_DIRECTORY}")
    list(APPEND GCOVR_COMMAND_LINE -r "${CTEST_SOURCE_DIRECTORY}")
    if(GCOVR_VERBOSE)
        list(APPEND GCOVR_COMMAND_LINE "--verbose")
    endif()
    if(GCOVR_OPTIONS)
        list(APPEND GCOVR_COMMAND_LINE ${GCOVR_OPTIONS})
    elseif(CTEST_GCOVR_EXTRA_FLAGS)
        list(APPEND GCOVR_COMMAND_LINE ${CTEST_GCOVR_EXTRA_FLAGS})
    endif()

    if(GCOVR_XML)
        set(GCOVR_XML_DIR "${GCOVR_REPORT_BASE_DIR}/xml")
        if(EXISTS "${GCOVR_XML_DIR}")
            file(REMOVE_RECURSE "${GCOVR_XML_DIR}")
        endif()
        file(MAKE_DIRECTORY "${GCOVR_REPORT_BASE_DIR}" "${GCOVR_XML_DIR}")

        ctest_info("Generate XML gcovr report : ${GCOVR_COMMAND_LINE} --xml --xml-pretty -o coverage.xml")
        execute_process(COMMAND ${GCOVR_COMMAND_LINE} --xml --xml-pretty -o coverage.xml
            WORKING_DIRECTORY "${GCOVR_XML_DIR}")
    endif()

    if(GCOVR_HTML)
        set(GCOVR_HTML_DIR "${GCOVR_REPORT_BASE_DIR}/html")
        if(EXISTS "${GCOVR_HTML_DIR}")
            file(REMOVE_RECURSE "${GCOVR_HTML_DIR}")
        endif()
        file(MAKE_DIRECTORY "${GCOVR_REPORT_BASE_DIR}" "${GCOVR_HTML_DIR}")

        ctest_info("Generate HTML gcovr report : ${GCOVR_COMMAND_LINE} --html --html-details -o coverage.html")
        execute_process(COMMAND ${GCOVR_COMMAND_LINE} --html --html-details -o coverage.html
            WORKING_DIRECTORY "${GCOVR_HTML_DIR}")
    endif()
endfunction()

#
# CTest Log functions
#

function(ctest_note)
    check_vars_def(CTEST_NOTES_LOG_FILE)

    message("[CTEST EXT NOTE] ${ARGN}")
    file(APPEND "${CTEST_NOTES_LOG_FILE}" "${ARGN}\n")
endfunction()

function(ctest_ext_dump_notes)
    ctest_info("==========================================================================")
    ctest_info("CTest configuration information")
    ctest_info("==========================================================================")

    get_git_repo_info("${CTEST_SOURCE_DIRECTORY}" CTEST_CURRENT_BRANCH CTEST_CURRENT_REVISION)

    ctest_note("Configuration for CTest submission:")
    ctest_note("")

    ctest_note("CTEST_EXT_VERSION                     : ${CTEST_EXT_VERSION}")
    ctest_note("CTEST_PROJECT_NAME                    : ${CTEST_PROJECT_NAME}")
    ctest_note("")

    ctest_note("CTEST_TARGET_SYSTEM                   : ${CTEST_TARGET_SYSTEM}")
    ctest_note("CTEST_MODEL                           : ${CTEST_MODEL}")
    ctest_note("")

    ctest_note("CTEST_SITE                            : ${CTEST_SITE}")
    ctest_note("CTEST_BUILD_NAME                      : ${CTEST_BUILD_NAME}")
    ctest_note("")

    ctest_note("CTEST_DASHBOARD_ROOT                  : ${CTEST_DASHBOARD_ROOT}")
    ctest_note("CTEST_SOURCE_DIRECTORY                : ${CTEST_SOURCE_DIRECTORY}")
    ctest_note("CTEST_BINARY_DIRECTORY                : ${CTEST_BINARY_DIRECTORY}")
    ctest_note("CTEST_NOTES_LOG_FILE                  : ${CTEST_NOTES_LOG_FILE}")
    ctest_note("")

    ctest_note("CTEST_WITH_UPDATE                     : ${CTEST_WITH_UPDATE}")
    ctest_note("CTEST_GIT_COMMAND                     : ${CTEST_GIT_COMMAND}")
    ctest_note("CTEST_PROJECT_GIT_URL                 : ${CTEST_PROJECT_GIT_URL}")
    ctest_note("CTEST_PROJECT_GIT_BRANCH              : ${CTEST_PROJECT_GIT_BRANCH}")
    ctest_note("CTEST_CURRENT_BRANCH                  : ${CTEST_CURRENT_BRANCH}")
    ctest_note("CTEST_CURRENT_REVISION                : ${CTEST_CURRENT_REVISION}")
    ctest_note("")

    ctest_note("CTEST_UPDATE_CMAKE_CACHE              : ${CTEST_UPDATE_CMAKE_CACHE}")
    ctest_note("CTEST_EMPTY_BINARY_DIRECTORY          : ${CTEST_EMPTY_BINARY_DIRECTORY}")
    ctest_note("CTEST_WITH_TESTS                      : ${CTEST_WITH_TESTS}")
    ctest_note("CTEST_TEST_TIMEOUT                    : ${CTEST_TEST_TIMEOUT}")
    ctest_note("CTEST_WITH_MEMCHECK                   : ${CTEST_WITH_MEMCHECK}")
    ctest_note("CTEST_WITH_COVERAGE                   : ${CTEST_WITH_COVERAGE}")
    ctest_note("CTEST_WITH_GCOVR                      : ${CTEST_WITH_GCOVR}")
    ctest_note("CTEST_WITH_SUBMIT                     : ${CTEST_WITH_SUBMIT}")
    ctest_note("")

    ctest_note("CTEST_CMAKE_GENERATOR                 : ${CTEST_CMAKE_GENERATOR}")
    ctest_note("CTEST_CONFIGURATION_TYPE              : ${CTEST_CONFIGURATION_TYPE}")
    ctest_note("CTEST_CMAKE_OPTIONS                   : ${CTEST_CMAKE_OPTIONS}")
    ctest_note("CTEST_BUILD_FLAGS                     : ${CTEST_BUILD_FLAGS}")
    ctest_note("")

    ctest_note("CTEST_MEMORYCHECK_COMMAND             : ${CTEST_MEMORYCHECK_COMMAND}")
    ctest_note("CTEST_MEMORYCHECK_SUPPRESSIONS_FILE   : ${CTEST_MEMORYCHECK_SUPPRESSIONS_FILE}")
    ctest_note("CTEST_MEMORYCHECK_COMMAND_OPTIONS     : ${CTEST_MEMORYCHECK_COMMAND_OPTIONS}")
    ctest_note("")

    ctest_note("CTEST_COVERAGE_COMMAND                : ${CTEST_COVERAGE_COMMAND}")
    ctest_note("CTEST_COVERAGE_EXTRA_FLAGS            : ${CTEST_COVERAGE_EXTRA_FLAGS}")
    ctest_note("")

    ctest_note("CTEST_GCOVR_EXECUTABLE                : ${CTEST_GCOVR_EXECUTABLE}")
    ctest_note("CTEST_GCOVR_EXTRA_FLAGS               : ${CTEST_GCOVR_EXTRA_FLAGS}")
    ctest_note("CTEST_GCOVR_REPORT_DIR                : ${CTEST_GCOVR_REPORT_DIR}")
    ctest_note("")

    ctest_note("CTEST_NOTES_FILES                     : ${CTEST_NOTES_FILES}")
    ctest_note("CTEST_UPLOAD_FILES                    : ${CTEST_UPLOAD_FILES}")
    ctest_note("")
endfunction()

#
# CTest Ext initialize
#

macro(ctest_ext_init)
    # Dashboard settings

    site_name(SITE_NAME)

    set_ifndef(CTEST_TARGET_SYSTEM                      "${CMAKE_SYSTEM}-${CMAKE_SYSTEM_PROCESSOR}")
    set_ifndef(CTEST_MODEL                              "Experimental")

    set_ifndef(CTEST_SITE                               "${SITE_NAME}")
    set_ifndef(CTEST_BUILD_NAME                         "${CTEST_TARGET_SYSTEM}-${CTEST_MODEL}")

    set_ifndef(CTEST_DASHBOARD_ROOT                     "${CTEST_SCRIPT_DIRECTORY}/${CTEST_TARGET_SYSTEM}/${CTEST_MODEL}")
    set_ifndef(CTEST_SOURCE_DIRECTORY                   "${CTEST_DASHBOARD_ROOT}/source")
    set_ifndef(CTEST_BINARY_DIRECTORY                   "${CTEST_DASHBOARD_ROOT}/build")
    set_ifndef(CTEST_NOTES_LOG_FILE                     "${CTEST_DASHBOARD_ROOT}/ctest_notes_log.txt")

    # Repository settings

    find_package(Git QUIET)

    if(EXISTS "${GIT_EXECUTABLE}")
        set_ifndef(CTEST_WITH_UPDATE                        TRUE)
        set_ifndef(CTEST_GIT_COMMAND                        "${GIT_EXECUTABLE}")
    else()
        set_ifndef(CTEST_WITH_UPDATE                        FALSE)
    endif()

    # Find tools

    if(NOT DEFINED CTEST_COVERAGE_COMMAND)
        find_program(CTEST_COVERAGE_COMMAND NAMES gcov)
    endif()

    if(NOT DEFINED CTEST_GCOVR_EXECUTABLE)
        find_program(CTEST_GCOVR_EXECUTABLE NAMES gcovr)
    endif()

    if(NOT DEFINED CTEST_MEMORYCHECK_COMMAND)
        find_program(CTEST_MEMORYCHECK_COMMAND NAMES valgrind)
    endif()

    # Stage

    set_ifndef(CTEST_STAGE "${CTEST_SCRIPT_ARG}")
    if(NOT CTEST_STAGE)
        set(CTEST_STAGE "Start;Configure;Build;Test;Coverage;MemCheck;Submit;Extra")
    endif()

    # Initialize

    set(HAVE_UPDATES TRUE)

    if(CTEST_STAGE MATCHES "Start")
        ctest_info("==========================================================================")
        ctest_info("Initialize testing for MODEL ${CTEST_MODEL} (CTest Ext module version ${CTEST_EXT_VERSION})")
        ctest_info("==========================================================================")

        if(NOT EXISTS "${CTEST_SOURCE_DIRECTORY}")
            if(NOT DEFINED CTEST_CHECKOUT_COMMAND)
                check_vars_exist(CTEST_GIT_COMMAND)
                check_vars_def(CTEST_PROJECT_GIT_URL)

                if(CTEST_PROJECT_GIT_BRANCH)
                    set(CTEST_CHECKOUT_COMMAND "${CTEST_GIT_COMMAND} clone -b ${CTEST_PROJECT_GIT_BRANCH} -- ${CTEST_PROJECT_GIT_URL} ${CTEST_SOURCE_DIRECTORY}")
                else()
                    set(CTEST_CHECKOUT_COMMAND "${CTEST_GIT_COMMAND} clone ${CTEST_PROJECT_GIT_URL} ${CTEST_SOURCE_DIRECTORY}")
                endif()
            endif()
        endif()

        ctest_info("Initial start and checkout")
        ctest_start("${CTEST_MODEL}")

        if(CTEST_WITH_UPDATE)
            if(NOT DEFINED CTEST_UPDATE_COMMAND)
                check_vars_exist(CTEST_GIT_COMMAND)

                set(CTEST_UPDATE_COMMAND "${CTEST_GIT_COMMAND}")
            endif()

            ctest_info("Repository update")
            ctest_update(RETURN_VALUE count)

            set(HAVE_UPDATES FALSE)
            if(count GREATER 0)
                set(HAVE_UPDATES TRUE)
            endif()
        endif()
    endif()
endmacro()

#
# CTest Ext set default vars
#

macro(ctest_ext_set_default)
    set_ifndef(CTEST_UPDATE_CMAKE_CACHE TRUE)
    set_ifndef(CTEST_EMPTY_BINARY_DIRECTORY TRUE)
    set_ifndef(CTEST_WITH_TESTS TRUE)
    set_ifndef(CTEST_TEST_TIMEOUT 600)
    set_ifndef(CTEST_WITH_MEMCHECK FALSE)
    set_ifndef(CTEST_WITH_COVERAGE FALSE)
    set_ifndef(CTEST_WITH_GCOVR FALSE)
    set_ifndef(CTEST_WITH_SUBMIT FALSE)
    set_ifndef(CTEST_GCOVR_REPORT_DIR "${CTEST_BINARY_DIRECTORY}/coverage")
    list(APPEND CTEST_UPLOAD_FILES "${CTEST_BINARY_DIRECTORY}/CMakeCache.txt")
endmacro()

#
# CTest Ext start
#

macro(ctest_ext_start)
    set_ifndef(CTEST_TRACK "${CTEST_MODEL}")

    ctest_info("==========================================================================")
    ctest_info("Start testing MODEL ${CTEST_MODEL} TRACK ${CTEST_TRACK}")
    ctest_info("==========================================================================")

    ctest_start("${CTEST_MODEL}" TRACK "${CTEST_TRACK}" APPEND)

    check_vars_def(
        CTEST_PROJECT_NAME
        CTEST_NOTES_LOG_FILE
        CTEST_UPDATE_CMAKE_CACHE CTEST_EMPTY_BINARY_DIRECTORY
        CTEST_WITH_TESTS CTEST_WITH_MEMCHECK CTEST_WITH_COVERAGE CTEST_WITH_GCOVR CTEST_WITH_SUBMIT
        CTEST_CMAKE_GENERATOR CTEST_CONFIGURATION_TYPE)

    list(APPEND CTEST_NOTES_FILES "${CTEST_NOTES_LOG_FILE}")

    if(CTEST_STAGE MATCHES "Start")
        file(REMOVE "${CTEST_NOTES_LOG_FILE}")
        ctest_ext_dump_notes()
    endif()
endmacro()

#
# CTest Ext clean build
#

function(ctest_ext_clean_build)
    if(CTEST_STAGE MATCHES "Configure")
        ctest_info("==========================================================================")
        ctest_info("Clean binary directory")
        ctest_info("==========================================================================")

        file(MAKE_DIRECTORY "${CTEST_BINARY_DIRECTORY}")

        if(CTEST_EMPTY_BINARY_DIRECTORY)
            ctest_empty_binary_directory("${CTEST_BINARY_DIRECTORY}")
        endif()

        if(CTEST_UPDATE_CMAKE_CACHE AND EXISTS "${CTEST_BINARY_DIRECTORY}/CMakeCache.txt")
            file(REMOVE "${CTEST_BINARY_DIRECTORY}/CMakeCache.txt")
        endif()
    endif()
endfunction()

#
# CTest Ext configure
#

macro(ctest_ext_configure)
    if(CTEST_STAGE MATCHES "Configure")
        ctest_info("==========================================================================")
        ctest_info("Configure")
        ctest_info("==========================================================================")

        ctest_configure(OPTIONS "${CTEST_CMAKE_OPTIONS}")
    endif()

    ctest_read_custom_files("${CTEST_BINARY_DIRECTORY}")
endmacro()

#
# CTest Ext build
#

function(ctest_ext_build)
    set(options "")
    set(oneValueArgs "TARGET")
    set(multiValueArgs "TARGETS")
    cmake_parse_arguments(BUILD "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(CTEST_STAGE MATCHES "Build")
        ctest_info("==========================================================================")
        ctest_info("Build")
        ctest_info("==========================================================================")

        if(BUILD_TARGET)
            ctest_info("Build target : ${BUILD_TARGET}")
            ctest_build(TARGET "${BUILD_TARGET}")
        elseif(BUILD_TARGETS)
            ctest_info("Build targets : ${BUILD_TARGETS}")

            # ctest_build doesn't support multiple target, emulate them with CMake script
            set(BUILD_SCRIPT "${CTEST_BINARY_DIRECTORY}/ctest_ext_build.cmake")
            file(REMOVE "${BUILD_SCRIPT}")

            foreach(target ${BUILD_TARGETS})
                file(APPEND "${BUILD_SCRIPT}" "message(STATUS \"Build target : ${target}\") \n")

                set(BUILD_COMMAND "execute_process(COMMAND \"${CMAKE_COMMAND}\"")
                set(BUILD_COMMAND "${BUILD_COMMAND} --build \"${CTEST_BINARY_DIRECTORY}\"")
                if(NOT target MATCHES "^(all|ALL)$")
                    set(BUILD_COMMAND "${BUILD_COMMAND} --target \"${target}\"")
                endif()
                set(BUILD_COMMAND "${BUILD_COMMAND} --config \"${CTEST_CONFIGURATION_TYPE}\"")
                if(CTEST_BUILD_FLAGS)
                    set(BUILD_COMMAND "${BUILD_COMMAND} -- ${CTEST_BUILD_FLAGS}")
                endif()

                set(BUILD_COMMAND "${BUILD_COMMAND} WORKING_DIRECTORY \"${CTEST_BINARY_DIRECTORY}\")")

                file(APPEND "${BUILD_SCRIPT}" "${BUILD_COMMAND} \n")
            endforeach()

            set(CTEST_BUILD_COMMAND "${CMAKE_COMMAND} -P ${BUILD_SCRIPT}")
            ctest_build()
        else()
            ctest_info("Build target : ALL")
            ctest_build()
        endif()
    endif()
endfunction()

#
# CTest Ext test
#

function(ctest_ext_test)
    if(CTEST_WITH_TESTS AND CTEST_STAGE MATCHES "Test")
        ctest_info("==========================================================================")
        ctest_info("Test")
        ctest_info("==========================================================================")

        ctest_info("Parameters : ${ARGN}")
        ctest_test(${ARGN})
    endif()
endfunction()

#
# CTest Ext test
#

function(ctest_ext_coverage)
    set(options "")
    set(oneValueArgs "")
    set(multiValueArgs "GCOVR_OPTIONS" "CTEST_OPTIONS")
    cmake_parse_arguments(COVERAGE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(CTEST_WITH_TESTS AND CTEST_STAGE MATCHES "Coverage")
        if(CTEST_WITH_GCOVR)
            ctest_info("==========================================================================")
            ctest_info("Generate gcovr coverage report")
            ctest_info("==========================================================================")

            ctest_info("Parameters : ${COVERAGE_GCOVR_OPTIONS}")
            run_gcovr(${COVERAGE_GCOVR_OPTIONS})
        endif()

        if(CTEST_WITH_COVERAGE)
            check_vars_def(CTEST_COVERAGE_COMMAND)

            ctest_info("==========================================================================")
            ctest_info("Generate CTest coverage report")
            ctest_info("==========================================================================")

            ctest_info("Parameters : ${COVERAGE_CTEST_OPTIONS}")
            ctest_coverage(${COVERAGE_CTEST_OPTIONS})
        endif()
    endif()
endfunction()

#
# CTest Ext test
#

function(ctest_ext_memcheck)
    if(CTEST_WITH_MEMCHECK AND CTEST_STAGE MATCHES "MemCheck")
        check_vars_def(CTEST_MEMORYCHECK_COMMAND)

        ctest_info("==========================================================================")
        ctest_info("MemCheck")
        ctest_info("==========================================================================")

        ctest_info("Parameters : ${ARGN}")
        ctest_memcheck(${ARGN})
    endif()
endfunction()

#
# CTest Ext test
#

function(ctest_ext_submit)
    if(CTEST_WITH_SUBMIT AND CTEST_STAGE MATCHES "Submit")
        ctest_info("==========================================================================")
        ctest_info("Submit")
        ctest_info("==========================================================================")

        if(CTEST_UPLOAD_FILES)
            ctest_info("Upload files : ${CTEST_UPLOAD_FILES}")
            ctest_upload(FILES ${CTEST_UPLOAD_FILES})
        endif()

        ctest_submit()
    endif()
endfunction()
