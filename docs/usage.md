# Usage

The CTest Extension module is supposed to be used in a project CTest script.
Project developers provide the testing script (along with source code or separately),
and testers use this script to perform project testing.

The usage from testers point of view:

1. Download project testing script.

2. Put the project testing script to a dashboard directory
(for example, `~/Dashboards/project` or `c:/Dashboards/project`).

3. Run CTest tool from a command line:

        $ ctest -VV -S ~/Dashboards/project/project_test.cmake

4. Add the above command to a scheduler (for example, `cron`) or
   to a CI system (like buildbot, jenkins, travis).

For CTest tool command line options please refer to
[CTest Documentation](http://www.cmake.org/cmake/help/v3.1/manual/ctest.1.html).
