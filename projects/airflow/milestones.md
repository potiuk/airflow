<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Apache Airflow — milestone conventions](#apache-airflow--milestone-conventions)
  - [Creating a missing milestone](#creating-a-missing-milestone)
  - [Defaults and policy](#defaults-and-policy)
  - [What the milestone unlocks](#what-the-milestone-unlocks)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# Apache Airflow — milestone conventions

Airflow uses GitHub milestones on the private `airflow-s/airflow-s`
tracker to pin an issue to the release it ships in. Milestones are
the hand-off signal from the remediation developer to the release
manager; the `sync-security-issue` skill creates and assigns them as
part of the `pr merged` → `fix released` transition.

Three milestone formats exist, matching the three release trains
(core / providers / Helm chart):

| Milestone format | Applies to scope label | Example | Source of the version |
|---|---|---|---|
| `Airflow-X.Y.Z` | `airflow` | `Airflow-2.6.2`, `3.2.2` | Release Plan wiki; `dev@` `[VOTE]` thread |
| `Providers YYYY-MM-DD` | `providers` | `Providers 2026-03-24` | Release Plan wiki **cut date**, not PyPI publish date |
| `Chart-X.Y.Z` | `chart` | `Chart-1.9.0` | Release Plan wiki |

Authoritative source for the current value of each: the
[Airflow Release Plan wiki](https://cwiki.apache.org/confluence/display/AIRFLOW/Release+Plan);
the `[RESULT][VOTE]` thread on `dev@airflow.apache.org` once the
release has shipped. See [`release-trains.md`](release-trains.md) for
the currently-in-flight release branches and the currently-assigned
release managers.

## Creating a missing milestone

New milestones are created on demand. The `sync-security-issue` skill
creates a missing provider-wave milestone via `gh api` in the same
proposal as the milestone assignment:

```bash
gh api -X POST repos/airflow-s/airflow-s/milestones \
  -f title="Providers 2026-03-24"
```

The maintenance rules and the create-and-assign recipe live in the
`fix-security-issue` skill's *Maintaining milestones and labels*
section.

## Defaults and policy

- The default milestone for a newly-triaged `airflow`-scope security
  issue that needs a patch release is the next patch of the currently
  active `v3-2-test` branch (as of 2026-04-16: `Airflow-3.2.2`). The
  current default is declared in [`release-trains.md`](release-trains.md).
- `3.1.9` is a legacy placeholder and must not be used for new
  security fixes unless the user explicitly requests a 3.1.x patch.
- Sometimes, as a result of the triage discussions, a fix should not
  be applied in the next patch-level release — for example, because
  of high risk involved or because it needs to be correlated with
  other changes. In such cases the milestone is set to the next
  **minor** release rather than the next patch-level release.

## What the milestone unlocks

Once the milestone is set on a `pr merged` tracker, the
`sync-security-issue` skill watches for the release to ship (via
PyPI / the Helm registry) and proposes the `pr merged` → `fix
released` label swap, which hands ownership off to the release
manager for steps 13–15. See the repo-level
[`../../README.md`](../../README.md) for the step-by-step lifecycle.
