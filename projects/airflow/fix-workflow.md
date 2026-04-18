<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Apache Airflow — remediation PR workflow specifics](#apache-airflow--remediation-pr-workflow-specifics)
  - [Upstream repository](#upstream-repository)
  - [Toolchain](#toolchain)
  - [Backport labels](#backport-labels)
  - [Commit trailer](#commit-trailer)
  - [PR title / body scrubbing](#pr-title--body-scrubbing)
  - [PR creation convention](#pr-creation-convention)
  - [Private-PR fallback](#private-pr-fallback)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# Apache Airflow — remediation PR workflow specifics

Airflow-specific details of how the `fix-security-issue` skill opens
a public fix PR against `apache/airflow`. Only the mechanics that
are specific to Apache Airflow live here; the generic flow (clone →
branch → commit → push → `gh pr create --web`) is described in the
[`fix-security-issue`](../../.claude/skills/fix-security-issue/SKILL.md)
skill itself.

## Upstream repository

| Key | Value |
|---|---|
| Upstream repo | `apache/airflow` |
| Upstream URL | <https://github.com/apache/airflow> |
| Upstream `AGENTS.md` | <https://github.com/apache/airflow/blob/main/AGENTS.md> |
| Contributing docs root | <https://github.com/apache/airflow/blob/main/contributing-docs/README.md> |
| Gen-AI disclosure reference | <https://github.com/apache/airflow/blob/main/contributing-docs/05_pull_requests.rst#gen-ai-assisted-contributions> |
| Public security policy | <https://github.com/apache/airflow/security/policy> |

The authoritative configuration for the upstream repository is in
[`project.md`](project.md); this file reiterates the same values for
convenience.

## Toolchain

Airflow's developer toolchain is:

- `uv` — Python package / script runner. Install:
  `curl -LsSf https://astral.sh/uv/install.sh | sh` (or see
  <https://github.com/astral-sh/uv>).
- `breeze` — Airflow's containerised developer shell. Install per
  `apache/airflow`'s `contributing-docs`.
- Python 3.x (per the currently supported range in `apache/airflow`'s
  `pyproject.toml`).

The `fix-security-issue` skill assumes a clean clone of
`apache/airflow` reachable from the agent's working directory, with
a remote named for the user's GitHub fork that `gh pr create` can
push to.

## Backport labels

Airflow uses `backport-to-<release-branch>` labels on public
`apache/airflow` PRs to flag which patch branches a merged change
should be backported to. The currently-in-flight release branches
are listed in [`release-trains.md`](release-trains.md).

Default policy as of 2026-04-16:

- Use `backport-to-v3-2-test` on every security fix that targets
  the `v3-2-test` branch (i.e. anything destined for the `3.2.2`
  patch milestone).
- Do **not** apply `backport-to-v3-1-test` by default — no further
  3.1.x releases are planned. A `v3-1-test` backport is only
  appropriate if the user explicitly requests it for a specific
  issue and is prepared to cut a 3.1.x patch release out-of-band.

## Commit trailer

Airflow's convention — mirroring the rule in `apache/airflow`'s own
`AGENTS.md` — is:

- **Never use `Co-Authored-By:` with an AI agent as co-author.**
  Agents are assistants, not authors.
- Use a `Generated-by:` trailer instead. Example:

  ```
  Generated-by: Claude Opus 4.6 (1M context) following the guidelines at
  https://github.com/apache/airflow/blob/main/contributing-docs/05_pull_requests.rst#gen-ai-assisted-contributions
  ```

## PR title / body scrubbing

Every public surface (commit message, branch name, PR title, PR body,
newsfragment) must be grep-checked for leakage of:

- `CVE-` (the CVE ID),
- `airflow-s` (the private tracker repo name / URLs),
- `vulnerability`, `security fix` (and similar security-nature signals).

A leaked CVE or `airflow-s` reference in a public `apache/airflow` PR
breaks the disclosure coordination; the skill refuses to push if the
scrubbing grep fails.

## PR creation convention

Always open PRs with `gh pr create --web` so the human reviewer can
check the title, body, and the Gen-AI disclosure in the browser
before submission. Pre-fill `--title` and `--body` (including the
Gen-AI disclosure block) so the reviewer only needs to review, not
edit.

## Private-PR fallback

The exceptional private-PR path (target branch `main` of
`airflow-s/airflow-s`, CI does not run, static checks and tests run
manually by the PR author) is described in Step 9 of
[`../../README.md`](../../README.md).
