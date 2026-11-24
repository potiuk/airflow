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

# Wait for a Dag to be parsed, unpause it, trigger a run through the REST API and wait for the result.
# Usage: trigger-dag.sh <run> <dag_id> [conf_json, default {}]
# Prints dag_run_id=... and state=...; exit 0 on success, 2 when the run failed, 1 on any other error.
set -euo pipefail

# shellcheck source=_common.sh
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
load_instance "${1:-}"
DAG_ID="${2:-}"
[[ -n "${DAG_ID}" ]] || die "pass the dag_id"
CONF="${3:-}"
[[ -n "${CONF}" ]] || CONF="{}"
API="http://localhost:${WEB_PORT}/api/v2"

deadline=$((SECONDS + 60))
until [[ "$(curl -s -o /dev/null -w '%{http_code}' "${API}/dags/${DAG_ID}")" == "200" ]]; do
    if [[ ${SECONDS} -ge ${deadline} ]]; then
        echo "${DAG_ID} not parsed after 60s; import errors:" >&2
        curl -s "${API}/importErrors" >&2
        exit 1
    fi
    sleep 5
done

curl -sf -o /dev/null -X PATCH -H 'Content-Type: application/json' \
    "${API}/dags/${DAG_ID}" -d '{"is_paused": false}' || die "could not unpause ${DAG_ID}"
response=$(curl -s -X POST -H 'Content-Type: application/json' \
    "${API}/dags/${DAG_ID}/dagRuns" -d "{\"logical_date\": null, \"conf\": ${CONF}}")
run_id=$(grep -o '"dag_run_id":"[^"]*"' <<<"${response}" | head -n 1 | cut -d'"' -f4 || true)
[[ -n "${run_id}" ]] || die "trigger failed: ${response}"
echo "dag_run_id=${run_id}"

deadline=$((SECONDS + 600))
while [[ ${SECONDS} -lt ${deadline} ]]; do
    state=$(curl -s "${API}/dags/${DAG_ID}/dagRuns/${run_id}" \
        | grep -o '"state":"[^"]*"' | head -n 1 | cut -d'"' -f4 || true)
    case "${state}" in
        success) echo "state=success"; exit 0 ;;
        failed) echo "state=failed"; exit 2 ;;
    esac
    sleep 5
done
die "run ${run_id} still ${state:-unknown} after 600s"
