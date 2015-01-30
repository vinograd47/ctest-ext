# CTest Ext Commands

This section describes all commands provided by CTest Extension module.
Those commands are supposed to be used in project's testing script.

## Dashboard testing commands

### ctest_ext_init

Initializes CTest Ext module for dashboard testing.

    ctest_ext_init()

The function sets dashboard options to default values (if they were not defined prior the call)
and performs project repository checkout/update if needed.

### ctest_ext_start

Starts dashboard testing.

    ctest_ext_start()

The function sets testing options to default values (if they were not defined prior the call)
and initializes logging mechanism.

### ctest_ext_configure

Configures CMake project.

    ctest_ext_configure()

To configure CMake cache variables use `add_cmake_cache_entry` command.

### ctest_ext_build

Builds CMake project.

    ctest_ext_build([TARGET <target>] [TARGETS <target1> <target2> ...])

### ctest_ext_test

Runs tests.

    ctest_ext_test(<arguments>)

The function will pass its arguments to `ctest_test` as is.

### ctest_ext_coverage

Collects coverage reports (in gcovr or/and in CTest format).

    ctest_ext_coverage([GCOVR_OPTIONS <options for run_gcovr>] [CTEST_OPTIONS <options for ctest_coverage>])

The function passes own arguments to `run_gcovr` and `ctest_coverage` as is.

### ctest_ext_memcheck

Runs dynamic analysis testing.

    ctest_ext_memcheck(<arguments>)

The function will pass its arguments to `ctest_memcheck` as is.

### ctest_ext_submit

Submits testing results to remote server.

    ctest_ext_submit()

## CMake configuration commands

### add_cmake_cache_entry

Adds new CMake cache entry.

    add_cmake_cache_entry(<name> <value> [TYPE <type>])

## Git repository control commands

### clone_git_repo

Clones git repository from `<git url>` to `<destination>` directory.

    clone_git_repo(<git url> <destination> [BRANCH <branch>])

Optionally `<branch>` name can be specified.

`CTEST_GIT_COMMAND` variable must be defined and must point to `git` command.

### update_git_repo

Updates local git repository in `<directory>` to latest state from remote repository.

    update_git_repo(<directory> [REMOTE <remote>] [BRANCH <branch>] [UPDATE_COUNT_OUTPUT <output variable>])

`<remote>` specifies remote repository name, `origin` by default.

`<branch>` specifies remote branch name, `master` by default.

`<output variable>` specifies optional output variable to store update count.
If it is zero, local repository already was in latest state.

`CTEST_GIT_COMMAND` variable must be defined and must point to `git` command.

### get_git_repo_info

Gets information about local git repository (branch name and revision).

    get_git_repo_info(<repository> <branch output variable> <revision output variable>)

## System commands

### create_tmp_dir

Creates temporary directory and returns path to it via `<output_variable>`.

    create_tmp_dir(<output_variable> [BASE_DIR <path to base temp directory>])

`BASE_DIR` can be used to specify location for base temporary path,
if it is not defined `TEMP`, `TMP` or `TMPDIR` environment variables will be used.

`CTEST_TMP_DIR` variable is used as default value for `BASE_DIR` if defined.

## Check commands

### set_ifndef

Sets `<variable>` to the value `<value>`, only if the `<variable>` is not defined.

    set_ifndef(<variable> <value>)

### check_vars_def

Checks that all variables are defined.

    check_vars_def(<variable1> <variable2> ...)

### check_vars_exist

Checks that all variables are defined and point to existed file/directory.

    check_vars_exist(<variable1> <variable2> ...)

### check_if_matches

Checks that <variable> matches one of the regular expression from the input list.

    check_if_matches(<variable> <regexp1> <regexp2> ...)

## Logging commands

### ctest_ext_info

Prints `<message>` to standard output with `[CTEST EXT INFO]` prefix for better visibility.

    ctest_ext_info(<message>)

### ctest_ext_note

Writes `<message>` both to console and to note file.

    ctest_ext_note(<message>)

The function appends `[CTEST EXT NOTE]` prefix to console output for better visibility.
The note file is used in submit command.

The command will be available after `ctest_ext_start` call.

`CTEST_NOTES_LOG_FILE` variable must be defined.

## Internal commands

### ctest_ext_dump_notes

Dumps all launch options to note file.

    ctest_ext_dump_notes()

This is an internal function, which is used by `ctest_ext_start`.

### run_gcovr

Runs `gcovr` command to generate coverage report.

    run_gcovr([XML] [HTML] [VERBOSE] [OUTPUT_BASE_NAME <output_dir>] [REPORT_BASE_DIR <report_name>] [OPTIONS <option1> <option2> ...])

This is an internal function, which is used in `ctest_ext_coverage`.

The `gcovr` command is run in `CTEST_BINARY_DIRECTORY` directory relatively to `CTEST_SOURCE_DIRECTORY` directory.
The binaries must be built with `gcov` coverage support.
The `gcovr` command must be run after all tests.

Coverage reports will be generated in:

  - `<REPORT_BASE_DIR>/xml/<OUTPUT_BASE_NAME>.xml`
  - `<REPORT_BASE_DIR>/html/<OUTPUT_BASE_NAME>.html`

`XML` and `HTML` options choose coverage report format (both can be specified).

`VERBOSE` turns on `gcovr` verbose mode.

`OUTPUT_BASE_NAME` specifies base name for output reports (`coverage` by default).

`REPORT_BASE_DIR` specifies base directory for output reports.
If not specified `CTEST_GCOVR_REPORT_DIR` variable is used,
which by default is equal to `${CTEST_BINARY_DIRECTORY}/coverage`

`OPTIONS` specifies additional options for `gcovr` command line.

`CTEST_GCOVR_EXECUTABLE` variable must be defined and must point to `gcovr` command.
