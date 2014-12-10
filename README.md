# CTest Extension module

--------------------------------------------------------------------------

## Table of Contents

- [1. Introduction](#1-introduction)
- [2. Usage](#2-usage)
- [3. Configuration](#3-configuration)
    - [3.1. Target system](#31-target-system)
    - [3.2. Testing model](#32-testing-model)
    - [3.3. Configure the testing script](#33-configure-the-testing-script)
- [4. Available options](#4-available-options)
    - [4.1. Mandatory testing options](#41-mandatory-testing-options)
    - [4.2. Repository settings](#42-repository-settings)
    - [4.3. Optional testing settings](#43-optional-testing-settings)
- [5. Usage with CI systems](#5-usage-with-ci-systems)
- [6. Example of CTest project script](#6-example-of-ctest-project-script)

--------------------------------------------------------------------------

## 1. Introduction

The CTest Extension module is a set of additional functions for CTest scripts.
The main goal of the CTest Extension module is to provide uniform testing approach
for CMake projects.

The CTest Extension module supports the following functionality:

* clone/update git repository;
* configure CMake project;
* build CMake project;
* run tests;
* build coverage report (in CTest format and in gcovr format);
* run dynamic analysis (like valgrind);
* upload testing results to remote server (eg. CDash web server).

--------------------------------------------------------------------------

## 2. Usage

The CTest Extension module is supposed to be used in project CTest script.
Project developers provides the testing script (along with source code or separately),
and testers use this script to perform project testing.

The usage from testers point of view:

1. Download project testing script.

2. Put the project testing script to a dashboard directory
(for example, `~/Dashboards/project` or `c:/Dashboards/project`).

3. Run CTest tool from a command line:

        $ ctest -VV -S ~/Dashboards/project/project_test.cmake

4. Add the above command to a scheduler (for example, `cron`) or
   to a CI system (like buildbot or jenkins).

For CTest tool command line options please refer to [CTEST].

--------------------------------------------------------------------------

## 3. Configuration

The CTest Extension module uses **Target system** and **Testing model** notations to
perform different tests, depending on target platform and user intention.

### 3.1. Target system

The **Target system** describes the target OS, version, architecture, etc.
This parameter allows the testing script to choose appropriate configuration
for CMake and build tools.

The set of supported targets is defined by the project.

The generic format for the **Target system** is `<KIND>[-<NAME>][-<ARCH>]`, where

* `<KIND>` is one of **Linux**, **Windows**, **MacOS**, **Android**.
* `<NAME>` is an optional OS name and version, for example **Ubuntu-14.04**, **Vista**.
* `<ARCH>` is an optional architecture description, for example **x86_64**, **ARM**, **ARM-Tegra5**.

### 3.2. Testing model

The **Testing model** notation describes the intention of the testing and
allows the testing script to choose appropriate set of tests.

The set of supported models is defined by the project.

Example of such set:

* *Experimental* - performs custom testing.
* *Nightly* - performs full and clean nightly testing.
* *Continuous* - performs quick testing, only if there were updates in the remote repository.
* *Release* - builds release packages.
* *Performance* - collects benchmarking results.
* *MemCheck* - performs dynamic analysis.
* *Documentation* - builds documentation.

### 3.3. Configure the testing script

The CTest Extension module can be configured in two ways:

1. Set the required parameters before including the CTest Extension module:

   ```CMake
set(CTEST_TARGET_SYSTEM "Linux-Ubuntu-14.04-x64")
set(CTEST_MODEL         "Performance")
include("${CTEST_SCRIPT_DIRECTORY}/ctest_ext.cmake")
   ```

2. Pass the options with CTest command line:

        $ ctest -VV -S ~/Dashboards/project/project_test.cmake \
            -DCTEST_TARGET_SYSTEM="Linux-Ubuntu-14.04-x64" \
            -DCTEST_MODEL="Nightly"

--------------------------------------------------------------------------

## 4. Available options

### 4.1. Mandatory testing options

##### CTEST_TARGET_SYSTEM

This option describes the target platform for the testing.
By default it is equal to `${CMAKE_SYSTEM}-${CMAKE_SYSTEM_PROCESSOR}`.

See [CMAKE_SYSTEM] and [CMAKE_SYSTEM_PROCESSOR].

##### CTEST_MODEL

The testing model (default - *Experimental*).

##### CTEST_SITE

Site name for submission. By default is equal to the host name.

##### CTEST_BUILD_NAME

Build name for submission. By default is equal to `${CTEST_TARGET_SYSTEM}-${CTEST_MODEL}`.

##### CTEST_DASHBOARD_ROOT

Root folder for the testing.

The testing script will use this folder to create temporary files,
so it should have write access and should be unique for different scripts.

By default is equal to `${CTEST_SCRIPT_DIRECTORY}/${CTEST_TARGET_SYSTEM}/${CTEST_MODEL}`.

##### CTEST_SOURCE_DIRECTORY

Directory with project sources. By default is equal to `${CTEST_DASHBOARD_ROOT}/source`.

If the folder doesn't exist the testing script will clone it from the remote repository
(see the next section).

##### CTEST_BINARY_DIRECTORY

Build folder. By default is equal to `${CTEST_DASHBOARD_ROOT}/build`.

##### CTEST_NOTES_LOG_FILE

Path to log file for CTest notes.

The CTest Extension module will use this file to log some important information
about testing and will add it to submission as a note.

By default is equal to `${CTEST_DASHBOARD_ROOT}/ctest_notes_log.txt`.



### 4.2. Repository settings

##### CTEST_WITH_UPDATE

Update source folder to latest state in remote repository. The option is enabled by default.

**Note:** This operation will reset current source folder state and will discard all not committed changes.

##### CTEST_GIT_COMMAND

Path to the `git` command line tool.

##### CTEST_PROJECT_GIT_URL

Project repository URL.

##### CTEST_PROJECT_GIT_BRANCH

Optional project git branch.



### 4.4. Optional testing settings

##### CTEST_UPDATE_CMAKE_CACHE

True, if the testing script should overwrite CMake cache on each launch.

##### CTEST_EMPTY_BINARY_DIRECTORY

True, if the testing script should clean build directory on each launch.

##### CTEST_WITH_TESTS

Enable/disable test launching.

##### CTEST_TEST_TIMEOUT

Timeout in seconds for single test execution.

##### CTEST_WITH_MEMCHECK

Enable/disable memory check analysis.

##### CTEST_WITH_COVERAGE

Enable/disable CTest-based code coverage analysis.

##### CTEST_WITH_GCOVR

Enable/disable gcovr-based code coverage analysis.

##### CTEST_WITH_SUBMIT

Enable/disable submission to remote server.

##### CTEST_CMAKE_GENERATOR

CMake generator.

##### CTEST_CONFIGURATION_TYPE

CMake configuration type (eg. Release, Debug).

##### CTEST_CMAKE_OPTIONS

Extra options for CMake command. This options will overwrite default ones.
For example:

```CMake
set(CTEST_CMAKE_OPTIONS "-DCUDA_TOOLKIT_ROOT_DIR:PATH=/usr/local/cuda-6.5")
```

##### CTEST_BUILD_TARGET

Target to build. By default is empty, which means ALL target.

##### CTEST_BUILD_FLAGS

Extra options for build command. For example:

```CMake
set(CTEST_BUILD_FLAGS "-j7")
```

##### CTEST_MEMORYCHECK_COMMAND

Path to memory check tool. Used only if `CTEST_WITH_MEMCHECK` is enabled.

##### CTEST_MEMORYCHECK_SUPPRESSIONS_FILE

Path to suppressions file for the memory check tool.
By default the testing script will use internal file for the `valgrind` tool.

##### CTEST_MEMORYCHECK_COMMAND_OPTIONS

Extra options for the memory check command.

##### CTEST_COVERAGE_COMMAND

Path to code coverage analysis tool. Used only if `CTEST_WITH_COVERAGE` is enabled.

##### CTEST_COVERAGE_EXTRA_FLAGS

Extra options for the code coverage analysis command.

##### CTEST_GCOVR_EXECUTABLE

Path to `gcovr` command line tool.

##### CTEST_GCOVR_EXTRA_FLAGS

Extra options for the `gcovr` command.

##### CTEST_GCOVR_REPORT_DIR

Output directory for `gcovr` reports.

By default is equal to `${CTEST_BINARY_DIRECTORY}/coverage`.

##### CTEST_NOTES_FILES

List of notes files, which should be included into submission.

##### CTEST_UPLOAD_FILES

List of files, which should be uploaded to the remote server.

By default, CMake cache will be uploaded

##### CTEST_TMP_DIR

Path to temporary directory.

By default is equal to one of `$ENV{TEMP}`, `$ENV{TMP}`, `$ENV{TMPDIR}` or `/tmp`.

##### CTEST_TRACK

Track for submission. By default is equal to ${CTEST_MODEL}.

--------------------------------------------------------------------------

## 5. Usage with CI systems

The testing script can be used with CI systems, like buildbot, Jenkins, etc.
The CI system might call the same CTest command to perform project configuration, build and testing.

The testing script supports step-by-step mode, to split all steps on CI system. For example:

    $ ctest -VV -S ~/Dashboards/project/project_test.cmake,Start
    $ ctest -VV -S ~/Dashboards/project/project_test.cmake,Configure
    $ ctest -VV -S ~/Dashboards/project/project_test.cmake,Build
    $ ctest -VV -S ~/Dashboards/project/project_test.cmake,Test
    $ ctest -VV -S ~/Dashboards/project/project_test.cmake,Coverage
    $ ctest -VV -S ~/Dashboards/project/project_test.cmake,MemCheck
    $ ctest -VV -S ~/Dashboards/project/project_test.cmake,Submit
    $ ctest -VV -S ~/Dashboards/project/project_test.cmake,Extra

--------------------------------------------------------------------------

## 6. Example of CTest project script

Assuming we have a CMake project with the following structure:

    - project/
      - CMakeLists.txt
      - <sources>

Add `CTestConfig.cmake` file to the project root folder with the following content:

```CMake
set(CTEST_PROJECT_NAME "ProjectName")
set(CTEST_NIGHTLY_START_TIME "01:00:00 UTC")

set(CTEST_DROP_METHOD "http")
set(CTEST_DROP_SITE "localhost")
set(CTEST_DROP_LOCATION "/CDash/submit.php?project=ProjectName")
set(CTEST_DROP_SITE_CDASH TRUE)
```

Add `project_test.cmake` file to the project root folder with the following content:

```CMake
#
# Include CTest Ext module
#

function(update_ctest_ext)
    message("Update CTest Extension module")

    find_package(Git QUIET)

    set(repo_url "https://github.com/jet47/ctest-ext.git")
    set(repo_dir "${CMAKE_CURRENT_LIST_DIR}/ctest-ext")
    set(tmp_dir "${CMAKE_CURRENT_LIST_DIR}/ctest-ext-tmp")

    if(NOT EXISTS "${repo_dir}")
        set(CTEST_CHECKOUT_COMMAND "${GIT_EXECUTABLE} clone ${repo_url} ${repo_dir}")
    endif()
    set(CTEST_UPDATE_COMMAND "${GIT_EXECUTABLE}")

    ctest_start("CTestExt" "${repo_dir}" "${tmp_dir}")
    ctest_update(SOURCE "${repo_dir}")

    file(REMOVE_RECURSE "${tmp_dir}")

    set(CTEST_EXT_MODULE_PATH "${repo_dir}/ctest_ext.cmake" PARENT_SCOPE)
endfunction()

if(NOT DEFINED CTEST_EXT_MODULE_PATH)
    update_ctest_ext()
endif()

include("${CTEST_EXT_MODULE_PATH}")

#
# Repository settings
#

set_ifndef(CTEST_PROJECT_GIT_URL "https://github.com/user/project.git")

#
# Initialize testing
#

ctest_ext_init()

#
# Check supported targets and models
#

check_if_matches(CTEST_TARGET_SYSTEM    "^Linux" "^Windows")
check_if_matches(CTEST_MODEL            "^Nightly$" "^Experimental$")

#
# Configure the testing model (set options, not specified by user, to default values)
#

set_ifndef(CTEST_UPDATE_CMAKE_CACHE     TRUE)
set_ifndef(CTEST_EMPTY_BINARY_DIRECTORY TRUE)
set_ifndef(CTEST_WITH_TESTS             TRUE)
set_ifndef(CTEST_TEST_TIMEOUT           600)
if(CTEST_MODEL MATCHES "Nightly")
    set_ifndef(CTEST_WITH_COVERAGE      TRUE)
    set_ifndef(CTEST_WITH_GCOVR         TRUE)
    set_ifndef(CTEST_WITH_MEMCHECK      TRUE)
else()
    set_ifndef(CTEST_WITH_COVERAGE      FALSE)
    set_ifndef(CTEST_WITH_GCOVR         FALSE)
    set_ifndef(CTEST_WITH_MEMCHECK      FALSE)
endif()
set_ifndef(CTEST_WITH_SUBMIT        TRUE)

#
# Configure cmake options
#

if(CTEST_UPDATE_CMAKE_CACHE)
    if(CTEST_TARGET_SYSTEM MATCHES "Windows")
        if(CTEST_TARGET_SYSTEM MATCHES "64")
            set_ifndef(CTEST_CMAKE_GENERATOR "Visual Studio 12 Win64")
        else()
            set_ifndef(CTEST_CMAKE_GENERATOR "Visual Studio 12")
        endif()
    else()
        set_ifndef(CTEST_CMAKE_GENERATOR "Unix Makefiles")
    endif()
    set_ifndef(CTEST_CONFIGURATION_TYPE "Debug")

    if(CTEST_MODEL MATCHES "Nightly")
        add_cmake_option("ENABLE_CPPCHECK" "BOOL" "ON")
    endif()

    if(CTEST_WITH_COVERAGE OR CTEST_WITH_GCOVR)
        add_cmake_option("ENABLE_COVERAGE" "BOOL" "ON")
    else()
        add_cmake_option("ENABLE_COVERAGE" "BOOL" "OFF")
    endif()
endif()

#
# Start testing
#

ctest_ext_set_default()

ctest_ext_start()

#
# Clean binary directory if needed
#

ctest_ext_clean_build()

#
# Configure
#

ctest_ext_configure()

#
# Build
#

ctest_ext_build()

#
# Test
#

if(CTEST_MODEL MATCHES "Nightly")
    ctest_ext_test(INCLUDE_LABEL "Full")
else()
    ctest_ext_test(EXCLUDE_LABEL "Light")
endif()

#
# Coverage
#

ctest_ext_coverage(GCOVR_OPTIONS XML HTML VERBOSE OUTPUT_BASE_NAME "coverage")

#
# MemCheck
#

ctest_ext_memcheck(INCLUDE_LABEL "Light")

#
# Submit
#

ctest_ext_submit()
```

--------------------------------------------------------------------------

[CTEST]: <http://www.cmake.org/cmake/help/v3.0/manual/ctest.1.html>
[CMAKE_SYSTEM]: <http://www.cmake.org/cmake/help/v3.0/variable/CMAKE_SYSTEM.html?highlight=cmake_system>
[CMAKE_SYSTEM_PROCESSOR]: <http://www.cmake.org/cmake/help/v3.0/variable/CMAKE_SYSTEM_PROCESSOR.html?highlight=cmake_system_processor>
