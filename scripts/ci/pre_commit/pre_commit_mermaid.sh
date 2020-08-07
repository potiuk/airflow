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
set -eao pipefail
AIRFLOW_SOURCES="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd ../../../ && pwd )"
export NO_TERMINAL_OUTPUT_FROM_SCRIPTS="true"

tmp_file=$(mktemp)

# shellcheck disable=SC2064
trap "rm -rf ${tmp_file}" EXIT

for file in "${@}"
do
    basename_file=${AIRFLOW_SOURCES}/"$(dirname "${file}")/$(basename "${file}" .mermaid)"
    md5sum_file="${basename_file}.md5"
    if ! diff "${md5sum_file}" <(md5sum "${file}"); then
        echo "Running generation for ${file}"
        rm -f "${basename_file}.png"
        rm -f "${basename_file}.md5"
        # unfortunately mermaid does not handle well multiline comments and we need licence comment
        # Stripping them manually :(. Multiline comments are coming in the future
        # https://github.com/mermaid-js/mermaid/issues/1249
        grep -v "^%%" <"${file}" > "${tmp_file}"
        "${NODE_VIRTUAL_ENV}/bin/mmdc" \
            -i "${tmp_file}" \
            -w 2048 \
            -o "${basename_file}.png" \
            -c "${AIRFLOW_SOURCES}/scripts/ci/mermaid-config.json"
        if [ -f "${basename_file}.png" ]; then
            md5sum "${file}" >"${md5sum_file}"
            echo
            echo "Successfully generated: ${basename_file}.png"
            echo "Successfully updated: ${basename_file}.md5"
            echo
            echo "Please add both files and commit them to repository"
            echo
        else
            1>&2 echo
            1>&2 echo "ERROR: Could not generate ${basename_file}.png"
            1>&2 echo
            exit 1
        fi
    fi
done
