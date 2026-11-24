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

# Check that the instance of a run publishes its web port and mounts airflow-core of this checkout.
# Usage: check-checkout.sh <run>
# Prints the container name; exit 1 when the port or the mounted sources do not match.
set -euo pipefail

# shellcheck source=_common.sh
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
load_instance "${1:-}"

container=$(docker ps --filter "label=com.docker.compose.project=${PROJECT}" \
    --filter label=com.docker.compose.service=airflow --format '{{.Names}}' | head -n 1)
[[ -n "${container}" ]] || die "no running airflow container in compose project ${PROJECT}"

ports=$(docker inspect "${container}" \
    --format '{{range $p, $b := .NetworkSettings.Ports}}{{range $b}}{{.HostPort}}->{{$p}} {{end}}{{end}}')
[[ " ${ports} " == *" ${WEB_PORT}->8080/tcp "* ]] || die "${container} does not publish ${WEB_PORT}->8080 (has: ${ports})"

source_dir=$(docker inspect "${container}" \
    --format '{{range .Mounts}}{{if eq .Destination "/opt/airflow/airflow-core"}}{{.Source}}{{end}}{{end}}')
# Docker Desktop on macOS reports host paths with a /host_mnt prefix.
source_dir="${source_dir#/host_mnt}"
expected="$(cd "${CHECKOUT}/airflow-core" && pwd -P)"
actual="$(cd "${source_dir}" 2>/dev/null && pwd -P || echo "${source_dir}")"
[[ "${actual}" == "${expected}" ]] || die "${container} mounts ${source_dir}, not ${expected}"

echo "container=${container}"
echo "airflow-core=${expected}"
