#
# Include CTest Ext module
#

include("${CMAKE_CURRENT_LIST_DIR}/../ctest_ext.cmake")

#
# Initialize testing
#

set_ifndef(CTEST_PROJECT_NAME       "CTestExtTemplate")

set_ifndef(CTEST_DASHBOARD_ROOT     "${CMAKE_CURRENT_LIST_DIR}/dashboard")
set_ifndef(CTEST_SOURCE_DIRECTORY   "${CMAKE_CURRENT_LIST_DIR}")

ctest_ext_init()

#
# Check supported targets and models
#

check_if_matches(CTEST_TARGET_SYSTEM    "^Linux" "^MacOS")
check_if_matches(CTEST_MODEL            "^Experimental$" "^Nightly$")

#
# Configure the testing model (set options, not specified by user, to default values)
#

if(CTEST_MODEL MATCHES "Nightly")
    if(CTEST_GCOVR_EXECUTABLE)
        set_ifndef(CTEST_WITH_COVERAGE          TRUE)
        set_ifndef(CTEST_COVERAGE_TOOL          "GCOVR")
    endif()

    if(CTEST_MEMORYCHECK_COMMAND)
        set_ifndef(CTEST_WITH_DYNAMIC_ANALYSIS  TRUE)
        set_ifndef(CTEST_DYNAMIC_ANALYSIS_TOOL  "CDASH")
    endif()
endif()

#
# Configure cmake options
#

set_ifndef(CTEST_CMAKE_GENERATOR "Unix Makefiles")
set_ifndef(CTEST_CONFIGURATION_TYPE "Debug")

if(CTEST_WITH_COVERAGE)
    add_cmake_cache_entry("CMAKE_CXX_FLAGS" TYPE "STRING" "--coverage")
endif()

#
# Start testing
#

ctest_ext_start()

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

ctest_ext_test(EXCLUDE "Test3")

#
# Coverage
#

ctest_ext_coverage(
    GCOVR
        HTML VERBOSE FILTER ".*/main.cpp")

#
# MemCheck
#

ctest_ext_dynamic_analysis()

#
# Submit
#

ctest_ext_submit()
