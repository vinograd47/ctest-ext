# Travis CI example

To use CTest Extension module with Travis CI use the following template for the `.travis.yml` file:

    language: cpp
    addons:
        apt:
            sources:
                - george-edison55-precise-backports # cmake 3.2.3
            packages:
                - cmake
                - cmake-data
    env:
      - CTEST_MODEL=Nightly
    script:
      - ctest -VV -S ./project_test.cmake -DCTEST_MODEL=$CTEST_MODEL
