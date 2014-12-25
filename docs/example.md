# Example of CTest project script

Assuming we have a CMake project with the following structure:

    - project/
      - CMakeLists.txt
      - <sources>

Add `CTestConfig.cmake` file to the project root folder with the following content:

    set(CTEST_PROJECT_NAME "ProjectName")
    set(CTEST_NIGHTLY_START_TIME "01:00:00 UTC")

    set(CTEST_DROP_METHOD "http")
    set(CTEST_DROP_SITE "localhost")
    set(CTEST_DROP_LOCATION "/CDash/submit.php?project=ProjectName")
    set(CTEST_DROP_SITE_CDASH TRUE)

Add `project_test.cmake` file to the project root folder with the following content:

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
