#!/usr/bin/env bash
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

#
# Autodetects common variables depending on the environment it is run in
#
# This autodetection of PYTHON_VERSION works in this sequence:
#
#    1) When running builds on DockerHub we cannot pass different environment
#       variables there, so we detect python version based on the image
#       name being build (airflow:master-python3.7 -> PYTHON_VERSION=3.7).
#       DockerHub adds index.docker.io in front of the image name.
#
#    2) When running builds on Travis CI we use python version determined
#       from default python3 available on the path. This way we
#       do not have to specify PYTHON_VERSION separately in each job.
#       (We do not need it it in Travis). We just specify which host python
#       version is used for that job. This makes a nice UI experience where
#       you see python version in Travis UI.
#
#    3) Running builds locally via scripts where we can pass PYTHON_VERSION
#       as environment variable. If variable is not set we use the same detection
#       as in Travis CI.
#

# shellcheck source=common/_default_branch.sh
. "${AIRFLOW_SOURCES}/common/_default_branch.sh"

#  Output:
#
#  * DEFAULT_BRANCH                - default branch used (master/v1-10-test)
#  * DOCKERHUB_USER/DOCKERHUB_REPO - DockerHub user/repo  (<USER>/<REPO>)
#  * AIRFLOW_CONTAINER_BRANCH_NAME - branch for the build
#  * PYTHON_VERSION                - actually used PYTHON_VERSION (might be overwritten)
#  * CI/NON_CI                     - ("true"/"false") to distinguish CI vs. NON_CI build
#  * AIRFLOW_VERSION               - version of Airflow from sources
#  * AIRFLOW_CONTAINER_USE_CACHE   - set to false if CRON job detected
#
function autodetect_variables() {
    # You can override DOCKERHUB_USER to use your own DockerHub account and play with your
    # own docker images. In this case you can build images locally and push them
    export DOCKERHUB_USER=${DOCKERHUB_USER:="apache"}

    # You can override DOCKERHUB_REPO to use your own DockerHub repository and play with your
    # own docker images. In this case you can build images locally and push them
    export DOCKERHUB_REPO=${DOCKERHUB_REPO:="airflow"}

    # if AIRFLOW_CONTAINER_BRANCH_NAME is not set it will be set to either SOURCE_BRANCH
    # (if overridden by configuration) or default branch configured in /common/_default_branch.sh
    SOURCE_BRANCH=${SOURCE_BRANCH:=${DEFAULT_BRANCH}}

    AIRFLOW_CONTAINER_BRANCH_NAME=${AIRFLOW_CONTAINER_BRANCH_NAME:=${SOURCE_BRANCH}}

    echo
    echo "Branch: ${AIRFLOW_CONTAINER_BRANCH_NAME}"
    echo

    # You can override AUTODETECT_PYTHON_BINARY if you want to use different version but for now we assume
    # that the binary used will be the default python 3 version available on the path
    # unless it is overridden with PYTHON_VERSION variable in the next step
    if ! AUTODETECT_PYTHON_BINARY=${AUTODETECT_PYTHON_BINARY:=$(command -v python3)}; then
        echo >&2
        echo >&2 "Error: You must have python3 in your PATH"
        echo >&2
        exit 1
    fi

    # Determine python version. This can be either specified by AUTODETECT_PYTHON_VERSION variable or it is
    # auto-detected from the version of the python3 binary (or AUTODETECT_PYTHON_BINARY you specify as
    # environment variable).
    # Note that even if we auto-detect it here, it can be further overridden in case IMAGE_NAME is speecified
    # as environment variable. The reason is that IMAGE_NAME is the only differentiating factor we can have
    # in the DockerHub build. We cannot specify different environment variables for different image names
    # so we use IMAGE_NAME to determine which PYTHON_VERSION is actually used for this particular build.
    # It's cumbersome - we can improve it in the future by swtching away from DockerHub builds - only use
    # DockerHub to store the images but not to run it to build the images. If we switch to another CI that
    # will let us build images outside of DockerHub and push them there, we will be able to get rid of this.
    # This will probably be necessary as we scale up becasue DockerHub build are very slow and they are
    # already queueing a lot.
    export AUTODETECT_PYTHON_VERSION=${PYTHON_VERSION:=$(${AUTODETECT_PYTHON_BINARY} -c \
     'import sys;print("%s.%s" % (sys.version_info.major, sys.version_info.minor))')}

    # IMAGE_NAME might come from DockerHub and we decide which PYTHON_VERSION to use based on it (see below)
    # In case IMAGE_NAME is not set we determine PYTHON_VERSION based on the default python on the path
    # So in virtualenvs it will use the virtualenv's PYTHON_VERSION and in DockerHub it will determine
    # PYTHHON_VERSION from the IMAGE_NAME set in the DockerHub build.
    # See comment above in PYTHON_VERSION - we will be able to get rid of this cumbersomness when we switch
    # to a different CI system and start pushing images to DockerHub rather than build it there.
    BASE_IMAGE_NAME=${IMAGE_NAME:=${DOCKERHUB_USER}/${DOCKERHUB_REPO}:${AIRFLOW_CONTAINER_BRANCH_NAME}-python${AUTODETECT_PYTHON_VERSION}}

    # Remove index.docker.io/ prefix as it is added by default by DockerHub
    LOCAL_BASE_IMAGE_NAME=${BASE_IMAGE_NAME#index.docker.io/}
    if [[ ! ${LOCAL_BASE_IMAGE_NAME} == ${DOCKERHUB_USER}/${DOCKERHUB_REPO}* ]]; then
        echo >&2
        echo >&2 "ERROR:  The ${LOCAL_BASE_IMAGE_NAME} does not start with ${DOCKERHUB_USER}/${DOCKERHUB_REPO}"
        echo >&2
        exit 1
    fi

    # Extract IMAGE_TAG from LOCAL_BASE_IMAGE_NAME (apache/airflow:master-python3.6 -> master-python3.6)
    IMAGE_TAG=${LOCAL_BASE_IMAGE_NAME##${DOCKERHUB_USER}/${DOCKERHUB_REPO}:}

    # Extract TAG_PREFIX from IMAGE_TAG (master-python3.6 -> master)
    TAG_PREFIX=${IMAGE_TAG%-*}
    export TAG_PREFIX

    # Extract python version from image name we want to build in case it was passed
    # Via IMAGE_NAME. The bash construct below extracts last field after '-' delimiter
    # So for example 'airflow:master-python3.6' will produce AUTODETECT_LONG_PYTHON_VERSION=python3.6
    AUTODETECT_LONG_PYTHON_VERSION="${LOCAL_BASE_IMAGE_NAME##*-}"

    # Verify that Auto-detected python version follows the expected pattern of python3.Y
    if [[ ! ${AUTODETECT_LONG_PYTHON_VERSION} =~ python[3]\.[0-9]+ ]]; then
        echo >&2
        echo >&2 "ERROR:  Python version extracted from IMAGE_NAME does not match the python3.Y format"
        echo >&2
        echo >&2 "The IMAGE_NAME format should be '<BRANCH>-python3.Y'"
        echo >&2
        exit 1
    fi

    # Now set the auto-detected python version based on the auto-detected long version
    export PYTHON_VERSION=${AUTODETECT_LONG_PYTHON_VERSION#python}

    # Disable writing .pyc files - slightly slower imports but not messing around when switching
    # Python version and avoids problems with root-owned .pyc files in host
    export PYTHONDONTWRITEBYTECODE=${PYTHONDONTWRITEBYTECODE:="true"}

    # Check if we are running in the CI environment
    CI=${CI:="false"}

    if [[ "${CI}" == "true" ]]; then
        NON_CI="false"
    else
        NON_CI="true"
    fi
    export CI
    export NON_CI

    # Determine version of the Airflow from version.py
    AIRFLOW_VERSION=$(cat airflow/version.py - << EOF | python
print(version.replace("+",""))
EOF
)
    export AIRFLOW_VERSION

    if [[ -n ${TRAVIS_EVENT_TYPE:=} ]]; then
        echo
        echo "Travis event type: ${TRAVIS_EVENT_TYPE}"
        echo
    fi

    # In case of CRON jobs on Travis we run builds without cache
    if [[ "${TRAVIS_EVENT_TYPE}" == "cron" ]]; then
        echo
        echo "Disabling cache for CRON jobs"
        echo
        AIRFLOW_CONTAINER_USE_CACHE=${AIRFLOW_CONTAINER_USE_CACHE:="false"}
    fi
}
