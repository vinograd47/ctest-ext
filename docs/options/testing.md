# Optional testing settings

## CTEST_UPDATE_CMAKE_CACHE

True, if the testing script should overwrite CMake cache on each launch.

## CTEST_EMPTY_BINARY_DIRECTORY

True, if the testing script should clean build directory on each launch.

## CTEST_WITH_TESTS

Enable/disable test launching.

## CTEST_TEST_TIMEOUT

Timeout in seconds for single test execution.

## CTEST_WITH_MEMCHECK

Enable/disable memory check analysis.

## CTEST_WITH_COVERAGE

Enable/disable CTest-based code coverage analysis.

## CTEST_WITH_GCOVR

Enable/disable gcovr-based code coverage analysis.

## CTEST_WITH_SUBMIT

Enable/disable submission to remote server.

## CTEST_CMAKE_GENERATOR

CMake generator.

## CTEST_CONFIGURATION_TYPE

CMake configuration type (eg. Release, Debug).

## CTEST_CMAKE_OPTIONS

Extra options for CMake command. This options will overwrite default ones.
For example:

    set(CTEST_CMAKE_OPTIONS "-DCUDA_TOOLKIT_ROOT_DIR:PATH=/usr/local/cuda-6.5")

## CTEST_BUILD_TARGET

Target to build. By default is empty, which means ALL target.

## CTEST_BUILD_FLAGS

Extra options for build command. For example:

    set(CTEST_BUILD_FLAGS "-j7")

## CTEST_MEMORYCHECK_COMMAND

Path to memory check tool. Used only if `CTEST_WITH_MEMCHECK` is enabled.

## CTEST_MEMORYCHECK_SUPPRESSIONS_FILE

Path to suppressions file for the memory check tool.
By default the testing script will use internal file for the `valgrind` tool.

## CTEST_MEMORYCHECK_COMMAND_OPTIONS

Extra options for the memory check command.

## CTEST_COVERAGE_COMMAND

Path to code coverage analysis tool. Used only if `CTEST_WITH_COVERAGE` is enabled.

## CTEST_COVERAGE_EXTRA_FLAGS

Extra options for the code coverage analysis command.

## CTEST_GCOVR_EXECUTABLE

Path to `gcovr` command line tool.

## CTEST_GCOVR_EXTRA_FLAGS

Extra options for the `gcovr` command.

## CTEST_GCOVR_REPORT_DIR

Output directory for `gcovr` reports.

By default is equal to `${CTEST_BINARY_DIRECTORY}/coverage`.

## CTEST_NOTES_FILES

List of notes files, which should be included into submission.

## CTEST_UPLOAD_FILES

List of files, which should be uploaded to the remote server.

By default, CMake cache will be uploaded

## CTEST_TMP_DIR

Path to temporary directory.

By default is equal to one of `$ENV{TEMP}`, `$ENV{TMP}`, `$ENV{TMPDIR}` or `/tmp`.

## CTEST_TRACK

Track for submission. By default is equal to ${CTEST_MODEL}.
