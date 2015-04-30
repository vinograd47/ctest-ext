# Usage with CI systems

The testing script can be used with CI systems, like buildbot, Jenkins, Travis, etc.
The CI system might call the same CTest command to perform project configuration, build and testing.

The testing script supports step-by-step mode, to split all steps on CI system. For example:

    $ ctest -VV -S ~/Dashboards/project/project_test.cmake,Start
    $ ctest -VV -S ~/Dashboards/project/project_test.cmake,Configure
    $ ctest -VV -S ~/Dashboards/project/project_test.cmake,Build
    $ ctest -VV -S ~/Dashboards/project/project_test.cmake,Test
    $ ctest -VV -S ~/Dashboards/project/project_test.cmake,Coverage
    $ ctest -VV -S ~/Dashboards/project/project_test.cmake,DynamicAnalysis
    $ ctest -VV -S ~/Dashboards/project/project_test.cmake,Submit
    $ ctest -VV -S ~/Dashboards/project/project_test.cmake,Extra
