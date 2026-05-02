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

# Apache Airflow — pr-triage comment templates

Per-project comment-body library for the
[`pr-triage`](apache-steward/.claude/skills/pr-triage/SKILL.md)
skill. The framework's
[`comment-templates.md`](apache-steward/.claude/skills/pr-triage/comment-templates.md)
documents what each template **must** contain (the contract); this
file declares Airflow's actual wording, URLs, and tone.

## Project-specific URLs

| Placeholder | Value |
|---|---|
| `<quality_criteria_url>` | <https://github.com/apache/airflow/blob/main/contributing-docs/05_pull_requests.rst#pull-request-quality-criteria> |
| `<two_stage_triage_rationale_url>` | <https://github.com/apache/airflow/blob/main/contributing-docs/25_maintainer_pr_triage.md#why-the-first-pass-is-automated> |
| `<project_display_name>` | `Apache Airflow` |

## Quality-criteria marker string

| Concept | Value |
|---|---|
| Triage-marker visible link text | `Pull Request quality criteria` |

This is the literal string the framework searches for to detect
already-triaged PRs. **Do not paraphrase** — the same exact string
must appear verbatim in every triage comment the skill posts, and
[`pr-stats`](apache-steward/.claude/skills/pr-stats/SKILL.md) uses
the same marker for its "is this PR triaged" detection.

## AI-attribution footer

The block appended verbatim to every contributor-facing comment
(see
[`comment-templates.md` § AI-attribution footer](apache-steward/.claude/skills/pr-triage/comment-templates.md#ai-attribution-footer)
for the rules — always-include, never-paraphrase, render at end of
body).

```markdown
---

_Note: This comment was drafted by an AI-assisted triage tool and may contain mistakes. Once you have addressed the points above, an Apache Airflow maintainer — a real person — will take the next look at your PR. We use this [two-stage triage process](https://github.com/apache/airflow/blob/main/contributing-docs/25_maintainer_pr_triage.md#why-the-first-pass-is-automated) so that our maintainers' limited time is spent where it matters most: the conversation with you._
```

## Template bodies

The framework's
[`comment-templates.md`](apache-steward/.claude/skills/pr-triage/comment-templates.md)
currently embeds Airflow-flavoured body text inline (a pre-
extraction migration artefact). Airflow uses those inline defaults
as-is; this section becomes load-bearing once the framework
completes the extraction so non-Airflow adopters can override
section-by-section without forking the whole file.

Until then, treat this section as a stub: the framework's defaults
*are* Airflow's defaults.
