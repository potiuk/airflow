<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Apache Airflow — scope labels](#apache-airflow--scope-labels)
  - [Scope → CVE product / package-name table](#scope-%E2%86%92-cve-product--package-name-table)
  - [*Affected versions* convention by scope](#affected-versions-convention-by-scope)
  - [Default `packageName` and vendor](#default-packagename-and-vendor)
  - [Closing dispositions (not scope labels)](#closing-dispositions-not-scope-labels)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# Apache Airflow — scope labels

Apache Airflow uses a small, finite set of **scope labels** applied at
Step 5 of the handling process (valid/invalid consensus landed). The
scope pins the tracker to one product the CVE will be allocated against
and drives:

- which release train the fix backports to (see
  [`release-trains.md`](release-trains.md));
- which milestone format the tracker is assigned (see
  [`milestones.md`](milestones.md));
- which `product` / `packageName` the CVE record uses
  (see table below).

**Exactly one** scope label is set per tracker. If a report affects
more than one scope, the `sync-security-issue` skill surfaces this as
a blocker and the triager splits the report into per-scope trackers
before allocation (never after — fixing the scope of an already-
allocated CVE requires Vulnogram + release-manager cleanup).

## Scope → CVE product / package-name table

| Tracker scope label | Vulnogram product | CVE container `packageName` | Collection URL |
|---|---|---|---|
| `airflow` | `Apache Airflow` | `apache-airflow` | <https://pypi.python.org> |
| `providers` | `Apache Airflow Providers <Provider>` — detect the specific provider from the tracker body (e.g. `Elasticsearch`, `CNCF Kubernetes`, `SMTP`, `Celery`) | `apache-airflow-providers-<name>` | <https://pypi.python.org> |
| `chart` | `Apache Airflow Helm Chart` | `apache-airflow-helm-chart` | <https://airflow.apache.org/> |
| `task-sdk` (Airflow 3.3+) | `Apache Airflow Task SDK` | `apache-airflow-task-sdk` | <https://pypi.python.org> |

The `task-sdk` scope is not yet active — through Airflow 3.2.x the
Task SDK code ships as part of `apache-airflow` and a Task-SDK-only
report is classified under `airflow`. See
[`release-trains.md`](release-trains.md) for the note on when this
changes.

## *Affected versions* convention by scope

The shape of the *Affected versions* body field on a tracker depends
on the scope, because each scope's milestone signal carries different
information about the next-fix version.

| Scope | Convention | Why |
|---|---|---|
| `airflow` | Concrete `< X.Y.Z` upper bound from day one (e.g. `< 3.2.2`). | The core release milestone (`Airflow 3.2.2`) is the version number, so the next-fix version is known the moment the tracker is assessed. |
| `chart` | Same as `airflow` (`< X.Y.Z`). | The Helm chart milestone is also a version number. |
| `providers` | Use the `< NEXT VERSION` placeholder until `fix released` (per package, one line per affected provider). | The wave milestone (`Providers YYYY-MM-DD`) is a date, not a version; the per-package version that ships the fix is decided by the release manager during the wave. The literal token `NEXT VERSION` is the project's sentinel for "fix not yet released, upper bound unknown". |

For providers, the lifecycle is:

1. **At triage:** sync proposes populating *Affected versions* with one
   line per affected package — `<package-name> < NEXT VERSION`.
   Combine with a known lower bound where applicable (e.g.
   `apache-airflow-providers-smtp >= 2.0.0, < NEXT VERSION`).
2. **At `fix released`:** the wave has shipped to PyPI. Sync looks up
   the released version with
   `curl -s https://pypi.org/pypi/<package-name>/json | jq -r '.info.version'`
   and proposes replacing each `NEXT VERSION` with the actual
   `< X.Y.Z` upper bound.
3. **At regen:** the CVE JSON generator strips `NEXT VERSION` before
   parsing. Pre-release: `versions[]` entry has no `lessThan` (open-
   ended upper bound, "no fix released yet"). Post-release: standard
   fully-bounded entry.

The full lifecycle and the signal-table rows that drive each
transition live in
[`../../.claude/skills/sync-security-issue/SKILL.md`](../../.claude/skills/sync-security-issue/SKILL.md);
the parser-side handling lives in
[`../../tools/vulnogram/generate-cve-json/SKILL.md`](../../tools/vulnogram/generate-cve-json/SKILL.md).

## Default `packageName` and vendor

- `vendor`: Apache Software Foundation
- `packageName` for untagged / uncertain reports: `apache-airflow`

These defaults are declared in [`project.md`](project.md) under
*Identity* and *CVE tooling*; the CVE-JSON generator reads them from
there.

## Closing dispositions (not scope labels)

`invalid`, `not CVE worthy`, `duplicate`, and `wontfix` are **closing
dispositions**, not scope labels. They are set at Step 5 or Step 6 of
the process when the tracker leaves the flow without a CVE. They do
not imply a product and never end up in the Vulnogram product field.
