# Run project testing script

1. Download project testing script.

2. Put the project testing script to a dashboard directory
(for example, `~/Dashboards/project` or `c:/Dashboards/project`).

3. Run CTest tool from a command line:

        $ ctest -VV -S ~/Dashboards/project/project_test.cmake

4. Add the above command to a scheduler (for example, `cron`) or
   to a CI system (like buildbot, jenkins, travis).

For CTest tool command line options please refer to
[CTest Documentation](http://www.cmake.org/cmake/help/v3.1/manual/ctest.1.html).

## Configure the testing script

The CTest Extension module can be configured in three ways:

1. Create parent CMake script, which will define all required variables and then
   include the project's testing script:

        set(CTEST_TARGET_SYSTEM "Linux-Ubuntu-14.04-x64")
        set(CTEST_MODEL         "Performance")
        include("~/Dashboards/project/project_test.cmake")

2. Pass the options with CTest command line:

        $ ctest -VV -S ~/Dashboards/project/project_test.cmake \
            -DCTEST_TARGET_SYSTEM="Linux-Ubuntu-14.04-x64" \
            -DCTEST_MODEL="Nightly"

3. Set the options as environment variables prior to CTest call:

        $ export CTEST_TARGET_SYSTEM="Linux-Ubuntu-14.04-x64"
        $ export CTEST_MODEL="Nightly"
        $ ctest -VV -S ~/Dashboards/project/project_test.cmake
