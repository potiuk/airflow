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

# Wait until the metadatabase, scheduler, triggerer and Dag processor all report healthy.
# Usage: wait-healthy.sh <run> [timeout_seconds, default 300]
# Exit 0 when healthy; 1 on timeout, after printing the end of standalone.log.
set -euo pipefail

# shellcheck source=_common.sh
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
load_instance "${1:-}"
TIMEOUT="${2:-300}"

deadline=$((SECONDS + TIMEOUT))
while [[ ${SECONDS} -lt ${deadline} ]]; do
    healthy=$(curl -sf "http://localhost:${WEB_PORT}/api/v2/monitor/health" \
        | grep -o '"status":"healthy"' | wc -l | tr -d ' ' || true)
    if [[ "${healthy}" == "4" ]]; then
        echo "healthy: http://localhost:${WEB_PORT}"
        exit 0
    fi
    sleep 5
done
echo "not healthy after ${TIMEOUT}s; end of ${RUN_DIR}/standalone.log:" >&2
tail -n 40 "${RUN_DIR}/standalone.log" >&2
exit 1
