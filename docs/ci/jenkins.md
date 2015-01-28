# Jenkins CI example

Create a parameterized job with the following parameters:

  - `CTEST_TARGET_SYSTEM` - choice parameter;
  - `CTEST_MODEL` - choice parameter;
  - `CTEST_COMMAND_ARGS` - string parameter.

Add repository checkout step to `$WORKSPACE/project` directory.

Add shell step to build section with the following content:

    mkdir -p $WORKSPACE/$CTEST_TARGET_SYSTEM/$CTEST_MODEL
    rm -rf $WORKSPACE/$CTEST_TARGET_SYSTEM/$CTEST_MODEL/build/Testing

    cat > $CTEST_TARGET_SYSTEM/$CTEST_MODEL/project_jenkins_test.cmake << EOF
        include("$WORKSPACE/ctest_ext.cmake")

        set(CTEST_TARGET_SYSTEM     "$CTEST_TARGET_SYSTEM")
        set(CTEST_MODEL             "$CTEST_MODEL")

        set(CTEST_DASHBOARD_ROOT    "$WORKSPACE/$CTEST_TARGET_SYSTEM/$CTEST_MODEL")
        set(CTEST_SOURCE_DIRECTORY  "$WORKSPACE/project")
        set(CTEST_BINARY_DIRECTORY  "${CTEST_DASHBOARD_ROOT}/build")

        set(CTEST_WITH_UPDATE       FALSE)

        if(CTEST_TARGET_SYSTEM MATCHES "Android")
            add_cmake_cache_entry("ANDROID_NDK" TYPE "PATH" "/opt/android-ndk-r10")
            add_cmake_cache_entry("ANDROID_EXECUTABLE" TYPE "FILEPATH" "/opt/android-sdk-linux/tools/android")
        endif()

        include("\${CTEST_SOURCE_DIRECTORY}/project_test.cmake")
    EOF

    ctest -VV -S $WORKSPACE/$CTEST_TARGET_SYSTEM/$CTEST_MODEL/project_jenkins_test.cmake $CTEST_COMMAND_ARGS

Add `xUnit` publisher for CTest with the following pattern:

    $CTEST_TARGET_SYSTEM/$CTEST_MODEL/build/Testing/**/Test.xml
