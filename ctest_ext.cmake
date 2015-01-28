##################################################################################
# The MIT License (MIT)
#
# Copyright (c) 2014-2015 Vladislav Vinogradov
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
set(CTEST_EXT_VERSION  0.3)

include(CMakeParseArguments)

##################################################################################
# Check commands
##################################################################################

#
# set_ifndef(<variable> <value>)
#
#   Sets <variable> to the value <value>, only if the <variable> is not defined.
#
function(set_ifndef VAR)
    if(NOT DEFINED ${VAR})
        set(${VAR} "${ARGN}" PARENT_SCOPE)
    endif()
endfunction()

#
# check_vars_def(<variable1> <variable2> ...)
#
#   Checks that all variables are defined.
#
function(check_vars_def)
    foreach(var ${ARGN})
        if(NOT DEFINED ${var})
            message(FATAL_ERROR "${var} is not defined")
        endif()
    endforeach()
endfunction()

#
# check_vars_exist(<variable1> <variable2> ...)
#
#   Checks that all variables are defined and point to existed file/directory.
#
function(check_vars_exist)
    check_vars_def(${ARGN})

    foreach(var ${ARGN})
        if(NOT EXISTS "${${var}}")
            message(FATAL_ERROR "${var} = ${${var}} is not exist")
        endif()
    endforeach()
endfunction()

#
# check_if_matches(<variable> <regexp1> <regexp2> ...)
#
#   Checks that <variable> matches one of the regular expression from the input list.
#
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
        message(FATAL_ERROR "${VAR}=${${VAR}} must match one from ${ARGN} list")
    endif()
endfunction()

#
# ctest_ext_info(<message>)
#
#   Prints <message> to standard output with [CTEST EXT INFO] prefix for better visibility.
#
function(ctest_ext_info)
    message("[CTEST EXT INFO] ${ARGN}")
endfunction()

##################################################################################
# System commands
##################################################################################

#
# create_tmp_dir(<output_variable> [BASE_DIR <path to base temp directory>])
#
#   Creates temporary directory and returns path to it via <output_variable>.
#
#   `BASE_DIR` can be used to specify location for base temporary path,
#   if it is not defined `TEMP`, `TMP` or `TMPDIR` environment variables will be used.
#
#   `CTEST_TMP_DIR` variable is used as default value for `BASE_DIR` if defined.
#
function(create_tmp_dir OUT_VAR)
    set(options "")
    set(oneValueArgs "BASE_DIR")
    set(multiValueArgs "")
    cmake_parse_arguments(TMP "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT DEFINED TMP_BASE_DIR)
        if(DEFINED CTEST_TMP_DIR)
            set(TMP_BASE_DIR "${CTEST_TMP_DIR}")
        else()
            foreach(dir "$ENV{TEMP}" "$ENV{TMP}" "$ENV{TMPDIR}" "/tmp")
                if (EXISTS "${dir}")
                    set(TMP_BASE_DIR "${dir}")
                endif()
            endforeach()
        endif()
    endif()

    check_vars_exist(TMP_BASE_DIR)

    # TODO : find better way to avoid collisions.
    string(RANDOM rand_name)
    while(EXISTS "${TMP_BASE_DIR}/${rand_name}")
        string(RANDOM rand_name)
    endwhile(condition)

    set(tmp_dir "${TMP_BASE_DIR}/${rand_name}")

    ctest_ext_info("Create temporary directory : ${tmp_dir}")
    file(MAKE_DIRECTORY "${tmp_dir}")

    set(${OUT_VAR} "${tmp_dir}" PARENT_SCOPE)
endfunction()

##################################################################################
# GIT repository control commands
##################################################################################

#
# clone_git_repo(<git url> <destination> [BRANCH <branch>])
#
#   Clones git repository from <git url> to <destination> directory.
#   Optionally <branch> name can be specified.
#
#   `CTEST_GIT_COMMAND` variable must be defined and must point to git command.
#
function(clone_git_repo GIT_URL GIT_DEST_DIR)
    set(options "")
    set(oneValueArgs "BRANCH")
    set(multiValueArgs "")
    cmake_parse_arguments(GIT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    check_vars_exist(CTEST_GIT_COMMAND)

    if(GIT_BRANCH)
        ctest_ext_info("Clone git repository ${GIT_URL} (branch ${GIT_BRANCH}) to ${GIT_DEST_DIR}")
        execute_process(COMMAND "${CTEST_GIT_COMMAND}" clone -b ${GIT_BRANCH} -- ${GIT_URL} ${GIT_DEST_DIR})
    else()
        ctest_ext_info("Clone git repository ${GIT_URL} to ${GIT_DEST_DIR}")
        execute_process(COMMAND "${CTEST_GIT_COMMAND}" clone ${GIT_URL} ${GIT_DEST_DIR})
    endif()
endfunction()

#
# update_git_repo(<directory> [REMOTE <remote>] [BRANCH <branch>] [UPDATE_COUNT_OUTPUT <output variable>])
#
#   Updates local git repository in <directory> to latest state from remote repository.
#
#   <remote> specifies remote repository name, `origin` by default.
#
#   <branch> specifies remote branch name, `master` by default.
#
#   <output variable> specifies optional output variable to store update count.
#   If it is zero, local repository already was in latest state.
#
#   `CTEST_GIT_COMMAND` variable must be defined and must point to git command.
#
function(update_git_repo GIT_REPO_DIR)
    set(options "")
    set(oneValueArgs "REMOTE" "BRANCH" "UPDATE_COUNT_OUTPUT")
    set(multiValueArgs "")
    cmake_parse_arguments(GIT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # TODO : use FETCH_HEAD
    set_ifndef(GIT_REMOTE "origin")
    set_ifndef(GIT_BRANCH "master")

    check_vars_exist(CTEST_GIT_COMMAND)

    ctest_ext_info("Fetch git remote repository ${GIT_REMOTE} (branch ${GIT_BRANCH}) in ${GIT_REPO_DIR}")
    execute_process(COMMAND "${CTEST_GIT_COMMAND}" fetch
        WORKING_DIRECTORY "${GIT_REPO_DIR}")

    if(GIT_UPDATE_COUNT_OUTPUT)
        ctest_ext_info("Compare git local repository with ${GIT_REMOTE}/${GIT_BRANCH} state in ${GIT_REPO_DIR}")
        execute_process(COMMAND "${CTEST_GIT_COMMAND}" diff HEAD "${GIT_REMOTE}/${GIT_BRANCH}"
            WORKING_DIRECTORY "${GIT_REPO_DIR}"
            OUTPUT_VARIABLE diff_output)

        string(LENGTH "${diff_output}" update_count)
        set(${GIT_UPDATE_COUNT_OUTPUT} "${update_count}" PARENT_SCOPE)
    endif()

    ctest_ext_info("Reset git local repository to ${GIT_REMOTE}/${GIT_BRANCH} state in ${GIT_REPO_DIR}")
    execute_process(COMMAND "${CTEST_GIT_COMMAND}" reset --hard "${GIT_REMOTE}/${GIT_BRANCH}"
        WORKING_DIRECTORY "${GIT_REPO_DIR}")
endfunction()

#
# get_git_repo_info(<repository> <branch output variable> <revision output variable>)
#
#   Gets information about local git repository (branch name and revision).
#
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

##################################################################################
# CMake configuration commands
##################################################################################

#
# add_cmake_cache_entry(<name> <value> [TYPE <type>])
#
#   Adds new CMake cache entry.
#
function(add_cmake_cache_entry OPTION_NAME)
    set(options "")
    set(oneValueArgs "TYPE")
    set(multiValueArgs "")
    cmake_parse_arguments(OPTION "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT CTEST_CMAKE_OPTIONS MATCHES "-D${OPTION_NAME}")
        string(REPLACE ";" " " OPTION_VALUE "${OPTION_UNPARSED_ARGUMENTS}")
        if(OPTION_TYPE)
            list(APPEND CTEST_CMAKE_OPTIONS "-D${OPTION_NAME}:${OPTION_TYPE}=${OPTION_VALUE}")
        else()
            list(APPEND CTEST_CMAKE_OPTIONS "-D${OPTION_NAME}=${OPTION_VALUE}")
        endif()
        set(CTEST_CMAKE_OPTIONS ${CTEST_CMAKE_OPTIONS} PARENT_SCOPE)
    endif()
endfunction()

##################################################################################
# gcovr coverage report commands
##################################################################################

#
# run_gcovr([XML] [HTML] [VERBOSE] [OUTPUT_BASE_NAME <output_dir>] [REPORT_BASE_DIR <report_name>] [OPTIONS <option1> <option2> ...])
#
#   Runs gcovr command to generate coverage report.
#   This is an internal function, which is used in `ctest_ext_coverage`.
#
#   The gcovr command is run in `CTEST_BINARY_DIRECTORY` directory relatively to `CTEST_SOURCE_DIRECTORY` directory.
#   The binaries must be built with gcov coverage support.
#   The gcovr command must be run after all tests.
#
#   Coverage reports will be generated in:
#
#     - <REPORT_BASE_DIR>/xml/<OUTPUT_BASE_NAME>.xml
#     - <REPORT_BASE_DIR>/html/<OUTPUT_BASE_NAME>.html
#
#   `XML` and `HTML` options choose coverage report format (both can be specified).
#
#   `VERBOSE` turns on gcovr verbose mode.
#
#   `OUTPUT_BASE_NAME` specifies base name for output reports ("coverage" by default).
#
#   `REPORT_BASE_DIR` specifies base directory for output reports.
#   If not specified `CTEST_GCOVR_REPORT_DIR` variable is used,
#   which by default is equal to "${CTEST_BINARY_DIRECTORY}/coverage"
#
#   `OPTIONS` specifies additional options for gcovr command line.
#
#   `CTEST_GCOVR_EXECUTABLE` variable must be defined and must point to gcovr command.
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

        ctest_ext_info("Generate XML gcovr report : ${GCOVR_COMMAND_LINE} --xml --xml-pretty -o ${GCOVR_OUTPUT_BASE_NAME}.xml")
        execute_process(COMMAND ${GCOVR_COMMAND_LINE} --xml --xml-pretty -o "${GCOVR_OUTPUT_BASE_NAME}.xml"
            WORKING_DIRECTORY "${GCOVR_XML_DIR}")
    endif()

    if(GCOVR_HTML)
        set(GCOVR_HTML_DIR "${GCOVR_REPORT_BASE_DIR}/html")
        if(EXISTS "${GCOVR_HTML_DIR}")
            file(REMOVE_RECURSE "${GCOVR_HTML_DIR}")
        endif()
        file(MAKE_DIRECTORY "${GCOVR_REPORT_BASE_DIR}" "${GCOVR_HTML_DIR}")

        ctest_ext_info("Generate HTML gcovr report : ${GCOVR_COMMAND_LINE} --html --html-details -o ${GCOVR_OUTPUT_BASE_NAME}.html")
        execute_process(COMMAND ${GCOVR_COMMAND_LINE} --html --html-details -o "${GCOVR_OUTPUT_BASE_NAME}.html"
            WORKING_DIRECTORY "${GCOVR_HTML_DIR}")
    endif()
endfunction()

##################################################################################
# CTest Logging commands
##################################################################################

#
# ctest_ext_note(<message>)
#
#   Writes <message> both to console and to note file.
#   The function appends "[CTEST EXT NOTE]" prefix to console output for better visibility.
#   The note file is used in submit command.
#
#   The command will be available after `ctest_ext_start` call.
#
#   `CTEST_NOTES_LOG_FILE` variable must be defined.
#
function(ctest_ext_note)
    check_vars_def(CTEST_NOTES_LOG_FILE)

    message("[CTEST EXT NOTE] ${ARGN}")
    file(APPEND "${CTEST_NOTES_LOG_FILE}" "${ARGN}\n")
endfunction()

#
# ctest_ext_dump_notes()
#
#   Dumps all launch options to note file.
#   This is an internal function, which is used by `ctest_ext_start`.
#
function(ctest_ext_dump_notes)
    ctest_ext_info("==========================================================================")
    ctest_ext_info("CTest configuration information")
    ctest_ext_info("==========================================================================")

    get_git_repo_info("${CTEST_SOURCE_DIRECTORY}" CTEST_CURRENT_BRANCH CTEST_CURRENT_REVISION)

    ctest_ext_note("Configuration for CTest submission:")
    ctest_ext_note("")

    ctest_ext_note("CTEST_EXT_VERSION                     : ${CTEST_EXT_VERSION}")
    ctest_ext_note("CTEST_PROJECT_NAME                    : ${CTEST_PROJECT_NAME}")
    ctest_ext_note("")

    ctest_ext_note("CTEST_TARGET_SYSTEM                   : ${CTEST_TARGET_SYSTEM}")
    ctest_ext_note("CTEST_MODEL                           : ${CTEST_MODEL}")
    ctest_ext_note("")

    ctest_ext_note("CTEST_SITE                            : ${CTEST_SITE}")
    ctest_ext_note("CTEST_BUILD_NAME                      : ${CTEST_BUILD_NAME}")
    ctest_ext_note("")

    ctest_ext_note("CTEST_DASHBOARD_ROOT                  : ${CTEST_DASHBOARD_ROOT}")
    ctest_ext_note("CTEST_SOURCE_DIRECTORY                : ${CTEST_SOURCE_DIRECTORY}")
    ctest_ext_note("CTEST_BINARY_DIRECTORY                : ${CTEST_BINARY_DIRECTORY}")
    ctest_ext_note("CTEST_NOTES_LOG_FILE                  : ${CTEST_NOTES_LOG_FILE}")
    ctest_ext_note("")

    ctest_ext_note("CTEST_WITH_UPDATE                     : ${CTEST_WITH_UPDATE}")
    ctest_ext_note("CTEST_GIT_COMMAND                     : ${CTEST_GIT_COMMAND}")
    ctest_ext_note("CTEST_PROJECT_GIT_URL                 : ${CTEST_PROJECT_GIT_URL}")
    ctest_ext_note("CTEST_PROJECT_GIT_BRANCH              : ${CTEST_PROJECT_GIT_BRANCH}")
    ctest_ext_note("CTEST_CURRENT_BRANCH                  : ${CTEST_CURRENT_BRANCH}")
    ctest_ext_note("CTEST_CURRENT_REVISION                : ${CTEST_CURRENT_REVISION}")
    ctest_ext_note("")

    ctest_ext_note("CTEST_UPDATE_CMAKE_CACHE              : ${CTEST_UPDATE_CMAKE_CACHE}")
    ctest_ext_note("CTEST_EMPTY_BINARY_DIRECTORY          : ${CTEST_EMPTY_BINARY_DIRECTORY}")
    ctest_ext_note("CTEST_WITH_TESTS                      : ${CTEST_WITH_TESTS}")
    ctest_ext_note("CTEST_TEST_TIMEOUT                    : ${CTEST_TEST_TIMEOUT}")
    ctest_ext_note("CTEST_WITH_MEMCHECK                   : ${CTEST_WITH_MEMCHECK}")
    ctest_ext_note("CTEST_WITH_COVERAGE                   : ${CTEST_WITH_COVERAGE}")
    ctest_ext_note("CTEST_WITH_GCOVR                      : ${CTEST_WITH_GCOVR}")
    ctest_ext_note("CTEST_WITH_SUBMIT                     : ${CTEST_WITH_SUBMIT}")
    ctest_ext_note("")

    ctest_ext_note("CTEST_CMAKE_GENERATOR                 : ${CTEST_CMAKE_GENERATOR}")
    ctest_ext_note("CTEST_CONFIGURATION_TYPE              : ${CTEST_CONFIGURATION_TYPE}")
    ctest_ext_note("CTEST_CMAKE_OPTIONS                   : ${CTEST_CMAKE_OPTIONS}")
    ctest_ext_note("CTEST_BUILD_FLAGS                     : ${CTEST_BUILD_FLAGS}")
    ctest_ext_note("")

    ctest_ext_note("CTEST_MEMORYCHECK_COMMAND             : ${CTEST_MEMORYCHECK_COMMAND}")
    ctest_ext_note("CTEST_MEMORYCHECK_SUPPRESSIONS_FILE   : ${CTEST_MEMORYCHECK_SUPPRESSIONS_FILE}")
    ctest_ext_note("CTEST_MEMORYCHECK_COMMAND_OPTIONS     : ${CTEST_MEMORYCHECK_COMMAND_OPTIONS}")
    ctest_ext_note("")

    ctest_ext_note("CTEST_COVERAGE_COMMAND                : ${CTEST_COVERAGE_COMMAND}")
    ctest_ext_note("CTEST_COVERAGE_EXTRA_FLAGS            : ${CTEST_COVERAGE_EXTRA_FLAGS}")
    ctest_ext_note("")

    ctest_ext_note("CTEST_GCOVR_EXECUTABLE                : ${CTEST_GCOVR_EXECUTABLE}")
    ctest_ext_note("CTEST_GCOVR_EXTRA_FLAGS               : ${CTEST_GCOVR_EXTRA_FLAGS}")
    ctest_ext_note("CTEST_GCOVR_REPORT_DIR                : ${CTEST_GCOVR_REPORT_DIR}")
    ctest_ext_note("")

    ctest_ext_note("CTEST_NOTES_FILES                     : ${CTEST_NOTES_FILES}")
    ctest_ext_note("CTEST_UPLOAD_FILES                    : ${CTEST_UPLOAD_FILES}")
    ctest_ext_note("")
endfunction()

##################################################################################
# CTest Ext Initialize
##################################################################################

#
# ctest_ext_init()
#
#   Initializes CTest Ext module for dashboard testing.
#
#   The function sets dashboard settings to default values (if they were not defined prior the call)
#   and performs project repository checkout/update if needed.
#
macro(ctest_ext_init)
    # For CTest Ext module self-testing
    message("CTEST_FULL_OUTPUT")

    # Dashboard settings

    set_ifndef(CTEST_TARGET_SYSTEM      "${CMAKE_SYSTEM}-${CMAKE_SYSTEM_PROCESSOR}")
    set_ifndef(CTEST_MODEL              "Experimental")

    if(NOT DEFINED CTEST_SITE)
        site_name(CTEST_SITE)
    endif()
    set_ifndef(CTEST_BUILD_NAME         "${CTEST_TARGET_SYSTEM}-${CTEST_MODEL}")

    set_ifndef(CTEST_DASHBOARD_ROOT     "${CTEST_SCRIPT_DIRECTORY}/${CTEST_TARGET_SYSTEM}/${CTEST_MODEL}")
    set_ifndef(CTEST_SOURCE_DIRECTORY   "${CTEST_DASHBOARD_ROOT}/source")
    set_ifndef(CTEST_BINARY_DIRECTORY   "${CTEST_DASHBOARD_ROOT}/build")
    set_ifndef(CTEST_NOTES_LOG_FILE     "${CTEST_DASHBOARD_ROOT}/ctest_ext_notes_log.txt")

    set_ifndef(CTEST_WITH_UPDATE        FALSE)

    # Tools

    if(NOT DEFINED CTEST_GIT_COMMAND)
        find_package(Git QUIET)
        if(GIT_FOUND)
            ctest_ext_info("Found git : ${GIT_EXECUTABLE} (version ${GIT_VERSION_STRING})")
            set_ifndef(CTEST_GIT_COMMAND "${GIT_EXECUTABLE}")
        endif()
    endif()

    if(NOT DEFINED CTEST_COVERAGE_COMMAND)
        find_program(CTEST_COVERAGE_COMMAND NAMES gcov)
        if(CTEST_COVERAGE_COMMAND)
            ctest_ext_info("Found gcov : ${CTEST_COVERAGE_COMMAND}")
        endif()
    endif()

    if(NOT DEFINED CTEST_GCOVR_EXECUTABLE)
        find_program(CTEST_GCOVR_EXECUTABLE NAMES gcovr)
        if(CTEST_GCOVR_EXECUTABLE)
            ctest_ext_info("Found gcovr : ${CTEST_GCOVR_EXECUTABLE}")
        endif()
    endif()

    if(NOT DEFINED CTEST_MEMORYCHECK_COMMAND)
        find_program(CTEST_MEMORYCHECK_COMMAND NAMES valgrind)
        if(CTEST_MEMORYCHECK_COMMAND)
            ctest_ext_info("Found valgrind : ${CTEST_MEMORYCHECK_COMMAND}")
        endif()
    endif()

    # Stage

    set_ifndef(CTEST_STAGE "${CTEST_SCRIPT_ARG}")
    if(NOT CTEST_STAGE)
        set(CTEST_STAGE "Start;Configure;Build;Test;Coverage;MemCheck;Submit;Extra")
    endif()

    # Initialize

    set(HAVE_UPDATES TRUE)

    if(CTEST_STAGE MATCHES "Start")
        ctest_ext_info("==========================================================================")
        ctest_ext_info("Initialize testing for MODEL ${CTEST_MODEL} (CTest Ext module version ${CTEST_EXT_VERSION})")
        ctest_ext_info("==========================================================================")

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

        ctest_ext_info("Initial start and checkout")
        ctest_start("${CTEST_MODEL}")

        if(CTEST_WITH_UPDATE)
            if(NOT DEFINED CTEST_UPDATE_COMMAND)
                check_vars_exist(CTEST_GIT_COMMAND)

                set(CTEST_UPDATE_COMMAND "${CTEST_GIT_COMMAND}")
            endif()

            ctest_ext_info("Repository update")
            ctest_update(RETURN_VALUE count)

            set(HAVE_UPDATES FALSE)
            if(count GREATER 0)
                set(HAVE_UPDATES TRUE)
            endif()
        endif()
    endif()
endmacro()

##################################################################################
# CTest Ext Start
##################################################################################

#
# ctest_ext_start()
#
#   Starts dashboard testing.
#
#   The function sets testing settings to default values (if they were not defined prior the call)
#   and initializes logging mechanism.
#
macro(ctest_ext_start)
    set_ifndef(CTEST_CMAKE_GENERATOR            "Unix Makefiles")
    set_ifndef(CTEST_CONFIGURATION_TYPE         "Debug")

    set_ifndef(CTEST_UPDATE_CMAKE_CACHE         TRUE)
    set_ifndef(CTEST_EMPTY_BINARY_DIRECTORY     TRUE)
    set_ifndef(CTEST_WITH_TESTS                 TRUE)
    set_ifndef(CTEST_TEST_TIMEOUT               600)
    set_ifndef(CTEST_WITH_COVERAGE              FALSE)
    set_ifndef(CTEST_WITH_GCOVR                 FALSE)
    set_ifndef(CTEST_WITH_MEMCHECK              FALSE)
    set_ifndef(CTEST_WITH_SUBMIT                FALSE)
    set_ifndef(CTEST_GCOVR_REPORT_DIR           "${CTEST_BINARY_DIRECTORY}/coverage")

    list(APPEND CTEST_NOTES_FILES   "${CTEST_NOTES_LOG_FILE}")
    list(APPEND CTEST_UPLOAD_FILES  "${CTEST_BINARY_DIRECTORY}/CMakeCache.txt")

    set_ifndef(CTEST_TRACK "${CTEST_MODEL}")

    ctest_ext_info("==========================================================================")
    ctest_ext_info("Start testing MODEL ${CTEST_MODEL} TRACK ${CTEST_TRACK}")
    ctest_ext_info("==========================================================================")

    ctest_start("${CTEST_MODEL}" TRACK "${CTEST_TRACK}" APPEND)

    if(CTEST_STAGE MATCHES "Start")
        file(REMOVE "${CTEST_NOTES_LOG_FILE}")
        ctest_ext_dump_notes()
    endif()
endmacro()

##################################################################################
# CTest Ext Configure
##################################################################################

#
# ctest_ext_configure()
#
#   Configures CMake project.
#
#   To configure CMake cache variables use `add_cmake_cache_entry` command.
#
macro(ctest_ext_configure)
    if(CTEST_STAGE MATCHES "Configure")
        ctest_ext_info("==========================================================================")
        ctest_ext_info("Configure")
        ctest_ext_info("==========================================================================")

        if(NOT EXISTS "${CTEST_BINARY_DIRECTORY}")
            ctest_ext_info("Create binary directory : ${CTEST_BINARY_DIRECTORY}")
            file(MAKE_DIRECTORY "${CTEST_BINARY_DIRECTORY}")
        elseif(CTEST_EMPTY_BINARY_DIRECTORY)
            ctest_ext_info("Clean binary directory : ${CTEST_BINARY_DIRECTORY}")
            ctest_empty_binary_directory("${CTEST_BINARY_DIRECTORY}")
        elseif(CTEST_UPDATE_CMAKE_CACHE AND EXISTS "${CTEST_BINARY_DIRECTORY}/CMakeCache.txt")
            ctest_ext_info("Remove old CMake cache : ${CTEST_BINARY_DIRECTORY}/CMakeCache.txt}")
            file(REMOVE "${CTEST_BINARY_DIRECTORY}/CMakeCache.txt")
        endif()

        ctest_configure(OPTIONS "${CTEST_CMAKE_OPTIONS}")
    endif()

    ctest_read_custom_files("${CTEST_BINARY_DIRECTORY}")
endmacro()

##################################################################################
# CTest Ext Build
##################################################################################

#
# ctest_ext_build([TARGET <target>] [TARGETS <target1> <target2> ...])
#
#   Builds CMake project.
#
function(ctest_ext_build)
    set(options "")
    set(oneValueArgs "TARGET")
    set(multiValueArgs "TARGETS")
    cmake_parse_arguments(BUILD "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(CTEST_STAGE MATCHES "Build")
        ctest_ext_info("==========================================================================")
        ctest_ext_info("Build")
        ctest_ext_info("==========================================================================")

        if(BUILD_TARGET)
            ctest_ext_info("Build target : ${BUILD_TARGET}")
            ctest_build(TARGET "${BUILD_TARGET}")
        elseif(BUILD_TARGETS)
            ctest_ext_info("Build targets : ${BUILD_TARGETS}")

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
            ctest_ext_info("Build target : ALL")
            ctest_build()
        endif()
    endif()
endfunction()

##################################################################################
# CTest Ext Test
##################################################################################

#
# ctest_ext_test(<arguments>)
#
#   Runs tests. The function will pass its arguments to `ctest_test` as is.
#
function(ctest_ext_test)
    if(CTEST_WITH_TESTS AND CTEST_STAGE MATCHES "Test")
        ctest_ext_info("==========================================================================")
        ctest_ext_info("Test")
        ctest_ext_info("==========================================================================")

        ctest_ext_info("Parameters : ${ARGN}")
        ctest_test(${ARGN})
    endif()
endfunction()

##################################################################################
# CTest Ext Coverage
##################################################################################

#
# ctest_ext_coverage([GCOVR_OPTIONS <options for run_gcovr>] [CTEST_OPTIONS <options for ctest_coverage>])
#
#   Collects coverage reports.
#   The function passes own arguments to `run_gcovr` and `ctest_coverage` as is.
#
function(ctest_ext_coverage)
    set(options "")
    set(oneValueArgs "")
    set(multiValueArgs "GCOVR_OPTIONS" "CTEST_OPTIONS")
    cmake_parse_arguments(COVERAGE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(CTEST_WITH_TESTS AND CTEST_STAGE MATCHES "Coverage")
        if(CTEST_WITH_GCOVR)
            ctest_ext_info("==========================================================================")
            ctest_ext_info("Generate gcovr coverage report")
            ctest_ext_info("==========================================================================")

            ctest_ext_info("Parameters : ${COVERAGE_GCOVR_OPTIONS}")
            run_gcovr(${COVERAGE_GCOVR_OPTIONS})
        endif()

        if(CTEST_WITH_COVERAGE)
            check_vars_def(CTEST_COVERAGE_COMMAND)

            ctest_ext_info("==========================================================================")
            ctest_ext_info("Generate CTest coverage report")
            ctest_ext_info("==========================================================================")

            ctest_ext_info("Parameters : ${COVERAGE_CTEST_OPTIONS}")
            ctest_coverage(${COVERAGE_CTEST_OPTIONS})
        endif()
    endif()
endfunction()

##################################################################################
# CTest Ext MemCheck
##################################################################################

#
# ctest_ext_memcheck(<arguments>)
#
#   Runs dynamic analysis testing. The function will pass its arguments to `ctest_memcheck` as is.
#
function(ctest_ext_memcheck)
    if(CTEST_WITH_MEMCHECK AND CTEST_STAGE MATCHES "MemCheck")
        check_vars_def(CTEST_MEMORYCHECK_COMMAND)

        ctest_ext_info("==========================================================================")
        ctest_ext_info("MemCheck")
        ctest_ext_info("==========================================================================")

        ctest_ext_info("Parameters : ${ARGN}")
        ctest_memcheck(${ARGN})
    endif()
endfunction()

##################################################################################
# CTest Ext Submit
##################################################################################

#
# ctest_ext_submit()
#
#   Submits testing results to remote server.
#
function(ctest_ext_submit)
    if(CTEST_WITH_SUBMIT AND CTEST_STAGE MATCHES "Submit")
        ctest_ext_info("==========================================================================")
        ctest_ext_info("Submit")
        ctest_ext_info("==========================================================================")

        if(CTEST_UPLOAD_FILES)
            ctest_ext_info("Upload files : ${CTEST_UPLOAD_FILES}")
            ctest_upload(FILES ${CTEST_UPLOAD_FILES})
        endif()

        ctest_submit()
    endif()
endfunction()
