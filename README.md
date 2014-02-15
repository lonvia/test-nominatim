Simple functional tests for the Nominatim API.

The tests use the lettuce framework (http://lettuce.it/) and
nose (https://nose.readthedocs.org). They are meant to be run
against a Nominatim installation with a complete planet-wide
setup based on a fairly recent planet. If you only have an
excerpt, some of the tests may fail.

Prerequisites
=============

 * lettuce framework (http://lettuce.it/)
 * nose (https://nose.readthedocs.org)
 * pytidylib (http://countergram.com/open-source/pytidylib)

Usage
=====

 * get prerequisites

     [sudo] pip install lettuce nose pytidylib

 * run the tests

     NOMINATIM_SERVER=http://your.nominatim.instance/ lettuce features


Writing Tests
=============

The following explanation assume that the reader is familiar with the lettuce
notations of features, scenarios and steps.


API Tests
---------

These tests are meant to test the different API calls and their parameters.

There are two kind of steps defined for these tests: 
request setup steps (see `tests/request_setup.py`) 
and steps for checking results (see `tests/check_*.py`).

Each scenario follows this simple sequence of steps:

  1. An action step from the request setup. It defines which API function
     to call and completely resets the internal state, forgetting any parameters
     that have been set so far.
  2. Further request setup steps to add parameters for the call.
  3. As many result checks as necessary. The first check step will
     automatically send a request to the Nominatim API. The result is then
     cached and all subsequent check steps are applied to the cached result.

Import Tests
------------

These tests check the import and update of the Nominatim database. They do not
test the correctness of osm2pgsql. Each test will write some data into the `place`
table (and optionally `the planet_osm_*` tables if required) and then run
Nominatim's processing functions on that.

These tests need to create their own test databases. By default they will be called
test_template_nominatim and test_nominatim. Names can be changed with the environment
variables TEMPLATE_DB and TEST_DB. The user running the tests needs superuser rights
for postgres.
