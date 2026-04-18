<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Apache Airflow — project index](#apache-airflow--project-index)
  - [File index](#file-index)
  - [How this folder evolves](#how-this-folder-evolves)
  - [Cross-references](#cross-references)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# Apache Airflow — project index

This directory contains every project-specific fact the skills need
when `config/active-project.md` declares `active_project: airflow`.
The generic framework lives at the repo root and under
[`../../.claude/skills/`](../../.claude/skills/) + `../../tools/`;
**nothing under `projects/airflow/` is read by a skill unless the
active project is this one**.

For the framework-level view of how project directories are organised,
how to add a new one, and the *"Current projects"* list, see
[`../README.md`](../README.md).

## File index

Authoritative manifest (read first):

| File | Purpose |
|---|---|
| [`project.md`](project.md) | **Project manifest.** Identity, repositories, mailing lists, tools enabled, CVE tooling, GitHub project board + issue-template field declarations, Gmail / PonyMail templates. The single file every skill reads to resolve project-scoped references. |

Release state (fast-moving — update whenever a release ships or a
release manager rotates):

| File | Purpose |
|---|---|
| [`release-trains.md`](release-trains.md) | Active release branches, release-manager attribution per cut, known rotation rosters, security-team roster snapshot + `gh api` lookup. |
| [`milestones.md`](milestones.md) | Milestone naming conventions (`Airflow-X.Y.Z`, `Providers YYYY-MM-DD`, `Chart-X.Y.Z`) + create-and-assign recipe. |

Scope + product mapping:

| File | Purpose |
|---|---|
| [`scope-labels.md`](scope-labels.md) | Exactly-one-of scope label (`airflow` / `providers` / `chart` / `task-sdk` when active) → CVE product / `packageName` / collection-URL mapping. |

Security-model references:

| File | Purpose |
|---|---|
| [`security-model.md`](security-model.md) | Authoritative URL for the Airflow Security Model + known-useful anchors (`#capabilities-of-dag-authors`, …) + drafting rule. Referenced by canned responses and validity assessments. |

CVE-allocation mechanics:

| File | Purpose |
|---|---|
| [`title-normalization.md`](title-normalization.md) | Regex cascade the `allocate-cve` skill applies to tracker titles before pasting them into the Vulnogram allocation form (strip *"Apache Airflow:"*, *"[ Security Report ]"*, trailing version parens, etc.). |

Remediation workflow:

| File | Purpose |
|---|---|
| [`fix-workflow.md`](fix-workflow.md) | `apache/airflow` fork / clone / `uv` / `breeze` specifics, backport-label policy, `Generated-by:` commit trailer, PR scrubbing rules, private-PR fallback. |

Editorial + reporter-facing:

| File | Purpose |
|---|---|
| [`naming-conventions.md`](naming-conventions.md) | Project-specific editorial rules: *"use `Dag`, not `DAG`"*, *"thousands of contributors"*, acronym casing, the `@`-mention-maintainers rule. |
| [`canned-responses.md`](canned-responses.md) | Reusable reporter-facing reply templates. Sent verbatim as email replies — tone, linking, and confidentiality rules from [`../../AGENTS.md`](../../AGENTS.md) apply. |

## How this folder evolves

- **When a release ships** → update [`release-trains.md`](release-trains.md)
  with the release manager attribution + any new release branches /
  milestones on the roadmap.
- **When a security-team member joins or rotates off** → re-run the
  `gh api` collaborator lookup in
  [`release-trains.md`](release-trains.md#security-team-roster) and
  update the snapshot in the same change.
- **When the Security Model gains a new chapter** → add the anchor to
  [`security-model.md`](security-model.md) so canned responses can
  link to it.
- **When we land a new canned response** → add it to
  [`canned-responses.md`](canned-responses.md) and flag any new
  Security-Model anchor it relies on.
- **When `apache/airflow` changes its fork / toolchain / backport
  conventions** → update [`fix-workflow.md`](fix-workflow.md).
- **When the GitHub project board's column list changes** → re-run
  the introspection query in
  [`../../tools/github/project-board.md`](../../tools/github/project-board.md#introspection--re-fetch-the-option-ids)
  and refresh the option-ID table in
  [`project.md`](project.md#github-project-board).

## Cross-references

- [`../../README.md`](../../README.md) — the project-agnostic
  lifecycle (16 steps + role sections). Start there if you are a new
  security-team member.
- [`../../AGENTS.md`](../../AGENTS.md) — agent conventions (tone,
  brevity, threading, confidentiality as a writing rule,
  placeholder convention).
- [`../../config/README.md`](../../config/README.md) — how the
  per-project + per-user configuration layers work, and how to
  switch the active project.
- [`../README.md`](../README.md) — *"Current projects"* overview +
  how to bootstrap a new one from `projects/_template/`.
