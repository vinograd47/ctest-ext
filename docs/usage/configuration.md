# Configuration

The CTest Extension module uses **Target system** and **Testing model** notations to
perform different tests, depending on target platform and user intention.

## Target system

The **Target system** describes the target OS, version, architecture, etc.
This parameter allows the testing script to choose appropriate configuration
for CMake and build tools.

The set of supported targets is defined by the project.

The generic format for the **Target system** is `<KIND>[-<NAME>][-<ARCH>]`, where

* `<KIND>` is one of **Linux**, **Windows**, **MacOS**, **Android**.
* `<NAME>` is an optional OS name and version, for example **Ubuntu-14.04**, **Vista**.
* `<ARCH>` is an optional architecture description, for example **x86_64**, **ARM**, **ARM-Tegra5**.

## Testing model

The **Testing model** notation describes the intention of the testing and
allows the testing script to choose appropriate set of tests.

The set of supported models is defined by the project.

Example of such set:

* *Experimental* - performs custom testing.
* *Nightly* - performs full and clean nightly testing.
* *Continuous* - performs quick testing, only if there were updates in the remote repository.
* *Release* - builds release packages.
* *Performance* - collects benchmarking results.
* *MemCheck* - performs dynamic analysis.
* *Documentation* - builds documentation.

## Configure the testing script

The CTest Extension module can be configured in two ways:

1. Set the required parameters before including the CTest Extension module:

        set(CTEST_TARGET_SYSTEM "Linux-Ubuntu-14.04-x64")
        set(CTEST_MODEL         "Performance")
        include("${CTEST_SCRIPT_DIRECTORY}/ctest_ext.cmake")

2. Pass the options with CTest command line:

        $ ctest -VV -S ~/Dashboards/project/project_test.cmake \
            -DCTEST_TARGET_SYSTEM="Linux-Ubuntu-14.04-x64" \
            -DCTEST_MODEL="Nightly"
