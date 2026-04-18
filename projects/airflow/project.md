<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Apache Airflow — project manifest](#apache-airflow--project-manifest)
  - [Identity](#identity)
  - [Repositories](#repositories)
  - [Mailing lists](#mailing-lists)
  - [Tools enabled](#tools-enabled)
  - [CVE tooling](#cve-tooling)
  - [GitHub project board](#github-project-board)
  - [Gmail and PonyMail](#gmail-and-ponymail)
  - [Issue-template fields](#issue-template-fields)
  - [Scope labels and CVE product mapping](#scope-labels-and-cve-product-mapping)
  - [Release trains, release managers, security team roster](#release-trains-release-managers-security-team-roster)
  - [Milestone conventions](#milestone-conventions)
  - [Security Model](#security-model)
  - [Title normalisation for CVE allocation](#title-normalisation-for-cve-allocation)
  - [Fix workflow specifics](#fix-workflow-specifics)
  - [Naming and editorial conventions](#naming-and-editorial-conventions)
  - [Canned responses](#canned-responses)
  - [File index](#file-index)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# Apache Airflow — project manifest

This file is the **project configuration** for Apache Airflow. Every
skill under [`.claude/skills/`](../../.claude/skills/) reads the
project name from
[`config/active-project.md`](../../config/active-project.md) and then
loads this manifest to resolve project-specific identity, repositories,
mailing lists, and references to the other files in this directory.

Adding a new project (including another ASF project) means copying
this file into a sibling `projects/<name>/` directory, adjusting the
values below, and updating `config/active-project.md`.

## Identity

| Key | Value |
|---|---|
| `project_name` | Apache Airflow |
| `vendor` | Apache Software Foundation |
| `short_name` | Airflow |
| `product_family_url` | <https://airflow.apache.org/> |

The `vendor` / `project_name` pair is what lands in the `vendor` and
`product` fields of the CVE 5.x record the `generate-cve-json` tool
produces.

## Repositories

| Key | Value | Purpose |
|---|---|---|
| `tracker_repo` | `airflow-s/airflow-s` | Private security tracker (this repo) |
| `tracker_repo_url` | <https://github.com/airflow-s/airflow-s> | |
| `tracker_default_branch` | `airflow-s` | Default PR target for this repo |
| `tracker_project_board_url` | <https://github.com/orgs/airflow-s/projects/2> | Security board |
| `upstream_repo` | `apache/airflow` | Public codebase where fixes land |
| `upstream_repo_url` | <https://github.com/apache/airflow> | |
| `upstream_agents_md_url` | <https://github.com/apache/airflow/blob/main/AGENTS.md> | Conventions the security repo mirrors |
| `upstream_contributing_docs_url` | <https://github.com/apache/airflow/blob/main/contributing-docs/README.md> | |
| `upstream_genai_disclosure_anchor` | <https://github.com/apache/airflow/blob/main/contributing-docs/05_pull_requests.rst#gen-ai-assisted-contributions> | Referenced by `Generated-by:` commit trailer |
| `upstream_security_policy_url` | <https://github.com/apache/airflow/security/policy> | |

## Mailing lists

| Key | Value | Notes |
|---|---|---|
| `security_list` | `security@airflow.apache.org` | Inbound reports; **not** publicly archived |
| `private_list` | `private@airflow.apache.org` | PMC escalation; **not** publicly archived |
| `users_list` | `users@airflow.apache.org` | Public advisories end up here; publicly archived |
| `dev_list` | `dev@airflow.apache.org` | Release `[RESULT][VOTE]` threads; publicly archived |
| `announce_list` | `announce@apache.org` | Cross-project announcement list; publicly archived |
| `commits_list` | `commits@airflow.apache.org` | Publicly archived |
| `asf_security_list` | `security@apache.org` | ASF-wide security team; relays some inbound reports |

**Public** archives live at `https://lists.apache.org/list.html?<list>`.
**Private** lists on `lists.apache.org/thread/<id>` 404 for non-members.
Only URLs on publicly archived lists may appear in CVE `references[]`
as `vendor-advisory`; see `../../AGENTS.md` and
[`security-model.md`](security-model.md).

## Tools enabled

This project uses the following tools; each has a corresponding
directory under `tools/` (populated incrementally across the refactor
PR series).

| Capability | Tool | Adapter directory | Config knobs declared here |
|---|---|---|---|
| Issue tracking + source control + project board | `github` | [`../../tools/github/`](../../tools/github/) | `tracker_repo`, `upstream_repo`, `github_project_board_*`, `issue_template_fields` |
| Inbound email / drafts | `gmail` | [`../../tools/gmail/`](../../tools/gmail/) | `security_list` subscription; PonyMail archive URL templates below |
| CVE allocation + record mgmt | `vulnogram` | [`../../tools/vulnogram/`](../../tools/vulnogram/) | see [CVE tooling](#cve-tooling) below |
| Release voting / announce | ASF mailing lists | — | via `dev_list` / `announce_list` / `users_list` |

To replace a tool (e.g. swap GitHub issues for JIRA), declare an
alternate tool in the table above, add a `tools/<name>/` adapter
directory, and make sure the values the generic skills need are still
reachable from this manifest.

## CVE tooling

Apache Airflow uses the ASF's **Vulnogram** instance as its CNA tool
for CVE allocation and record management. The Vulnogram-side
mechanics (allocation URL + PMC-gated flow, record URL templates,
`#source` paste flow, `DRAFT` → `REVIEW` → `PUBLIC` state machine,
reviewer-comment-via-email signal, CVE-5.x JSON generator) live under
[`../../tools/vulnogram/`](../../tools/vulnogram/); the per-project
values below are what the generic recipes substitute in.

| Key | Value |
|---|---|
| `cve_tool` | `vulnogram` (ASF-hosted) |
| `cve_tool_allocate_url` | <https://cveprocess.apache.org/allocatecve> |
| `cve_tool_record_url_template` | `https://cveprocess.apache.org/cve5/<CVE-ID>` |
| `cve_tool_source_tab_url_template` | `https://cveprocess.apache.org/cve5/<CVE-ID>#source` |
| `cve_allocation_gated_by` | Airflow PMC membership (ASF OAuth) |
| `asf_org_id` | `f0158376-9dc2-43b6-827c-5f631a4d8d09` |
| `cna_private_owner` | `airflow` |
| `cna_private_projecturl` | <https://airflow.apache.org/> |
| `cna_private_userslist` | `users@airflow.apache.org` |

The `asf_org_id` is the ASF's CNA organisation UUID and is shared by
every ASF project; the `cna_private_*` triple is project-specific and
lands inside the Vulnogram `CNA_private` envelope the generator emits.

The generator that produces the paste-ready JSON from the tracker
body lives at
[`../../tools/vulnogram/generate-cve-json/`](../../tools/vulnogram/generate-cve-json/).
See [`../../tools/vulnogram/allocation.md`](../../tools/vulnogram/allocation.md)
for the allocation flow and
[`../../tools/vulnogram/record.md`](../../tools/vulnogram/record.md)
for the record-management flow.

## GitHub project board

The security team runs a Projects V2 board ("Security issues") as its
primary overview surface. Every tracker sits in exactly one `Status`
column. The GitHub-side mechanics (introspection, GraphQL write path,
orphan-issue fallback) live in
[`../../tools/github/project-board.md`](../../tools/github/project-board.md);
the per-project IDs below are what that generic recipe substitutes in.

| Key | Value |
|---|---|
| `project_board_url` | <https://github.com/orgs/airflow-s/projects/2> |
| `project_board_number` | `2` |
| `project_board_node_id` | `PVT_kwDOCAwKzs4BUzbt` |
| `status_field_node_id` | `PVTSSF_lADOCAwKzs4BUzbtzhD08bw` |

**`Status` column → option-ID mapping** (re-fetch with the
introspection query in `project-board.md` if any write returns
`not found`):

| Column | Option ID |
|---|---|
| `Needs triage` | `aee65beb` |
| `Assessed` | `ce6377ce` |
| `CVE allocated` | `aae2beb3` |
| `PR created` | `af56c90c` |
| `PR merged` | `b21b5352` |
| `Fix released` | `1f2dbb6c` |
| `Announced` | `12e22331` |

**Label + body state → `Status` column mapping**:

| Issue state | Correct `Status` column |
|---|---|
| `needs triage` label set, no scope label yet | `Needs triage` |
| Scope label applied, no CVE yet | `Assessed` |
| `cve allocated` label set, no fix PR yet | `CVE allocated` |
| `pr created` label set | `PR created` |
| `pr merged` label set (release has not shipped) | `PR merged` |
| `fix released` label set, advisory not yet sent | `Fix released` |
| `announced - emails sent` label set (Step 13) **or** *Public advisory URL* body field populated + `announced` label set (Step 14) | `Announced` — one column for both steps; next move is Step 15 |

**One column covers Step 13 *and* Step 14.** There is no `Closed`
column; closed issues simply leave the board. The `announced` label
stays meaningful on the tracker (it is the load-bearing signal for
the CVE JSON's `CNA_private.state` REVIEW → PUBLIC transition) but
does not map to a separate column.

## Gmail and PonyMail

The active project's Gmail / PonyMail configuration. Gmail-side
mechanics (MCP call shapes, threading rule, search-query patterns,
archive URL construction) live under
[`../../tools/gmail/`](../../tools/gmail/); the concrete per-project
values below are what the generic recipes substitute in.

| Key | Value | Used by |
|---|---|---|
| `security_list` | `security@airflow.apache.org` | `list:` filter, draft `Cc:` target — see [`../../tools/gmail/search-queries.md`](../../tools/gmail/search-queries.md) |
| `security_list_domain` | `security.airflow.apache.org` | Gmail `list:` operator — the domain form, not the plain address |
| `users_list` | `users@airflow.apache.org` | Public advisory archive scans — see [`../../tools/gmail/ponymail-archive.md`](../../tools/gmail/ponymail-archive.md) |
| `dev_list` | `dev@airflow.apache.org` | `[RESULT][VOTE]` attribution search — see [`../../tools/gmail/search-queries.md`](../../tools/gmail/search-queries.md#release-resultvote-attribution) |
| `ponymail_private_search_url_template` | `https://lists.apache.org/list?security@airflow.apache.org:YYYY-M:<url-encoded subject>` | `import-security-issue` Step 4 — user pastes back the resolved thread URL |
| `ponymail_public_search_url_template` | `https://lists.apache.org/list.html?users@airflow.apache.org:YYYY:<CVE-ID>` | `sync-security-issue` Step 2b — scans the public archive for the advisory |
| `ponymail_api_url_template` | `https://lists.apache.org/api/thread.lua?list=users&domain=airflow.apache.org&q=<CVE-ID>` | Machine-readable variant of the public-archive scan |
| `ponymail_thread_url_template` | `https://lists.apache.org/thread/<hash>?<list>` | Canonical resolved-thread URL form — used in the *security-thread* and *public-advisory-url* body fields |

The `YYYY-M` token in the private-search template uses a 1- or 2-digit
month without a leading zero (e.g. `2026-4` for April 2026), per the
PonyMail URL-construction note in
[`../../tools/gmail/ponymail-archive.md`](../../tools/gmail/ponymail-archive.md#url-shapes).

**GitHub-notification mirror senders** (excluded from most Gmail
searches — the project's GitHub tracker mirrors issue activity to the
security list):

```text
-from:notifications@github.com
-from:noreply@github.com
-from:airflow-s@noreply.github.com
-from:security-noreply@github.com
```

## Issue-template fields

The skills' body-field roles map to the following concrete `###`
headings in the Airflow issue template at
[`.github/ISSUE_TEMPLATE/issue_report.yml`](../../.github/ISSUE_TEMPLATE/issue_report.yml).
The generic role → GitHub-field mapping contract lives in
[`../../tools/github/issue-template.md`](../../tools/github/issue-template.md);
the concrete names below are what skills read and write for this
project.

| Role (generic) | Field name (Airflow) | Template type | Required? |
|---|---|---|---|
| `issue-description` | `The issue description` | `textarea` | yes |
| `public-summary` | `Short public summary for publish` | `textarea` | no |
| `affected-versions` | `Affected versions` | `input` | no |
| `security-thread` | `Security mailing list thread` | `input` | yes |
| `public-advisory-url` | `Public advisory URL` | `input` | no |
| `reporter-credit` | `Reporter credited as` | `input` | no |
| `pr-with-fix` | `PR with the fix` | `input` | no |
| `cwe` | `CWE` | `input` | no |
| `severity` | `Severity` | `dropdown` (`Unknown`, `Low`, `Moderate`, `Important`, `Critical`) | yes |
| `cve-tool-link` | `CVE tool link` | `input` | no |

**Empty-field convention:** GitHub renders `_No response_` for unset
fields, and the skills honour that literal on both read and write;
see [`../../tools/github/issue-template.md`](../../tools/github/issue-template.md#empty-field-convention).

## Scope labels and CVE product mapping

Airflow tracks scope via exactly one of a small, finite set of labels
applied at Step 5 of the process. The detailed table (label → CVE
product → package name) lives in [`scope-labels.md`](scope-labels.md).

## Release trains, release managers, security team roster

Authoritative content about which Airflow release branches are in
flight, who the current release manager of each train is, and who is
on the security team lives in [`release-trains.md`](release-trains.md).

The security team roster is the collaborator list of `tracker_repo`.
Authoritative lookup:

```bash
gh api repos/airflow-s/airflow-s/collaborators --jq '.[].login'
```

## Milestone conventions

The milestone format is project-specific. Airflow's conventions (core,
providers waves, Helm chart) live in [`milestones.md`](milestones.md).

## Security Model

The Apache Airflow Security Model is the authoritative source the
canned responses and assessment rationales link into. Known-useful
anchors and the drafting policy (*"point to it, don't re-explain
it"*) live in [`security-model.md`](security-model.md).

## Title normalisation for CVE allocation

The rules for stripping *"Apache Airflow:"* / *"[ Security Report ]"*
/ trailing version parens from tracker titles before pasting into the
Vulnogram allocation form live in
[`title-normalization.md`](title-normalization.md).

## Fix workflow specifics

Airflow-specific mechanics of the remediation PR workflow — the
`apache/airflow` fork layout, the `uv` / `breeze` toolchain, the
`backport-to-v3-2-test` family of labels, the `Generated-by:` commit
trailer — live in [`fix-workflow.md`](fix-workflow.md).

## Naming and editorial conventions

Airflow-specific editorial rules (e.g. *"use `Dag`, not `DAG`"*,
*"thousands of contributors"*, preferred acronym forms) live in
[`naming-conventions.md`](naming-conventions.md). Project-agnostic
editorial rules (tone, brevity, threading, confidentiality) stay in
the repo-root [`../../AGENTS.md`](../../AGENTS.md).

## Canned responses

Reusable reporter-facing reply templates live in
[`canned-responses.md`](canned-responses.md) in this directory. They
are Airflow-specific because every response links into the Airflow
Security Model; other projects would maintain their own analogue.

## File index

Files in this directory, by purpose:

| File | Content |
|---|---|
| [`project.md`](project.md) | This manifest |
| [`release-trains.md`](release-trains.md) | Active release branches, release-manager attribution, security-team roster |
| [`milestones.md`](milestones.md) | Milestone naming conventions for core, providers, chart |
| [`scope-labels.md`](scope-labels.md) | Scope label → CVE product / package-name mapping |
| [`security-model.md`](security-model.md) | Security Model URL + known-useful anchors + drafting rule |
| [`title-normalization.md`](title-normalization.md) | Regex cascade for stripping Airflow tags from titles before CVE allocation |
| [`fix-workflow.md`](fix-workflow.md) | `apache/airflow` clone / fork / `uv` / `breeze` / backport-label specifics |
| [`naming-conventions.md`](naming-conventions.md) | Dag vs DAG, "thousands of contributors", acronyms |
| [`canned-responses.md`](canned-responses.md) | Reporter-facing reply templates (Airflow-specific) |
