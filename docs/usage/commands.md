# CTest Ext Commands

This section describes all commands provided by CTest Extension module.
Those commands are supposed to be used in project's testing script.

## Dashboard testing commands

### ctest_ext_init

Initializes CTest Ext module for dashboard testing.

    ctest_ext_init()

The function sets dashboard settings to default values (if they were not defined prior the call)
and performs project repository checkout/update if needed.

### ctest_ext_start

Starts dashboard testing.

    ctest_ext_start()

The function sets testing settings to default values (if they were not defined prior the call)
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

Collects coverage reports.

    ctest_ext_coverage(
        [GCOVR <options for run_gcovr>]
        [LCOV <options for run_lcov>]
        [CDASH <options for ctest_coverage>])

The function passes own arguments to `run_gcovr`, `run_lcov` and `ctest_coverage` as is.

### ctest_ext_dynamic_analysis

Runs dynamic analysis testing.

    ctest_ext_dynamic_analysis(
        CDASH <options for ctest_memcheck>)

The function will pass its arguments to `ctest_memcheck` as is.

### ctest_ext_submit

Submits testing results to remote server.

    ctest_ext_submit()

## CMake configuration commands

### add_cmake_cache_entry

Adds new CMake cache entry.

    add_cmake_cache_entry(<name> <value> [TYPE <type>] [FORCE])

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

### set_from_env

Sets `<variable>` to the value of environment variable with the same name,
only if the `<variable>` is not defined and the environment variable is defined.

    set_from_env(<variable1> <variable2> ...)

### override_from_ctest_vars

Overrides all variables from `CTEST_<var_name>` values, if they are defined.

    override_from_ctest_vars(<variable1> <variable2> ...)

### check_vars_def

Checks that all variables are defined.

    check_vars_def(<variable1> <variable2> ...)

### check_vars_exist

Checks that all variables are defined and point to existed file/directory.

    check_vars_exist(<variable1> <variable2> ...)

### check_if_matches

Checks that <variable> matches one of the regular expression from the input list.

    check_if_matches(<variable> <regexp1> <regexp2> ...)

### list_filter_out

Filter out all items in the `<list>`, which match one of the regular expression from the input list.

    list_filter_out(<list> <regexp1> <regexp2> ...)

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

### ctext_ext_log_stage

Log new stage start.

    ctext_ext_log_stage(<message>)

## Internal commands

### ctest_ext_dump_notes

Dumps all launch options to note file.

    ctest_ext_dump_notes()

This is an internal function, which is used by `ctest_ext_start`.

### run_gcovr

Runs `gcovr` command to generate coverage report.

    run_gcovr([XML] [HTML]
              [FILTER <filter>]
              [OUTPUT_BASE_NAME <output_dir>]
              [XML_DIR <xml output dir>]
              [HTML_DIR <html output dir>]
              [EXTRA_OPTIONS <option1> <option2> ...])

This is an internal function, which is used in `ctest_ext_coverage`.

The gcovr command is run in `CTEST_BINARY_DIRECTORY` directory relatively to `CTEST_SOURCE_DIRECTORY` directory.
The binaries must be built with gcov coverage support.
The gcovr command must be run after all tests.

Coverage reports will be generated in:

  - <XML_DIR>/<OUTPUT_BASE_NAME>.xml
  - <HTML_DIR>/<OUTPUT_BASE_NAME>.html

`XML` and `HTML` options choose coverage report format (both can be specified).

`FILTER` options is used to specify file filter for report.
If not specified `${CTEST_SOURCE_DIRECTORY}/*` will be used.

`OUTPUT_BASE_NAME` specifies base name for output reports.
If not specified `coverage` will be used.

`XML_DIR` specifies base directory for XML reports.
If not specified `${CTEST_BINARY_DIRECTORY}/coverage-gcovr/xml` will be used.

`HTML_DIR` specifies base directory for HTML reports.
If not specified `${CTEST_BINARY_DIRECTORY}/coverage-gcovr/html` will be used.

`EXTRA_OPTIONS` specifies additional options for gcovr command line.

If `CTEST_GCOVR_<option_name>` variable if defined, it will override the value of
`<option_name>` option.

`CTEST_GCOVR_EXECUTABLE` variable must be defined and must point to gcovr command.

### run_lcov

Runs `lcov` and `genthml` commands to generate coverage report.

    run_lcov([BRANCH_COVERAGE] [FUNCTION_COVERAGE]
             [SKIP_HTML]
             [OUTPUT_LCOV_DIR <output_lcov_dir>]
             [OUTPUT_HTML_DIR <output_html_dir>]
             [EXTRACT] <extract patterns>
             [REMOVE] <remove patterns>
             [EXTRA_LCOV_OPTIONS <lcov extra options>]
             [EXTRA_GENTHML_OPTIONS <genhtml extra options>])

Runs `lcov` and `genthml` commands to generate coverage report.

This is an internal function, which is used in `ctest_ext_coverage`.

`BRANCH_COVERAGE` and `FUNCTION_COVERAGE` options turn on branch and function coverage analysis.

`SKIP_HTML` disables html report generation.

The `lcov` command is run in `CTEST_BINARY_DIRECTORY` directory relatively to `CTEST_SOURCE_DIRECTORY` directory.
The binaries must be built with `gcov` coverage support.
The `lcov` command must be run after all tests.

If `CTEST_LCOV_<option_name>` variable if defined, it will override the value of
`<option_name>` option.

`CTEST_LCOV_EXECUTABLE` variable must be defined and must point to `lcov` command.
`CTEST_GENHTML_EXECUTABLE` variable must be defined and must point to `genhtml` command.
