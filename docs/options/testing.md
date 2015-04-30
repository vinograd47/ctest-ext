# Optional testing settings

## CTEST_UPDATE_CMAKE_CACHE

True, if the testing script should overwrite CMake cache on each launch.

## CTEST_EMPTY_BINARY_DIRECTORY

True, if the testing script should clean build directory on each launch.

## CTEST_CMAKE_GENERATOR

CMake generator.

## CTEST_CONFIGURATION_TYPE

CMake configuration type (eg. Release, Debug).

## CTEST_INITIAL_CACHE

Initial CMake cache.

## CTEST_CMAKE_EXTRA_OPTIONS

Extra options for CMake configuration command.

## CTEST_BUILD_FLAGS

Extra options for build command. For example:

    set(CTEST_BUILD_FLAGS "-j7")

## CTEST_WITH_TESTS

Enable/disable test launching.

## CTEST_TEST_TIMEOUT

Timeout in seconds for single test execution.

## CTEST_WITH_COVERAGE

Enable/disable code coverage analysis.

## CTEST_COVERAGE_TOOL

Tool used for code coverage analysis:

  - GCOVR
  - LCOV
  - CDASH

## CTEST_WITH_DYNAMIC_ANALYSIS

Enable/disable dynamic analysis.

## CTEST_DYNAMIC_ANALYSIS_TOOL

Tool used for dynamic analysis:

  - CDASH

## CTEST_WITH_SUBMIT

Enable/disable submission to remote server.
