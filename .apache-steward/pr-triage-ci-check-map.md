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

# Apache Airflow — pr-triage CI-check to doc-URL map

Per-project CI-check categorisation table for the
[`pr-triage`](apache-steward/.claude/skills/pr-triage/SKILL.md)
skill's violations comments. Companion to the framework's
[`projects/_template/pr-triage-ci-check-map.md`](apache-steward/projects/_template/pr-triage-ci-check-map.md)
scaffold.

When a PR has failing CI checks, the skill groups failures by
category (static checks, tests, image builds, etc.) and links each
category to the documentation for that area.

## Table

Pattern matching is **case-insensitive substring**, evaluated in
the order below — first match wins. Put more-specific patterns
above broader ones (e.g. `mypy-airflow-core` before bare `mypy`).

| Pattern | Category | Doc URL |
|---|---|---|
| `static checks` | Pre-commit / static checks | <https://github.com/apache/airflow/blob/main/contributing-docs/08_static_code_checks.rst> |
| `pre-commit` | Pre-commit / static checks | <https://github.com/apache/airflow/blob/main/contributing-docs/08_static_code_checks.rst> |
| `prek` | Pre-commit / static checks | <https://github.com/apache/airflow/blob/main/contributing-docs/08_static_code_checks.rst> |
| `ruff` | Ruff (linting / formatting) | <https://github.com/apache/airflow/blob/main/contributing-docs/08_static_code_checks.rst> |
| `mypy-` | mypy (type checking) | <https://github.com/apache/airflow/blob/main/contributing-docs/08_static_code_checks.rst> |
| `unit test` | Unit tests | <https://github.com/apache/airflow/blob/main/contributing-docs/09_testing.rst> |
| `test-` | Unit tests | <https://github.com/apache/airflow/blob/main/contributing-docs/09_testing.rst> |
| `docs` | Build docs | <https://github.com/apache/airflow/blob/main/contributing-docs/11_documentation_building.rst> |
| `spellcheck-docs` | Build docs | <https://github.com/apache/airflow/blob/main/contributing-docs/11_documentation_building.rst> |
| `build-docs` | Build docs | <https://github.com/apache/airflow/blob/main/contributing-docs/11_documentation_building.rst> |
| `helm` | Helm tests | <https://github.com/apache/airflow/blob/main/contributing-docs/testing/helm_unit_tests.rst> |
| `k8s` | Kubernetes tests | <https://github.com/apache/airflow/blob/main/contributing-docs/testing/k8s_tests.rst> |
| `kubernetes` | Kubernetes tests | <https://github.com/apache/airflow/blob/main/contributing-docs/testing/k8s_tests.rst> |
| `build ci image` | Image build | <https://github.com/apache/airflow/blob/main/contributing-docs/08_static_code_checks.rst> |
| `build prod image` | Image build | <https://github.com/apache/airflow/blob/main/contributing-docs/08_static_code_checks.rst> |
| `ci-image` | Image build | <https://github.com/apache/airflow/blob/main/contributing-docs/08_static_code_checks.rst> |
| `prod-image` | Image build | <https://github.com/apache/airflow/blob/main/contributing-docs/08_static_code_checks.rst> |
| `provider` | Provider tests | <https://github.com/apache/airflow/blob/main/contributing-docs/12_provider_distributions.rst> |
| `*` (catch-all) | Other failing CI checks | <https://github.com/apache/airflow/blob/main/contributing-docs/08_static_code_checks.rst> |

## Fallbacks

| Concept | Doc URL |
|---|---|
| Merge conflicts (rebase guide) | <https://github.com/apache/airflow/blob/main/contributing-docs/10_working_with_git.rst> |
| Pull Request quality criteria (the Copilot-review / unresolved-threads fallback) | <https://github.com/apache/airflow/blob/main/contributing-docs/05_pull_requests.rst#pull-request-quality-criteria> |
