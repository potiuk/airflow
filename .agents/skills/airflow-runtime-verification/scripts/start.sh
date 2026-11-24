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

# Start an isolated "airflow standalone" for one verification run and keep it in the foreground.
# Usage: start.sh <run> [--backend postgres|mysql|sqlite] [--python <version>]
# Run it as a background command; it ends when stop.sh removes the instance (exit code 143).
set -euo pipefail

# shellcheck source=_common.sh
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

RUN="${1:-}"
require_run "${RUN}"
shift
BACKEND="postgres"
PYTHON="3.11"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --backend) BACKEND="$2"; shift 2 ;;
        --python) PYTHON="$2"; shift 2 ;;
        *) die "unknown option $1" ;;
    esac
done
case "${BACKEND}" in
    postgres) DB_PORT_VAR="POSTGRES_HOST_PORT" ;;
    mysql) DB_PORT_VAR="MYSQL_HOST_PORT" ;;
    sqlite) DB_PORT_VAR="" ;;
    *) die "backend must be postgres, mysql or sqlite" ;;
esac

CHECKOUT="$(git rev-parse --show-toplevel)" || die "run this from inside the checkout under test"
RUN_DIR="${CHECKOUT}/files/verify/${RUN}"
[[ -e "${RUN_DIR}" ]] && die "${RUN_DIR} exists: use a new run name for every start"
mkdir -p "${RUN_DIR}"

# A port is taken when something on the host accepts a connection on it. Ports handed out by
# other runs that are still starting are skipped through their instance.env files.
is_free() {
    local port="$1"
    if grep -qs "=${port}\$" "${CHECKOUT}"/files/verify/*/instance.env; then
        return 1
    fi
    ! (exec 3<>"/dev/tcp/127.0.0.1/${port}") 2>/dev/null
}

PORTS=()
candidate=31000
while [[ ${#PORTS[@]} -lt 4 ]]; do
    [[ ${candidate} -le 32000 ]] || die "no four free ports between 31000 and 32000"
    if is_free "${candidate}"; then
        PORTS+=("${candidate}")
    fi
    candidate=$((candidate + 1))
done

cat > "${RUN_DIR}/instance.env" <<ENV
RUN=${RUN}
PROJECT=verify-${RUN}
BACKEND=${BACKEND}
PYTHON=${PYTHON}
WEB_PORT=${PORTS[0]}
SSH_PORT=${PORTS[1]}
FLOWER_PORT=${PORTS[2]}
DB_PORT=${PORTS[3]}
ENV
cat "${RUN_DIR}/instance.env"

cd "${CHECKOUT}"
export ANSWER=no WEB_HOST_PORT="${PORTS[0]}" SSH_PORT="${PORTS[1]}" FLOWER_HOST_PORT="${PORTS[2]}"
if [[ -n "${DB_PORT_VAR}" ]]; then
    export "${DB_PORT_VAR}=${PORTS[3]}"
fi
exec breeze shell --project-name "verify-${RUN}" --backend "${BACKEND}" --python "${PYTHON}" --quiet \
    "AIRFLOW__CORE__LOAD_EXAMPLES=False AIRFLOW__CORE__SIMPLE_AUTH_MANAGER_ALL_ADMINS=True airflow standalone" \
    > "${RUN_DIR}/standalone.log" 2>&1 < /dev/null
