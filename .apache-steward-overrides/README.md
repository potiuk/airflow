<!--
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# apache-steward overrides for `apache/airflow`

Agent-readable instructions that **override** specific steps or
behaviours of the
[`apache-steward`](https://github.com/apache/airflow-steward)
framework's skills, scoped to this repository. Each override
file is named after the framework skill it modifies (e.g.
`pr-management-triage.md` overrides the `pr-management-triage`
skill).

The framework skills consult this directory at run-time before
executing default behaviour. See
[`docs/setup/agentic-overrides.md`](https://github.com/apache/airflow-steward/blob/main/docs/setup/agentic-overrides.md)
in the framework for the full contract.

**Hard rules** (baked into the framework's agent instructions):

- Never modify the snapshot under
  [`/.apache-steward/`](../.apache-steward/) — it is gitignored
  and gets nuked-and-replaced on every `/setup-steward upgrade`.
  Local mods go in **this** directory.
- Framework changes go via PR to `apache/airflow-steward`, not
  here.
- Every override file should explain **why** the deviation
  exists and **whether** it should be upstreamed.

## How to add an override

```text
/setup-steward override <framework-skill-name>
```

That sub-action either opens the existing override or scaffolds
a new one for the named framework skill, with prompts for the
overrides you want to apply.

## Current overrides

(none yet — this directory will fill up as Airflow encodes
project-specific deviations from the framework's default
workflows)
