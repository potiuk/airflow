#!/usr/bin/env bash

#
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing,
#  software distributed under the License is distributed on an
#  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#  KIND, either express or implied.  See the License for the
#  specific language governing permissions and limitations
#  under the License.

set -xeuo pipefail
MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PYTHON_VERSION=${PYTHON_VERSION:=$(python -c 'import sys; print("%s.%s" % (sys.version_info.major, sys.version_info.minor))')}
export AIRFLOW_VERSION=$(cat airflow/version.py - << EOF | python
print(version.replace("+",""))
EOF
)
export DOCKERHUB_USER=${DOCKERHUB_USER:="apache"}
export AIRFLOW_CI_VERBOSE="true"
export BACKEND=${BACKEND:="sqlite"}
export ENV=${ENV:="docker"}
# Branch name to download image from
# Can be overridden by SOURCE_BRANCH
# Define an empty BRANCH_NAME_FIRST
export BRANCH_NAME=${BRANCH_NAME:=""}
# in case SOURCE_BRANCH is defined it can override the BRANCH_NAME
export BRANCH_NAME=${SOURCE_BRANCH:=${BRANCH_NAME}}
# Default branch name for triggered builds is master
export BRANCH_NAME=${BRANCH_NAME:="master"}

if [[ "${ENV}" == "docker" ]]; then
  docker-compose --log-level INFO \
      -f ${MY_DIR}/docker-compose.yml \
      -f ${MY_DIR}/docker-compose-${BACKEND}.yml \
        run airflow-testing /opt/airflow/scripts/ci/in_container/entrypoint_ci.sh;
else
  ${MY_DIR}/kubernetes/minikube/stop_minikube.sh
  ${MY_DIR}/kubernetes/setup_kubernetes.sh &&
  ${MY_DIR}/kubernetes/kube/deploy.sh -d persistent_mode &&
  export MINIKUBE_IP=$(minikube ip)
  docker-compose --log-level ERROR \
      -f ${MY_DIR}/docker-compose.yml \
      -f ${MY_DIR}/docker-compose-${BACKEND}.yml \
      -f ${MY_DIR}/docker-compose-kubernetes.yml \
         run airflow-testing /opt/airflow/scripts/ci/in_container/entrypoint_ci.sh;
  ${MY_DIR}/kubernetes/minikube/stop_minikube.sh
fi
