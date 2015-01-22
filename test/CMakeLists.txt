cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)
enable_testing()

project(CTestExt NONE)

include(CTest)

get_filename_component(CTEST_EXT_ROOT_DIR "${CMAKE_SOURCE_DIR}/.." ABSOLUTE)

set(TEMPLATE_PROJECT_DIR "${CTEST_EXT_ROOT_DIR}/template")

set(DASHBOARD_ROOT "${CMAKE_BINARY_DIR}/dashboards/Experimental")
configure_file("template_test.cmake.in" "${DASHBOARD_ROOT}/template_test.cmake" @ONLY)
add_test(NAME Experimental
    COMMAND "${CMAKE_CTEST_COMMAND}" "-VV" "-S" "${DASHBOARD_ROOT}/template_test.cmake" "-DCTEST_MODEL=Experimental")
add_test(NAME ExperimentalStart
    COMMAND "${CMAKE_CTEST_COMMAND}" "-VV" "-S" "${DASHBOARD_ROOT}/template_test.cmake,Start" "-DCTEST_MODEL=Experimental")
add_test(NAME ExperimentalConfigure
    COMMAND "${CMAKE_CTEST_COMMAND}" "-VV" "-S" "${DASHBOARD_ROOT}/template_test.cmake,Configure" "-DCTEST_MODEL=Experimental")
set_tests_properties(ExperimentalConfigure PROPERTIES DEPENDS ExperimentalStart)
add_test(NAME ExperimentalBuild
    COMMAND "${CMAKE_CTEST_COMMAND}" "-VV" "-S" "${DASHBOARD_ROOT}/template_test.cmake,Build" "-DCTEST_MODEL=Experimental")
set_tests_properties(ExperimentalBuild PROPERTIES DEPENDS ExperimentalConfigure)
add_test(NAME ExperimentalTest
    COMMAND "${CMAKE_CTEST_COMMAND}" "-VV" "-S" "${DASHBOARD_ROOT}/template_test.cmake,Test" "-DCTEST_MODEL=Experimental")
set_tests_properties(ExperimentalTest PROPERTIES DEPENDS ExperimentalBuild)
add_test(NAME ExperimentalWithFilter
    COMMAND "${CMAKE_CTEST_COMMAND}" "-VV" "-S" "${DASHBOARD_ROOT}/template_test.cmake" "-DCTEST_MODEL=Experimental" "-R" "Test1")
set_tests_properties(ExperimentalWithFilter PROPERTIES PASS_REGULAR_EXPRESSION "100% tests passed, 0 tests failed out of 1")

set(DASHBOARD_ROOT "${CMAKE_BINARY_DIR}/dashboards/Nightly")
configure_file("template_test.cmake.in" "${DASHBOARD_ROOT}/template_test.cmake" @ONLY)
add_test(NAME Nightly
    COMMAND "${CMAKE_CTEST_COMMAND}" "-VV" "-S" "${DASHBOARD_ROOT}/template_test.cmake" "-DCTEST_MODEL=Nightly")

set(DASHBOARD_ROOT "${CMAKE_BINARY_DIR}/dashboards/InvalidModel")
configure_file("template_test.cmake.in" "${DASHBOARD_ROOT}/template_test.cmake" @ONLY)
add_test(NAME InvalidModel
    COMMAND "${CMAKE_CTEST_COMMAND}" "-VV" "-S" "${DASHBOARD_ROOT}/template_test.cmake" "-DCTEST_MODEL=Invalid")
set_tests_properties(InvalidModel PROPERTIES
  WILL_FAIL TRUE)

set(DASHBOARD_ROOT "${CMAKE_BINARY_DIR}/dashboards/InvalidTarget")
configure_file("template_test.cmake.in" "${DASHBOARD_ROOT}/template_test.cmake" @ONLY)
add_test(NAME InvalidTarget
    COMMAND "${CMAKE_CTEST_COMMAND}" "-VV" "-S" "${DASHBOARD_ROOT}/template_test.cmake" "-DCTEST_MODEL=Experimental" "-DCTEST_TARGET_SYSTEM=Invalid")
set_tests_properties(InvalidTarget PROPERTIES
  WILL_FAIL TRUE)
