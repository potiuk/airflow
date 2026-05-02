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

# Apache Airflow — pr-maintainer-review criteria

Per-project navigation map for the
[`pr-maintainer-review`](apache-steward/.claude/skills/pr-maintainer-review/SKILL.md)
skill's review-criteria source files. Companion to the framework's
[`projects/_template/pr-maintainer-review-criteria.md`](apache-steward/projects/_template/pr-maintainer-review-criteria.md)
scaffold.

The framework does not restate the rules; this file points at them.
The skill's review pass reads each source file at session start
(and re-reads per-area files as PRs route into different trees) and
quotes the **source rule verbatim** in any finding it raises.

## Repo-wide source files

| File | What it covers |
|---|---|
| [`.github/instructions/code-review.instructions.md`](../.github/instructions/code-review.instructions.md) | The rule set every Apache Airflow PR is reviewed against (architecture / DB / quality / testing / API / UI / generated files / AI-generated-code signals / quality signals). |
| [`AGENTS.md`](../AGENTS.md) | Repo-wide AI/agent instructions (architecture boundaries, security model, coding standards, testing standards, commits & PR conventions). |

## Per-area source files

Always loaded — the skill also auto-discovers any `AGENTS.md`
under the touched paths via `git ls-files`.

| File | When it applies |
|---|---|
| [`registry/AGENTS.md`](../registry/AGENTS.md) | Registry-tree-specific rules. |
| [`dev/AGENTS.md`](../dev/AGENTS.md) | `dev/` scripts conventions. |
| [`dev/ide_setup/AGENTS.md`](../dev/ide_setup/AGENTS.md) | IDE bootstrap conventions. |
| [`providers/AGENTS.md`](../providers/AGENTS.md) | Provider-tree boundary, compat-layer, and `provider.yaml` expectations. |
| [`providers/elasticsearch/AGENTS.md`](../providers/elasticsearch/AGENTS.md) | Elasticsearch-specific rules. |
| [`providers/opensearch/AGENTS.md`](../providers/opensearch/AGENTS.md) | OpenSearch-specific rules. |

## Security-model calibration

| File | Used by |
|---|---|
| [`airflow-core/docs/security/security_model.rst`](../airflow-core/docs/security/security_model.rst) | The skill's `Security model — calibration` section (`review-flow.md`). Used to distinguish actual vulnerabilities from documented limitations and deployment-hardening opportunities. |

## Backports / version-specific PRs

| Concept | Pattern |
|---|---|
| Backport branch pattern | `vX-Y-test` |

Backports get a lighter-touch review focused on diff parity and
cherry-pick conflicts; prefer `COMMENT` over `REQUEST_CHANGES`
unless the cherry-pick has clearly drifted from the `main` change.

## Section anchors

The skill links per-finding to the section in
[`.github/instructions/code-review.instructions.md`](../.github/instructions/code-review.instructions.md)
that the finding cites:

| Section | Anchor URL |
|---|---|
| Architecture boundaries | <https://github.com/apache/airflow/blob/main/.github/instructions/code-review.instructions.md#architecture-boundaries> |
| Database / query correctness | <https://github.com/apache/airflow/blob/main/.github/instructions/code-review.instructions.md#database-and-query-correctness> |
| Code quality | <https://github.com/apache/airflow/blob/main/.github/instructions/code-review.instructions.md#code-quality-rules> |
| Testing | <https://github.com/apache/airflow/blob/main/.github/instructions/code-review.instructions.md#testing-requirements> |
| API correctness | <https://github.com/apache/airflow/blob/main/.github/instructions/code-review.instructions.md#api-correctness> |
| UI (React/TypeScript) | <https://github.com/apache/airflow/blob/main/.github/instructions/code-review.instructions.md#ui-code-reacttypescript> |
| Generated files | <https://github.com/apache/airflow/blob/main/.github/instructions/code-review.instructions.md#generated-files> |
| AI-generated code signals | <https://github.com/apache/airflow/blob/main/.github/instructions/code-review.instructions.md#ai-generated-code-signals> |
| Quality signals to check | <https://github.com/apache/airflow/blob/main/.github/instructions/code-review.instructions.md#quality-signals-to-check> |
| Commits and PRs | <https://github.com/apache/airflow/blob/main/AGENTS.md#commits-and-prs> |
| Security model | <https://github.com/apache/airflow/blob/main/AGENTS.md#security-model> |
