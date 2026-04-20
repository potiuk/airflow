<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [AGENTS instructions](#agents-instructions)
  - [Repository purpose](#repository-purpose)
  - [Per-project and per-user configuration](#per-project-and-per-user-configuration)
    - [Placeholder convention used in skill files](#placeholder-convention-used-in-skill-files)
  - [Local setup](#local-setup)
  - [Commit and PR conventions](#commit-and-pr-conventions)
  - [Confidentiality of the tracker repository](#confidentiality-of-the-tracker-repository)
    - [Other ASF projects — never name or describe their vulnerabilities](#other-asf-projects--never-name-or-describe-their-vulnerabilities)
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
    - [Linking tracker issues and PRs](#linking-tracker-issues-and-prs)
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

The repo has three layers:

1. **Generic** — project-agnostic process, agent conventions, and skill
   definitions. Lives at the repo root and under `.claude/skills/`.
2. **Project-specific** — the currently-active project's identity,
   roster, release trains, canned responses, security-model references,
   and milestone conventions. Lives under [`projects/<name>/`](projects/).
   The active project is declared in
   [`config/active-project.md`](config/active-project.md).
3. **Tool adapters** — operation catalogues and reference docs for the
   external tools the skills call (GitHub, Gmail, Vulnogram, …). Lives
   under [`tools/<name>/`](tools/). Each project's manifest declares
   which tools it opts into.

Repo-root files:

- [`README.md`](README.md) — the end-to-end process for handling security issues (generic lifecycle).
- [`how-to-fix-a-security-issue.md`](how-to-fix-a-security-issue.md) — high-level description of the fix workflow.
- [`new-members-onboarding.md`](new-members-onboarding.md) — onboarding guide for new security team members.
- [`config/README.md`](config/README.md) — tutorial for the two configuration layers (project + user).
- [`config/active-project.md`](config/active-project.md) — declares which project under `projects/` this working tree targets.
- [`config/user.md`](config/user.md) (each user's local copy of [`config/user.md.example`](config/user.md.example), **gitignored**) — per-user identity, PMC status, tool preferences, local environment paths.
- [`projects/<PROJECT>/`](projects/) — project-specific content (canned responses, release trains, security model, milestones, …).
- [`tools/<name>/`](tools/) — tool adapters (GitHub operations, issue-template schema, project-board GraphQL, …) for the external tools the skills invoke.

There is no source code to build or test. Changes are reviewed and merged by the security team.

## Per-project and per-user configuration

Two configuration layers tell the skills how this working tree is set
up. The overview + a step-by-step tutorial for setting both up lives
in [`config/README.md`](config/README.md).

**Project layer — shared, checked in.** Every project-specific fact
the skills need is declared in a single manifest per project. For the
currently active project, see
[`projects/<PROJECT>/project.md`](projects/airflow/project.md). The
active project is picked by
[`config/active-project.md`](config/active-project.md). The manifest
lists:

- project identity (vendor, product, URLs);
- repositories (tracker repo, upstream repo, default branches);
- mailing lists (security, private, public, dev, announce);
- tools enabled (GitHub, Gmail, Vulnogram, …);
- CVE tooling (allocation URL, record URL template, CNA container defaults);
- pointers to the other files in the project directory (release trains,
  scope labels, milestones, security model, title-normalisation rules,
  canned responses, fix workflow, naming conventions).

**User layer — personal, gitignored.** Each triager keeps their own
[`config/user.md`](config/user.md) (copied from
[`config/user.md.example`](config/user.md.example)) declaring their
identity, PMC status, per-capability tool picks, and local
environment paths (e.g. the local `<upstream>` clone location). Skills
read this file at Step 0 pre-flight and skip the corresponding
prompts when a field is set. Fields that are unset fall back to
runtime prompts — nothing is broken if `user.md` is missing; it is an
opt-in convenience. See
[`config/README.md`](config/README.md#what-the-user-layer-does) for
the list of knobs the file exposes today.

When this document (or any skill) says *"the tracker repo"*, *"the
upstream repo"*, *"the security list"*, *"the canned responses"*,
it means the value declared in `projects/<PROJECT>/project.md` and
its sibling files. When it says *"the user's GitHub handle"*, *"PMC
status"*, *"the local upstream clone"*, it means the value in
`config/user.md`. When a fact is truly project-agnostic (a lifecycle
rule, a confidentiality principle, a brevity rule), it lives in this
file or in [`README.md`](README.md).

### Placeholder convention used in skill files

Skill files, tool-adapter docs, and this file use a small set of
substitution placeholders instead of baking in one project's
concrete values. Agents reading a skill must resolve these against
the active configuration before executing any command:

| Placeholder | Resolves to | Source |
|---|---|---|
| `<PROJECT>` | The active project's directory name under `projects/` — for this tree, `airflow`. | `config/active-project.md` → `active_project:` |
| `<tracker>` | The GitHub slug of the tracker repo — for this tree, `<tracker>`. | `projects/<PROJECT>/project.md` → `tracker_repo` |
| `<upstream>` | The GitHub slug of the upstream codebase the fixes land in — for this tree, `<upstream>`. | `projects/<PROJECT>/project.md` → `upstream_repo` |
| `<N>` | An issue or PR number. | The user's input to the skill |
| `<CVE-ID>` | A CVE identifier of the form `CVE-YYYY-NNNNN`. | Per-tracker |

The case split (`<PROJECT>` uppercase, `<tracker>` / `<upstream>`
lowercase) is deliberate: `<PROJECT>` is the *identity* placeholder
the whole framework pivots on, so it gets the template-variable
styling; `<tracker>` / `<upstream>` are per-capability tool targets
that already use the lowercase convention in
[`tools/github/operations.md`](tools/github/operations.md). Do not
invent new placeholders; if a skill needs a value that isn't on the
list above, thread it in via the project manifest or the user
config rather than reaching for a fresh convention.

Concretely: in a bash snippet, `gh issue view <N> --repo <tracker>`
means *"before running this, substitute `<tracker>` for the value in
`projects/<PROJECT>/project.md` → `tracker_repo`"*. In a markdown
link, `[…](../../../projects/<PROJECT>/canned-responses.md)` means
*"substitute `<PROJECT>` for the value in
`config/active-project.md` → `active_project`, then follow the
link"*. Writing the literal value directly (e.g. `<tracker>`
or `projects/<PROJECT>/`) in a skill is a refactor bug — skills must
stay project-agnostic so swapping projects is a config change, not
a code change.

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
  [`projects/<PROJECT>/fix-workflow.md`](projects/airflow/fix-workflow.md#commit-trailer).
- **Always open PRs with `gh pr create --web`** so the human reviewer can check the title,
  body, and the generative-AI disclosure in the browser before submission. Pre-fill `--title`
  and `--body` (including the Gen-AI disclosure block) so they only need to review, not edit.
- **Target branch for this repository is declared in the project manifest** — see
  [`projects/<PROJECT>/project.md`](projects/airflow/project.md#repositories)
  (`tracker_default_branch`). The non-default branch (`main`) is used only as a
  staging branch for the private-PR fallback described in
  [`README.md`](README.md). Unless the user explicitly says otherwise, base
  PRs on the tracker's default branch.
- Keep the commit message focused on the user-visible change, not the mechanics of how the edit
  was made.

## Confidentiality of the tracker repository

The existence of the private tracker repository (`<tracker>`), the
issue numbers it contains, the labels we use, and the discussions
inside it are **not public**. Anything that leaves the security
team's private channels — public `<upstream>` PRs, public GitHub
issues, public mailing lists, public canned responses, public
release notes, public commit messages, public blog posts, **anything
visible to non-security-team members** — must not contain:

- URLs of the form `https://github.com/<tracker>/...` (issue links,
  PR links, discussion links, comment links);
- bare references like `<tracker>#NNN` or `#NNN` in a context where
  the implicit repository is `<tracker>`;
- the literal string `<tracker>` (i.e. the active project's tracker
  repo slug) used as a repo or org name;
- screenshots or excerpts of the tracker's GitHub UI;
- copy/paste of comments, labels, or milestones from the tracker if
  doing so reveals that the source is the private security tracker.

These references are allowed **only** in:

- documents that live inside the tracker repository (this file,
  `README.md`, `projects/<PROJECT>/canned-responses.md`, `SKILL.md`
  files, etc.);
- private mail threads on the project's `<security-list>` with the
  original reporter (where letting them know we have a tracking issue
  is part of the status update they receive);
- private mail to the project's `<private-list>` (PMC escalation
  list) when escalating a stalled discussion per process step 4.

In particular:

- **Public `<upstream>` PR descriptions and commit messages** must
  not reveal the CVE, the security nature of the change, or any link
  back to `<tracker>`. This is already required by process step 8 of
  [`README.md`](README.md) and the rule above reinforces it.
- **Canned responses** (for the active project,
  [`projects/<PROJECT>/canned-responses.md`](projects/airflow/canned-responses.md))
  must remain free of `<tracker>` URLs, because they are sent
  verbatim as email replies. If you are tempted to add one, link to
  the project's public Security Model or security policy instead —
  for Airflow, see
  [`projects/<PROJECT>/security-model.md`](projects/airflow/security-model.md).
- **Status updates the skill drafts to reporters** *may* include the
  `<tracker>` tracking-issue URL — the reporter is on the private
  `<security-list>` thread and is expected to keep it confidential —
  but the same content **must not** be reused in any public comment,
  comment to the public `<upstream>` PR, or release-time advisory
  text.
- **`gh issue comment` calls inside the tracker repository are fine**
  because they land on the private issue itself; they do not leak.

When editing or generating any text destined for a public audience,
search it for the tracker repo slug (substitute `<tracker>` with the
concrete value — for this tree, the sequence `airflow-s`) and for
the patterns above before saving or sending. If a public audience
needs to see a tracking link for transparency, link to the **public**
artifact (the merged `<upstream>` PR, the published CVE on
`cve.org`, the public users-list advisory archive) — never to the
private tracker.

### Other ASF projects — never name or describe their vulnerabilities

While triaging a report, you may learn about vulnerabilities in
**other ASF projects** through the same channels that surface our
own reports: the reporter's mail thread mentions that they filed a
similar issue against Superset or Allura; a cross-project digest on
`<asf-security-list>` summarises active reports across several
projects; a Gmail search for a CVE ID or a vulnerability pattern
returns hits on threads belonging to unrelated projects; your own
deduction from a reporter's résumé or prior disclosures correlates
them with work against another project. **None of that content may
appear in the tracker.** Specifically, these surfaces must not name,
reference, describe, or hint at another ASF project's vulnerability:

- **Tracker issue bodies**, rollup comment entries, status comments,
  labels, milestone descriptions, per-field values (*Short public
  summary for publish*, *Reporter credited as* notes, *Security
  mailing list thread*, etc.).
- **The CVE JSON attachment** and every other artefact the
  `generate-cve-json` tool emits — the `descriptions[]`, `credits[]`,
  `references[]`, and `cpeApplicability[]` fields are all
  world-readable once the record reaches PUBLIC.
- **Public `<upstream>` PR descriptions and commit messages** (see
  the main Confidentiality rule above — this subsection extends it
  to cover other projects too).
- **Canned responses** and any text that ends up in a reply to the
  reporter or on a public list.

This applies **even when**:

- the same reporter discovered the same pattern in multiple ASF
  projects and said so openly on `<security-list>`;
- the cross-project correlation would be informative for our own
  triage (e.g. *"their fix used approach X, we should consider the
  same"*);
- the other project's report is already public — a published CVE
  does not re-authorise discussion of the private report that
  preceded it, nor of any other report we happen to know about
  from that project's team;
- the reporter themselves linked to the other project's advisory in
  their mail.

**Why:** every ASF project operates its own CNA process under its
own security team. Content about project X's in-flight or
historical vulnerability is project X's private information, not
Airflow's, and copying it into our tracker effectively re-publishes
it via screenshots, excerpts pasted into advisories, timeline
clippings, or future scrapes. Cross-project correlations also
reveal investigation patterns, reporter behaviour, and triage-team
attention that the other project's team may not have chosen to
share with us. The fact that we learned something via a shared
channel (`security@apache.org`, a cross-project Gmail thread)
grants us exactly as much licence to broadcast it as the sender
intended — which is almost always *"none beyond the conversation
we're in right now"*.

**What to do instead.** Keep cross-project observations in the
channel they arrived on:

- Reporter mentioned another project on the `<security-list>` thread
  → discuss it on that same thread if it helps triage; do not copy
  into the tracker.
- Observation is load-bearing for Airflow's own fix or advisory
  (e.g. the other project's fix shape informs ours) → summarise it
  **without naming the project**. *"The reporter has filed similar
  reports with other ASF projects"* is allowed and sometimes
  useful; *"the reporter has filed the same traversal pattern
  against Superset and Allura"* is not. *"A sibling ASF project
  landed a comparable fix"* is allowed; *"Tomcat landed the
  equivalent fix in 11.0.3"* is not.
- Cross-project triage belongs on `<asf-security-list>` or in a
  direct mail to that project's security team, not in our tracker.

**Self-check before posting, committing, or drafting.** Grep the
text for the names of known ASF projects — a non-exhaustive but
high-signal list: `Superset`, `Allura`, `Tomcat`, `Kafka`, `Spark`,
`Cassandra`, `Hadoop`, `Hive`, `HTTPD`, `Struts`, `Solr`,
`Zookeeper`, `Beam`, `Flink`, `NiFi`, `Pulsar`, `CloudStack`,
`OFBiz`, `Commons`, `Lucene`, `Camel`, `Druid`, `ActiveMQ`,
`Guacamole`, `Shiro`, `CXF`, `Iceberg` — and for the generic
phrases *"also reported against"*, *"cross-project"*, *"other
Apache projects"*, *"sister project"*, *"the same finder also"*,
*"similar to CVE-<year>-<number>"* (when that CVE belongs to
another project). If a hit lands in any tracker-destined surface,
remove it or rewrite it in the de-identified form above. When in
doubt, leave it out — the cost of omitting useful context is
low, the cost of leaking another project's private information is
not.

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

The active project's security team scores every accepted vulnerability independently,
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

When populating the CVE record's `references[]` array (via the
`generate-cve-json` script or directly in the project's CVE-tool
UI), **never tag a URL as `vendor-advisory` if the URL points to a
non-publicly archived list**. The project's mailing lists fall into
two groups — see
[`projects/<PROJECT>/project.md → Mailing lists`](projects/airflow/project.md#mailing-lists)
for the concrete list membership and the public / private marking:

- **Publicly archived** (for ASF projects, on `lists.apache.org`):
  users list, dev list, announce list, commits list. Thread URLs on
  these lists resolve correctly for the whole world and are the
  right target for a `vendor-advisory` reference on the public CVE
  record.
- **Private**, not publicly archived: the project's `<security-list>`
  and `<private-list>`. For ASF projects these produce
  `lists.apache.org/thread/<id>` URLs that look identical in shape
  to public-list URLs but 404 for everyone outside the security
  team. They must **never** appear in the public CVE record.

Concretely, the issue template has two separate fields for this:

- The *"Security mailing list thread"* field is the **internal**
  reference for the security team: it holds the URL (or Gmail
  thread ID) of the original `<security-list>` thread so triagers
  can navigate back to the report. It is expected to 404 for anyone
  outside the security team. Keep whatever the reporter /
  team-member put there — do **not** scrub it during sync.
- The *"Public advisory URL"* field holds the archive URL on the
  project's public users-list archive once the public advisory has
  been sent (Step 13 of the process). This is the URL that ends up
  as the `vendor-advisory` reference on the public CVE record.
  Before the advisory is sent the field stays empty; the
  `sync-security-issue` skill scans the users-list archive for the
  CVE ID and proposes populating the field automatically once the
  advisory lands.

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
[`projects/<PROJECT>/canned-responses.md`](projects/airflow/canned-responses.md)
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
escalation messages to `<private-list>`, relay requests to
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
   with the next patch release."*).
3. The relevant **artifact URLs** on their own line(s) — CVE tool
   link, PR URL, advisory archive URL — per the linking rules in
   [Linking CVEs](#linking-cves) and
   [Linking tracker issues and PRs](#linking-tracker-issues-and-prs).
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
[`projects/<PROJECT>/canned-responses.md`](projects/airflow/canned-responses.md)
**verbatim**. That template is longer because it introduces the process
to a reporter who has not yet seen it and carries the credit-preference
question; leave it alone and do not trim it per this brevity rule.

Everything else — every follow-up, every status update, every relay
to a PMC member, every message to the ASF security team — falls
under this rule.

### Threading: drafts stay on the inbound Gmail thread

Every drafted email that relates to a tracking issue **should**
attach to the original inbound Gmail thread. The preferred path is
to pass the inbound `threadId` to `create_draft`; the pragmatic
fallback — when the `threadId` cannot be resolved — is to omit it
and create the draft with the matching `Re: <root subject>` line,
which most clients still thread by subject. The full rule (when
each path applies, when to stop instead, how to surface the
degraded threading in the skill's proposal) lives in
[`tools/gmail/threading.md`](tools/gmail/threading.md).

### ASF-security-relay reports: a special case for drafting

Some reports reach the project's security list via the ASF security
team (from `security@apache.org`, or a personal `@apache.org` address
of an ASF-security-team member) rather than from the external reporter
directly. The drafting rules for that case — different `To:`, same
threading behaviour (prefer `threadId`, fall back to the inbound
subject), terse body — live in
[`tools/gmail/asf-relay.md`](tools/gmail/asf-relay.md). The detection
signals the `import-security-issue` skill uses to classify a candidate
as a relay live in that skill's Step 3.

### Point reporters to the project's Security Model, don't re-explain it

The project's Security Model is the authoritative source for what is and
is not considered a security vulnerability. Canned responses must link
directly to the relevant chapter instead of paraphrasing it. Paraphrases
drift over time and create a second source of truth that has to be
maintained.

The authoritative URL and known-useful anchors for the currently active
project live in
[`projects/<PROJECT>/security-model.md`](projects/airflow/security-model.md).
When adding a new canned response, identify the matching chapter in the
Security Model first. If no chapter covers the case, that is a signal
the Security Model should be updated upstream (in the project's source
repository) rather than duplicated in the canned responses.

### Linking CVEs

Whenever a CVE ID appears in text this repository produces — status
comments on `<tracker>` issues, proposals from the
`sync-security-issue` skill, recap messages, canned-response drafts
to reporters, internal notes — render it as a **clickable link**,
not as bare text. The canonical link is the active project's CVE-tool
record URL, which any security team member can click through to the
live CVE record we control:

```
https://cveprocess.apache.org/cve5/<CVE-ID>
```

Example:

> [`CVE-2026-40690`](https://cveprocess.apache.org/cve5/CVE-2026-40690)

For CVEs that have already been **published** (the advisory has been sent
to `<users-list>`, the issue carries `vendor-advisory`, and the
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
[Confidentiality of the tracker repository](#confidentiality-of-the-tracker-repository)
section above:

- CVE-tool links are fine inside `<tracker>` private comments and
  in private mail to the reporter on `<security-list>` — the tool
  is team-internal and does not reveal anything beyond the CVE ID
  itself.
- Public `<upstream>` PR descriptions, public mailing-list posts,
  and any other public surface **must not** link to the CVE tool
  before the advisory is sent — doing so implies the existence of
  the private tracking issue. Once the advisory is public, link
  only to `cve.org` (or NVD), never to the CVE tool.

When editing an existing document that contains a bare `CVE-YYYY-NNNNN`
string, convert it to the linked form in the same edit.

### Linking tracker issues and PRs

Whenever a reference to a `<tracker>` issue, pull request, comment,
or discussion appears in text this repository produces — sync / fix
skill proposals, status comments on the private issue itself, recap
messages, internal notes, `SKILL.md` files — render it as a
**clickable markdown link**, not as a bare `#NNN` or
`<tracker>#NNN`. The URL format is:

```
https://github.com/<tracker>/issues/<N>
https://github.com/<tracker>/pull/<N>
https://github.com/<tracker>/issues/<N>#issuecomment-<C>
```

Preferred rendering (with `<tracker>` substituted — for this tree,
`<tracker>`):

> [`<tracker>#221`](https://github.com/<tracker>/issues/221)

or, when the repository is already obvious from context (for example
inside a comment on `<tracker>#221` itself):

> [`#221`](https://github.com/<tracker>/issues/221)

Link both the number *and* any referenced comment / review by using
the per-comment anchor:

> [`<tracker>#216 — issuecomment-4252393493`](https://github.com/<tracker>/issues/216#issuecomment-4252393493)

**Confidentiality, as always**, takes precedence: these rendered
links are *only* allowed inside the tracker repository and in
private mail threads on the project's `<security-list>` — they are
**never** permitted in public `<upstream>` PR descriptions, public
mailing-list posts, public canned responses, or anywhere else a
non-security-team member could see them. See the
[Confidentiality of the tracker repository](#confidentiality-of-the-tracker-repository)
section above. The scrubbing grep the `fix-security-issue` skill
runs before pushing anything public is the final line of defence and
must catch any stray tracker-repo URL or `#NNN` reference that slips
into public text.

When editing an existing document in this repo that contains a bare
`#NNN` or `<tracker>#NNN`, convert it to the linked form in the same
edit. Skill-generated output (sync proposals, issue comments, email
drafts to reporters on the `<security-list>` thread) must emit the
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
[`projects/<PROJECT>/naming-conventions.md`](projects/airflow/naming-conventions.md#mentioning-airflow-maintainers-and-security-team-members).
The authoritative roster and the release-manager rotation list live in
[`projects/<PROJECT>/release-trains.md`](projects/airflow/release-trains.md).

The sync-security-issue and fix-security-issue skills should render
every maintainer / security-team / release-manager reference in the
status comments they post as an `@` handle. Before publishing a status
comment, the skills must grep for names of known people and flag any
bare-name occurrence to the user.

### Other editorial guidelines

- Project-specific naming rules (e.g. *"use `Dag` not `DAG`"*,
  *"thousands of contributors"*, acronym casing) live in the active
  project's naming-conventions file — for Airflow, see
  [`projects/<PROJECT>/naming-conventions.md`](projects/airflow/naming-conventions.md).
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
  the on-ramp of the process. Scans `<security-list>` for threads
  that have not yet been copied into `<tracker>` as tracking issues,
  classifies each candidate (real report vs. automated-scan / consolidated /
  media / spam), extracts the issue-template fields from the root email, and —
  after user confirmation — creates one tracker per valid report plus a Gmail
  draft of the receipt-of-confirmation reply (from
  [`projects/<PROJECT>/canned-responses.md`](projects/airflow/canned-responses.md),
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
  `<security-list>` mail thread, and any fixing PRs; proposes label,
  milestone, field, and draft-email updates; and prompts the user to confirm each
  change before applying it. Points the user at
  [`allocate-cve`](.claude/skills/allocate-cve/SKILL.md) when a CVE is
  needed. **At the end of every run** it also invokes
  [`generate-cve-json`](tools/vulnogram/generate-cve-json/SKILL.md) with
  `--attach` to refresh the CVE JSON attachment on the tracking issue (auto-
  resolving `--remediation-developer` from the first <upstream> PR author
  in the *PR with the fix* body field), so the attached JSON stays in
  lock-step with the issue body. Skipped only when no CVE has been allocated
  yet, or when the issue has been closed as invalid / not-CVE-worthy / duplicate.
- [`allocate-cve`](.claude/skills/allocate-cve/SKILL.md) — walks the
  user through allocating a CVE via the active project's CVE-tool
  allocation form (for Airflow, ASF Vulnogram at
  <https://cveprocess.apache.org/allocatecve>; see
  `projects/<PROJECT>/project.md → CVE tooling`).
  **The allocation itself is PMC-gated** — only the active project's
  PMC members can submit the form. The skill asks up front whether
  the user is on the PMC (reading
  `config/user.md → role_flags.pmc_member` when set); if not, it
  reshapes the recipe into a `@`-mention relay message the triager
  forwards to a PMC member (on the tracker or on the
  `<security-list>` thread). Either way it reads the tracking issue,
  strips the project-specific redundant prefixes from the title (per
  `projects/<PROJECT>/title-normalization.md`) to produce a
  CVE-ready title for the allocation form, and — once the allocated
  `CVE-YYYY-NNNNN` ID is pasted back — updates the tracker in one
  coordinated pass: fills in
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
  in the user's local `<upstream>` clone (path from
  `config/user.md → environment.upstream_clone`), runs local checks and
  tests, and opens a public PR via `gh pr create --web`. Every public
  surface (commit message, branch name, PR title, PR body,
  newsfragment) is scrubbed for CVE / the tracker repo slug (for this
  tree, the substring `airflow-s`) / `vulnerability` / `security fix`
  leakage before being written or pushed. Updates the `<tracker>`
  tracking issue with the new PR link afterwards.
- [`generate-cve-json`](tools/vulnogram/generate-cve-json/SKILL.md) — generates
  a paste-ready CVE 5.x JSON record from a tracking issue, matching the shape
  Vulnogram exports (`containers.cna` with `affected`, `descriptions` + HTML
  `supportingMedia`, `problemTypes` with `type: "CWE"`, `metrics.other`,
  tagged `references`, `providerMetadata.orgId`, `cveMetadata` envelope). A
  deterministic `uv run` script — [the `generate-cve-json` project](tools/vulnogram/generate-cve-json/) —
  parses the issue's template fields (multiple credits on separate lines,
  multiple reference URLs, `>= X, < Y` version ranges), writes the JSON to a
  file, and prints the Vulnogram `#json` paste URL for the CVE. The
  project's CVE-tool URL and any tracker-repo URLs (`<tracker>`) are
  filtered out of `references[]` before serialising.

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
  [`projects/<PROJECT>/security-model.md`](projects/airflow/security-model.md)).
- Self-review the tone of any modified canned response against the "polite but firm" guidance above.

## References

- [`config/README.md`](config/README.md) — two-layer configuration model + step-by-step tutorial (project + user).
- [`config/active-project.md`](config/active-project.md) — declares which project under `projects/` this working tree targets.
- [`config/user.md.example`](config/user.md.example) — per-user configuration template (copy to `config/user.md`, which is gitignored).
- [`projects/<PROJECT>/project.md`](projects/airflow/project.md) — the active project's manifest (identity, repositories, mailing lists, tools enabled, CVE tooling, GitHub project board + issue-template field declarations).
- [`projects/<PROJECT>/`](projects/airflow/) — other project-specific files (canned responses, release trains, security model, scope labels, milestones, title-normalization, fix workflow, naming conventions).
- [`tools/github/`](tools/github/) — GitHub tool adapter: `tool.md` (overview), `operations.md` (`gh` CLI / API catalogue), `issue-template.md` (body-field schema), `labels.md` (lifecycle-label taxonomy), `project-board.md` (Projects V2 GraphQL).
- [`tools/gmail/`](tools/gmail/) — Gmail tool adapter: `tool.md` (overview), `operations.md` (MCP catalogue + no-update limitation), `threading.md` (prefer-`threadId`-else-subject-fallback rule), `asf-relay.md` (ASF-security-relay drafting), `search-queries.md` (query templates), `ponymail-archive.md` (ASF PonyMail URL construction).
- [`tools/vulnogram/`](tools/vulnogram/) — Vulnogram (ASF CVE tool) adapter: `tool.md` (overview), `allocation.md` (PMC-gated allocation flow), `record.md` (record URLs + `#source` paste + `DRAFT`/`REVIEW`/`PUBLIC` state machine + reviewer-comment signal), `generate-cve-json/` (CVE-5.x JSON generator — Python project).
- [`tools/cve-org/`](tools/cve-org/) — public CVE registry adapter: `tool.md` covers the MITRE CVE Services API v2 `check-published` recipe, used by `sync-security-issue` to verify that a closed tracker's CVE has propagated from the CNA tool to cve.org before sending the reporter the final *"CVE is live"* email.
