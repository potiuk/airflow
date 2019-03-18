#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
set -euo pipefail

MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd ${MY_DIR}/../../ || exit 1

export AIRFLOW_CONTAINER_SKIP_MAIN_IMAGE="false"
export AIRFLOW_CONTAINER_SKIP_CI_IMAGE="true"
export AIRFLOW_CONTAINER_PUSH_IMAGES="false"
export AIRFLOW_CONTAINER_FORCE_PULL_IMAGES="true"
export AIRFLOW_CONTAINER_BUILD_NPM="false"

. ./hooks/build

set -x
docker run --entrypoint flake8 "${LOCAL_IMAGE}"
set +x

popd || exit 1
