# Travis CI example

To use CTest Extension module with Travis CI use the following template for the `.travis.yml` file:

    language: cpp
    compiler:
      - gcc
      - clang
    env:
      - CTEST_MODEL=Experimental
      - CTEST_MODEL=Nightly
    install:
      - wget -qO- http://www.cmake.org/files/v3.1/cmake-3.1.0-Linux-x86_64.tar.gz | tar xvz
    script:
      - ./cmake-3.1.0-Linux-x86_64/bin/ctest -VV -S ./project_test.cmake -DCTEST_MODEL=$CTEST_MODEL -DCTEST_EMPTY_BINARY_DIRECTORY=FALSE
