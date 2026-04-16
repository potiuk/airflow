<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [AGENTS instructions](#agents-instructions)
  - [Repository purpose](#repository-purpose)
  - [Local setup](#local-setup)
  - [Release branches currently in flight](#release-branches-currently-in-flight)
  - [Commit and PR conventions](#commit-and-pr-conventions)
  - [Confidentiality of `airflow-s/airflow-s`](#confidentiality-of-airflow-sairflow-s)
  - [Assessing reports](#assessing-reports)
  - [Writing and editing documentation](#writing-and-editing-documentation)
  - [Reusable skills](#reusable-skills)
  - [Before submitting](#before-submitting)
  - [References](#references)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# AGENTS instructions

These instructions apply to any AI agent (or agent-assisted contributor) working on
this repository. The repository is private and hosts the Airflow security team's
processes, canned responses, and onboarding documentation — it is read by security
team members and, through the canned responses, indirectly by external reporters.
Small wording choices matter.

## Repository purpose

This repository contains:

- [`README.md`](README.md) — the end-to-end process for handling security issues reported against Apache Airflow.
- [`canned-responses.md`](canned-responses.md) — reusable replies that the security team sends to reporters.
- [`how-to-fix-a-security-issue.md`](how-to-fix-a-security-issue.md) — high-level description of the fix workflow.
- [`new-members-onboarding.md`](new-members-onboarding.md) — onboarding guide for new security team members.

There is no source code to build or test. Changes are reviewed and merged by the security team.

## Local setup

This repository uses [`prek`](https://github.com/j178/prek) (a fast, Rust-based drop-in
replacement for `pre-commit`) to run pre-commit hooks that keep the documentation
consistent — regenerating the `doctoc` tables of contents, stripping trailing whitespace,
checking line endings, and blocking accidentally committed secrets. The hook configuration
lives in [`.pre-commit-config.yaml`](.pre-commit-config.yaml).

Install `prek` once and enable the hooks in your local clone before making any changes:

```bash
uv tool install prek   # or: pipx install prek
prek install           # installs the git hook into .git/hooks/pre-commit
```

After that, every `git commit` in this repo will run the hooks automatically. You can also
run them on demand:

```bash
prek run --all-files                 # run all hooks against every file
prek run doctoc --all-files          # only regenerate TOCs
prek run --from-ref airflow-s        # run against everything changed vs the base branch
```

If a hook modifies files (for example, `doctoc` regenerating a TOC), the commit is aborted;
re-stage the modified files and commit again. **Do not bypass the hooks with `--no-verify`** —
if a hook is failing, fix the underlying issue or update the hook configuration in the same PR.

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

### Current release managers

Each Airflow release has a specific release manager (not always the same
person from one release to the next). The release manager is the committer
who prepares the release candidate, calls the VOTE on `dev@airflow.apache.org`,
closes the vote with `[RESULT][VOTE]`, and pushes the final artefacts. That
same person is also the one who sends the security advisories for every CVE
that shipped in their release to `announce@apache.org` and
`users@airflow.apache.org` (Step 12 of the security process).

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

### Known release-manager rotations

The Airflow Release Plan wiki page records the active rotation rosters
for each release train. As of 2026-04-16 they are:

- **Providers** — Jens Scheffler (@jscheffl), Jarek Potiuk (@potiuk), Vincent BECK (@vincbeck), Shahar Epstein (@shahar1)
- **Airflow Ctl** — Buğra Öztürk (@bugraoz93), Jarek Potiuk (@potiuk)
- **Helm Chart** — Jedidiah Cunningham (@jedcunningham), Jens Scheffler (@jscheffl), Buğra Öztürk (@bugraoz93), Jarek Potiuk (@potiuk)
- **Airflow 2 (core)** — Jarek Potiuk (@potiuk) (single maintainer, no rotation)

Airflow 3 (core) release managers are not yet on a fixed rotation at
the time of writing — each release is picked up individually; check
the Release Plan page for the current cut.

### Release managers for releases currently relevant to the security tracker

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

### Security team roster

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

**What this means for sync and fix skills**

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

## Commit and PR conventions

- **Never use `Co-Authored-By:` with an AI agent as co-author.** Agents are assistants, not authors. This matches the
  rule in [`apache/airflow/AGENTS.md`](https://github.com/apache/airflow/blob/main/AGENTS.md). Use a
  `Generated-by:` trailer instead, e.g.:

  ```
  Generated-by: Claude Opus 4.6 (1M context) following the guidelines at
  https://github.com/apache/airflow/blob/main/contributing-docs/05_pull_requests.rst#gen-ai-assisted-contributions
  ```

- **Always open PRs with `gh pr create --web`** so the human reviewer can check the title,
  body, and the generative-AI disclosure in the browser before submission. Pre-fill `--title`
  and `--body` (including the Gen-AI disclosure block) so they only need to review, not edit.
- **Target branch is `airflow-s`**, not `main`. The default branch of this repository is `airflow-s`;
  `main` exists only as a staging branch for the occasional private-PR workflow described in
  [`README.md`](README.md). Unless the user explicitly says otherwise, base PRs on `airflow-s`.
- Keep the commit message focused on the user-visible change, not the mechanics of how the edit
  was made.

## Confidentiality of `airflow-s/airflow-s`

The existence of this private repository, the issue numbers it contains, the
labels we use, and the discussions inside it are **not public**. Anything that
leaves the security team's private channels — public Apache Airflow PRs,
public GitHub issues, public mailing lists, public canned responses, public
release notes, public commit messages, public blog posts, **anything visible
to non-security-team members** — must not contain:

- URLs of the form `https://github.com/airflow-s/airflow-s/...`
  (issue links, PR links, discussion links, comment links);
- bare references like `airflow-s/airflow-s#NNN` or `#NNN` in a context where
  the implicit repository is `airflow-s/airflow-s`;
- the literal string `airflow-s` used as a repo or org name;
- screenshots or excerpts of the airflow-s GitHub UI;
- copy/paste of comments, labels, or milestones from this repository if doing
  so reveals that the source is the private security tracker.

These references are allowed **only** in:

- documents that live inside this private repository (this file, `README.md`,
  `canned-responses.md`, `SKILL.md` files, etc.);
- private mail threads on `security@airflow.apache.org` with the original
  reporter (where letting them know we have a tracking issue is part of the
  status update they receive);
- private mail to `private@airflow.apache.org` when escalating a stalled
  discussion per process step 4.

In particular:

- **Public `apache/airflow` PR descriptions and commit messages** must not
  reveal the CVE, the security nature of the change, or any link back to
  `airflow-s/airflow-s`. This is already required by process step 8 of
  [`README.md`](README.md) and the rule above reinforces it.
- **Canned responses** (`canned-responses.md`) must remain free of
  `airflow-s/airflow-s` URLs, because they are sent verbatim as email replies.
  If you are tempted to add one, link to the public Airflow Security Model or
  policy instead.
- **Status updates the skill drafts to reporters** *may* include the
  `airflow-s/airflow-s` tracking-issue URL — the reporter is on the private
  `security@airflow.apache.org` thread and is expected to keep it
  confidential — but the same content **must not** be reused in any public
  comment, comment to the public Airflow PR, or release-time advisory text.
- **`gh issue comment` calls inside this repository are fine** because they
  land on the private issue itself; they do not leak.

When editing or generating any text destined for a public audience, search it
for `airflow-s` and the patterns above before saving or sending. If a public
audience needs to see a tracking link for transparency, link to the **public**
artifact (the merged `apache/airflow` PR, the published CVE on `cve.org`, the
`users@` advisory archive on `lists.apache.org`) — never to the private
tracker.

## Assessing reports

### Reporter-supplied CVSS scores are informational only — never propagate them

Reporters frequently attach a CVSS vector or numeric score to their report, either
inline in the mail thread, in a private GitHub Security Advisory draft, or in the
body of the tracking issue. **Treat every reporter-supplied CVSS score as
informational background only.** Do not:

- copy the reporter's score into the tracking-issue `Severity` field;
- copy it into the CVE tool, the generated CVE JSON, the public advisory, or any
  status update to the reporter;
- repeat it in an email reply, even to confirm it.

The Airflow security team scores every accepted vulnerability independently,
as part of the CVE-allocation step, using the same CVSS version and vector
conventions we use for all Airflow CVEs. The independent score is the **only**
score that ends up in the CVE record and the public advisory. Reasons:

- reporter scores are frequently inflated (*"High"* or *"Critical"* is the
  default for many report templates, regardless of actual exploitability in
  an Airflow deployment);
- reporters typically do not know the Airflow Security Model and therefore
  misjudge which capabilities are in-scope for a CVE in the first place;
- propagating the reporter's score creates an implicit contract with them — if
  we later revise it downward, they feel the rug has been pulled, and the
  revision becomes a negotiation instead of an assessment.

Practical consequences:

- When a sync skill or any agent reads a reporter's score from the mail thread,
  a GHSA record, or an issue body, it must surface it in the *observed state*
  only ("*reporter estimated CVSS 4.0 = 7.2*"), never as a proposed value for
  the `Severity` field.
- Proposed field updates for `Severity` must either leave the field as
  `_No response_` until the team scores it independently, or come from a
  security-team member who has already done the scoring in-thread or in a
  comment on the tracking issue — not from the reporter.
- Draft replies to the reporter must not echo their score. If the reporter
  asks us to confirm their score, respond that we score every CVE
  independently during the CVE-allocation step and will share the final
  score when the public advisory is sent.

This rule applies equally to CVSS 3.x and 4.0 vectors, to qualitative labels
(*"Low"*, *"High"*, *"Critical"*), and to any self-assigned CWE the reporter
attaches alongside.

### CVE references must never point at non-public mailing-list threads

When populating the CVE record's ``references[]`` array (via the
`generate-cve-json` script or directly in the Vulnogram UI), **never
tag a URL as ``vendor-advisory`` if the URL points to a non-publicly
archived list**. The Airflow lists fall into two groups:

- **Publicly archived** on `lists.apache.org`: `users@airflow.apache.org`,
  `dev@airflow.apache.org`, `announce@apache.org`,
  `commits@airflow.apache.org`. Thread URLs on these lists resolve
  correctly for the whole world and are the right target for a
  ``vendor-advisory`` reference on the public CVE record.
- **Private**, not publicly archived: `security@airflow.apache.org`,
  `private@airflow.apache.org`. `lists.apache.org/thread/<id>` URLs
  that come from an inbound report on `security@` look identical in
  shape to public-list URLs, but they 404 for everyone outside the
  security team. They must **never** appear in the public CVE record.

Concretely, the issue template has two separate fields for this:

- The *"Security mailing list thread"* field is the **internal**
  reference for the security team: it holds the URL (or Gmail thread
  ID) of the original `security@airflow.apache.org` thread so
  triagers can navigate back to the report. It is expected to 404 for
  anyone outside the security team. Keep whatever the reporter /
  team-member put there — do **not** scrub it during sync.
- The *"Public advisory URL"* field (new as of 2026-04-16) holds the
  archive URL on `lists.apache.org/list.html?users@airflow.apache.org`
  once the public advisory has been sent (Step 12 of the process).
  This is the URL that ends up as the `vendor-advisory` reference on
  the public CVE record. Before the advisory is sent the field stays
  empty; the `sync-security-issue` skill scans the users@ archive
  for the CVE ID and proposes populating the field automatically
  once the advisory lands.

The `generate-cve-json` script enforces this split:

- It **never** pulls URLs from the *"Security mailing list thread"*
  field into `references[]`. That field is private by construction
  and stays in the issue for team navigation only.
- It **does** pull URLs from the *"Public advisory URL"* field
  automatically and tags them as `vendor-advisory`. The
  `--advisory-url` CLI flag still exists for ad-hoc overrides but
  in the normal flow the release manager populates the body field
  once, and every re-run of the generator picks it up.

Putting it differently: if a reader clicks a `vendor-advisory` link on
the public CVE record and gets a 404, the CVE record is broken.
Avoid shipping broken CVE records.

## Writing and editing documentation

The documents in this repository are short and opinionated. When editing them, prefer small,
targeted improvements over rewrites, and preserve the existing structure (including the
`doctoc`-generated tables of contents) unless the change is explicitly about structure.

### Tone: polite but firm — no room to wiggle

The canned responses in [`canned-responses.md`](canned-responses.md) are the public face of the
security team. They are often sent to reporters whose submissions have been assessed as invalid
or out of scope. The tone must be:

1. **Polite and professional.** Thank the reporter, acknowledge the intent, stay neutral.
2. **Firm and unambiguous.** State the outcome as a decision, not as a negotiation. The response
   is an expectation, not a suggestion.
3. **Free of accusation, sarcasm, and condescension.** Never imply the reporter "didn't bother
   to read", never say things like "Two reasons indicate that you did not", never tell them to
   "digest" the security model. These phrasings leave bad taste and, worse, invite argument.
4. **Free of hedging.** Avoid phrases like "feel absolutely free", "we would appreciate if you
   stopped", or "we would kindly ask you to consider" — they weaken the message and imply the
   expectation is optional. Prefer "please do not use this address for such requests" or "we are
   unable to treat this as a security issue unless…".

Concrete phrasing patterns that work well:

- Lead with: *"Thank you for the report."* Then state the outcome.
- State the decision in plain terms: *"We do not consider this a vulnerability."* / *"We cannot
  accept this report."* / *"This is explicitly out of scope for our security process."*
- Anchor the decision in an authoritative document, not in the responder's opinion:
  *"… is documented in our Security Model under '…': <link>."*
- When describing consequences of repeated policy violations, use passive, factual language:
  *"Accounts that repeatedly send reports which do not meet the policy are added to a deny list."*
  Do not threaten.
- End with a constructive alternative where one exists: *"We would welcome a PR through the
  regular contribution process."*

### Point reporters to the Security Model, don't re-explain it

The [Airflow Security Model](https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html)
is the authoritative source for what is and is not considered a security vulnerability. Canned
responses must link directly to the relevant chapter instead of paraphrasing it. Paraphrases
drift over time and create a second source of truth that has to be maintained.

Known-useful anchors:

- `#capabilities-of-dag-authors`
- `#dag-authors-executing-arbitrary-code`
- `#dag-author-code-passing-unsanitized-input-to-operators-and-hooks`
- `#limiting-dag-author-capabilities`
- `#connection-configuration-users`
- `#connection-configuration-capabilities`
- `#denial-of-service-by-authenticated-users`
- `#self-xss-by-authenticated-users`
- `#simple-auth-manager`
- `#third-party-dependency-vulnerabilities-in-docker-images`
- `#automated-scanning-results-without-human-verification`

When adding a new canned response, identify the matching chapter in the Security Model first.
If no chapter covers the case, that is a signal the Security Model should be updated in
[`apache/airflow`](https://github.com/apache/airflow) rather than duplicated here.

### Linking CVEs

Whenever a CVE ID appears in text this repository produces — status comments
on `airflow-s` issues, proposals from the `sync-security-issue` skill, recap
messages, canned-response drafts to reporters, internal notes — render it as
a **clickable link**, not as bare text. The canonical link is the ASF CVE
tool entry, which any security team member can click through to the live
CVE record we control:

```
https://cveprocess.apache.org/cve5/<CVE-ID>
```

Example:

> [`CVE-2026-40690`](https://cveprocess.apache.org/cve5/CVE-2026-40690)

For CVEs that have already been **published** (the advisory has been sent
to `users@airflow.apache.org`, the issue carries `vendor-advisory`, and the
CVE record is visible on public databases), additionally link to the public
`cve.org` / MITRE record so non-security-team readers can see the public
description without needing access to the ASF tool:

```
https://www.cve.org/CVERecord?id=<CVE-ID>
```

A published CVE should appear with both links, for example:

> `CVE-2025-50213` ([ASF](https://cveprocess.apache.org/cve5/CVE-2025-50213),
> [cve.org](https://www.cve.org/CVERecord?id=CVE-2025-50213))

`https://nvd.nist.gov/vuln/detail/<CVE-ID>` is an acceptable alternative to
`cve.org` once NVD has scored the record. Before publication, `cve.org`
shows the CVE as RESERVED with no details — skip the public link in that
case and link only to the ASF tool.

**Confidentiality**, as a cross-reference to the
"Confidentiality of `airflow-s/airflow-s`" section above:

- ASF CVE tool links are fine inside `airflow-s/airflow-s` private
  comments and in private mail to the reporter on
  `security@airflow.apache.org` — the tool is team-internal and does not
  reveal anything beyond the CVE ID itself.
- Public `apache/airflow` PR descriptions, public mailing-list posts, and
  any other public surface **must not** link to the ASF CVE tool before the
  advisory is sent — doing so implies the existence of the private tracking
  issue. Once the advisory is public, link only to `cve.org` (or NVD),
  never to the ASF tool.

When editing an existing document that contains a bare `CVE-YYYY-NNNNN`
string, convert it to the linked form in the same edit.

### Linking `airflow-s/airflow-s` issues and PRs

Whenever a reference to an `airflow-s/airflow-s` issue, pull request,
comment, or discussion appears in text this repository produces — sync /
fix skill proposals, status comments on the private issue itself, recap
messages, internal notes, `SKILL.md` files — render it as a **clickable
markdown link**, not as a bare `#NNN` or `airflow-s/airflow-s#NNN`. The
URL format is:

```
https://github.com/airflow-s/airflow-s/issues/<N>
https://github.com/airflow-s/airflow-s/pull/<N>
https://github.com/airflow-s/airflow-s/issues/<N>#issuecomment-<C>
```

Preferred rendering:

> [`airflow-s/airflow-s#221`](https://github.com/airflow-s/airflow-s/issues/221)

or, when the repository is already obvious from context (for example
inside a comment on `airflow-s/airflow-s#221` itself):

> [`#221`](https://github.com/airflow-s/airflow-s/issues/221)

Link both the number *and* any referenced comment / review by using the
per-comment anchor:

> [`airflow-s/airflow-s#216 — issuecomment-4252393493`](https://github.com/airflow-s/airflow-s/issues/216#issuecomment-4252393493)

**Confidentiality, as always**, takes precedence: these rendered links
are *only* allowed inside this private repository and in private mail
threads on `security@airflow.apache.org` — they are **never** permitted
in public `apache/airflow` PR descriptions, public mailing-list posts,
public canned responses, or anywhere else a non-security-team member
could see them. See the "Confidentiality of `airflow-s/airflow-s`"
section above. The scrubbing grep the `fix-security-issue` skill runs
before pushing anything public is the final line of defence and must
catch any stray `airflow-s` URL or `airflow-s#NNN` reference that slips
into public text.

When editing an existing document in this repo that contains a bare
`#NNN` or `airflow-s/airflow-s#NNN`, convert it to the linked form in
the same edit. Skill-generated output (sync proposals, issue comments,
email drafts to reporters on the `security@` thread) must emit the
linked form from the start — bare references are a miss.

### Mentioning Airflow maintainers and security-team members

When writing text that lands on a GitHub issue or PR and refers to a
specific Airflow maintainer, committer, release manager, or
security-team member, **use the person's GitHub handle with the
leading ``@`` so GitHub notifies them**. Simply writing their name in
plain text does not fire a notification, and the whole point of
mentioning the person is usually that they own the next step or are
the right reviewer. Agent-generated status comments, PR bodies, sync
recaps, fix-PR follow-up comments, and draft-advisory text should all
follow the rule.

Concretely:

- **GitHub handle, not plain name**: write ``@jscheffl``, not
  *"Jens Scheffler"*, in a GitHub surface. It is fine to keep the
  plain name in the same sentence for readability as long as the
  ``@``-mention is present somewhere: *"The next providers wave is
  cut by Jens Scheffler (@jscheffl)"*.
- **Which people the rule applies to**: Airflow PMC members,
  committers, release managers listed in
  [the "Current release managers" section above](#current-release-managers),
  and members of the security team. Current release managers and the
  providers / Airflow Ctl / Helm Chart rotation rosters are listed in
  that section with their GitHub handles — use those as the
  authoritative source.
- **Which surfaces the rule applies to**: public ``apache/airflow`` PR
  comments/bodies; private ``airflow-s/airflow-s`` issue comments and
  status comments; sync recaps printed back to the user that call out
  a specific person. It does **not** apply to email text on
  ``security@airflow.apache.org`` (those go to the reporter and the
  list, not through GitHub's notification system).
- **Public-surface caveat**: the confidentiality rules in
  [the "Confidentiality of ``airflow-s/airflow-s``" section](#confidentiality-of-airflow-sairflow-s)
  still bind. In a **public** ``apache/airflow`` PR or comment, a
  mention must stand on its own — it must not be accompanied by any
  of the forbidden terms (``CVE-``, ``airflow-s``, *"security fix"*,
  etc.) that would reveal the private nature of the coordination.
- **External reporters**: when referring to an external reporter who
  has a known GitHub handle and whose handle the team has agreed to
  credit publicly, the same rule applies. When the reporter has not
  confirmed their GitHub handle or has opted out of credit, use their
  confirmed credit form in plain text and do not ``@``-mention them.

The sync-security-issue and fix-security-issue skills should render
every maintainer / security-team / release-manager reference in the
status comments they post as an ``@`` handle. Before publishing a
status comment, the skills must grep for names of known people and
flag any bare-name occurrence to the user.

### Other editorial guidelines

- Do not include concrete contributor counts (e.g., "4000 contributors", "3600 contributors").
  Use *"thousands of contributors"* — the number changes constantly and hard-coding it dates the
  document immediately.
- Use **`Dag`** (not `DAG`) when referring to Airflow DAGs in prose — e.g. *"Dag author"*,
  *"Dag run"*, *"serialized Dags"*. This matches the Airflow Security Model chapter titles
  (*"Capabilities of Dag authors"*, *"Dag authors executing arbitrary code"*, etc.) and the
  convention used throughout `apache/airflow`'s own documentation and `AGENTS.md`. Do not
  use the all-caps `DAG` form in documentation in this repository; leave it only inside
  quoted content, URLs, anchor slugs, or code identifiers where it already appears.
- Prefer *PoC*, *DoS*, *CVE* as the canonical capitalisations for those acronyms.
- Use em dashes (`—`) sparingly; prefer shorter sentences to dash-heavy ones.
- Preserve the `doctoc` TOC markers at the top of each document. If you rename a heading, update
  the corresponding TOC entry in the same change.
- Do not add emojis.

## Reusable skills

Reusable, agent-friendly task definitions live under
[`.claude/skills/`](.claude/skills/). Each skill is a plain Markdown file with
YAML frontmatter, so it can be picked up by Claude Code, GitHub Copilot, and any
other agent that follows the emerging skill convention. When a new recurring
task is automated, add it as a skill rather than burying the instructions in a
commit message or an ad-hoc comment.

Currently available:

- [`sync-security-issue`](.claude/skills/sync-security-issue/SKILL.md) —
  reconciles a security issue with its GitHub discussion, its
  `security@airflow.apache.org` mail thread, and any fixing PRs; proposes label,
  milestone, field, and draft-email updates; and prompts the user to confirm each
  change before applying it. Prints the ASF CVE allocation link when a CVE is
  needed. **At the end of every run** it also invokes
  [`generate-cve-json`](.claude/skills/generate-cve-json/SKILL.md) with
  `--attach` to refresh the CVE JSON attachment on the tracking issue (auto-
  resolving `--remediation-developer` from the first apache/airflow PR author
  in the *PR with the fix* body field), so the attached JSON stays in
  lock-step with the issue body. Skipped only when no CVE has been allocated
  yet, or when the issue has been closed as invalid / not-CVE-worthy / duplicate.
- [`fix-security-issue`](.claude/skills/fix-security-issue/SKILL.md) — runs
  `sync-security-issue` first, then analyses the issue discussion to decide
  whether the reported problem is easily fixable (clear consensus, small scope,
  known location). If it is, proposes an implementation plan, writes the change
  in the user's local `apache/airflow` clone, runs local checks and tests, and
  opens a public PR via `gh pr create --web`. Every public surface (commit
  message, branch name, PR title, PR body, newsfragment) is scrubbed for CVE /
  `airflow-s` / `vulnerability` / `security fix` leakage before being written or
  pushed. Updates the `airflow-s` tracking issue with the new PR link afterwards.
- [`generate-cve-json`](.claude/skills/generate-cve-json/SKILL.md) — generates
  a paste-ready CVE 5.x JSON record from a tracking issue, matching the shape
  Vulnogram exports (`containers.cna` with `affected`, `descriptions` + HTML
  `supportingMedia`, `problemTypes` with `type: "CWE"`, `metrics.other`,
  tagged `references`, `providerMetadata.orgId`, `cveMetadata` envelope). A
  deterministic `uv run` script — [the `generate-cve-json` project](.claude/skills/generate-cve-json/) —
  parses the issue's template fields (multiple credits on separate lines,
  multiple reference URLs, `>= X, < Y` version ranges), writes the JSON to a
  file, and prints the Vulnogram `#json` paste URL for the CVE. The ASF CVE
  tool URL and any `airflow-s` URLs are filtered out of `references[]`
  before serialising.

When adding a new skill:

- place it under `.claude/skills/<skill-name>/SKILL.md`;
- start with YAML frontmatter containing `name`, `description`, and `when_to_use`;
- make every state-changing action a *proposal* that requires explicit user
  confirmation before it runs;
- avoid agent-specific syntax so the skill remains portable across tools.

## Before submitting

- Re-read the diff and check that every change is intentional.
- Check that any renamed headings have matching TOC updates.
- Verify that links to the Airflow Security Model use an anchor that exists on the current
  stable version.
- Self-review the tone of any modified canned response against the "polite but firm" guidance above.

## References

- [`apache/airflow/AGENTS.md`](https://github.com/apache/airflow/blob/main/AGENTS.md) — the parent convention these instructions mirror.
- [Airflow Security Model](https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html) — authoritative source for what is and is not a vulnerability.
- [Airflow security policy](https://github.com/apache/airflow/security/policy) — public-facing rules reporters are expected to follow.
