#!/usr/bin/env bash
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Bash sanity settings (error on exit, complain for undefined vars, error when pipe fails)
set -euo pipefail

CMDNAME="$(basename -- "$0")"

AIRFLOW_ROOT="$(cd ${MY_DIR}; pwd)"
export AIRFLOW__CORE__DAGS_FOLDER="S{AIRFLOW_ROOT}/tests/dags"

# add test/contrib to PYTHONPATH
export PYTHONPATH=${PYTHONPATH:-${AIRFLOW_ROOT}/tests/test_utils}

# environment
export AIRFLOW_HOME=${AIRFLOW_HOME:=${HOME}}

echo Airflow home: ${AIRFLOW_HOME}

export AIRFLOW__CORE__UNIT_TEST_MODE=True

# add test/test_utils to PYTHONPATH TODO: Do we need that ??? Looks fishy.
export PYTHONPATH=${PYTHONPATH}:${MY_DIR}/tests/test_utils

usage() {
      echo """

Usage: ${CMDNAME} [FLAGS] [TESTS_TO_RUN] -- <EXTRA_NOSETEST_ARGS>

Runs tests specified (or all tests if no tests are specified)

Flags:

-h, --help
        Shows this help message.

-s, --skip-db-init
        Skips database initialization

"""
}

echo

####################  Parsing options/arguments
PARAMS=$(getopt \
    -o "${_RUN_TESTS_GETOPT_SHORT_OPTIONS:=}" \
    -l "${_RUN_TESTS_GETOPT_LONG_OPTIONS:=}" \
    --name "$CMDNAME" -- "$@")

if [[ $? -ne 0 ]]
then
    usage
fi


eval set -- "${PARAMS}"
unset PARAMS

SKIP_DB_INIT="false"

# Parse Flags.
# Please update short and long options in the run-tests-complete script
# This way autocomplete will work out-of-the-box
while true
do
  case "${1}" in
    -h|--help)
      usage;
      exit 0 ;;
    -s|--skip-db-init)
      SKIP_DB_INIT="true"
      shift ;;
    --)
      shift ;
      break ;;
    *)
      usage
      echo
      echo "ERROR: Unknown argument ${1}"
      echo
      exit 1
      ;;
  esac
done


# any argument received after -- is overriding the default nose execution arguments:
NOSE_ARGS=$@

if [[ "${SKIP_DB_INIT}" == "true" ]]; then
    echo
    echo "Skipping initializing of the DB"
    echo
else
    echo "Initializing the DB"
    yes | airflow initdb || true
    airflow resetdb -y
fi

kinit -kt ${KRB5_KTNAME} airflow

if [[ -z "${NOSE_ARGS}" ]]; then
  NOSE_ARGS="--with-coverage \
  --cover-erase \
  --cover-html \
  --cover-package=airflow \
  --cover-html-dir=airflow/www/static/coverage \
  --with-ignore-docstrings \
  --rednose \
  --with-timer \
  -v \
  --logging-level=DEBUG"
fi

# For impersonation tests running on SQLite on Travis, make the database world readable so other
# users can update it
AIRFLOW_DB="${HOME}/airflow.db"

if [[ -f "${AIRFLOW_DB}" ]]; then
  chmod a+rw "${AIRFLOW_DB}"
  chmod g+rwx "${AIRFLOW_HOME}"
fi

echo "Starting the tests with the following nose arguments: ${NOSE_ARGS}"
nosetests ${NOSE_ARGS}
