<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Apache Airflow — scope labels](#apache-airflow--scope-labels)
  - [Scope → CVE product / package-name table](#scope-%E2%86%92-cve-product--package-name-table)
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
