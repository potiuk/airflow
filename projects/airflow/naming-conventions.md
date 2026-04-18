<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Apache Airflow — naming and editorial conventions](#apache-airflow--naming-and-editorial-conventions)
  - [`Dag`, not `DAG`, in prose](#dag-not-dag-in-prose)
  - ["Thousands of contributors"](#thousands-of-contributors)
  - [Acronyms](#acronyms)
  - [Mentioning Airflow maintainers and security-team members](#mentioning-airflow-maintainers-and-security-team-members)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# Apache Airflow — naming and editorial conventions

This file holds the Airflow-specific editorial rules the skills and
canned responses follow. Project-agnostic editorial rules (tone,
brevity, threading, confidentiality) live in the repo-level
[`../../AGENTS.md`](../../AGENTS.md).

## `Dag`, not `DAG`, in prose

Use **`Dag`** (not `DAG`) when referring to Airflow DAGs in prose —
e.g. *"Dag author"*, *"Dag run"*, *"serialized Dags"*. This matches
the Airflow Security Model chapter titles (*"Capabilities of Dag
authors"*, *"Dag authors executing arbitrary code"*, etc.) and the
convention used throughout `apache/airflow`'s own documentation and
`AGENTS.md`. Do not use the all-caps `DAG` form in documentation in
this repository; leave it only inside quoted content, URLs, anchor
slugs, or code identifiers where it already appears.

## "Thousands of contributors"

Do not include concrete contributor counts (e.g., *"4000 contributors"*,
*"3600 contributors"*). Use *"thousands of contributors"* — the
number changes constantly and hard-coding it dates the document
immediately.

## Acronyms

Prefer **`PoC`**, **`DoS`**, **`CVE`** as the canonical capitalisations
for those acronyms across Airflow canned responses and status comments.

## Mentioning Airflow maintainers and security-team members

When writing text that lands on a GitHub issue or PR and refers to a
specific Airflow maintainer, committer, release manager, or
security-team member, **use the person's GitHub handle with the
leading `@` so GitHub notifies them**. Plain-text names do not fire
notifications, and the whole point of mentioning the person is usually
that they own the next step or are the right reviewer.

Concretely:

- **GitHub handle, not plain name**: write `@jscheffl`, not
  *"Jens Scheffler"*, in a GitHub surface. It is fine to keep the
  plain name in the same sentence for readability as long as the
  `@`-mention is present somewhere: *"The next providers wave is
  cut by Jens Scheffler (@jscheffl)"*.
- **Which people the rule applies to**: Airflow PMC members,
  committers, release managers listed in the
  [`release-trains.md`](release-trains.md) rosters, and members of the
  security team (collaborators of `airflow-s/airflow-s`).
- **Which surfaces the rule applies to**: public `apache/airflow` PR
  comments/bodies; private `airflow-s/airflow-s` issue comments and
  status comments; sync recaps printed back to the user that call out
  a specific person. It does **not** apply to email text on
  `security@airflow.apache.org` (those go to the reporter and the
  list, not through GitHub's notification system).
- **Public-surface caveat**: the confidentiality rules from
  [`../../AGENTS.md`](../../AGENTS.md) still bind. In a **public**
  `apache/airflow` PR or comment, a mention must stand on its own —
  it must not be accompanied by any of the forbidden terms (`CVE-`,
  `airflow-s`, *"security fix"*, etc.) that would reveal the private
  nature of the coordination.
- **External reporters**: when referring to an external reporter who
  has a known GitHub handle and whose handle the team has agreed to
  credit publicly, the same rule applies. When the reporter has not
  confirmed their GitHub handle or has opted out of credit, use their
  confirmed credit form in plain text and do not `@`-mention them.

The `sync-security-issue` and `fix-security-issue` skills should
render every maintainer / security-team / release-manager reference
in the status comments they post as an `@` handle. Before publishing
a status comment, the skills must grep for names of known people and
flag any bare-name occurrence to the user.
