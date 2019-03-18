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

set -euo pipefail

MY_DIR="$(cd "`dirname "$0"`"; pwd)"
pushd "${MY_DIR}" || exit 1

if [[ ${APT_DEPS_IMAGE:=""} != "" ]]; then
    # We are inside the container which means that we should fix permissions of the _build folder files
    # Those files are mounted from the host!
    echo "Changing ownership of docs/_build folder to ${AIRFLOW_USER}:${AIRFLOW_USER}"
    sudo chown ${AIRFLOW_USER}:${AIRFLOW_USER} _build
    echo "Changed ownership of docs/_build folder to ${AIRFLOW_USER}:${AIRFLOW_USER}"
fi

echo "Removing content of the  _build folder"
rm -rf "_build/*"
echo "Removed content of the _build folder"

mkdir -pv _build


set +e
# shellcheck disable=SC2063
NUM_INCORRECT_USE_LITERALINCLUDE=$(grep -inR --include \*.rst 'literalinclude::.\+example_dags' . | \
    tee /dev/tty |
    wc -l |\
    tr -d '[:space:]')
set -e

echo
echo "Checking for presence of literalinclude in example DAGs"
echo

if [[ "${NUM_INCORRECT_USE_LITERALINCLUDE}" -ne "0" ]]; then
    echo
    echo "Unexpected problems found in the documentation. "
    echo "You should use a exampleinclude directive to include example DAGs."
    echo "Currently, ${NUM_INCORRECT_USE_LITERALINCLUDE} problem found."
    echo
    exit 1
else
    echo
    echo "No literalincludes in example DAGs found"
    echo
fi

SUCCEED_LINE=$(make html |\
    tee /dev/tty |\
    grep 'build succeeded' |\
    head -1)

NUM_CURRENT_WARNINGS=$(echo ${SUCCEED_LINE} |\
    sed -E 's/build succeeded, ([0-9]+) warnings?\./\1/g')

if [[ ${APT_DEPS_IMAGE:=""} != "" ]]; then
    # We are inside the container which means that we should fix back the permissions of the _build folder files
    # Those files are mounted from the host!
    echo "Changing ownership of docs/_build folder back to ${HOST_USER_ID}:${HOST_GROUP_ID}"
    sudo chown ${HOST_USER_ID}:${HOST_GROUP_ID} _build
    echo "Changed ownership of docs/_build folder back to ${HOST_USER_ID}:${HOST_GROUP_ID}"
fi


if echo ${SUCCEED_LINE} | grep -q "warning"; then
    echo
    echo "Unexpected problems found in the documentation. "
    echo "Currently, ${NUM_CURRENT_WARNINGS} warnings found. "
    echo
    exit 1
fi

popd || exit 1
