# CTest Extension module

[![Build Status](https://travis-ci.org/jet47/ctest-ext.svg)](https://travis-ci.org/jet47/ctest-ext) [![Documentation Status](https://readthedocs.org/projects/ctest-ext/badge/?version=latest)](https://readthedocs.org/projects/ctest-ext/?badge=latest)

The CTest Extension module is a set of additional functions for CTest scripts.
The main goal of the CTest Extension module is to provide uniform testing approach
for CMake projects.

The CTest Extension module supports the following functionality:

* clone/update git repository;
* configure CMake project;
* build CMake project;
* run tests;
* build coverage report (in CTest format and in gcovr format);
* run dynamic analysis (like valgrind);
* upload testing results to remote server (eg. CDash web server). 

Please refer to the [Latest Documentation](http://ctest-ext.readthedocs.org/en/latest/).
