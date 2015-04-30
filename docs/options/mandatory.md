#  Mandatory testing options

## CTEST_PROJECT_NAME

Project name.

## CTEST_TARGET_SYSTEM

This option describes the target platform for the testing.
By default it is equal to `${CMAKE_SYSTEM}-${CMAKE_SYSTEM_PROCESSOR}`.

See [CMAKE_SYSTEM] and [CMAKE_SYSTEM_PROCESSOR].

## CTEST_MODEL

The testing model (default - *Experimental*).

## CTEST_SITE

Site name for submission. By default is equal to the host name.

## CTEST_BUILD_NAME

Build name for submission. By default is equal to `${CTEST_TARGET_SYSTEM}-${CTEST_MODEL}`.

## CTEST_DASHBOARD_ROOT

Root folder for the testing.

The testing script will use this folder to create temporary files,
so it should have write access and should be unique for different scripts.

By default is equal to `${CTEST_SCRIPT_DIRECTORY}/${CTEST_TARGET_SYSTEM}/${CTEST_MODEL}`.

## CTEST_SOURCE_DIRECTORY

Directory with project sources. By default is equal to `${CTEST_DASHBOARD_ROOT}/source`.

If the folder doesn't exist the testing script will clone it from the remote repository
(see the next section).

## CTEST_BINARY_DIRECTORY

Build folder. By default is equal to `${CTEST_DASHBOARD_ROOT}/build`.

## CTEST_NOTES_LOG_FILE

Path to log file for CTest notes.

The CTest Extension module will use this file to log some important information
about testing and will add it to submission as a note.

By default is equal to `${CTEST_DASHBOARD_ROOT}/ctest_notes_log.txt`.

[CMAKE_SYSTEM]: <http://www.cmake.org/cmake/help/v3.1/variable/CMAKE_SYSTEM.html>
[CMAKE_SYSTEM_PROCESSOR]: <http://www.cmake.org/cmake/help/v3.1/variable/CMAKE_SYSTEM_PROCESSOR.html>
