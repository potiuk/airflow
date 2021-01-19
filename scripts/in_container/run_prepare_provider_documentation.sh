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
# shellcheck source=scripts/in_container/_in_container_script_init.sh
. "$( dirname "${BASH_SOURCE[0]}" )/_in_container_script_init.sh"

function import_all_provider_classes() {
    group_start "Importing all classes"
    python3 "${AIRFLOW_SOURCES}/dev/import_all_classes.py" --path "airflow/providers"
    group_end
}

function verify_provider_packages_named_properly() {
    python3 "${PROVIDER_PACKAGES_DIR}/prepare_provider_packages.py" \
        "${OPTIONAL_BACKPORT_FLAG[@]}" \
        verify-provider-classes
}

function run_prepare_documentation() {
    local prepared_documentation=()
    local skipped_documentation=()
    local error_documentation=()

    local provider_package
    for provider_package in "${PROVIDER_PACKAGES[@]}"
    do
        set +e
        local res
        # There is a separate group created in logs for each provider package
        python3 "${PROVIDER_PACKAGES_DIR}/prepare_provider_packages.py" \
            --version-suffix "${TARGET_VERSION_SUFFIX}" \
            "${OPTIONAL_BACKPORT_FLAG[@]}" \
            "${OPTIONAL_RELEASE_VERSION_ARGUMENT[@]}" \
            update-package-documentation \
            "${provider_package}"
        res=$?
        if [[ ${res} == "64" ]]; then
            skipped_documentation+=("${provider_package}")
            continue
        fi
        if [[ ${res} != "0" ]]; then
            error_documentation+=("${provider_package}")
            continue
        fi
        prepared_documentation+=("${provider_package}")
        set -e
    done
    echo "==================================================================================="
    echo "Summary of prepared documentations:"
    echo
    echo "   Success:"
    echo "${COLOR_GREEN}"
    echo "${prepared_documentation[@]}" | fold -w 100
    echo "${COLOR_RESET}"
    echo "   Skipped:"
    echo "${COLOR_YELLOW}"
    echo "${skipped_documentation[@]}" | fold -w 100
    echo "${COLOR_RESET}"
    echo "   Errors:"
    echo "${COLOR_RED}"
    echo "${error_documentation[@]}" | fold -w 100
    echo "${COLOR_RESET}"
    echo
    echo "==================================================================================="


}


setup_provider_packages

cd "${AIRFLOW_SOURCES}" || exit 1

export PYTHONPATH="${AIRFLOW_SOURCES}"

verify_suffix_versions_for_package_preparation

pip install --upgrade "pip==${AIRFLOW_PIP_VERSION}"

# install extra packages missing in devel_ci
# TODO: remove it when devel_all == devel_ci
install_remaining_dependencies
reinstall_azure_storage_blob
import_all_provider_classes
verify_provider_packages_named_properly

# We will be able to remove it when we get rid of BACKPORT_PACKAGES
OPTIONAL_RELEASE_VERSION_ARGUMENT=()
if [[ $# != "0" && ${1} =~ ^[0-9][0-9][0-9][0-9]\.[0-9][0-9]\.[0-9][0-9]$ ]]; then
    OPTIONAL_RELEASE_VERSION_ARGUMENT+=("--release-version" "${1}")
    shift
fi

PROVIDER_PACKAGES=("${@}")
get_providers_to_act_on "${@}"

run_prepare_documentation
