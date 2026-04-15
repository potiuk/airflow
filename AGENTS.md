<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [AGENTS instructions](#agents-instructions)
  - [Repository purpose](#repository-purpose)
  - [Local setup](#local-setup)
  - [Release branches currently in flight](#release-branches-currently-in-flight)
  - [Commit and PR conventions](#commit-and-pr-conventions)
  - [Confidentiality of `airflow-s/airflow-s`](#confidentiality-of-airflow-sairflow-s)
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

As of 2026-04-15, the Airflow release trains are:

- **Airflow `main`** — becomes the next minor release (3.3.x eventually).
- **`v3-2-test`** — patch branch for the **Airflow 3.2.x** series. 3.2.1
  has already been cut; the **next patch release from this branch is
  `3.2.2`**. New security fixes that need a patch release target this
  branch.
- **`v3-1-test`** — **no further 3.1.x releases are planned**. In particular,
  `3.1.9` will **not** be cut. The `3.1.9` milestone exists in
  `airflow-s/airflow-s` as an open milestone, but it is a legacy placeholder
  and should not be used for new security fixes.

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
  needed.
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
  deterministic `uv run` script — [`generate_cve_json.py`](.claude/skills/generate-cve-json/generate_cve_json.py) —
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
