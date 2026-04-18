<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [AGENTS instructions](#agents-instructions)
  - [Repository purpose](#repository-purpose)
  - [Per-project configuration](#per-project-configuration)
  - [Local setup](#local-setup)
  - [Commit and PR conventions](#commit-and-pr-conventions)
  - [Confidentiality of `airflow-s/airflow-s`](#confidentiality-of-airflow-sairflow-s)
  - [Assessing reports](#assessing-reports)
    - [Reporter-supplied CVSS scores are informational only — never propagate them](#reporter-supplied-cvss-scores-are-informational-only--never-propagate-them)
    - [CVE references must never point at non-public mailing-list threads](#cve-references-must-never-point-at-non-public-mailing-list-threads)
  - [Writing and editing documentation](#writing-and-editing-documentation)
    - [Tone: polite but firm — no room to wiggle](#tone-polite-but-firm--no-room-to-wiggle)
    - [Brevity: emails state facts, not context](#brevity-emails-state-facts-not-context)
    - [Threading: drafts stay on the inbound Gmail thread](#threading-drafts-stay-on-the-inbound-gmail-thread)
    - [ASF-security-relay reports: a special case for drafting](#asf-security-relay-reports-a-special-case-for-drafting)
    - [Point reporters to the project's Security Model, don't re-explain it](#point-reporters-to-the-projects-security-model-dont-re-explain-it)
    - [Linking CVEs](#linking-cves)
    - [Linking `airflow-s/airflow-s` issues and PRs](#linking-airflow-sairflow-s-issues-and-prs)
    - [Mentioning project maintainers and security-team members](#mentioning-project-maintainers-and-security-team-members)
    - [Other editorial guidelines](#other-editorial-guidelines)
  - [Reusable skills](#reusable-skills)
  - [Before submitting](#before-submitting)
  - [References](#references)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# AGENTS instructions

These instructions apply to any AI agent (or agent-assisted contributor) working on
this repository. The repository hosts a generic, reusable framework for handling
security issues for Apache Software Foundation (ASF) projects, currently
configured for **Apache Airflow**. Processes, canned responses, and onboarding
documentation are read by security team members and, through the canned
responses, indirectly by external reporters. Small wording choices matter.

## Repository purpose

The repo has two layers:

1. **Generic** — project-agnostic process, agent conventions, and skill
   definitions. Lives at the repo root and under `.claude/skills/`.
2. **Project-specific** — the currently-active project's identity,
   roster, release trains, canned responses, security-model references,
   and milestone conventions. Lives under [`projects/<name>/`](projects/).
   The active project is declared in
   [`config/active-project.md`](config/active-project.md).

Repo-root files:

- [`README.md`](README.md) — the end-to-end process for handling security issues (generic lifecycle).
- [`how-to-fix-a-security-issue.md`](how-to-fix-a-security-issue.md) — high-level description of the fix workflow.
- [`new-members-onboarding.md`](new-members-onboarding.md) — onboarding guide for new security team members.
- [`config/active-project.md`](config/active-project.md) — declares which project under `projects/` this working tree targets.
- [`projects/<active>/`](projects/) — project-specific content (canned responses, release trains, security model, milestones, …).

There is no source code to build or test. Changes are reviewed and merged by the security team.

## Per-project configuration

Every project-specific fact the skills need is declared in a single
manifest per project. For the currently active project, see
[`projects/airflow/project.md`](projects/airflow/project.md). The manifest
lists:

- project identity (vendor, product, URLs);
- repositories (tracker repo, upstream repo, default branches);
- mailing lists (security, private, public, dev, announce);
- tools enabled (GitHub, Gmail, Vulnogram, …);
- CVE tooling (allocation URL, record URL template, CNA container defaults);
- pointers to the other files in the project directory (release trains,
  scope labels, milestones, security model, title-normalisation rules,
  canned responses, fix workflow, naming conventions).

When this document (or any skill) says *"the tracker repo"*, *"the
upstream repo"*, *"the security list"*, *"the canned responses"*,
it means the value declared in `projects/<active>/project.md` and
its sibling files. When a fact is truly project-agnostic (a lifecycle
rule, a confidentiality principle, a brevity rule), it lives in this
file or in [`README.md`](README.md).

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

## Commit and PR conventions

- **Never use `Co-Authored-By:` with an AI agent as co-author.** Agents are
  assistants, not authors. Use a `Generated-by:` trailer instead. The exact
  trailer wording is project-specific — for the currently active project see
  [`projects/airflow/fix-workflow.md`](projects/airflow/fix-workflow.md#commit-trailer).
- **Always open PRs with `gh pr create --web`** so the human reviewer can check the title,
  body, and the generative-AI disclosure in the browser before submission. Pre-fill `--title`
  and `--body` (including the Gen-AI disclosure block) so they only need to review, not edit.
- **Target branch for this repository is declared in the project manifest** — see
  [`projects/airflow/project.md`](projects/airflow/project.md#repositories)
  (`tracker_default_branch`). The non-default branch (`main`) is used only as a
  staging branch for the private-PR fallback described in
  [`README.md`](README.md). Unless the user explicitly says otherwise, base
  PRs on the tracker's default branch.
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
  `projects/<active>/canned-responses.md`, `SKILL.md` files, etc.);
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
- **Canned responses**
  ([`projects/airflow/canned-responses.md`](projects/airflow/canned-responses.md))
  must remain free of `airflow-s/airflow-s` URLs, because they are sent
  verbatim as email replies. If you are tempted to add one, link to the
  project's public Security Model or security policy instead — see
  [`projects/airflow/security-model.md`](projects/airflow/security-model.md).
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
- The *"Public advisory URL"* field holds the
  archive URL on `lists.apache.org/list.html?users@airflow.apache.org`
  once the public advisory has been sent (Step 13 of the process).
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

The canned responses in
[`projects/airflow/canned-responses.md`](projects/airflow/canned-responses.md)
are the public face of the security team. They are often sent to reporters
whose submissions have been assessed as invalid or out of scope. The tone
must be:

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

### Brevity: emails state facts, not context

Every outbound email drafted by a skill — status updates to reporters,
escalation messages to `private@airflow.apache.org`, relay requests to
PMC members, communications to the ASF security team (`cve-managers@`,
`security@apache.org`) — must be **short and factual**. The recipient
already has the context; the point of the message is to deliver new
information.

**Baseline shape.** A status-update email to a reporter should fit in
three short paragraphs or less:

1. One sentence stating **what changed** (CVE allocated, fix PR
   opened, advisory sent, etc.).
2. One sentence stating **what comes next** and roughly when (e.g.
   *"The advisory will be sent once the fix ships, currently expected
   with Airflow 3.2.2."*).
3. The relevant **artifact URLs** on their own line(s) — CVE tool
   link, PR URL, advisory archive URL — per the linking rules in
   [Linking CVEs](#linking-cves) and
   [Linking `airflow-s/airflow-s` issues and PRs](#linking-airflow-sairflow-s-issues-and-prs).
   Gmail autolinks bare URLs; do not use markdown or shorthand.

That is the entire body. No re-introduction of the vulnerability, no
recap of earlier messages on the same thread, no explanation of the
handling process, no speculation about severity or timelines beyond
the single forward-looking sentence in paragraph 2.

**Emails to the ASF security team are even shorter.** The ASF CVE
managers and the ASF security team already know the Airflow process,
the Vulnogram tool, and the CVE-5 schema. A message to them is a
**request or a fact**, not a briefing:

- Lead with the ask or the fact in one sentence (*"Please push the
  attached credit correction to cve.org for CVE-YYYY-NNNNN."*).
- Include only the minimum artifact the recipient needs to act (the
  CVE ID, the corrected JSON, the archive URL) — one link, maybe two.
- Do **not** restate the vulnerability, the Airflow release train, or
  the history of the ticket.
- Do **not** explain why the ASF team's action is needed when their
  role in the process is already established (e.g. pushing to cve.org,
  allocating a CVE from a PMC-gated form).

**What to omit in every drafted email, reporter or otherwise:**

- The vulnerability description or attack narrative — the recipient
  read it in the previous message on the thread or knows it from the
  tracker.
- A recap of earlier status updates ("As you know, we confirmed
  validity on X and allocated the CVE on Y…").
- Security-model paraphrasing — link to the chapter, do not
  re-explain (per
  [Point reporters to the Security Model, don't re-explain it](#point-reporters-to-the-security-model-dont-re-explain-it)).
- Inflated closings ("We greatly appreciate your continued
  patience…"). A plain *"Thanks,"* / *"Regards,"* is enough.
- Any open question that was already asked on the thread and is
  still awaiting a reply (see the "Do not re-ask" rule in the
  `sync-security-issue` skill — pinging twice gets us blocklisted).

**Exception: the initial receipt-of-confirmation reply.** The first
message the security team sends to a new reporter, drafted by the
`import-security-issue` skill, uses the *"Confirmation of receiving
the report"* canned response from
[`projects/airflow/canned-responses.md`](projects/airflow/canned-responses.md)
**verbatim**. That template is longer because it introduces the process
to a reporter who has not yet seen it and carries the credit-preference
question; leave it alone and do not trim it per this brevity rule.

Everything else — every follow-up, every status update, every relay
to a PMC member, every message to the ASF security team — falls
under this rule.

### Threading: drafts stay on the inbound Gmail thread

Every drafted email that relates to a tracking issue **must** be
created on the original inbound Gmail thread — the thread whose
`threadId` was recorded when the tracker was imported. Gmail does
**not** thread by subject string; a `Re: <subject>` fabricated
locally will not attach to any existing thread. Threading is bound
by `threadId` or by the MIME `In-Reply-To` / `References` headers,
and the Gmail API abstracts both via the `threadId` parameter to
`mcp__claude_ai_Gmail__create_draft`. **Always pass it.**

- **Same thread every time.** Whatever the recipient change — a
  reporter reply, an ASF-security relay request, a PMC credit
  question, a follow-up asking for a PoC — the draft stays on the
  inbound tracker's `threadId`. A triager reading the Gmail
  conversation view should see every exchange on a single tracker
  in one place; if threading breaks, that history scatters across
  two conversations.
- **Subject stays as `Re: <root subject>`**, never a fabricated
  new one. Gmail's own threading survives without matching
  subjects when `threadId` is set, but other clients (Thunderbird,
  Outlook, Apple Mail) and the recipient's own client commonly
  fall back to subject-based threading. A drifted subject looks
  like a broken conversation on half the world's mail readers.
- **`To:` may differ from the original correspondents.** It is
  fine to address a draft to a specific person (an ASF
  security-team member who relayed the report, a named PMC member,
  an individual reporter) even if the original inbound root was
  addressed to a list. Threading does not require recipient
  overlap; it requires `threadId`.
- **Not knowing the `threadId` is a blocker, not a licence to
  fabricate a new thread.** If the skill cannot resolve the
  inbound `threadId` from the tracker body (the *"Security
  mailing list thread"* field) or from the skill's own Step 1
  context, stop and surface the gap to the user before drafting.
  A standalone draft with no thread context is worse than no
  draft.

### ASF-security-relay reports: a special case for drafting

Some reports reach `security@airflow.apache.org` via the ASF
security team — `security@apache.org` itself, or a personal
`@apache.org` address of an ASF security-team member — forwarding
a report that came in through GHSA, HackerOne, or another channel
the Airflow security team does not have direct access to. In
those cases the "reporter" on the Gmail thread is the ASF
forwarder, and the **actual external reporter is unreachable to
us directly**: we can only reach them by asking the ASF forwarder
to relay questions through the same external channel.

When drafting any reply on an ASF-security-relay tracker —
receipt of confirmation, credit-preference request, status
update — the rule is the same:

- **`threadId`** — the inbound relay thread's `threadId`, per the
  threading rule above. Never fabricate a new thread for a
  credit-preference relay; it goes on the same thread as the
  original inbound report.
- **Subject** — `Re: <root subject>`, i.e. the subject of the
  inbound relay message. No fabricated new subject, no
  relay-specific title like *"Airflow: credit-preference relay
  for <GHSA-ID>"*.
- **`To:`** — the ASF forwarder (the `From:` address of the
  inbound relay message). Typically this is a personal
  `@apache.org` address; use that, not the `security@apache.org`
  list alias, so the conversation stays with the individual who
  already knows the report.
- **`Cc:`** — `security@airflow.apache.org` as always.
- **Body** — short, per the
  [Brevity](#brevity-emails-state-facts-not-context) rule. The
  ASF security team knows the handling process; do **not**
  restate the vulnerability, the severity analysis, or the
  Airflow CVE process. Link to the external reference (GHSA ID,
  HackerOne report URL) rather than repeating technical detail.
  When the purpose of the draft is a credit-preference relay,
  the ask is one sentence: *"Please forward the credit-preference
  question below to the external reporter through the original
  channel."*

### Point reporters to the project's Security Model, don't re-explain it

The project's Security Model is the authoritative source for what is and
is not considered a security vulnerability. Canned responses must link
directly to the relevant chapter instead of paraphrasing it. Paraphrases
drift over time and create a second source of truth that has to be
maintained.

The authoritative URL and known-useful anchors for the currently active
project live in
[`projects/airflow/security-model.md`](projects/airflow/security-model.md).
When adding a new canned response, identify the matching chapter in the
Security Model first. If no chapter covers the case, that is a signal
the Security Model should be updated upstream (in the project's source
repository) rather than duplicated in the canned responses.

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

### Mentioning project maintainers and security-team members

When writing text that lands on a GitHub issue or PR and refers to a
specific project maintainer, committer, release manager, or security-
team member, **use the person's GitHub handle with the leading `@` so
GitHub notifies them**. Plain-text names do not fire notifications,
and the whole point of mentioning the person is usually that they own
the next step or are the right reviewer. Agent-generated status
comments, PR bodies, sync recaps, fix-PR follow-up comments, and
draft-advisory text should all follow the rule.

The project-specific roster rules (who the rule applies to, which
surfaces it applies to, public-surface caveats tied to this project's
confidentiality constraints, how external reporters are handled) live
in
[`projects/airflow/naming-conventions.md`](projects/airflow/naming-conventions.md#mentioning-airflow-maintainers-and-security-team-members).
The authoritative roster and the release-manager rotation list live in
[`projects/airflow/release-trains.md`](projects/airflow/release-trains.md).

The sync-security-issue and fix-security-issue skills should render
every maintainer / security-team / release-manager reference in the
status comments they post as an `@` handle. Before publishing a status
comment, the skills must grep for names of known people and flag any
bare-name occurrence to the user.

### Other editorial guidelines

- Project-specific naming rules (e.g. *"use `Dag` not `DAG`"*,
  *"thousands of contributors"*, acronym casing) live in the active
  project's naming-conventions file — for Airflow, see
  [`projects/airflow/naming-conventions.md`](projects/airflow/naming-conventions.md).
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

- [`import-security-issue`](.claude/skills/import-security-issue/SKILL.md) —
  the on-ramp of the process. Scans `security@airflow.apache.org` for threads
  that have not yet been copied into `airflow-s/airflow-s` as tracking issues,
  classifies each candidate (real report vs. automated-scan / consolidated /
  media / spam), extracts the issue-template fields from the root email, and —
  after user confirmation — creates one tracker per valid report plus a Gmail
  draft of the receipt-of-confirmation reply (from
  [`projects/airflow/canned-responses.md`](projects/airflow/canned-responses.md),
  including the credit-preference question). Deduplicates against existing
  tracker bodies by searching for the
  Gmail `threadId`. This is Step 2 of the handling process in
  [`README.md`](README.md) and the first skill a triager runs in a morning
  sweep.
- [`deduplicate-security-issue`](.claude/skills/deduplicate-security-issue/SKILL.md) —
  merges two tracking issues that describe the same root-cause
  vulnerability discovered independently by different reporters. Copies
  the dropped tracker's body verbatim into the kept tracker as a
  *"Second independent report"* section, concatenates the reporters'
  credit lines and mailing-list thread references, regenerates the kept
  tracker's CVE JSON attachment so both finders land in `credits[]`, and
  closes the dropped tracker with the `duplicate` label. Refuses to
  operate across different scope labels (those require a scope split
  via `sync-security-issue`, not a dedupe). Typically invoked after
  `import-security-issue` Step 2a surfaces a STRONG GHSA-ID match with
  an existing tracker.
- [`sync-security-issue`](.claude/skills/sync-security-issue/SKILL.md) —
  reconciles a security issue with its GitHub discussion, its
  `security@airflow.apache.org` mail thread, and any fixing PRs; proposes label,
  milestone, field, and draft-email updates; and prompts the user to confirm each
  change before applying it. Points the user at
  [`allocate-cve`](.claude/skills/allocate-cve/SKILL.md) when a CVE is
  needed. **At the end of every run** it also invokes
  [`generate-cve-json`](.claude/skills/generate-cve-json/SKILL.md) with
  `--attach` to refresh the CVE JSON attachment on the tracking issue (auto-
  resolving `--remediation-developer` from the first apache/airflow PR author
  in the *PR with the fix* body field), so the attached JSON stays in
  lock-step with the issue body. Skipped only when no CVE has been allocated
  yet, or when the issue has been closed as invalid / not-CVE-worthy / duplicate.
- [`allocate-cve`](.claude/skills/allocate-cve/SKILL.md) — walks the user
  through allocating a CVE via the ASF Vulnogram form at
  <https://cveprocess.apache.org/allocatecve>. **The allocation itself is
  PMC-gated** — only Airflow PMC members can submit the Vulnogram form.
  The skill asks up front whether the user is on the PMC; if not, it
  reshapes the recipe into a ``@``-mention relay message the triager
  forwards to a PMC member (on the tracker or on the
  `security@airflow.apache.org` thread). Either way it reads the
  tracking issue, strips redundant `Apache Airflow` / `[ Security Report ]`
  / trailing version noise from the title to produce a CVE-ready title
  for the Vulnogram form, and — once the allocated `CVE-YYYY-NNNNN` ID
  is pasted back — updates the tracker in one coordinated pass: fills in
  the *CVE tool link* body field, adds the `cve allocated` label, posts
  a collapsed status-change comment, regenerates the CVE JSON attachment
  in the body via `generate-cve-json --attach`, and (when relevant)
  drafts a reporter status update on the original mail thread. **Always
  hands off to `sync-security-issue`** at the end so the allocation-
  triggered changes are reconciled with the milestone, assignee, fix-PR
  state, and reporter-thread state in one continuous flow.
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
- Verify that links to the project's Security Model use an anchor that
  exists on the current stable version (active project's anchors:
  [`projects/airflow/security-model.md`](projects/airflow/security-model.md)).
- Self-review the tone of any modified canned response against the "polite but firm" guidance above.

## References

- [`config/active-project.md`](config/active-project.md) — declares which project under `projects/` this working tree targets.
- [`projects/airflow/project.md`](projects/airflow/project.md) — the active project's manifest (identity, repositories, mailing lists, tools enabled, CVE tooling).
- [`projects/airflow/`](projects/airflow/) — other project-specific files (canned responses, release trains, security model, scope labels, milestones, title-normalization, fix workflow, naming conventions).
