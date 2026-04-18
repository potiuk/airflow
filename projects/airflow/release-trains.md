<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Apache Airflow — release trains, release managers, security team roster](#apache-airflow--release-trains-release-managers-security-team-roster)
  - [Release branches currently in flight](#release-branches-currently-in-flight)
  - [Current release managers](#current-release-managers)
  - [Known release-manager rotations](#known-release-manager-rotations)
  - [Release managers for releases currently relevant to the security tracker](#release-managers-for-releases-currently-relevant-to-the-security-tracker)
  - [Security team roster](#security-team-roster)
  - [What this means for sync and fix skills](#what-this-means-for-sync-and-fix-skills)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# Apache Airflow — release trains, release managers, security team roster

This file is the project-specific, fast-moving state that the skills
read to decide *which branches do we back fixes to*, *who is the
release manager of the next cut*, and *who is currently on the
security team*. It is referenced from
[`project.md`](project.md) (identity / repositories) and from
the generic repo-level [`../../AGENTS.md`](../../AGENTS.md) (agent
conventions).

When any of the facts below changes — a new release has shipped, a
new train opens or closes, a security-team member joins or rotates
off — update this file in the same change.

## Release branches currently in flight

As of 2026-04-16, the Airflow release trains are:

- **Airflow `main`** — becomes the next minor release (3.3.x eventually).
  Note: as of Airflow 3.3 the **Task SDK** ships as a separately-released
  component rather than being bundled into `apache-airflow` (the `Task
  SDK 1.2.0` release alongside `3.2.0` was the last one shipped jointly).
  Through 3.2.x, Task SDK code is part of the `apache-airflow` package and
  a security report that only touches the Task SDK is therefore classified
  under the `airflow` scope. Once a Task SDK-specific report lands against
  3.3+, introduce a new `task-sdk` scope label and extend the
  sync-security-issue skill's scope list accordingly.
- **`v3-2-test`** — patch branch for the **Airflow 3.2.x** series. 3.2.1
  has already been cut; the **next patch release from this branch is
  `3.2.2`**. New security fixes that need a patch release target this
  branch.
- **`v3-1-test`** — **no further 3.1.x releases are planned**. In particular,
  `3.1.9` will **not** be cut. The `3.1.9` milestone exists in
  `airflow-s/airflow-s` as an open milestone, but it is a legacy placeholder
  and should not be used for new security fixes.

## Current release managers

Each Airflow release has a specific release manager (not always the same
person from one release to the next). The release manager is the committer
who prepares the release candidate, calls the VOTE on `dev@airflow.apache.org`,
closes the vote with `[RESULT][VOTE]`, and pushes the final artefacts. That
same person is also the one who sends the security advisories for every CVE
that shipped in their release to `announce@apache.org` and
`users@airflow.apache.org` (Step 13 of the security process).

**Do not assume or guess the release manager.** Two authoritative sources,
in the order they should be consulted:

1. **The Airflow Release Plan wiki**:
   <https://cwiki.apache.org/confluence/display/AIRFLOW/Release+Plan>.
   This is the canonical forward-looking schedule for every release train
   (core Airflow, Providers, Airflow Ctl, Helm Chart, Airflow 2), and it
   lists the release manager for each upcoming cut along with the planned
   cut date. Check this page first when the question is *"who is
   responsible for the next advisory on release X?"*.
2. **The `[RESULT][VOTE]` thread on `dev@airflow.apache.org`** — the
   sender of the `[RESULT][VOTE] Release Airflow <version>` (or
   `[RESULT][VOTE] Airflow Providers - release preparation date <YYYY-MM-DD>`)
   message **is** the release manager for that specific cut. Use this
   when the release has already shipped (the Release Plan wiki only
   tracks the upcoming schedule). Archive search URL:
   <https://lists.apache.org/list.html?dev@airflow.apache.org>.

## Known release-manager rotations

The Airflow Release Plan wiki page records the active rotation rosters
for each release train. As of 2026-04-16 they are:

- **Providers** — Jens Scheffler (@jscheffl), Jarek Potiuk (@potiuk), Vincent BECK (@vincbeck), Shahar Epstein (@shahar1)
- **Airflow Ctl** — Buğra Öztürk (@bugraoz93), Jarek Potiuk (@potiuk)
- **Helm Chart** — Jedidiah Cunningham (@jedcunningham), Jens Scheffler (@jscheffl), Buğra Öztürk (@bugraoz93), Jarek Potiuk (@potiuk)
- **Airflow 2 (core)** — Jarek Potiuk (@potiuk) (single maintainer, no rotation)

Airflow 3 (core) release managers are not yet on a fixed rotation at
the time of writing — each release is picked up individually; check
the Release Plan page for the current cut.

## Release managers for releases currently relevant to the security tracker

- **Airflow 3.2.0** (core, shipped 2026-04-07) — **Rahul Vats**
  (`rah.sharma11@gmail.com`, GitHub: `vatsrahul1001`). Source: his
  `[RESULT][VOTE] Release Airflow 3.2.0 from 3.2.0rc2 & Task SDK 1.2.0
  from 1.2.0rc2` on `dev@airflow.apache.org`, 2026-04-07. Responsible
  for the advisories for CVE-2026-30898, CVE-2026-30912, CVE-2026-31987,
  CVE-2026-32228, CVE-2026-32690 and any other CVE that shipped in 3.2.0.
- **Airflow Providers — release preparation date 2026-03-24** (wave that
  shipped `apache-airflow-providers-keycloak` 0.7.0 on 2026-03-28) —
  **Jens Scheffler** (`jscheffl@apache.org`, GitHub: `jscheffl`). Source:
  his `[RESULT][VOTE] Airflow Providers - release preparation date
  2026-03-24` on `dev@airflow.apache.org`, 2026-03-28. Responsible for
  the advisory for CVE-2026-40948 (Keycloak OAuth login-CSRF).
- **Airflow Providers — release preparation date 2026-04-08** (wave that
  shipped `apache-airflow-providers-keycloak` 0.7.1 on 2026-04-12) —
  **Jarek Potiuk** (`jarek@potiuk.com`, GitHub: `potiuk`). Source: the
  `[VOTE] Airflow Providers, release preparation date 2026-04-08` thread
  on `dev@airflow.apache.org`. Relevant as the "forward-carry" owner for
  CVE-2026-40948 since 0.7.1 is now the current Keycloak provider
  version users should upgrade to.

When you update this list (because a new release has shipped), record
the date the release went out and the archive link to the
`[RESULT][VOTE]` thread so the attribution is auditable. Update the
rotation rosters above whenever the Release Plan wiki page changes.

## Security team roster

The authoritative source for **who is a member of the Airflow security
team** is the collaborator list of the private
[`airflow-s/airflow-s`](https://github.com/airflow-s/airflow-s)
repository — **anyone listed as a collaborator**, regardless of
permission level (read, triage, write, maintain, admin), is on the
security team. Do not filter by permission level; some members have
triage or read access and still actively participate in assessments,
fixes, and advisory coordination.

Look it up with:

```bash
gh api repos/airflow-s/airflow-s/collaborators --jq '.[].login'
```

Snapshot as of 2026-04-16 (GitHub handles, 24 people): `ashb`,
`raboof`, `potiuk`, `uranusjr`, `ephraimbuddy`, `Lee-W`, `sunank200`,
`kaxil`, `bugraoz93`, `ch4n3-yoon`, `pierrejeambrun`, `hussein-awala`,
`aritra24`, `amoghrajesh`, `happyhacking-k`, `vatsrahul1001`,
`eladkal`, `shubhamraj-git`, `shahar1`, `jedcunningham`, `sjyangkevin`,
`jscheffl`, `vincbeck`, `pankajastro` (plus the `airflow-sec` service
account, which is not a person).

When this list becomes stale (a new member is added, someone rotates
off), re-run the `gh api` call above and update the snapshot in the
same change. The snapshot is the fast lookup; the `gh api` call is the
authoritative truth.

## What this means for sync and fix skills

- When selecting a milestone for a newly-triaged security issue, default to
  **`3.2.2`** (via the `v3-2-test` backport) for anything that needs a patch
  release. Do **not** propose `3.1.9` unless the user explicitly asks for
  it. If the `sync-security-issue` skill finds an issue currently parked on
  `3.1.9` (or on `3.2.1` now that it has been cut), propose moving it to
  `3.2.2`.
- When selecting backport labels on public `apache/airflow` PRs, use
  `backport-to-v3-2-test` only — do **not** also apply
  `backport-to-v3-1-test` by default. A `v3-1-test` backport is only
  appropriate if the user explicitly requests it for a specific issue and
  is prepared to cut a 3.1.x patch release out-of-band.
- If the `3.2.2` milestone does **not** yet exist in `airflow-s/airflow-s`
  when the skill needs it, create it via `gh api` and then assign the issue
  to it — see the "Maintaining milestones and labels" section of the
  `fix-security-issue` skill.
- This section is the authoritative answer to *"which branches do we back
  fixes to?"* — when this changes (for example, when 3.3.x is cut, when
  `3.2.2` is released, or when `v3-2-test` goes into patch-only mode),
  update it in the same change that ships the release.
