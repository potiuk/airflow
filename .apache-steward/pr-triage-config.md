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

# Apache Airflow — pr-triage configuration

Per-project configuration for the
[`pr-triage`](apache-steward/.claude/skills/pr-triage/SKILL.md) and
[`pr-stats`](apache-steward/.claude/skills/pr-stats/SKILL.md)
skills. Companion to the framework's
[`projects/_template/pr-triage-config.md`](apache-steward/projects/_template/pr-triage-config.md)
scaffold.

## Identifiers

| Key | Value | Used by |
|---|---|---|
| `committers_team` | `apache/airflow-committers` | `classify-and-act.md` row F5b — team-mention detection. |
| `area_label_prefix` | `area:` | `classify-and-act.md`, `pr-stats` — area-label grouping. |

## Project-specific labels

| Concept | Label |
|---|---|
| `ready_for_maintainer_review` | `ready for maintainer review` |
| `quality_violations_close` | `quality violations - closed` |
| `suspicious_changes` | `suspicious changes` |
| `work_in_progress` | (Airflow uses GitHub's draft state, not a WIP label — leave the rule disabled) |

## Grace windows

| Concept | Value |
|---|---|
| Stale-draft close threshold | 30 days |
| Inactive-open → draft threshold | 14 days |
| Stale-review-ping cooldown | 7 days |
| Stale-workflow-approval threshold | 7 days |
