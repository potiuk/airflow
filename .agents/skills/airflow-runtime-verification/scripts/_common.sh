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

# Shared by the runtime-verification scripts; sourced, not run.

die() {
    echo "ERROR: $*" >&2
    exit 1
}

require_run() {
    local run="${1:-}"
    [[ "${run}" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "pass a run name of lowercase letters, digits and dashes"
}

load_instance() {
    require_run "$1"
    CHECKOUT="$(git rev-parse --show-toplevel)" || die "run this from inside the checkout under test"
    RUN_DIR="${CHECKOUT}/files/verify/$1"
    [[ -f "${RUN_DIR}/instance.env" ]] || die "no instance.env in ${RUN_DIR}: start the run with start.sh first"
    # shellcheck source=/dev/null
    source "${RUN_DIR}/instance.env"
}
