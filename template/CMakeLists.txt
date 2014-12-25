cmake_minimum_required(VERSION 2.8.7)

enable_testing()

project(CTestExtTemplate)

find_package(Threads REQUIRED)

include_directories(gtest)

add_library(gtest STATIC "gtest/gtest.h" "gtest/gtest.cpp")

add_executable(test_app "main.cpp")

target_link_libraries(test_app LINK_PRIVATE gtest ${CMAKE_THREAD_LIBS_INIT})

add_test(NAME Test1 COMMAND test_app "--gtest_filter=Func.Test1")
add_test(NAME Test2 COMMAND test_app "--gtest_filter=Func.Test2")
add_test(NAME Test3 COMMAND test_app "--gtest_filter=Func.Test3")
