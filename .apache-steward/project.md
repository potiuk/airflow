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

# Apache Airflow — project manifest

This is the **project configuration** for `apache-airflow` as an
adopter of the [`apache/airflow-steward`](https://github.com/apache/airflow-steward)
framework. The framework lives at
[`.apache-steward/apache-steward/`](apache-steward/) as a git
submodule; this directory carries the airflow-specific content the
framework's skills resolve via the
[`<project-config>/` placeholder convention](apache-steward/AGENTS.md#placeholder-convention-used-in-skill-files).

apache-airflow adopts only the
[PR triage and review](apache-steward/.claude/skills/pr-triage/SKILL.md)
skill family — the security workflow runs out of the private
security-tracker repo (`apache/airflow-s`), not out of the public
upstream. Files declaring security-workflow specifics
(`canned-responses.md`, `scope-labels.md`, `release-trains.md`,
etc.) intentionally do **not** live here; they're declared in the
security tracker's own `.apache-steward/` directory.

## Identity

| Key | Value |
|---|---|
| `project_name` | Apache Airflow |
| `vendor` | Apache Software Foundation |
| `short_name` | Airflow |
| `product_family_url` | <https://airflow.apache.org/> |

## Repositories

| Key | Value | Purpose |
|---|---|---|
| `upstream_repo` | `apache/airflow` | Public codebase — this repo. PR-skill default target. |
| `upstream_repo_url` | <https://github.com/apache/airflow> | |
| `upstream_default_branch` | `main` | |

## Pointers to sibling files

The PR-skill family resolves its project-specific content from
these files in this directory:

| File | Used by |
|---|---|
| [`pr-triage-config.md`](pr-triage-config.md) | `pr-triage`, `pr-stats` |
| [`pr-triage-comment-templates.md`](pr-triage-comment-templates.md) | `pr-triage` |
| [`pr-triage-ci-check-map.md`](pr-triage-ci-check-map.md) | `pr-triage` |
| [`pr-maintainer-review-criteria.md`](pr-maintainer-review-criteria.md) | `pr-maintainer-review` |
