# Create project testing script

The CText Extension module is supposed to be used for CMake-based projects.
This section will show how to write testing script for CMake project step-by-step.

Assuming we have a CMake project with the following structure:

    - project/
      - CMakeLists.txt
      - <sources>

To enable CTest-based testing add two new files to the project structure:

    - project/
      - CMakeLists.txt
      - CTestConfig.cmake       <---
      - project_test.cmake      <---
      - <sources>

## CTestConfig.cmake

The `CTestConfig.cmake` file describes project name and remote server location for dashboard submission:

    set(CTEST_PROJECT_NAME "<YOUR_PROJECT_NAME>")
    set(CTEST_NIGHTLY_START_TIME "01:00:00 UTC")

    set(CTEST_DROP_METHOD "http")
    set(CTEST_DROP_SITE "localhost")
    set(CTEST_DROP_LOCATION "/CDash/submit.php?project=<YOUR_PROJECT_NAME>")
    set(CTEST_DROP_SITE_CDASH TRUE)

Change `CTEST_DROP_SITE` to the actual location of your CDash server if needed, for example `my.cdash.org`.

For more information see [Testing_With_CTest](http://www.vtk.org/Wiki/CMake/Testing_With_CTest).

## project_test.cmake

The `project_test.cmake` is a CMake script, which describes testing procedure for the project.

The CText Extension module provides additional set of commands, that can be used in the testing script.
For detailed information about the provided commands see [CTest Ext Commands](commands.md).

### 1. Include CText Ext module

First step in the project testing script is to find and include CText Ext module.

Use the following code for that purpose:

    if(NOT CTEST_EXT_INCLUDED)
        function(download_ctest_ext)
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
            if(DEFINED ENV{CTEST_EXT_MODULE_PATH} AND EXISTS "$ENV{CTEST_EXT_MODULE_PATH}")
                set(CTEST_EXT_MODULE_PATH "$ENV{CTEST_EXT_MODULE_PATH}")
            elseif(EXISTS "${CMAKE_CURRENT_LIST_DIR}/ctest_ext.cmake")
                set(CTEST_EXT_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/ctest_ext.cmake")
            else()
                download_ctest_ext()
            endif()
        endif()

        include("${CTEST_EXT_MODULE_PATH}")
    endif()

The code performs the following steps:

1. Checks `CTEST_EXT_MODULE_PATH` CTest variable (can be passed via command line `-DCTEST_EXT_MODULE_PATH=<...>`
  or from other calling script) and uses it if defined.
2. Checks `CTEST_EXT_MODULE_PATH` environment variable and uses it if it is defined and points to existing file.
3. Checks the project script's own directory and use CText Ext module script if it is located there.
4. Download latest version of CTest Ext module from GitHub repository.

### 2. Initialize CTest Ext module

Next step is CTest Ext module initialization:

    set_ifndef(CTEST_PROJECT_GIT_URL    "https://github.com/user/project.git")
    set_ifndef(CTEST_WITH_UPDATE        TRUE)

    ctest_ext_init()

The initialization command clones/updates project's git repository if needed.

### 3. Configure project for testing

Next step is project configuration.
The project testing script should select appropriate CMake options for build and testing
using provided **Target system** and **Testing model** notations.

    # Check supported targets and models
    check_if_matches(CTEST_TARGET_SYSTEM    "^Linux" "^Windows")
    check_if_matches(CTEST_MODEL            "^Experimental$" "^Nightly$" "^Continuous$" "^Release$" "^Documentation$")

    # Checks for Continuous model
    set(IS_CONTINUOUS FALSE)
    if(CTEST_MODEL MATCHES "Continuous")
        set(IS_CONTINUOUS TRUE)
    endif()

    set(IS_BINARY_EMPTY FALSE)
    if(NOT EXISTS "${CTEST_BINARY_DIRECTORY}/CMakeCache.txt")
        set(IS_BINARY_EMPTY TRUE)
    endif()

    if(IS_CONTINUOUS AND NOT IS_BINARY_EMPTY AND NOT HAVE_UPDATES)
        ctest_ext_info("Continuous model : no updates")
        return()
    endif()

    # Configure the testing model
    set_ifndef(CTEST_WITH_SUBMIT            TRUE)

    if(CTEST_MODEL MATCHES "Documentation")
        set_ifndef(CTEST_WITH_TESTS FALSE)
    else()
        set_ifndef(CTEST_WITH_TESTS TRUE)
    endif()

    if(CTEST_MODEL MATCHES "Nightly")
        set_ifndef(CTEST_WITH_COVERAGE      TRUE)
        set_ifndef(CTEST_WITH_GCOVR         TRUE)
        set_ifndef(CTEST_WITH_MEMCHECK      TRUE)
    else()
        set_ifndef(CTEST_WITH_COVERAGE      FALSE)
        set_ifndef(CTEST_WITH_GCOVR         FALSE)
        set_ifndef(CTEST_WITH_MEMCHECK      FALSE)
    endif()

    if(CTEST_MODEL MATCHES "Continuous")
        set_ifndef(CTEST_EMPTY_BINARY_DIRECTORY FALSE)
    else()
        set_ifndef(CTEST_EMPTY_BINARY_DIRECTORY TRUE)
    endif()

    # Set CMake options
    if(CTEST_TARGET_SYSTEM MATCHES "Windows")
        if(CTEST_TARGET_SYSTEM MATCHES "64")
            set_ifndef(CTEST_CMAKE_GENERATOR "Visual Studio 13 Win64")
        else()
            set_ifndef(CTEST_CMAKE_GENERATOR "Visual Studio 13")
        endif()
    else()
        set_ifndef(CTEST_CMAKE_GENERATOR "Unix Makefiles")
    endif()

    if(CTEST_MODEL MATCHES "(Release|Continuous)")
        set_ifndef(CTEST_CONFIGURATION_TYPE "Release")
    else()
        set_ifndef(CTEST_CONFIGURATION_TYPE "Debug")
    endif()

    add_cmake_cache_entry("ENABLE_CTEST" "ON")

    if(CTEST_MODEL MATCHES "Nightly")
        add_cmake_cache_entry("ENABLE_CPPCHECK" "ON")
    endif()

    if(CTEST_WITH_COVERAGE OR CTEST_WITH_GCOVR)
        add_cmake_cache_entry("ENABLE_COVERAGE" "ON")
    else()
        add_cmake_cache_entry("ENABLE_COVERAGE" "OFF")
    endif()

    if(CTEST_MODEL MATCHES "Documentation")
        add_cmake_cache_entry("BUILD_DOCS" TYPE "BOOL" "ON")
    endif()

    if(CTEST_MODEL MATCHES "Release")
        if(CTEST_TARGET_SYSTEM MATCHES "Windows")
            add_cmake_cache_entry("CPACK_GENERATOR" TYPE "STRING" "ZIP")
        else()
            add_cmake_cache_entry("CPACK_GENERATOR" TYPE "STRING" "TGZ")
        endif()
    endif()

### 4. Start testing, configure and build project

Next steps is

- Start dashboard testing.
- Configure project.
- Build project.

    ctest_ext_start()

    ctest_ext_configure()

    if(CTEST_MODEL MATCHES "Release")
        ctest_ext_build(TARGETS "ALL" "package")
    elseif(CTEST_MODEL MATCHES "Documentation")
        ctest_ext_build(TARGET "docs")
    else()
        ctest_ext_build()
    endif()

### 5. Run tests

Now we can run tests, calculate coverage, perform dynamic analysis.

    if(CTEST_MODEL MATCHES "Nightly")
        ctest_ext_test(INCLUDE_LABEL "Full")
    else()
        ctest_ext_test(EXCLUDE_LABEL "Light")
    endif()

    ctest_ext_coverage(CTEST LABELS "Module")

    ctest_ext_memcheck(INCLUDE_LABEL "Light")

### 6. Submit results to remote server

Final step it to submit testing results to remote server.

    if(CTEST_MODEL MATCHES "Release")
        if(CTEST_TARGET_SYSTEM MATCHES "Windows")
            file(GLOB packages "${CTEST_BINARY_DIRECTORY}/*.zip")
        else()
            file(GLOB packages "${CTEST_BINARY_DIRECTORY}/*.tar.gz")
        endif()

        list(APPEND CTEST_UPLOAD_FILES ${packages})
    endif()

    ctest_ext_submit()
