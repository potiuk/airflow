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

# Assume all the scripts are sourcing the file from the scripts/ci directory
# and MY_DIR variable is set to this directory. It can be overridden however
#
# Sets file name for last forced answer. This is where last forced answer is stored. It is usually
# removed by "cleanup_last_force_answer" method just before question is asked. The only exceptions
# are pre-commit checks which (except the first - build - step) do not remove the last forced
# answer so that the first answer is used for all builds within this pre-commit run.
#
function _set_last_force_answer_file() {
    LAST_FORCE_ANSWER_FILE="${BUILD_CACHE_DIR}/last_force_answer.sh"
    export LAST_FORCE_ANSWER_FILE
}

# Removes the "Force answer" (yes/no/quit) given previously
#
# This is the default behaviour of all rebuild scripts to ask independently whether you want to
# rebuild the image or not. Sometimes however we want to reuse answer previously given. For
# example if you answered "no" to rebuild the image, the assumption is that you do not
# want to rebuild image for other rebuilds in the same pre-commit execution.
#
# All the pre-commit checks therefore have `export SKIP_CLEANUP_OF_LAST_ANSWER="true"` set
# So that in case they are run in a sequence of commits they will not rebuild. Similarly if your most
# recent answer was "no" and you run `pre-commit run mypy` (for example) it will also reuse the
# "no" answer given previously. This happens until you run any of the breeze commands or run all
# precommits `pre-commit run` - then the "LAST_FORCE_ANSWER_FILE" will be removed and you will
# be asked again.
function cleanup_last_force_answer() {
    if [[ ${SKIP_CLEANUP_OF_LAST_ANSWER:=""} != "true" ]]; then
        print_info
        print_info "Removing last answer from ${LAST_FORCE_ANSWER_FILE}"
        print_info
        rm -f "${LAST_FORCE_ANSWER_FILE}"
    else
        if [[ -f "${LAST_FORCE_ANSWER_FILE}" ]]; then
            print_info
            print_info "Retaining last answer from ${LAST_FORCE_ANSWER_FILE}"
            print_info "$(cat "${LAST_FORCE_ANSWER_FILE}")"
            print_info
        fi
    fi
}

#
# Sets mounting of host volumes to container for static checks
# unless AIRFLOW_MOUNT_HOST_VOLUMES_FOR_STATIC_CHECKS is not true
#
# Output: AIRFLOW_CONTAINER_EXTRA_DOCKER_FLAGS
function _set_extra_container_docker_flags() {
    AIRFLOW_MOUNT_HOST_VOLUMES_FOR_STATIC_CHECKS=${AIRFLOW_MOUNT_HOST_VOLUMES_FOR_STATIC_CHECKS:="true"}
    export AIRFLOW_MOUNT_HOST_VOLUMES_FOR_STATIC_CHECKS

    if [[ ${AIRFLOW_MOUNT_HOST_VOLUMES_FOR_STATIC_CHECKS} == "true" ]]; then
        print_info
        print_info "Mounting host volumes to Docker"
        print_info
        AIRFLOW_CONTAINER_EXTRA_DOCKER_FLAGS=( \
          "-v" "${AIRFLOW_SOURCES}/airflow:/opt/airflow/airflow:cached" \
          "-v" "${AIRFLOW_SOURCES}/.mypy_cache:/opt/airflow/.mypy_cache:cached" \
          "-v" "${AIRFLOW_SOURCES}/dev:/opt/airflow/dev:cached" \
          "-v" "${AIRFLOW_SOURCES}/docs:/opt/airflow/docs:cached" \
          "-v" "${AIRFLOW_SOURCES}/scripts:/opt/airflow/scripts:cached" \
          "-v" "${AIRFLOW_SOURCES}/.bash_history:/root/.bash_history:cached" \
          "-v" "${AIRFLOW_SOURCES}/.bash_aliases:/root/.bash_aliases:cached" \
          "-v" "${AIRFLOW_SOURCES}/.inputrc:/root/.inputrc:cached" \
          "-v" "${AIRFLOW_SOURCES}/.bash_completion.d:/root/.bash_completion.d:cached" \
          "-v" "${AIRFLOW_SOURCES}/tmp:/opt/airflow/tmp:cached" \
          "-v" "${AIRFLOW_SOURCES}/tests:/opt/airflow/tests:cached" \
          "-v" "${AIRFLOW_SOURCES}/.flake8:/opt/airflow/.flake8:cached" \
          "-v" "${AIRFLOW_SOURCES}/pylintrc:/opt/airflow/pylintrc:cached" \
          "-v" "${AIRFLOW_SOURCES}/setup.cfg:/opt/airflow/setup.cfg:cached" \
          "-v" "${AIRFLOW_SOURCES}/setup.py:/opt/airflow/setup.py:cached" \
          "-v" "${AIRFLOW_SOURCES}/.rat-excludes:/opt/airflow/.rat-excludes:cached" \
          "-v" "${AIRFLOW_SOURCES}/logs:/opt/airflow/logs:cached" \
          "-v" "${AIRFLOW_SOURCES}/logs:/root/logs:cached" \
          "-v" "${AIRFLOW_SOURCES}/files:/files:cached" \
          "-v" "${AIRFLOW_SOURCES}/tmp:/opt/airflow/tmp:cached" \
          "--env" "PYTHONDONTWRITEBYTECODE" \
        )
    else
        print_info
        print_info "Skip mounting host volumes to Docker"
        print_info
        AIRFLOW_CONTAINER_EXTRA_DOCKER_FLAGS=( \
            "--env" "PYTHONDONTWRITEBYTECODE" \
        )
    fi
    export AIRFLOW_CONTAINER_EXTRA_DOCKER_FLAGS
}

#
# Verifies if stored md5sum of the file changed since the last tme ot was checked
# The md5sum files are stored in .build directory - you can delete this directory
# If you want to rebuild everything from the scratch
# Returns 0 if md5sum is OK
function _check_file_md5sum {
    local FILE="${1}"
    local MD5SUM
    local MD5SUM_CACHE_DIR="${BUILD_CACHE_DIR}/${DEFAULT_BRANCH}/${THE_IMAGE_TYPE}"
    mkdir -pv "${MD5SUM_CACHE_DIR}"
    MD5SUM=$(md5sum "${FILE}")
    local MD5SUM_FILE
    MD5SUM_FILE="${MD5SUM_CACHE_DIR}"/$(basename "${FILE}").md5sum
    local MD5SUM_FILE_NEW
    MD5SUM_FILE_NEW=${CACHE_TMP_FILE_DIR}/$(basename "${FILE}").md5sum.new
    echo "${MD5SUM}" > "${MD5SUM_FILE_NEW}"
    local RET_CODE=0
    if [[ ! -f "${MD5SUM_FILE}" ]]; then
        print_info "Missing md5sum for ${FILE#${AIRFLOW_SOURCES}} (${MD5SUM_FILE#${AIRFLOW_SOURCES}})"
        RET_CODE=1
    else
        diff "${MD5SUM_FILE_NEW}" "${MD5SUM_FILE}" >/dev/null
        RES=$?
        if [[ "${RES}" != "0" ]]; then
            print_info "The md5sum changed for ${FILE}"
            RET_CODE=1
        fi
    fi
    return ${RET_CODE}
}

#
# Moves md5sum file from it's temporary location in CACHE_TMP_FILE_DIR to
# BUILD_CACHE_DIR - thus updating stored MD5 sum fo the file
#
function _move_file_md5sum {
    local FILE="${1}"
    local MD5SUM_FILE
    local MD5SUM_CACHE_DIR="${BUILD_CACHE_DIR}/${DEFAULT_BRANCH}/${THE_IMAGE_TYPE}"
    mkdir -pv "${MD5SUM_CACHE_DIR}"
    MD5SUM_FILE="${MD5SUM_CACHE_DIR}"/$(basename "${FILE}").md5sum
    local MD5SUM_FILE_NEW
    MD5SUM_FILE_NEW=${CACHE_TMP_FILE_DIR}/$(basename "${FILE}").md5sum.new
    if [[ -f "${MD5SUM_FILE_NEW}" ]]; then
        mv "${MD5SUM_FILE_NEW}" "${MD5SUM_FILE}"
        print_info "Updated md5sum file ${MD5SUM_FILE} for ${FILE}."
    fi
}

#
# Stores md5sum files for all important files and
# records that we built the images locally so that next time we use
# it from the local docker cache rather than pull (unless forced)
#
function _update_all_md5_files() {
    print_info
    print_info "Updating md5sum files"
    print_info
    local FILE
    for FILE in "${FILES_FOR_REBUILD_CHECK[@]}"
    do
        _move_file_md5sum "${AIRFLOW_SOURCES}/${FILE}"
    done
    local SUFFIX=""
    if [[ -n ${PYTHON_VERSION:=""} ]]; then
        SUFFIX="_${PYTHON_VERSION}"
    fi
    mkdir -pv "${BUILD_CACHE_DIR}/${DEFAULT_BRANCH}"
    touch "${BUILD_CACHE_DIR}/${DEFAULT_BRANCH}/.built_${THE_IMAGE_TYPE}${SUFFIX}"
}

#
# Checks md5sum of all important files in order to optimise speed of running various operations
# That mount sources of Airflow to container and require docker image built with latest dependencies.
# the Docker image will only be marked for rebuilding only in case any of the important files change:
#
# This is needed because we want to skip rebuilding of the image when only airflow sources change but
# Trigger rebuild in case we need to change dependencies (setup.py, setup.cfg, change version of Airflow
# or the Dockerfile itself changes.
#
# Another reason to skip rebuilding Docker is thar currently it takes a bit longer time than simple Docker
# files. There are the following, problems with the current Dockerfiles that need longer build times:
# 1) We need to fix group permissions of files in Docker because different linux build services have
#    different default umask and Docker uses group permissions in checking for cache invalidation.
# 2) we use multi-stage build and in case of slim image we needlessly build a full CI image because
#    support for this only comes with the upcoming buildkit: https://github.com/docker/cli/issues/1134
#
# As result of this check - most of the static checks will start pretty much immediately.
#
# Output:  AIRFLOW_CONTAINER_DOCKER_BUILD_NEEDED
#
function _check_if_docker_build_is_needed() {
    print_info "Checking if build is needed for ${THE_IMAGE_TYPE} image python version: ${PYTHON_VERSION}"
    local IMAGE_BUILD_NEEDED="false"
    local FILE
    if [[ ${AIRFLOW_CONTAINER_FORCE_DOCKER_BUILD:=""} == "true" ]]; then
        print_info "Docker image build is forced for ${THE_IMAGE_TYPE} image"
        set +e
        for FILE in "${FILES_FOR_REBUILD_CHECK[@]}"
        do
            # Just store md5sum for all files in md5sum.new - do not check if it is different
            _check_file_md5sum "${AIRFLOW_SOURCES}/${FILE}"
        done
        set -e
        IMAGES_TO_REBUILD+=("${THE_IMAGE_TYPE}")
        export AIRFLOW_CONTAINER_DOCKER_BUILD_NEEDED="true"
    else
        set +e
        for FILE in "${FILES_FOR_REBUILD_CHECK[@]}"
        do
            if ! _check_file_md5sum "${AIRFLOW_SOURCES}/${FILE}"; then
                export AIRFLOW_CONTAINER_DOCKER_BUILD_NEEDED="true"
                IMAGE_BUILD_NEEDED=true
            fi
        done
        set -e
        if [[ ${IMAGE_BUILD_NEEDED} == "true" ]]; then
            IMAGES_TO_REBUILD+=("${THE_IMAGE_TYPE}")
            export AIRFLOW_CONTAINER_DOCKER_BUILD_NEEDED="true"
            print_info "Docker image build is needed for ${THE_IMAGE_TYPE} image!"
        else
            print_info "Docker image build is not needed for ${THE_IMAGE_TYPE} image!"
        fi
    fi
    print_info
}

#
# Confirms that the image should be rebuilt
# Input LAST_FORCE_ANSWER_FILE - file containing FORCE_ANSWER_TO_QUESTIONS variable set
# Output: FORCE_ANSWER_TO_QUESTIONS (yes/no)
#         LAST_FORCE_ANSWER_FILE contains `export FORCE_ANSWER_TO_QUESTIONS=yes/no`
# Exits when q is selected.
function _confirm_image_rebuild() {
    if [[ -f "${LAST_FORCE_ANSWER_FILE}" ]]; then
        # set variable from last answered response given in the same pre-commit run - so that it can be
        # set in one pre-commit check (build) and then used in another (pylint/mypy/flake8 etc).
        # shellcheck disable=SC1090
        source "${LAST_FORCE_ANSWER_FILE}"
    fi
    set +e
    local RES
    if [[ ${CI:="false"} == "true" ]]; then
        print_info
        print_info "CI environment - forcing rebuild for image ${THE_IMAGE_TYPE}."
        print_info
        RES="0"
    elif [[ -n "${FORCE_ANSWER_TO_QUESTIONS:=""}" ]]; then
        print_info
        print_info "Forcing answer '${FORCE_ANSWER_TO_QUESTIONS}'"
        print_info
        case "${FORCE_ANSWER_TO_QUESTIONS}" in
            [yY][eE][sS]|[yY])
                RES="0" ;;
            [qQ][uU][iI][tT]|[qQ])
                RES="2" ;;
            *)
                RES="1" ;;
        esac
    elif [[ -t 0 ]]; then
        # Check if this script is run interactively with stdin open and terminal attached
        "${AIRFLOW_SOURCES}/confirm" "Rebuild image ${THE_IMAGE_TYPE} (might take some time)"
        RES=$?
    elif [[ ${DETECTED_TERMINAL:=$(tty)} != "not a tty" ]]; then
        # Make sure to use output of tty rather than stdin/stdout when available - this way confirm
        # will works also in case of pre-commits (git does not pass stdin/stdout to pre-commit hooks)
        # shellcheck disable=SC2094
        "${AIRFLOW_SOURCES}/confirm" "Rebuild image ${THE_IMAGE_TYPE} (might take some time)" \
            <"${DETECTED_TERMINAL}" >"${DETECTED_TERMINAL}"
        RES=$?
        export DETECTED_TERMINAL
    elif [[ -c /dev/tty ]]; then
        export DETECTED_TERMINAL=/dev/tty
        # Make sure to use /dev/tty first rather than stdin/stdout when available - this way confirm
        # will works also in case of pre-commits (git does not pass stdin/stdout to pre-commit hooks)
        # shellcheck disable=SC2094
        "${AIRFLOW_SOURCES}/confirm" "Rebuild image ${THE_IMAGE_TYPE} (might take some time)" \
            <"${DETECTED_TERMINAL}" >"${DETECTED_TERMINAL}"
        RES=$?
    else
        print_info
        print_info "No terminal, no stdin - quitting"
        print_info
        # No terminal, no stdin, no force answer - quitting!
        RES="2"
    fi
    set -e
    if [[ ${RES} == "1" ]]; then
        print_info
        print_info "Skipping rebuild for image ${THE_IMAGE_TYPE}"
        print_info
        SKIP_REBUILD="true"
        # Force "no" also to subsequent questions so that if you answer it once, you are not asked
        # For all other pre-commits and you will continue using the images you already have
        export FORCE_ANSWER_TO_QUESTIONS="no"
        echo 'export FORCE_ANSWER_TO_QUESTIONS="no"' > "${LAST_FORCE_ANSWER_FILE}"
    elif [[ ${RES} == "2" ]]; then
        echo >&2
        echo >&2 "ERROR: The ${THE_IMAGE_TYPE} needs to be rebuilt - it is outdated. "
        echo >&2 "   Make sure you build the images bu running run one of:"
        echo >&2 "         * ./scripts/ci/local_ci_build*.sh"
        echo >&2 "         * ./scripts/ci/local_ci_pull_and_build*.sh"
        echo >&2
        echo >&2 "   If you run it via pre-commit separately, run 'pre-commit run build' first."
        echo >&2
        exit 1
    else
        # Force "yes" also to subsequent questions
        export FORCE_ANSWER_TO_QUESTIONS="yes"
    fi
}

function _pull_image_if_needed() {
    # Whether to force pull images to populate cache
    export AIRFLOW_CONTAINER_FORCE_PULL_IMAGES=${AIRFLOW_CONTAINER_FORCE_PULL_IMAGES:="false"}
    # In CI environment we skip pulling latest python image
    export AIRFLOW_CONTAINER_PULL_BASE_IMAGES=${AIRFLOW_CONTAINER_PULL_BASE_IMAGES:=${NON_CI}}

    if [[ "${AIRFLOW_CONTAINER_USE_CACHE}" == "true" ]]; then
        if [[ "${AIRFLOW_CONTAINER_FORCE_PULL_IMAGES}" == "true" ]]; then
            if [[ ${AIRFLOW_CONTAINER_PULL_BASE_IMAGES} == "false" ]]; then
                echo
                echo "Skip force-pulling the ${PYTHON_BASE_IMAGE} image."
                echo
            else
                echo
                echo "Force pull base image ${PYTHON_BASE_IMAGE}"
                echo
                verbose_docker pull "${PYTHON_BASE_IMAGE}"
                echo
            fi
        fi
        for IMAGE in ${AIRFLOW_WWW_IMAGE} ${AIRFLOW_BASE_IMAGE} ${AIRFLOW_IMAGE}
        do
            local PULL_IMAGE=${AIRFLOW_CONTAINER_FORCE_PULL_IMAGES}
            local IMAGE_HASH
            IMAGE_HASH=$(docker images -q "${IMAGE}" 2> /dev/null)
            if [[ "${IMAGE_HASH}" == "" ]]; then
                PULL_IMAGE="true"
            fi
            if [[ "${PULL_IMAGE}" == "true" ]]; then
                echo
                echo "Pulling the image ${IMAGE}"
                echo
                verbose_docker pull "${IMAGE}" || true
                echo
            fi
        done
    fi
}

#
# Builds the image
#
function _build_image() {
    _print_build_info
    echo
    echo Building image "${IMAGE_DESCRIPTION}"
    echo
    _pull_image_if_needed

    if [[ "${AIRFLOW_CONTAINER_USE_LOCAL_DOCKER_CACHE}" == "true" ]]; then
        DOCKER_CACHE_DIRECTIVE=()
    elif [[ "${AIRFLOW_CONTAINER_USE_CACHE}" == "false" ]]; then
        DOCKER_CACHE_DIRECTIVE=("--no-cache")
    else
        DOCKER_CACHE_DIRECTIVE=(
            "--cache-from" "${AIRFLOW_BASE_IMAGE}"
            "--cache-from" "${AIRFLOW_WWW_IMAGE}"
            "--cache-from" "${AIRFLOW_IMAGE}"
        )
    fi
    export DOCKER_CACHE_DIRECTIVE
    VERBOSE=${VERBOSE:="false"}

    if [[ -n ${DETECTED_TERMINAL:=""} ]]; then
        echo -n "Building ${THE_IMAGE_TYPE}.
        " > "${DETECTED_TERMINAL}"
        spin "${OUTPUT_LOG}" &
        SPIN_PID=$!
        # shellcheck disable=SC2064
        trap "kill ${SPIN_PID}" SIGINT SIGTERM
    fi
    if [[ ${THE_IMAGE_TYPE} == "CHECKLICENCE" ]]; then
        verbose_docker build . -f Dockerfile-checklicence \
            "${DOCKER_CACHE_DIRECTIVE[@]}" -t "${AIRFLOW_IMAGE}" | tee -a "${OUTPUT_LOG}"
    else
        verbose_docker build \
            --build-arg PYTHON_BASE_IMAGE="${PYTHON_BASE_IMAGE}" \
            --build-arg AIRFLOW_VERSION="${AIRFLOW_VERSION}" \
            --build-arg AIRFLOW_BRANCH="${AIRFLOW_CONTAINER_BRANCH_NAME}" \
            "${DOCKER_CACHE_DIRECTIVE[@]}" \
            -t "${AIRFLOW_WWW_IMAGE}" \
            --target "airflow-www" \
            . | tee -a "${OUTPUT_LOG}"
        verbose_docker build \
            --build-arg PYTHON_BASE_IMAGE="${PYTHON_BASE_IMAGE}" \
            --build-arg AIRFLOW_VERSION="${AIRFLOW_VERSION}" \
            --build-arg AIRFLOW_BRANCH="${AIRFLOW_CONTAINER_BRANCH_NAME}" \
            "${DOCKER_CACHE_DIRECTIVE[@]}" \
            -t "${AIRFLOW_BASE_IMAGE}" \
            --target "airflow-base" \
            . | tee -a "${OUTPUT_LOG}"
        verbose_docker build \
            --build-arg PYTHON_BASE_IMAGE="${PYTHON_BASE_IMAGE}" \
            --build-arg AIRFLOW_VERSION="${AIRFLOW_VERSION}" \
            --build-arg AIRFLOW_BRANCH="${AIRFLOW_CONTAINER_BRANCH_NAME}" \
            "${DOCKER_CACHE_DIRECTIVE[@]}" \
            -t "${AIRFLOW_IMAGE}" \
            --target "${TARGET_IMAGE}" \
            . | tee -a "${OUTPUT_LOG}"
        if [[ "${PYTHON_VERSION_FOR_DEFAULT_IMAGE}" == "${PYTHON_VERSION}" ]]; then
            verbose_docker tag "${AIRFLOW_IMAGE}" "${AIRFLOW_IMAGE_DEFAULT}" | tee -a "${OUTPUT_LOG}"
        fi
    fi
    if [[ -n ${SPIN_PID:=""} ]]; then
        kill "${SPIN_PID}" || true
        wait "${SPIN_PID}" || true
        echo > "${DETECTED_TERMINAL}"
    fi
}

function remove_all_images() {
    echo
    "${AIRFLOW_SOURCES}/confirm" "Removing all local images ."
    echo
    start_step "Removing images"
    verbose_docker rmi "${PYTHON_BASE_IMAGE}" || true
    verbose_docker rmi "${CHECKLICENCE_BASE_IMAGE}" || true
    verbose_docker rmi "${AIRFLOW_PROD_IMAGE}" || true
    verbose_docker rmi "${AIRFLOW_CI_IMAGE}" || true
    verbose_docker rmi "${AIRFLOW_CHECKLICENCE_IMAGE}" || true
    echo
    echo "###################################################################"
    echo "NOTE!! Removed Airflow images for Python version ${PYTHON_VERSION}."
    echo "       But the disk space in docker will be reclaimed only after"
    echo "       running 'docker system prune' command."
    echo "###################################################################"
    echo
    end_step
}

#
# Rebuilds an image if needed
#
function _rebuild_image_if_needed() {
    set_image_variables

    if [[ -f "${BUILD_CACHE_DIR}/${DEFAULT_BRANCH}/.built_${THE_IMAGE_TYPE}_${PYTHON_VERSION}" ]]; then
        print_info
        print_info "${THE_IMAGE_TYPE} image already built locally."
        print_info
    else
        print_info
        print_info "${THE_IMAGE_TYPE} image not built locally: pulling and building"
        print_info
        export AIRFLOW_CONTAINER_FORCE_PULL_IMAGES="true"
        export AIRFLOW_CONTAINER_FORCE_DOCKER_BUILD="true"
    fi

    AIRFLOW_CONTAINER_DOCKER_BUILD_NEEDED="false"
    IMAGES_TO_REBUILD=()
    _check_if_docker_build_is_needed
    if [[ "${AIRFLOW_CONTAINER_DOCKER_BUILD_NEEDED}" == "true" ]]; then
        SKIP_REBUILD="false"
        if [[ ${CI:=} != "true" && "${FORCE_BUILD:=}" != "true" ]]; then
            _confirm_image_rebuild
        fi
        if [[ ${SKIP_REBUILD} != "true" ]]; then
            _fix_group_permissions
            print_info
            print_info "Rebuilding started: ${THE_IMAGE_TYPE} image."
            print_info
            _build_image
            _update_all_md5_files
            print_info
            print_info "Rebuilding completed: ${THE_IMAGE_TYPE} image."
            print_info
        fi
    else
        print_info
        print_info "No need to rebuild - none of the important files changed: ${FILES_FOR_REBUILD_CHECK[*]}"
        print_info
    fi
}


_cleanup_image() {
    set_image_variables
    verbose_docker rmi "${AIRFLOW_IMAGE}" || true | tee -a "${OUTPUT_LOG}"
}

_push_image() {
    set_image_variables
    if [[ -n ${AIRFLOW_WWW_IMAGE:=""} ]]; then
        verbose_docker push "${AIRFLOW_WWW_IMAGE}" | tee -a "${OUTPUT_LOG}"
    fi
    if [[ -n ${AIRFLOW_BASE_IMAGE:=""} ]]; then
        verbose_docker push "${AIRFLOW_BASE_IMAGE}" | tee -a "${OUTPUT_LOG}"
    fi
    verbose_docker push "${AIRFLOW_IMAGE}" | tee -a "${OUTPUT_LOG}"
    if [[ -n ${DEFAULT_IMAGE:=""} ]]; then
        verbose_docker push "${DEFAULT_IMAGE}" | tee -a "${OUTPUT_LOG}"
    fi
}

function rebuild_checklicence_image_if_needed() {
    export THE_IMAGE_TYPE="CHECKLICENCE"
    export IMAGE_DESCRIPTION="Airflow Checklicence"
    _rebuild_image_if_needed
}

function cleanup_checklicence_image() {
    export THE_IMAGE_TYPE="CHECKLICENCE"
    _cleanup_image
}

function push_checklicence_image() {
    export THE_IMAGE_TYPE="CHECKLICENCE"
    _push_image
}

function rebuild_ci_image_if_needed() {
    export THE_IMAGE_TYPE="CI"
    export IMAGE_DESCRIPTION="Airflow CI"
    export TARGET_IMAGE="airflow-ci"
    _rebuild_image_if_needed
}

function cleanup_ci_image() {
    export THE_IMAGE_TYPE="CI"
    _cleanup_image
}

function push_ci_image() {
    export THE_IMAGE_TYPE="CI"
    _push_image
}

function rebuild_prod_image_if_needed() {
    export THE_IMAGE_TYPE="PROD"
    export IMAGE_DESCRIPTION="Airflow PROD"
    export TARGET_IMAGE="airflow-prod"
    _rebuild_image_if_needed
}

function cleanup_prod_image() {
    export THE_IMAGE_TYPE="PROD"
    _cleanup_image
}

function push_prod_image() {
    export THE_IMAGE_TYPE="PROD"
    _push_image
}

function _go_to_airflow_sources {
    print_info
    pushd "${AIRFLOW_SOURCES}" &>/dev/null || exit 1
    print_info
    print_info "Running in host in $(pwd)"
    print_info
}

function rebuild_all_images_if_needed_and_confirmed() {
    AIRFLOW_CONTAINER_DOCKER_BUILD_NEEDED="false"
    IMAGES_TO_REBUILD=()
    for THE_IMAGE_TYPE in "${LOCALLY_BUILT_IMAGES[@]}"
    do
        _check_if_docker_build_is_needed
    done

    if [[ ${AIRFLOW_CONTAINER_DOCKER_BUILD_NEEDED} == "true" ]]; then
        print_info
        print_info "Docker image build is needed for ${IMAGES_TO_REBUILD[*]}!"
        print_info
    else
        print_info
        print_info "Docker image build is not needed for any of the image types!"
        print_info
    fi

    if [[ "${AIRFLOW_CONTAINER_DOCKER_BUILD_NEEDED}" == "true" ]]; then
        echo
        echo "Some of your images need to be rebuild because important files (like package list) has changed."
        echo
        echo "You have those options:"
        echo "   * Rebuild the images now by answering 'y' (this might take some time!)"
        echo "   * Skip rebuilding the images and hope changes are not big (you will be asked again)"
        echo "   * Quit and manually rebuild the images using"
        echo "        * scripts/local_ci_build.sh or"
        echo "        * scripts/local_ci_pull_and_build.sh or"
        echo
        export ACTION="rebuild"
        export THE_IMAGE_TYPE="${IMAGES_TO_REBUILD[*]}"

        SKIP_REBUILD="false"
        _confirm_image_rebuild

        if [[ ${SKIP_REBUILD} != "true" ]]; then
            rebuild_ci_image_if_needed
            rebuild_ci_image_if_needed
            rebuild_checklicence_image_if_needed
        fi
    fi
}

function build_image_on_ci() {
    if [[ "${CI:=}" != "true" ]]; then
        print_info
        print_info "Cleaning up docker installation!!!!!!"
        print_info
        "${AIRFLOW_SOURCES}/confirm" "Cleaning docker data and rebuilding"
    fi

    export AIRFLOW_CONTAINER_FORCE_PULL_IMAGES="true"
    export FORCE_BUILD="true"
    export VERBOSE="${VERBOSE:="false"}"

    # Cleanup docker installation. It should be empty in CI but let's not risk
    verbose_docker system prune --all --force | tee -a "${OUTPUT_LOG}"
    rm -rf "${BUILD_CACHE_DIR}"

    if  [[ ${TRAVIS_JOB_NAME} == "Check lic"* ]]; then
        rebuild_checklicence_image_if_needed
    else
        rebuild_ci_image_if_needed
    fi

    # Disable force pulling forced above
    unset AIRFLOW_CONTAINER_FORCE_PULL_IMAGES
    unset FORCE_BUILD
}

function _print_build_info() {
    print_info
    print_info "Airflow ${AIRFLOW_VERSION} Python: ${PYTHON_VERSION}."
    print_info
}

# Clears the status of fixing permissions so that this is done only once per script execution
function _clear_fix_group_permissions() {
    unset PERMISSIONS_FIXED
}
#
# Fixing permissions for all important files that are going to be added to Docker context
# This is necessary, because there are different default umask settings on different *NIX
# In case of some systems (especially in the CI environments) there is default +w group permission
# set automatically via UMASK when git checkout is performed.
#    https://unix.stackexchange.com/questions/315121/why-is-the-default-umask-002-or-022-in-many-unix-systems-seems-insecure-by-defa
# Unfortunately default setting in git is to use UMASK by default:
#    https://git-scm.com/docs/git-config/1.6.3.1#git-config-coresharedRepository
# This messes around with Docker context invalidation because the same files have different permissions
# and effectively different hash used for context validation calculation.
#
# We fix it by removing write permissions for other/group for important files that are checked during
# building docker images
#
function _fix_group_permissions() {
    if [[ ${PERMISSIONS_FIXED:=} == "true" ]]; then
        echo
        echo "Permissions already fixed"
        echo
        return
    fi
    echo
    echo "Fixing group permissions"
    STAT_BIN=stat
    if [[ "${OSTYPE}" == "darwin"* ]]; then
        STAT_BIN=gstat
    fi
    # Get all files in the context - by building a small alpine based image
    # then COPY all files (.) from the context and listing the files via find method
    ALL_FILES_TO_FIX="$(cd "${AIRFLOW_SOURCES}"; git ls-files)"
    for FILE in ${ALL_FILES_TO_FIX}; do
        ACCESS_RIGHTS=$("${STAT_BIN}" -c "%A" "${AIRFLOW_SOURCES}/${FILE}" || echo "--------")
        # check if the file is group/other writeable
        if [[ "${ACCESS_RIGHTS:5:1}" != "-" || "${ACCESS_RIGHTS:8:1}" != "-" ]]; then
            if [[ "${VERBOSE_FIX_FILE:="false"}" == "true" ]]; then
                "${STAT_BIN}" --printf "%a %A %F \t%s \t->    " "${AIRFLOW_SOURCES}/${FILE}"
            fi
            chmod og-w "${AIRFLOW_SOURCES}/${FILE}"
            if [[ "${VERBOSE_FIX_FILE:="false"}" == "true" ]]; then
                "${STAT_BIN}" --printf "%a %A %F \t%s \t%n\n" "${AIRFLOW_SOURCES}/${FILE}"
            fi
        fi
    done
    echo "Fixed group permissions for ${#FILES_FOR_REBUILD_CHECK[@]} files"
    echo
    export PERMISSIONS_FIXED="true"
}

function set_image_variables() {
    export PYTHON_BASE_IMAGE="python:${PYTHON_VERSION}-slim-buster"

    export AIRFLOW_BASE_IMAGE="${DOCKERHUB_USER}/${DOCKERHUB_REPO}:${TAG_PREFIX}-python${PYTHON_VERSION}-base"

    export AIRFLOW_CI_IMAGE="${DOCKERHUB_USER}/${DOCKERHUB_REPO}:${TAG_PREFIX}-python${PYTHON_VERSION}-ci"
    export AIRFLOW_CI_IMAGE_DEFAULT="${DOCKERHUB_USER}/${DOCKERHUB_REPO}:${TAG_PREFIX}-ci"

    export AIRFLOW_PROD_IMAGE="${DOCKERHUB_USER}/${DOCKERHUB_REPO}:${TAG_PREFIX}-python${PYTHON_VERSION}"
    export AIRFLOW_PROD_IMAGE_DEFAULT="${DOCKERHUB_USER}/${DOCKERHUB_REPO}:${TAG_PREFIX}"

    export AIRFLOW_CHECKLICENCE_IMAGE="${DOCKERHUB_USER}/${DOCKERHUB_REPO}:checklicence"

    if [[ ${THE_IMAGE_TYPE} == "CI" ]]; then
        export AIRFLOW_BASE_IMAGE="${AIRFLOW_BASE_IMAGE}"
        export AIRFLOW_IMAGE="${AIRFLOW_CI_IMAGE}"
        export AIRFLOW_IMAGE_DEFAULT="${AIRFLOW_CI_IMAGE_DEFAULT}"
        export AIRFLOW_WWW_IMAGE="${DOCKERHUB_USER}/${DOCKERHUB_REPO}:${TAG_PREFIX}-www"
    elif [[ ${THE_IMAGE_TYPE} == "PROD" ]]; then
        export AIRFLOW_BASE_IMAGE="${AIRFLOW_BASE_IMAGE}"
        export AIRFLOW_IMAGE="${AIRFLOW_PROD_IMAGE}"
        export AIRFLOW_IMAGE_DEFAULT="${AIRFLOW_PROD_IMAGE_DEFAULT}"
        export AIRFLOW_WWW_IMAGE="${DOCKERHUB_USER}/${DOCKERHUB_REPO}:${TAG_PREFIX}-www"
    elif [[ ${THE_IMAGE_TYPE} == "CHECKLICENCE" ]]; then
        export AIRFLOW_BASE_IMAGE=""
        export AIRFLOW_IMAGE="${AIRFLOW_CHECKLICENCE_IMAGE}"
        export AIRFLOW_IMAGE_DEFAULT=""
        export AIRFLOW_WWW_IMAGE=""
    fi
}


#
# Performs basic sanity checks common for most of the scripts in this directory
#
function prepare_build() {
    _set_last_force_answer_file
    cleanup_last_force_answer
    _go_to_airflow_sources
    _set_extra_container_docker_flags
    _clear_fix_group_permissions
}
