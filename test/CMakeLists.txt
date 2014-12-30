cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)
enable_testing()

project(CTestExt NONE)

get_filename_component(CTEST_EXT_ROOT_DIR "${CMAKE_SOURCE_DIR}/.." ABSOLUTE)

set(TEMPLATE_PROJECT_DIR "${CTEST_EXT_ROOT_DIR}/template")

set(DASHBOARD_ROOT "${CMAKE_BINARY_DIR}/dashboards/TemplateExperimental")
configure_file("template_test.cmake.in" "${DASHBOARD_ROOT}/template_test.cmake" @ONLY)
add_test(NAME TemplateExperimental
    COMMAND "${CMAKE_CTEST_COMMAND}" "-VV" "-S" "${DASHBOARD_ROOT}/template_test.cmake" "-DCTEST_MODEL=Experimental")

set(DASHBOARD_ROOT "${CMAKE_BINARY_DIR}/dashboards/TemplateNightly")
configure_file("template_test.cmake.in" "${DASHBOARD_ROOT}/template_test.cmake" @ONLY)
add_test(NAME TemplateNightly
    COMMAND "${CMAKE_CTEST_COMMAND}" "-VV" "-S" "${DASHBOARD_ROOT}/template_test.cmake" "-DCTEST_MODEL=Nightly")
