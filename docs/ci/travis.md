# Travis CI example

To use CTest Extension module with Travis CI use the following template for the `.travis.yml` file:

    language: cpp

    sudo: required
    dist: trusty

    addons:
      apt:
        packages:
          - valgrind

    env:
      global:
        - CTEST_EXT_COLOR_OUTPUT=TRUE
        - CTEST_BUILD_FLAGS=-j4

    matrix:
      include:
        - os: linux
          compiler: gcc
          env: CTEST_TARGET_SYSTEM=Linux-gcc    CTEST_MODEL=Nightly
        - os: osx
          compiler: clang
          env: CTEST_TARGET_SYSTEM=MacOS-clang  CTEST_MODEL=Nightly

    script:
      - ctest -VV -S ./project_test.cmake
