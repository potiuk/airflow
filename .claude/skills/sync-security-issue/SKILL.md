---
name: sync-security-issue
description: |
  Synchronize a security issue in <tracker> with the state of its
  GitHub discussion, the security@airflow.apache.org mailing thread, and any
  <upstream> PRs that fix it. The skill gathers all relevant signals,
  proposes label, milestone, assignee, field and draft-email updates, and
  only applies changes the user has explicitly confirmed. Suggests the next
  step in the handling process and prints the CVE allocation link when a CVE
  is needed.
when_to_use: |
  Invoke when a security team member says "sync issue NNN", "refresh the
  state of issue NNN", "update issue NNN from the thread", or "walk me
  through issue NNN". Also appropriate as part of a recurring triage sweep
  where the team member wants to reconcile a batch of open issues with the
  current state of the world.
---

<!-- Placeholder convention (see AGENTS.md#placeholder-convention-used-in-skill-files):
     <PROJECT>  → value of `active_project:` in config/active-project.md
                 (for this tree: airflow)
     <tracker>  → value of `tracker_repo:` in projects/<PROJECT>/project.md
                 (for this tree: airflow-s/airflow-s)
     <upstream> → value of `upstream_repo:` in projects/<PROJECT>/project.md
                 (for this tree: apache/airflow)
     Before running any bash command below, substitute these with the
     active-project values read from config/ + projects/<PROJECT>/project.md. -->

# sync-security-issue

This skill reconciles a single security issue in
[`<tracker>`](https://github.com/<tracker>) with:

1. the **GitHub issue** itself — comments, labels, milestone, assignee, description fields;
2. the **email thread** on `security@airflow.apache.org` that originated the report (and any follow-ups);
3. any **pull requests** in `<upstream>` or `<tracker>` that reference or fix the issue;
4. the **handling process** documented in [`README.md`](../../../README.md).

**Golden rule 1 — propose before applying.** Every change this skill
performs is a *proposal*. The user running the sync must explicitly
confirm each update before it is applied. Do not mutate GitHub state, do
not send email, do not create, close, or edit anything without a clear
"yes" from the user for that specific action. Drafts are always created
as Gmail **drafts**, never sent directly.

**Golden rule 2 — every `<tracker>` reference is a clickable
link.** Whenever this skill mentions the tracking issue, any other
`<tracker>` issue, a `<tracker>` PR, a specific
issue comment, a milestone, or a label from this repository — in the
observed-state dump, in the proposal, in the confirmation prompt, in
the apply-loop output, in the regeneration output, in the recap, in
status-change comments posted to the issue itself, anywhere — render
it as a markdown link the user can click, **never** as a bare `#NNN`
or `<tracker>#NNN` or plain-text number. The link form is
defined in the "Linking `<tracker>` issues and PRs" section
of [`AGENTS.md`](../../../AGENTS.md):

- **Issue**: `[<tracker>#221](https://github.com/<tracker>/issues/221)`
  (or `[#221](https://github.com/<tracker>/issues/221)` when
  the repository is already obvious from context, e.g. inside a
  status-change comment *on* that same issue).
- **PR**: `[<tracker>#NNN](https://github.com/<tracker>/pull/NNN)`
  (`.../pull/N`, not `.../issues/N`).
- **Comment**: link to the `#issuecomment-<C>` anchor, e.g.
  `[<tracker>#216 — issuecomment-4252393493](https://github.com/<tracker>/issues/216#issuecomment-4252393493)`.
- **Milestone**: link to `https://github.com/<tracker>/milestone/<number>`
  (not the title), because milestone titles can change and the number
  is stable. Example: `[3.2.2](https://github.com/<tracker>/milestone/42)`.

**Self-check before presenting any user-visible text** (proposal body,
recap body, status-comment body, apply-loop progress messages): grep
the text for bare `#\d+` tokens and bare `<tracker>#\d+`
tokens and convert any match to the link form. If the scrub finds a
reference the skill does not have the full URL for yet, look it up
with `gh issue view <N> --repo <tracker> --json url --jq .url`
before emitting. The confidentiality rule still applies: these linked
references belong to the private surfaces listed in the
"Confidentiality of `<tracker>`" section of
[`AGENTS.md`](../../../AGENTS.md) and must **never** appear in any
public surface.

---

## Inputs

Before running the skill, you need a **selector** that resolves to one
or more issues:

- **Issue number**: `#185`, `185`, `#212, #214, #218`.
- **CVE ID**: `CVE-2026-40913` — looked up by matching against each
  open issue's *CVE tool link* body field.
- **Title substring**: `JWT`, `KubernetesExecutor` — fuzzy title match;
  always confirm the resolved set with the user before dispatching.
- **Label**: `announced`, `pr merged`, `cve allocated` —
  all open issues carrying that label.
- **All open issues**: `sync all` / `sync all open` — the 21-ish-issue
  default for a triage sweep.

Selectors can be combined (`sync #212, CVE-2026-40690, JWT`) and the
skill resolves each independently. See the "Bulk mode — syncing many
issues in parallel" section below for the full resolution table and
the confirmation prompt pattern.

Optional: a hint from the user about what they want to focus on
(*"has this been CVE-assessed yet?"*, *"is the PR merged?"*, etc.).
Use it to prioritise but still run the full sync.

If the user does not supply any selector, ask for one before doing
anything else.

---

## Bulk mode — syncing many issues in parallel

When the user asks for a bulk sync (*"sync all open issues"*, *"sync
#212, #214 and #218"*, *"refresh state of everything that is still
`cve allocated`"*, or a triage-sweep variant), switch into **bulk
mode**: each issue is assessed by a **separate subagent** running in
parallel, and the orchestrator merges the results into a single
combined proposal for the user to confirm once.

Running the full single-issue flow 20 times in the main agent would
blow the context window with mail threads, PR diffs, and comment
bodies the user does not need to see. Delegating per-issue gathering
to subagents keeps the main context clean and runs the reads
concurrently, which is exactly what the sync needs.

### Orchestrator responsibilities

1. **Pick the issue list.** Resolve the user's selector into a
   concrete list of issue numbers before spawning subagents. The
   selectors the skill accepts, in order of precedence:

   | User input | Resolves to |
   |---|---|
   | `sync all` | every open issue in `<tracker>` **plus recently-closed trackers still awaiting a post-close cve.org publication check**. Resolve as: `gh issue list --repo <tracker> --state open --limit 100 --json number,title,labels` ∪ `gh issue list --repo <tracker> --state closed --label "announced" --limit 50 --json number,title,labels,closedAt --jq '[.[] \| select(.closedAt > (now - 90*86400 \| todate))]'`. The closed bucket is limited to the last 90 days and to trackers carrying the `announced` label — those are the ones waiting for cve.org propagation + the final reporter notification (see [1g](#1g-recently-closed-trackers--check-cveorg-publication-state)). Everything else is a no-op on closed issues and is excluded. |
   | `sync all open` | explicit open-only variant — `gh issue list --repo <tracker> --state open --limit 100 --json number,title,labels`. No closed trackers. Use when you want the classic open-only sweep and nothing else. |
   | `sync #212`, `sync 212`, `sync #212, #214, #218`, `sync #212-#218` | the issue number(s) verbatim — no resolution needed. Works on open and closed trackers alike (the closed-issue sub-steps run when the tracker is closed with `announced`). |
   | `sync CVE-2026-40913` or `sync CVE-2026-40913, CVE-2026-40690` | look up each CVE ID with `gh search issues "CVE-YYYY-NNNNN" --repo <tracker> --json number,title,body --jq '.[] | select(.body \| contains("CVE-YYYY-NNNNN")) \| .number'` (match against the body's *CVE tool link* field) and expand. |
   | `sync <free-text>` (e.g. `sync JWT`, `sync KubernetesExecutor`) | title-substring match — run `gh issue list --repo <tracker> --state open --search "<free-text> in:title" --json number,title` and surface the matches back to the user for confirmation before dispatching (title matches are the fuzziest selector — always confirm, never auto-dispatch). |
   | `sync <label>` (e.g. `sync announced`, `sync pr merged`) | all open issues carrying that label — `gh issue list --repo <tracker> --state open --label "<label>" --json number,title`. |
   | `sync announced` (as a label selector) | as above, open-only. To include the recently-closed `announced` bucket, use `sync all` (default) or `sync closed announced`. |
   | `sync closed announced` | the recently-closed `announced` bucket by itself — useful when you want to run the cve.org publication-check sweep without touching open issues (for example, as a post-release cron). |
   | `sync open` | alias for `sync all open`. |
   | `sync closed` | open *and* closed issues, **all** closed (not just recent `announced`). Explicit, narrow-scope request — most sync actions are no-ops on closed issues that are not in the `announced` bucket. |

   Selectors can be combined: `sync #212, CVE-2026-40690, JWT`
   resolves each independently and dispatches the union of the
   resulting issue numbers. After resolving, **echo the final list
   back to the user and ask for confirmation** before spawning
   subagents — this catches fuzzy-match surprises (a title-substring
   hit that was not intended, a CVE alias that matched two scope
   trackers) before they cost an API round-trip. When the open /
   closed buckets both contribute, group them in the echo so the
   user can tell at a glance *"9 open, 2 recently-closed awaiting
   cve.org"*.

   When the selector resolves to zero issues, tell the user and stop
   — do not fall back to `sync all`.

2. **Spawn one subagent per issue, in a single message.** Use the
   `general-purpose` subagent type and send all `Agent` tool calls in
   the **same assistant message** so they run concurrently. For 20
   issues, that is 20 parallel `Agent` calls in one turn.

   Each subagent prompt must be self-contained and must instruct the
   subagent to:

   - Do **only Step 1** (gather state) from this skill — no
     confirmations, no edits, no draft emails, no label changes, no
     milestone creation, no comments. The subagent is a read-only
     assessor.
   - Read the issue, its closing-PR references, the fixing PR state
     and milestone, the originating Gmail thread, and mine comments
     and mail for the signals in the table in Step 1d.
   - Return a **compact structured report** — not a freeform
     narrative. The exact shape is below.

3. **Aggregate and present one combined proposal.** Once all
   subagents return, fold their reports into one table / numbered
   proposal covering every issue, grouped so the user can confirm
   with `all`, `NN:all`, `NN:1,3`, or per-issue subsets (see the
   existing apply-loop conventions). Only after the user confirms
   does the orchestrator apply changes.

4. **Apply sequentially, not in parallel.** Even though assessment
   ran in parallel, the apply phase must be sequential so
   `gh`-rate-limit surprises, partial failures, and user interrupts
   stay legible. Do not spawn subagents for the apply phase.

### Subagent report shape

Each subagent must return a single code block (or JSON) with exactly
these fields so the orchestrator can merge deterministically:

```
issue: <N>
title: <one line>
scope_label: airflow | providers | chart | <missing>
current_labels: [<label>, ...]
current_milestone: <title or null>
current_assignees: [<login>, ...]
fix_pr:
  url: <<upstream> PR URL or null>
  state: open | merged | closed | null
  author: <login or null>
  author_is_security_team: true | false | null
  merged_at: <ISO8601 or null>
  milestone: <PR milestone title or null>
release_shipped: true | false | unknown
reporter:
  name: <name or null>
  email: <email or null>
  gmail_thread_id: <id or null>
  credit_confirmed_as: <string or null>
  credit_question_pending: true | false
cve_id: <CVE-YYYY-NNNNN or null>
process_step: <number from the README table>
proposed_label_add: [<label>, ...]
proposed_label_remove: [<label>, ...]
proposed_milestone: <title or null, with note "(create)" if it does not yet exist>
proposed_assignees_add: [<login>, ...]
proposed_body_field_updates: [<one-line description>, ...]
proposed_status_comment: <one-line summary or null>
proposed_reporter_email: <one-line summary or null>
blockers: [<short reason the orchestrator or user must resolve before apply>, ...]
notes: <free-form one-to-three sentences, only if something does not fit above>
```

The orchestrator uses the structured fields to produce the merged
proposal table and relies on `blockers` to flag issues that cannot
be resolved without user input (for example a missing Gmail thread
or an ambiguous credit line).

### Hard rules for bulk mode

- **No mutations in subagents.** Subagents must not call
  `gh issue edit`, `gh issue comment`, `gh api … -X PATCH/POST`,
  `gh label create`, `gh api …/milestones` (create), or any Gmail
  send / draft-create tool. They are read-only. If a subagent
  reports it did mutate something, the orchestrator must surface
  that as a bug and stop.
- **No new CVE allocations in subagents.** Printing the CVE
  allocation URL is fine; actually allocating is a human step
  anyway.
- **Gmail drafts are created by the orchestrator**, only after user
  confirmation, and only from the orchestrator's main context. This
  keeps the drafts queue linear and auditable.
- **Confidentiality still applies.** Subagents are bound by the
  same rule: no `<tracker>` content may leak into any
  public surface. This is a no-op for read-only subagents but worth
  stating.
- **Link-form self-check still applies** to the orchestrator's
  merged output — every `#NNN` must be rendered as a clickable link
  per Golden rule 2.

### When bulk mode is **not** appropriate

- The user asked for a single issue (`sync #216`). Run the normal
  flow in the main agent — spawning one subagent for one issue is
  pure overhead.
- The user wants to *drive* the sync interactively ("walk me
  through #216, I want to review each signal as we go"). Bulk mode
  collapses the per-issue detail; use single-issue mode instead.
- The proposed action requires deep multi-turn conversation with
  the user (for example "help me decide whether this is even valid").
  Single-issue mode is the right tool there.

---

## Prerequisites

The skill needs:

- **Gmail MCP** connected to an account subscribed to
  `security@airflow.apache.org`. Required for reading the reporter
  thread and drafting status updates.
- **`gh` CLI authenticated** with collaborator access to
  `<tracker>` (read + issue-write) and `<upstream>`
  (read is enough — the sync only reads PR state on that repo).
- Outbound HTTPS to `pypi.org`, `artifacthub.io`, and
  `lists.apache.org` — the sync curls these to detect released
  versions and to find advisory archive URLs.

See
[Prerequisites for running the agent skills](../../../README.md#prerequisites-for-running-the-agent-skills)
in `README.md` for the overall setup.

---

## Step 0 — Pre-flight check

Before reading any tracker state, verify:

1. **Gmail MCP is reachable** — trivial
   `mcp__claude_ai_Gmail__search_threads` with `pageSize: 1`; an
   auth error here means Gmail MCP is not configured, stop and
   say so.
2. **`gh` is authenticated** with access to `<tracker>` —
   `gh api repos/<tracker> --jq .name` must return
   `airflow-s`. A 401/403/404 means the user needs
   `gh auth login` or collaborator access.
3. **Selector resolves to a concrete issue (or set of issues)** —
   if the user said `sync NNN` but the number does not exist in
   `<tracker>`, stop before Step 1 and ask which issue
   they meant.

If any check fails, stop and surface what is missing. Do **not**
proceed to Step 1 on a partial setup — half the observations would
be wrong and the proposals downstream would be junk.

---

## Step 1 — Gather the current state

Run these reads in parallel where possible. Do **not** make any changes yet.

### 1a. Read the GitHub issue

```bash
gh issue view <N> --repo <tracker> \
  --json number,title,state,body,labels,milestone,assignees,author,createdAt,updatedAt,closedAt,comments
```

Record:

- current labels (note whether `needs triage` is still present, and whether a
  scope label — `airflow`, `providers`, or `chart` — is set);
- current milestone (and whether it matches any linked PR's target release);
- current assignees;
- the report body — check for missing fields the process expects:
  - reporter name / requested credit,
  - CWE,
  - affected product (Airflow / provider name / chart),
  - affected versions,
  - severity score,
  - CVE ID (if allocated),
  - link to the fixing PR(s);
- the discussion so far (comments), paying attention to the most recent activity
  and any stalled-for-30-days state.

Also read the tracker's **project-board status** on the "Security
issues" board — the board is the primary overview surface for the
security team, and every issue has exactly one `Status` option set.
The board column must match the issue's label-derived state; when it
drifts, the sync proposes a move.

The GraphQL introspection recipe for the board lives in
[`tools/github/project-board.md`](../../../tools/github/project-board.md#introspection--find-the-itemid-and-current-column).
The per-project board URL, node IDs, and label → column mapping live
in
[`projects/<PROJECT>/project.md`](../../../projects/<PROJECT>/project.md#github-project-board).

Substitute the project's `<tracker-owner>` / `<tracker-name>` /
`<project-number>` into the introspection query, then record the
item's `itemId` (needed for the Step 4 apply mutation) and the
current `status` column.

### 1b. Find referenced and referencing PRs

First, get the PRs that GitHub itself has linked to the issue via "fixes" /
"closes" / "resolves" keywords:

```bash
gh issue view <N> --repo <tracker> --json closedByPullRequestsReferences
```

Then look for any PR in either repo that mentions the issue number, in either
state. `gh search prs --state` only accepts `open` or `closed`, so run two
queries (or omit `--state` entirely for "any state"):

```bash
gh search prs "airflow-s#<N>" --repo <upstream>         --json number,title,state,url,milestone,mergedAt
gh search prs "#<N>"          --repo <tracker>    --json number,title,state,url,milestone,mergedAt
```

If the issue body itself contains a PR URL (the report template has a "PR with
the fix" field), fetch that PR directly and trust it more than the search:

```bash
gh pr view <PR-NUMBER> --repo <upstream> \
  --json number,title,state,url,milestone,mergedAt,mergeCommit,labels,reviews,isDraft
```

For each PR found, record: number, repo, title, state (open / merged / closed),
merge date, milestone. A PR that is merged into `<upstream>` with a milestone
set is the strongest signal for what milestone the security issue should carry.

### 1c. Find the **real** reporter and read the mailing-list thread

> The author of the GitHub issue in `<tracker>` is **not** necessarily
> the person who reported the vulnerability. Per [`README.md`](../../../README.md)
> step 1, the security team copies reports from the
> `security@airflow.apache.org` mailing list into GitHub issues, so the GitHub
> author is usually a security team member, while the **real reporter** is
> whoever sent the original email. Always identify the real reporter before
> proposing credit, draft replies, or status updates.

Process for finding the real reporter and the original thread:

1. **Do not stop at the GitHub-notification mirror thread.** Searching Gmail
   for the issue title typically returns the GitHub-notification thread
   (`From: <user> via security <security@airflow.apache.org>`,
   `To: <tracker> <airflow-s@noreply.github.com>`) first. That is
   *not* the original report — it is a mirror of the GitHub issue and its
   comments. Filter it out and keep digging.

2. **Search for the original mail by content, not by title.** The GitHub issue
   title is usually paraphrased by the security team member who copied it.
   The original email had a different subject line. Pick a *distinctive
   phrase* from the issue body (a function name, an endpoint, an error
   message) and search Gmail with it, **excluding GitHub notifications**.
   The canonical query template for this search lives in
   [`tools/gmail/search-queries.md`](../../../tools/gmail/search-queries.md#sync-security-issue--reporter-thread-lookup-by-distinctive-phrase)
   (the GitHub-notification exclusions used for this project are
   declared in
   [`projects/<PROJECT>/project.md`](../../../projects/<PROJECT>/project.md#gmail-and-ponymail)).

3. **Identify the original sender.** In the result set, look for the message
   whose `In-Reply-To` is empty (i.e. the root of its thread) and whose
   `From:` is **not** the security team member who created the GitHub issue.
   That sender is the real reporter. Record:

   - their name and email address (e.g. `Jed Cunningham <jedcunningham@apache.org>`),
   - the original Gmail `threadId` — this is the thread you must reply on
     when drafting status updates,
   - the original subject line (you will reuse it for In-Reply-To threading).

4. **Read the full thread** with
   `mcp__claude_ai_Gmail__gmail_read_thread <threadId>` and extract:

   - the reporter's **preferred credit** if they have already stated one
     (name, affiliation, handle, or anonymous) — see the dedicated
     subsection below;
   - any additional technical context or PoC the reporter supplied beyond
     what made it into the GitHub issue;
   - **all status updates already sent to the reporter by the security team**
     — this is what tells you whether a new status update is needed (see
     Step 2b);
   - the latest message in the thread, *who* sent it, and whether the ball
     is in our court.

5. **Sync a reporter-confirmed credit line into the issue body** whenever
   the mail thread contains a clear credit confirmation from the reporter
   that has not yet been reflected in the tracker's *"Reporter credited
   as"* field. This is a dedicated check, not an afterthought — reporters
   frequently reply with their preferred credit line only once, and if
   that reply is not caught in the next sync run, the placeholder stays in
   the issue body and may end up in the public advisory.

   Scan every message **from the reporter** in the Gmail thread
   (identified in steps 1–3), in reverse chronological order, for the
   first message that contains any of the following patterns. Treat the
   first hit as the authoritative credit:

   - *"please credit me as \<X\>"* / *"credit: \<X\>"* / *"please
     kindly include the following credit: \<X\>"*;
   - *"use the handle \<X\>"* / *"use my GitHub handle \<X\>"*;
   - a signature block that the reporter explicitly says should be used
     verbatim for the advisory (*"credit line: \<full name\>, \<company\>
     \[\<country\>\]"*);
   - *"do not credit me"* / *"anonymous"* / *"I'd prefer to remain
     anonymous"* — treat as a confirmed opt-out; set the body field to
     `anonymous` and flag that the advisory must use that form.

   If the extracted credit form differs from what the tracker currently
   carries in *"Reporter credited as"*, propose the update as a concrete
   numbered item in Step 2b. **Do not apply it silently** — the user must
   confirm the exact form before it lands in the body, since the same
   string ends up in the CVE record's `credits[]` and in the eventual
   public advisory.

   If the reporter has been *asked* the credit question but has not yet
   responded, do not propose a change — leave the placeholder in place
   and note in the proposal that the credit question is still pending a
   reply.

   The confirmed-credit check is one of the most load-bearing items in
   the whole sync: a wrong credit line in the advisory is visible to the
   world, hard to correct after publication, and directly undermines the
   trust the reporter extended to us.

5. **If you cannot find the original thread**, say so explicitly in the
   proposal and ask the user whether the GitHub issue author is also the
   reporter (which does happen for issues a security team member discovered
   themselves). Do not assume.

### 1d. Mine comments and mail messages for actionable signals

The GitHub issue comments, the Gmail thread messages, and any cross-
referenced thread (release-announcement emails on `announce@`, PR-review
comments on the public fix PR, GHSA discussion) often contain facts
that the tracker has not caught up with yet. **Read every message
body, not just the headers**, and extract any of the following
signals. Each one translates directly into a proposed body-field
update, label change, or next-step recommendation in Step 2:

| Signal in a message / comment | Translates to |
|---|---|
| Reporter reply with a confirmed credit line (*"please credit me as …"*, *"use handle X"*, *"anonymous is fine"*) | Replace the `Reporter credited as` placeholder with the confirmed form; mark the credit question as resolved so the next status-update draft does not re-ask it. |
| Reporter explicit opt-out of credit (*"do not credit me"*, *"anonymous"*) | Set the field to `anonymous` and flag the advisory to use that form. |
| Release manager's `[RESULT][VOTE] Release Airflow <version>` on `dev@airflow.apache.org` for a version that carries the fix | Record the release manager in the "Known release managers" subsection of [`AGENTS.md`](../../../AGENTS.md) if not already there; flag Step 13 (advisory) as assigned to that person. |
| Advisory message sent to `announce@apache.org` / `users@airflow.apache.org` for the CVE on the tracker | Propose adding the `announced - emails sent` label and removing `fix released`. **Do not propose closing the issue here** — closing is gated on the archived public advisory URL being captured (see the next row). |
| Advisory archived on `users@airflow.apache.org` (the announcement message is now visible in `lists.apache.org/list.html?users@airflow.apache.org` — scan the archive with the CVE ID when `announced - emails sent` is set and the *"Public advisory URL"* body field is empty) | Propose populating the *"Public advisory URL"* body field with the archive URL, regenerating the CVE JSON attachment (the generator picks the URL up automatically and tags it `vendor-advisory`), adding the `announced` label, **and moving the project-board column from `Fix released` to `Announced`** on [`<tracker>` Project 2](https://github.com/orgs/airflow-s/projects/2). The `Announced` column is the board's representation of Step 14 — the advisory has landed and the CVE record is staged with `CNA_private.state = "PUBLIC"` ready for the release manager's single-paste Step 15. **Do not close the issue and do not add the `vendor-advisory` label** — that is Step 15, owned by the release manager after they move the record to PUBLIC in Vulnogram. |
| Project-board column drifted from the issue's label-derived state (e.g. a tracker carries `pr merged` but is still in the `PR created` column on [Project 2](https://github.com/orgs/airflow-s/projects/2), or `announced` + *Public advisory URL* body field populated but the column is still `Fix released`) | Propose moving the project item to the correct column per the mapping table in Step 2b. The board is the primary security-team overview surface; a stale column hides ownership handoffs from the team at a glance. |
| `announced` label set and CVE record on `cveprocess.apache.org` now reports state PUBLISHED (checked via `curl -s https://cveprocess.apache.org/cve5/<CVE-ID>.json` / the ASF CVE tool API, or an explicit release-manager comment on the issue stating the Vulnogram push is done) | Propose closing the issue. Do not update any labels. This is the terminal transition. |
| CVE record has open **review comments / reviewer proposals** (detected via the Gmail-search path in Step 1e — reviewer-comment notifications from Vulnogram land on `security@airflow.apache.org` with the CVE ID in the subject line; the `cveprocess.apache.org/cve5/<CVE-ID>.json` endpoint is behind ASF OAuth and is not readable from this skill's context, so Gmail is the load-bearing signal source). | Surface each open review comment in Step 2a with **clickable links** to the Gmail thread and to the CVE record on `cveprocess.apache.org` (the reader can authenticate in-browser to see live state), verbatim-quoted; then for each one that maps cleanly to a tracking-issue body field (CWE, Affected versions, Reporter credited as, Public advisory URL, Short public summary), **propose the matching body-field update** as a numbered item in Step 2b. The body is the source of truth for the CVE JSON — regeneration in Step 5 will pull the update back into the paste-ready attachment, and the release manager's only remaining action is the Vulnogram paste + comment-resolution click. Comments that do not map to a body field (severity/CVSS, out-of-scope challenges, free-form rewrites) are surfaced verbatim and flagged for human decision. See Step 1e for the full Gmail-search recipe and the reviewer-comment-to-field mapping table. |
| The referenced `<upstream>` PR has been opened but is still in `open` state | Propose `pr created` label; update the *"PR with the fix"* body field with the PR URL. |
| The referenced `<upstream>` PR moved to `merged` | Propose swapping `pr created` → `pr merged`; update milestone to the shipping release if now known. |
| The *"PR with the fix"* body field has at least one PR URL **and** the *"Remediation developer"* body field is missing the PR author's name (or is `_No response_`) | Propose appending the PR author's display name (`gh pr view <N> --repo <upstream> --json author --jq '.author.name // .author.login'`) to the *"Remediation developer"* body field. **Append, never overwrite** — manual edits (co-authors added by the triager, name spelling corrections, "Anonymous" overrides) must survive subsequent syncs. Run once per fresh PR URL added to the field; skip if the resolved name is already present (case-insensitive substring match). The CVE JSON generator reads the field on its next regeneration and emits one `type: "remediation developer"` credit per line, so this hand-off keeps the credit attached even if Vulnogram drops the CLI flag. See the *"Auto-resolve --remediation-developer"* note in Step 5 for the historical CLI-flag fallback. |
| Tracker has the `providers` scope label, the *"Affected versions"* body field is missing or has a pre-convention shape (`?`, bare upper bound against the latest released version, free-form text), and `fix released` is **not** set | Propose populating *"Affected versions"* with one line per affected package in the form `<package-name> < NEXT VERSION` (e.g. `apache-airflow-providers-elasticsearch < NEXT VERSION`). The literal `NEXT VERSION` token is the project's sentinel for "fix not yet released, upper bound unknown" — the providers wave milestone (date-based, e.g. `Providers 2026-04-21`) does not reveal which exact provider package version will carry the fix; only the release manager's `[RESULT][VOTE]` thread on `dev@` after the wave ships does. The CVE JSON generator strips the token before parsing and emits a `versions[]` entry without `lessThan`, so Vulnogram accepts the JSON. Combine with a known lower bound where one applies (e.g. `apache-airflow-providers-smtp >= 2.0.0, < NEXT VERSION`). **This rule is providers-only** — core (`airflow` scope) trackers always know the next core release from the milestone (`Airflow 3.2.2`) and use a real `< X.Y.Z` upper bound from day one. |
| Providers tracker transitions to `fix released` **and** the released package version is now known (from PyPI / the wave's `[RESULT][VOTE]` thread) **and** *"Affected versions"* still contains `NEXT VERSION` | Propose replacing each `NEXT VERSION` with the actual released version, per package: `<package-name> < <X.Y.Z>`. Source the version with `curl -s https://pypi.org/pypi/<package-name>/json \| jq -r '.info.version'` and cross-check against the fix PR's milestone. After the body update, regenerate the CVE JSON attachment so the `versions[]` entry picks up the bounded `lessThan` shape and the record becomes review-ready. |
| A release carrying the fix has shipped (PR's milestone release is on PyPI / Helm registry, or an explicit *"fix shipped in X.Y.Z"* comment) | Propose swapping `pr merged` → `fix released` (Step 12). This is the release manager's cue to own Steps 13–15 (advisory send → URL capture → Vulnogram PUBLIC → close). **Also propose swapping the assignee from the remediation developer to the release manager** (looked up via the three-source cascade in Step 2c — [`projects/<PROJECT>/release-trains.md`](../../../projects/<PROJECT>/release-trains.md) "Release managers for releases currently relevant to the security tracker" → Release Plan wiki → `[RESULT][VOTE]` thread on `dev@`), so the issue list reflects ownership hand-off. See the *Assignee hand-off at the `fix released` transition* paragraph under **Assignees** in Step 2b for the full rule. |
| GHSA state transition (opened, accepted, published, rejected) in a GHSA-forwarded email | If the GHSA is closed as "not accepted" but the security team accepted the report on `security@`, flag the divergence in the status comment so it is not lost. |
| Team member saying *"let's also backport to v3-2-test"* / *"please mark X for backport"* | Note the requested backport label on the public PR as an item for Step 9 of the `fix-security-issue` workflow. |
| Reporter flagging a second distinct vulnerability on the same thread | Surface as an explicit question to the user — it may warrant a separate tracking issue. |
| Team member classifying severity or CWE independently (not copying the reporter) | Propose setting the `Severity` / `CWE` fields accordingly, with a pointer to the comment that established the assessment. |
| Stale "pending" text from an earlier status update (e.g. the tracker still says *"CVE allocation pending"* but the issue body now has a CVE) | Propose removing the stale reference from the status-change comment trail. |

**Scan the two most recent message bodies carefully** — that is where a
freshly-landed signal most often lives. Older messages rarely produce
actionable signals that have not already been applied, but still scan
for the credit-preference keywords listed above whenever a credit
question is still open. When a signal produces an edit to an existing
draft (for example, a catch-up reply is stale because the reporter has
since confirmed credit), surface the stale draft ID explicitly so the
user knows to discard it in Gmail — there is no `draft-update` tool.

**Verify the draft still exists before flagging it.** Before surfacing a
stale-draft ID from a previous sync's comment trail, call
`mcp__claude_ai_Gmail__list_drafts` (optionally narrowed by
`query: 'security@airflow.apache.org'`) and check that the `id` is still
in the result set. If the draft is gone (already discarded or already
sent), **do not** repeat the "discard manually in Gmail" nag in the new
status comment — the flag has self-replicated once and will keep going
forever if every sync copies it forward blindly. If the verification
step itself fails (Gmail 500, API timeout), say so explicitly rather
than defaulting to "assume stale"; silent replication is the failure
mode to avoid.

Do **not** act on signals automatically; as always, each one becomes a
numbered proposal item in Step 2 and only applies after user
confirmation.

### 1e. Check Gmail for CVE review comments sent to `security@airflow.apache.org`

Whenever the tracking issue has a CVE ID allocated (the *CVE tool link*
body field is populated, or the `cve allocated` label is set), look for
reviewer comments on the CVE record in Gmail.

**Why Gmail and not `cveprocess.apache.org`.** The CVE-record JSON on
`https://cveprocess.apache.org/cve5/<CVE-ID>.json` is gated behind ASF
OAuth and returns an HTML login page to anonymous `curl` or `gh api`,
so an automated read from this skill's context is not viable. Vulnogram
instead notifies the CNA mailing list
(`security@airflow.apache.org`) by email whenever a reviewer leaves a
comment / TODO on the record, and those emails are readable from Gmail
through the normal `mcp__claude_ai_Gmail__*` tools the skill already
uses for reporter threads. That is the load-bearing signal path.

**Search recipe.** Use the CVE-review-comment query templates in
[`tools/gmail/search-queries.md`](../../../tools/gmail/search-queries.md#sync-security-issue--cve-review-comment-search);
substitute the active project's `<security-list-domain>` (Airflow:
`security.airflow.apache.org`, declared in
[`projects/<PROJECT>/project.md`](../../../projects/<PROJECT>/project.md#gmail-and-ponymail))
and run via `search_threads` per
[`tools/gmail/operations.md`](../../../tools/gmail/operations.md#search-threads).

Stay inside the skill's Gmail budget: **≤ 2 extra searches per issue**
for the CVE-review path (on top of the Step 1c reporter-thread search
budget).

**Filtering the results.** Not every hit is a reviewer comment. Discard:

- The GitHub-notifications mirror of the tracking issue (already
  excluded by the `-from:` filters above, but double-check the `From:`
  on each hit).
- The original reporter's thread (the sender is in Step 1c's
  `reporter.email`) — these messages mention the CVE but are not
  reviewer comments.
- `[RESULT][VOTE]` or other `dev@airflow.apache.org` release-train
  messages that happen to list the CVE in the advisory body — these
  are post-publication announcements, not review comments.
- Our own outbound messages to `security@` announcing the CVE or
  pasting the JSON — the sender here is a security-team member.

What **is** a reviewer comment: a message sent to
`security@airflow.apache.org` with the CVE ID in the subject, whose
sender is **not** the reporter, not a security-team collaborator, and
not `@apache.org` tooling (typical senders include ASF Security's
CNA-team reviewers, `cve@mitre.org`, or an individual ASF Security
PMC member). The body usually contains explicit proposals — *"Please
update the CWE to CWE-NNN"*, *"The affected range should be `< X.Y.Z`"*,
*"Credits are missing a remediation-developer entry"*, etc.

Read each matching thread **once** with `mcp__claude_ai_Gmail__get_thread`
to extract the comment bodies verbatim.

**Fallback when no CVE-review emails are found.** Absence of signal is
the common case — most CVEs go through REVIEW and PUBLISHED with no
reviewer pushback. Just record `cve_review_comments: []` and move on;
do **not** retry the `cveprocess.apache.org` curl from this skill.

If a reader wants to double-check against the live Vulnogram record,
link to it in the proposal (`https://cveprocess.apache.org/cve5/<CVE-ID>`)
and note that the human can open it in a browser with their ASF login.

For every actionable review comment found, include the following in
the **observed state** in Step 2a:

- a clickable link to the Gmail thread where the comment landed;
- a clickable link to the CVE record on `cveprocess.apache.org`
  (the reader can authenticate in the browser to see the live state);
- a verbatim short quote of the reviewer's ask.

Then, for **each** open review comment, map it to a concrete
proposal on the **tracking issue** (not the CVE record itself — see
the next paragraph on why this matters) and surface it as a
numbered item in Step 2b. The tracking issue body is the
single source of truth for the CVE JSON, so the typical workflow
is: *reviewer asks → update tracking-issue body field → regenerate
CVE JSON attachment (Step 5 of this skill runs it automatically
after apply) → release manager copy-pastes the updated JSON into
Vulnogram's `#source` tab to address the reviewer's comment*. By
proposing the body update directly, the sync saves the release
manager from a round trip: they open the record once (to
acknowledge / resolve the comment after pasting the new JSON),
not twice (once to read the comment, once to paste after a
separate human body edit).

Map common review comments to body fields like this:

| Reviewer comment shape | Proposed body update |
|---|---|
| *"CWE should be CWE-NNN, not CWE-MMM"* / *"This looks like CWE-NNN"* | Propose updating the issue's **CWE** field to the new value, with a quoted pointer back to the comment (*"per reviewer comment on `cveprocess.apache.org/cve5/<CVE-ID>`"*). |
| *"Affected range looks wrong — should be `< X.Y.Z`"* / *"The fix first shipped in X.Y.Z, not the version listed"* | Propose updating the issue's **Affected versions** field to the range the reviewer asked for. |
| *"Missing `vendor-advisory` reference"* / *"No public advisory URL in references"* | Propose populating the issue's **Public advisory URL** body field, using the Step 1d users@-archive-scan path (regeneration will automatically pick it up as a `vendor-advisory` reference — no manual edit of `references[]` needed). |
| *"Credit line `X` is missing"* / *"Move `X` from `finder` to `reporter`"* / *"`Y` asked to be credited as `Z` — please update"* | Propose updating the **Reporter credited as** body field for `finder` credits or the **Remediation developer** body field for `remediation developer` credits (one line per credit in either; the generator preserves order, regeneration in Step 5 picks the change up automatically). |
| *"Severity score should be `<X>` / CVSS vector is wrong"* | Surface the comment in the observed state but **do not** auto-propose a body change. Severity/CVSS is a judgement call that requires independent scoring by a security-team member — per the "Reporter-supplied CVSS scores are informational only" rule in [`AGENTS.md`](../../../AGENTS.md), and the same rule extends to third-party reviewer asks. Flag it as *"needs security-team scoring before addressing"* in Step 2c. |
| *"Fix the description wording — it should say …"* | Propose updating the **Short public summary for publish** body field with the reviewer's suggested text verbatim; flag explicitly in the proposal that it is a paste-as-is and the user should re-read before confirming. |
| *"Mark this as duplicate of CVE-YYYY-NNNN"* / *"This is actually `out of scope` per the Security Model"* | Do **not** auto-propose closing / rejecting. Surface as a blocker requiring a human decision and link the security-team members who last commented on the issue. |
| *"Please re-open for review — I've updated the …"* | No issue-body change; include in Step 2c as *"go back to Vulnogram and click Re-request Review"*. |

For any review comment that does **not** fit one of the rows
above, include it in Step 2a verbatim and flag it in Step 2c for
human decision rather than guessing a body mapping. Being
cautious here is cheap: a wrong auto-proposal costs one round of
user rejection, but a silently-applied wrong change propagates
through the regenerated CVE JSON into a broken PUBLISHED record.

After the user confirms a body-update proposal and it lands,
Step 5 of the apply loop runs `generate-cve-json --attach`
automatically, so the attached CVE JSON is regenerated in the
same sync run — the release manager's next action is just the
Vulnogram paste.

Also include the standard *"Open the CVE record at
`<URL>` and resolve the review comment"* line in Step 2c so the
user knows what the release manager still needs to do in
Vulnogram after the body update lands (resolving the comment is
a Vulnogram UI action that sync cannot drive).

**Do not try to edit the CVE record from this skill.** Writes to
`cveprocess.apache.org` itself stay with the release manager.
Reviewer proposals that cannot be expressed as a body-field
change (wholesale re-descriptions, duplicate-declarations,
out-of-scope challenges) frequently require a judgement call
that belongs with the security team member owning the issue.
Sync's responsibility ends at surfacing the open comments **and**
pre-staging any mechanical body updates so the RM's remaining
work is one Vulnogram paste plus one comment-resolution click
per reviewer ask.

If no CVE ID is allocated yet (the *CVE tool link* body field is
`_No response_` and `cve allocated` is not set), skip this
subsection entirely — there is no record to review-check yet. If
Gmail search 500s or times out, skip this subsection for this sync
run and flag it as a retry in Step 2c; do not hold up the whole
proposal for a transient Gmail error.

### 1f. Locate the process step

Cross-reference the handling process in
[`README.md`](../../../README.md) and determine which numbered step of the
process the issue is currently at:

| Observed state | Process step |
|---|---|
| New issue, `needs triage` label, no assessment discussion | 1–2 (report received, acknowledgement sent) |
| Assessment discussion in progress, no decision | 3 |
| Discussion stalled for more than 30 days | 4 (wider audience) |
| Consensus, invalid → close | 5 / 6 |
| Consensus, valid, no CVE yet | 6 (allocate CVE) |
| CVE allocated, no fix PR yet | 7 |
| Fix PR open, not merged (`pr created` label should be set) | 7 / 8 / 9 / 10 |
| Fix PR merged, no release with the fix has shipped yet (swap `pr created` → `pr merged`) | 11 |
| Release with the fix has shipped, advisory not sent yet (swap `pr merged` → `fix released`) | 12 |
| `fix released` set, advisory not yet sent — release manager owns the advisory | 13 |
| Advisory sent, `announced - emails sent` set, *Public advisory URL* body field still empty (issue stays open) | 13 → 14 |
| *Public advisory URL* populated, `announced` label set (issue stays open — awaiting RM's Vulnogram push) | 14 |
| `announced` set and CVE state is PUBLISHED on `cveprocess.apache.org` → close the issue (do not update labels) | 15 |
| **Closed**, `announced` set, cve.org check **not yet run** for this tracker since close | post-15 (cve.org publication check — see [1g](#1g-recently-closed-trackers--check-cveorg-publication-state)) |
| Closed, credits missing | 16 |

The `pr created`, `pr merged`, and `fix released` labels describe the
fix-side flow; `cve allocated` and `announced - emails sent` describe
the advisory-side flow. Both can coexist on the same issue — for
example, a typical mid-flight issue carries `airflow`, `cve allocated`
and `pr merged` at the same time.

---

### 1g. Recently-closed trackers — check cve.org publication state

For **closed** trackers carrying the `announced` label (the ones
`sync all` now includes alongside open issues), the CNA-tool record
has been moved to `PUBLIC` and the issue was closed at Step 15 —
but propagation from the CNA tool to `cve.org` is asynchronous
(minutes to days). Until cve.org reflects the published state,
there is nothing to tell the reporter except *"still propagating"*;
once it does, the reporter is owed a final *"CVE is live"* email.

The check is read-only and uses the MITRE CVE Services API v2 —
the recipe lives in
[`tools/cve-org/tool.md`](../../../tools/cve-org/tool.md#publication-state-check--check-published).
Concretely, for each closed-`announced` tracker in this run:

1. Extract the `CVE-YYYY-NNNNN` ID from the tracker's *CVE tool
   link* body field (same field the allocate-cve and sync skills
   already read).
2. Call the API:
   ```bash
   curl -sSf https://cveawg.mitre.org/api/cve/<CVE-ID> \
     | jq -r '{state: .cveMetadata.state, datePublished: .cveMetadata.datePublished}'
   ```
3. Interpret:
   - `state == "PUBLISHED"` → capture `datePublished` and propose
     the *CVE-published* reporter email in Step 2b.
   - `state == "RESERVED"` → record *"cve.org shows RESERVED;
     propagation not complete yet"* in the observed state; no
     email yet; a future sync run will catch the publication.
   - `state == "REJECTED"` → **surface as a blocker**. The record
     was withdrawn post-publication. Do not draft a reporter
     email; flag to the security team.
   - `curl` error (404 / 5xx / DNS) → record *"cve.org lookup
     failed — <short error> — try again next sync"*. Do not
     propose notification on an absent response.

**Idempotence.** Check the tracker's comment trail for a prior
*"Sync YYYY-MM-DD — CVE-published reporter notification drafted"*
status-change comment. If one exists and the reporter thread
already carries a corresponding sent message, skip the proposal
and record *"CVE-published notification already sent on <date>"*.

**Gmail-budget.** The cve.org check is a single HTTP call per
tracker — not metered against the Gmail budget. Still, keep it
inside the skill's overall "≤ 1 extra HTTP round-trip per tracker"
soft limit for closed-bucket scans: if multiple closed trackers
are in scope, run the checks in parallel via the subagent fanout
(one curl per subagent), not serially in the orchestrator.

**When the tracker has no CVE ID.** Closed trackers without a
`CVE-YYYY-NNNNN` in the *CVE tool link* body field are closing
dispositions (`invalid` / `not CVE worthy` / `duplicate` /
`wontfix`) — skip the cve.org check entirely and drop the tracker
from the closed-bucket sweep.

---

## Step 2 — Build a proposal (do not apply anything yet)

Produce a single, compact summary for the user with three sections:

### 2a. Observed state

A bullet list of the facts gathered in Step 1 — current labels, milestone,
assignees, linked PRs, mailing-thread status, and the process step the issue is
currently at. Keep it tight.

### 2b. Proposed changes

Each proposed change is a **numbered item** and must be explicit about *what*
will change and *why*. Group them by category:

- **Labels to add / remove** — e.g. *"remove `needs triage`; add `airflow`"*. Reason: one scope label is required by the process once triage is complete.
- **Milestone** — propose the matching release milestone on the
  issue. The milestone format depends on the scope label and is
  project-specific; for the active project see
  [`projects/<PROJECT>/milestones.md`](../../../projects/<PROJECT>/milestones.md)
  (the scope → milestone-format mapping and the rule that a merged PR's
  own milestone wins over the release-train default). The current
  release-train default used when no PR milestone is available lives
  in
  [`projects/<PROJECT>/release-trains.md`](../../../projects/<PROJECT>/release-trains.md).

  **If the milestone does not yet exist**, the proposal must say
  so and include the exact `gh api` command to create it. For a
  provider-wave milestone the description should name the release
  manager so the advisory owner is visible at a glance:

  ```bash
  # Core or chart:
  gh api repos/<tracker>/milestones \
    -f title='<Milestone>' -f state=open \
    -f description='<optional>'

  # Provider wave (cut date + RM from the Release Plan wiki):
  gh api repos/<tracker>/milestones \
    -f title='Providers YYYY-MM-DD' -f state=open \
    -f description='Providers release cut on YYYY-MM-DD, RM: <Name>'
  ```

  After the create call, assign the milestone to the issue via
  `gh issue edit <N> --milestone 'Providers YYYY-MM-DD'` (or by
  milestone number via the REST API if the milestone is closed).

- **Assignees** — when a fix PR exists in `<upstream>` (found in
  Step 1b or named in the *"PR with the fix"* body field) **and the
  PR author is a member of the Airflow security team** (their GitHub
  handle appears in the security-team roster in
  [`projects/<PROJECT>/release-trains.md`](../../../projects/<PROJECT>/release-trains.md) — when in doubt,
  run `gh api repos/<tracker>/collaborators --jq '.[].login'`
  as the authoritative check; **every collaborator counts regardless
  of their permission level** — read, triage, write, maintain, and
  admin are all valid), **propose setting the tracking issue's
  assignee to that PR author**. The PR author is the natural owner
  for driving the issue through the rest of the process (review,
  merge, backport label, advisory coordination), and setting them
  as assignee gives the whole team a fast "who is on this?" answer
  in the issue list.

  If the PR author is **not** on the security-team roster (for
  example, an external contributor who submitted the fix via the
  public process), do **not** assign them — they are not part of the
  internal handling process and do not need the tracking-issue
  notifications. Instead, leave the assignee empty or propose a
  security-team member who is already engaged in the discussion.

  Also propose clearing a stale assignment if the person is no longer
  active on the issue, and propose self-assigning a team member only
  if the user explicitly asks.

  **Assignee hand-off at the `fix released` transition.** When the
  sync transitions an issue to `fix released` (Step 12 — the fix has
  shipped to PyPI / the Helm registry), ownership moves from the
  remediation developer to the release manager for Steps 13–15
  (advisory send → URL capture → Vulnogram PUBLIC → close).
  **Propose swapping the assignee from the remediation developer to
  the release manager** in the same sync run that flips
  `pr merged` → `fix released`, so the issue list reflects who is
  actually on the hook next. Look up the release manager using the
  three-source cascade from Step 2c (the "Known release managers"
  subsection of [`AGENTS.md`](../../../AGENTS.md), then the
  [Release Plan wiki](https://cwiki.apache.org/confluence/display/AIRFLOW/Release+Plan),
  then the `[RESULT][VOTE] Release Airflow <version>` thread on
  `dev@airflow.apache.org`), and propose the swap as a concrete
  numbered item in Step 2b. If the release manager is not a
  collaborator on `<tracker>` yet, surface that as a
  blocker and ask the user whether to invite them before assigning
  — GitHub silently ignores assignee writes for non-collaborators.

  This swap is **only** appropriate at the `fix released`
  transition. Earlier transitions (`pr created`, `pr merged`) keep
  the remediation developer as assignee because the fix PR is still
  their responsibility. Later transitions
  (`announced - emails sent`, `announced`,
  `vendor-advisory`) keep the release manager because the advisory
  lifecycle is theirs. Do **not** shuffle assignees back and forth.
- **Description fields** — if the issue body is missing any of the fields the
  release manager will eventually need (CWE, product, affected versions, severity,
  CVE ID, credits, links to PRs, short public summary for publish), propose a
  patched description. Show the full replacement body in the proposal, not a
  diff, so the user can review it.

  **Every `_No response_` field must be explicitly reviewed in every sync
  run.** Before presenting the proposal, scan the issue body for remaining
  `_No response_` placeholders. For each one, either propose a concrete
  value (if the discussion, the mail thread, the PR, or the GHSA provides
  enough information to fill it in) or flag it explicitly in the proposal
  as *"still `_No response_` — needs \<what\> before it can be filled"*.
  Do not silently leave fields empty across multiple sync runs — the
  release manager at Step 13 needs **every** field filled in to send the
  advisory.

  **Special case for the "Security mailing list thread" field — leave
  it alone.** This field holds the internal navigation reference to
  the private `security@airflow.apache.org` thread that originated the
  report. The URL is expected to 404 for anyone outside the security
  team; that is the intended behaviour. **Do not scrub this field,
  do not replace the URL with a textual note, do not "clean it up".**
  The `generate-cve-json` script no longer exports URLs from this
  field to `references[]`, so the 404-risk it used to carry is gone.
  Keep whatever the reporter or triager put there so the team can
  navigate back to the original thread from the tracker.

  **The "Public advisory URL" body field** is a separate body field
  that carries the archived public advisory URL on
  `lists.apache.org/list.html?users@airflow.apache.org` (or
  `announce@apache.org`). Empty until Step 13 — the release manager
  fills it in **after** the advisory email has been sent and archived.
  Every sync run must:

  1. If `announced - emails sent` is set and the field is still
     empty, **scan the public users@ archive for the CVE ID** using
     the PonyMail API + `list.html` fallback pattern documented in
     [`tools/gmail/ponymail-archive.md`](../../../tools/gmail/ponymail-archive.md#use-case--sync-security-issue).
     The active project's URL templates are declared in
     [`projects/<PROJECT>/project.md`](../../../projects/<PROJECT>/project.md#gmail-and-ponymail)
     (`ponymail_api_url_template`, `ponymail_public_search_url_template`,
     `ponymail_thread_url_template`).
     If the archive returns a hit, propose populating the field with
     the resolved thread URL (per `ponymail_thread_url_template`),
     regenerating the CVE JSON attachment, and adding the
     `announced` label.
  2. If the field is already populated, treat it as authoritative —
     no scan needed. Regenerate the CVE JSON attachment so the URL
     flows into `references[]` as `vendor-advisory`.
  3. The sync skill's responsibility ends when the label is
     `announced`. **Do not propose closing the issue**
     — closing is a Step 15 action and belongs to the release
     manager, who finishes the lifecycle by copying the attached
     CVE JSON into Vulnogram and closing the issue (no label
     changes).
  4. On subsequent sync runs, check whether the CVE record on
     `cveprocess.apache.org/cve5/<CVE-ID>` has moved to PUBLISHED.
     When it has, propose closing the issue (do not update labels).
     This is the only place sync proposes closing an advisory-flow
     issue; all earlier closes are only for closing dispositions
     (`invalid` / `not CVE worthy` / `duplicate` / `wontfix`) at
     Steps 5–6.

  See the "CVE references must never point at non-public mailing-list
  threads" section of [`AGENTS.md`](../../../AGENTS.md) for the full
  rationale of the two-field split.

  **Special case for the `Severity` field — never propagate reporter-supplied
  CVSS scores.** If the reporter attached a CVSS vector or a qualitative label
  (*"Low"*, *"High"*, *"Critical"*) to the mail thread, a GHSA draft, or the
  issue body, surface it in the *observed state* dump as informational context
  (e.g. *"reporter estimated CVSS 4.0 = 7.2 per the GHSA"*) but **do not** use
  it as the proposed value for the `Severity` field. The Airflow security team
  scores every accepted vulnerability independently during the CVE-allocation
  step; the independent score is the one that ends up in the CVE record and
  the public advisory. The `Severity` field on the tracking issue must either
  stay `_No response_` until a security-team member scores it independently
  (in-thread or in an issue comment), or reflect that independent score —
  never the reporter's. Apply the same rule to a self-assigned CWE the
  reporter attaches alongside. Full rationale: the
  "Reporter-supplied CVSS scores are informational only" subsection of
  [`AGENTS.md`](../../../AGENTS.md).
- **Status transitions** — e.g. *"close the issue as invalid"*, *"add `Not yet
  announced` now that <upstream>#NNNN has merged"*, *"add `vendor-advisory
  ready` now that the users@ advisory URL has been captured — the release
  manager will copy the CVE JSON to Vulnogram and close the issue"*.

- **Project-board column.** Every tracker has exactly one `Status`
  option set on the Security-issues board, and the column must match
  the issue's label-derived state. Reconcile whenever the labels and
  the column disagree — the board is the primary overview surface for
  the security team and scans of *"who owns what right now"* start
  there.

  The label + body-state → board-column mapping and the board URL
  live in
  [`projects/<PROJECT>/project.md`](../../../projects/<PROJECT>/project.md#github-project-board).
  Board-column mutations are applied via the GraphQL
  `updateProjectV2ItemFieldValue` mutation; the recipe lives in
  [`tools/github/project-board.md`](../../../tools/github/project-board.md#write--move-a-tracker-to-a-different-column)
  and is invoked from the Step 4 apply list.

- **Status update to the reporter** — **whenever the issue's status has changed
  since the last message we sent to the reporter, propose a Gmail draft that
  brings the reporter up to date.** The set of transitions that warrant a
  status update is enumerated authoritatively in
  [`README.md` — Keeping the reporter informed](../../../README.md#keeping-the-reporter-informed);
  the skill must draft an update when any of those has happened since our
  last message in the original mail thread, including the post-close
  *"CVE is live on cve.org"* transition surfaced by
  [Step 1g](#1g-recently-closed-trackers--check-cveorg-publication-state).

  **Pick the matching canned-response template** rather than
  free-drafting wording. The active project's
  [`projects/<PROJECT>/canned-responses.md`](../../../projects/airflow/canned-responses.md)
  carries one template per lifecycle transition — *"CVE allocated"*,
  *"Fix PR opened"*, *"Fix PR merged"*, *"Release shipped"*,
  *"Advisory sent"*, *"CVE published on cve.org"*, *"Credit
  correction"*. Substitute the SCREAMING_SNAKE_CASE placeholders
  (`CVE_ID`, `PR_URL`, `VERSION`, `ADVISORY_URL`, `RELEASE_URL`)
  with the concrete values read from the tracker body and the
  Step 1b / Step 1g signals. Only draft from scratch if the
  transition is not in the canned set; if you do, follow the
  "Brevity: emails state facts, not context" rule in
  [`AGENTS.md`](../../../AGENTS.md) and offer to add the new
  wording to the canned-responses file as a follow-up.

  Each status update follows the three-paragraph shape from the
  "Brevity: emails state facts, not context" section of
  [`AGENTS.md`](../../../AGENTS.md): (a) one sentence on what
  changed, (b) one sentence on what comes next and roughly when,
  (c) the relevant artifact URLs on their own line(s). Nothing else.
  No re-introduction of the vulnerability, no recap of earlier
  messages on the same thread, no process explanation, no
  speculation about severity or schedule beyond the single
  forward-looking sentence. The reporter read the previous update
  on this same thread — trust that and do not restate it.

  Always reply on the **original** Gmail thread (the one identified
  in Step 1c), not on the GitHub-notifications mirror thread.

  **Use full, clickable URLs for every reference in the email body.**
  Gmail renders plain URLs as clickable links; shorthand like
  ``<upstream>#65346`` or ``<tracker>#261`` does **not**
  render as a link and forces the reporter to reconstruct the URL by
  hand. Concretely:

  - For the internal tracking issue (allowed on the private mail
    thread), write the **full** URL:
    ``https://github.com/<tracker>/issues/<N>``. Do not use
    ``#<N>`` or ``<tracker>#<N>`` shorthand.
  - For fix PRs on ``<upstream>``, write the **full** URL:
    ``https://github.com/<upstream>/pull/<N>``. Do not use
    ``<upstream>#<N>`` shorthand.
  - Same rule for any other GitHub reference you mention in the body
    (public issues, commits, security advisories): always the full
    URL. Markdown-link syntax (``[text](url)``) does **not** render
    in plain-text email — use the bare URL.
  - CVE IDs can stay as ``CVE-YYYY-NNNN`` inline text (email clients
    typically do not autolink them), or be written as the full ASF
    CVE tool URL (``https://cveprocess.apache.org/cve5/CVE-YYYY-NNNN``)
    when you want the reporter to be able to click through.
  - Advisory archive URLs (``lists.apache.org/thread/...``) are
    already full URLs; just paste them as-is.

  This is specific to the **email** path. Comments on the
  ``<tracker>`` issue itself should still use the
  markdown-linked ``[#<N>](url)`` / ``[<upstream>#<N>](url)``
  form per Golden rule 2, because GitHub does render that markdown.

  **Confidentiality:** the existence of `<tracker>` is private (see
  the "Confidentiality of `<tracker>`" section of
  [`AGENTS.md`](../../../AGENTS.md)). A status-update email to the reporter on
  the `security@airflow.apache.org` thread *may* include the `airflow-s`
  tracking-issue URL — the reporter is already on the private thread — but
  the same text **must not** be reused in any public location: do not put it
  in the public `<upstream>` PR description, in any public comment, or in
  the eventual public advisory. When linking from public surfaces, link to
  the public artifact instead (the merged `<upstream>` PR, the published
  CVE on `cve.org`, the `users@` advisory archive).

  **Do not re-ask questions that have already been asked.** Before drafting,
  scan the existing thread end-to-end for any open question we have already
  put to the reporter — most importantly the credit-preference question, but
  also any technical follow-ups. If a question is already pending an answer
  from the reporter, **omit it from the new draft**. Restate the credit
  question only if (a) it has never been asked on the thread, or (b) more than
  ~7 days have passed since it was last asked **and** publication is imminent.
  When in doubt, ask the user before re-pinging the reporter — pinging twice
  about the same question is rude and gets us blocklisted.

  Concrete check: when you find a previous message from the security team in
  the thread, look for keywords like *"credited"*, *"credit"*, *"how would
  you like to be"*, *"name (and, if applicable, affiliation"*, or *"prefer to
  remain anonymous"*. If any of those are present in a message we sent and
  the reporter has not replied, the credit question is **already pending** —
  do not re-ask.

- **Status update on the GitHub issue (`<tracker>`)** — **every
  status change must also be recorded as a comment on the issue itself**,
  not only sent by email. The two-channels rationale (email keeps the
  reporter, issue comment keeps the team and the release manager) lives in
  [`README.md` — Recording status transitions on the tracker](../../../README.md#recording-status-transitions-on-the-tracker).

  **Comment shape — keep the scroll short.** The comment body has two
  distinct audiences with two distinct needs: a triager scrolling the
  issue timeline wants to know *what changed and what is next* in two
  sentences, while a release manager or auditor reading the same issue
  months later wants the full rationale. Satisfy both without making
  the first audience scroll past a wall of text:

  ```markdown
  **Sync YYYY-MM-DD — <one-sentence bold headline of what happened>.**

  - <Action 1: short, imperative, links only when load-bearing>
  - <Action 2>
  - <Action 3>

  **Next:** <one sentence on the expected next step>.

  <details>
  <summary>Details of update</summary>

  <everything else: verbatim reviewer comments, CVSS rationale,
  RM-attribution trail, label-transition reasoning, stale-draft
  flags, cross-links, prior-comment pointers, etc. All of the
  context that helps the auditor but that the scroller does not
  need.>

  </details>
  ```

  Keep the visible part — everything above the `<details>` block —
  under roughly **six lines** of rendered markdown. If a single
  item cannot be compressed to one bullet, break it into an action
  headline at the top and push the reasoning into `<details>`.
  Clickable `<tracker>` references (Golden rule 2) apply
  to both the visible part and the `<details>` interior.

  **The first line of every status-change comment MUST be a bold-
  markdown headline.** It starts with `**` and ends with `**` (or
  `**...**.`), and it names the kind of change inline — `**Sync …`,
  `**Status update …`, `**Merged [<tracker>#<drop>] …`,
  `**Closing as duplicate of …`, `**Split for scope clarity …`,
  `**Imported on YYYY-MM-DD …`. Do **not** open with a plain
  `Sync status (sync-security-issue skill, YYYY-MM-DD)`-style line:
  that form (no bold, no inline headline) is what the older
  pre-collapse comments used, and it is easy for automated
  detection passes to miss — every comment produced by this skill
  has to follow the bold-headline + `<details>` shape so both
  humans scrolling the timeline and future automation can
  identify it unambiguously.

  **Legacy flat-format comments.** Trackers created before the
  collapsed-`<details>` shape was adopted carry sync-status comments
  written as one long wall of text. Step 1d's comment-mining pass
  MUST surface **every** legacy-format comment on the tracker being
  synced — detection is a **content-anchored** sweep, not a
  prefix-anchored one. Look for *any* comment whose body lacks a
  `<details>` disclosure and whose first ~500 characters match any
  of:

  - a bold prefix — `**Sync `, `**Status update`, `**Merged `,
    `**Closing as duplicate`, `**Split for scope clarity`,
    `**Imported on `;
  - a bare-text prefix (legacy, no `**`) — `Sync status (`,
    `Sync YYYY-MM-DD`, `Status update`;
  - a content tell that indicates a sync-style post even when the
    prefix is idiosyncratic — `sync-security-issue skill`,
    `re-triage`, `Reporter notification still pending`,
    `Outstanding — Step `.

  For each hit, propose a **body-rewrite** as one of the numbered
  items in the Step 2 proposal: keep the original content verbatim
  inside a new `<details>Details of update</details>` block, and
  replace the opening with a short two- or three-line bold-headline
  + `**Next:**` + reporter-notification line that matches the
  current shape. Apply the rewrite with `gh api -X PATCH
  repos/<tracker>/issues/comments/<id> --input <json>`
  (where `<json>` is a `{"body": "..."}` payload — `--field
  body=@file` URL-encodes the newlines). Do not silently rewrite
  history: surface each rewrite as its own proposal item so the
  user sees exactly which comment is being reshaped.

  End the visible part with exactly one of the reporter-notification
  status lines:

  - *"Reporter has been notified on the original mail thread."* — when a
    status-update draft has been created in the same sync, **or**
  - *"No reporter notification needed (reporter is on the security team)."*
    — only if the real reporter is themselves a member of the security team
    and is already in the loop, **or**
  - *"Reporter notification still pending — see draft `<draftId>`."* — if a
    draft was created but the user has not yet sent it, **or** simply
    omit the line when no reporter notification is meaningful (for
    example on a team-discovered issue with no reporter thread).

- **Draft email to reporter (other reasons)** — whenever the ball is in our
  court on the email thread for any other reason (a question from the
  reporter, a follow-up needed for triage, communicating a negative
  assessment), propose a **Gmail draft** reply (not a sent message). State
  the intent of the draft in one line and prefer to reuse a canned response
  from [`canned-responses.md`](../../../projects/<PROJECT>/canned-responses.md) verbatim where
  one applies. Show the exact subject, recipients, In-Reply-To, and body in
  the proposal.

  **Brevity** applies here too — if no canned response fits and you are
  drafting fresh wording, keep it to the facts the reporter needs (the
  question being answered, the decision being communicated) plus one
  artifact link. See the "Brevity: emails state facts, not context"
  section of [`AGENTS.md`](../../../AGENTS.md).

  **Never send.** Always create a draft. Prefer attaching it to the
  inbound mail thread by `threadId` (from Step 1c); if Step 1c
  could not resolve a `threadId`, fall back to a subject-matched
  draft (`threadId` omitted, `subject: Re: <root subject>`) per the
  threading rule in
  [`tools/gmail/threading.md`](../../../tools/gmail/threading.md).
  Surface which path was taken in the proposal. The Gmail MCP's
  no-update-no-delete limitation — and the resulting rule that
  corrections surface the prior `draftId` for manual discard
  rather than silently shadowing it — is documented in
  [`tools/gmail/operations.md`](../../../tools/gmail/operations.md#hard-limitation--no-update-no-delete).

### 2c. Next-step recommendation

A single short paragraph describing what the user should do *after* these
updates land, based on the process step. Examples:

- *"Step 3: start the CVE-worthiness discussion in a comment on the issue, tagging at least one other security team member."*
- *"Step 4: draft a consultation message for `private@airflow.apache.org` — the discussion has been stalled for 34 days."*
- *"Step 6: allocate a CVE. Run the [`allocate-cve`](../allocate-cve/SKILL.md) skill (it prints the ASF Vulnogram form URL plus a CVE-ready title and wires the allocated ID back into the tracker)."*
- *"Step 10: close the private PR at <tracker>#NNN now that <upstream>#NNNN has merged."*
- *"Step 11: `pr merged` — tracker parked until the release train ships. No action needed from the security team; the next sync run will detect the PyPI / Helm release and propose the `fix released` swap (Step 12)."*
- *"Step 12: `fix released` — the release carrying the fix is now on PyPI / the Helm registry. Ownership of the issue has transferred to the release manager; the label swap was the hand-off."*
- *"Step 13: the release manager should now fill in the CVE tool fields taken from the issue — CWE, product, versions, severity, patch link, credits — move the CVE to REVIEW → READY, and send the advisory to `announce@apache.org` / `users@airflow.apache.org`."*
- *"Step 14: scan the users@ archive for the CVE ID, populate the *Public advisory URL* body field, regenerate the CVE JSON attachment, and move the issue to `announced`. Sync does all of this automatically on the next run once the advisory is archived."*
- *"Step 15: release manager — copy the regenerated CVE JSON into Vulnogram, close the issue."*

**Never guess the release manager.** When a next-step recommendation or a
status-comment references "the release manager for `<version>`", look up
the actual person, in this order:

1. **Check the "Known release managers" subsection of
   [`AGENTS.md`](../../../AGENTS.md) first** — if the release is already
   listed there, use that name. This is the cache; the next two sources
   are how the cache was populated and how you refresh it.
2. **Check the Airflow Release Plan wiki** at
   <https://cwiki.apache.org/confluence/display/AIRFLOW/Release+Plan>.
   This is the canonical forward-looking schedule for every release
   train (core Airflow, Providers, Airflow Ctl, Helm Chart, Airflow 2)
   and lists the release manager for each *upcoming* cut. Use this when
   the relevant release hasn't been cut yet, or when you need the
   rotation roster.
3. **Check the `[RESULT][VOTE]` thread on `dev@airflow.apache.org`** —
   the sender of the `[RESULT][VOTE] Release Airflow <version>` (or
   `[RESULT][VOTE] Airflow Providers - release preparation date
   <YYYY-MM-DD>`) message **is** the release manager for that specific
   cut. Use this when the release has already shipped (the wiki only
   tracks upcoming schedule, not past releases). Gmail search query
   for providers:
   `"[RESULT][VOTE]" "Airflow Providers" from:dev@airflow.apache.org`.
   Narrow with a date range if needed.

If the release manager is not yet in
[`projects/<PROJECT>/release-trains.md`](../../../projects/<PROJECT>/release-trains.md)
after you look them up, surface that in the proposal and propose
appending them (with the source link to the `[RESULT][VOTE]` thread
and the release date) to the "Release managers for releases currently
relevant to the security tracker" subsection in the same sync run. **Do
not substitute a "plausible" name** (e.g. a frequent release manager
from previous releases) — the release manager rotates per cut, and a
wrong name in a status update leads to the advisory sitting on nobody's
desk.

**If a CVE needs to be allocated**, always point the user at the
[`allocate-cve`](../allocate-cve/SKILL.md) skill explicitly on its own
line so the handoff is unambiguous:

> Allocate a CVE via the [`allocate-cve`](../allocate-cve/SKILL.md)
> skill. It opens the ASF Vulnogram form at
> <https://cveprocess.apache.org/allocatecve>, pre-computes a CVE-ready
> title (stripped of `Apache Airflow:` / `[ Security Report ]` / version
> noise), and — once you paste back the allocated `CVE-YYYY-NNNNN` ID —
> wires it into the tracker (body field, label, status comment, CVE
> JSON embed).

**Whenever a CVE ID is mentioned** — in the proposal, in the status-change
comment on the `airflow-s` issue, in the draft email to the reporter, or in
the recap — render it as a clickable link per the "Linking CVEs" section of
[`AGENTS.md`](../../../AGENTS.md). Concretely:

- Before publication: link to the ASF CVE tool record, e.g.
  `[CVE-2026-40690](https://cveprocess.apache.org/cve5/CVE-2026-40690)`.
- After publication (issue has `vendor-advisory`, advisory has been sent to
  `users@airflow.apache.org`): additionally link to the public `cve.org`
  record, e.g. `CVE-2025-50213 ([ASF](https://cveprocess.apache.org/cve5/CVE-2025-50213),
  [cve.org](https://www.cve.org/CVERecord?id=CVE-2025-50213))`.

Do not emit bare `CVE-YYYY-NNNNN` text — always link.

See **Golden rule 2** at the top of this skill: every
`<tracker>` reference in the proposal must be a clickable
markdown link. Do not emit bare `#NNN` or `<tracker>#NNN`.

---

## Step 3 — Confirm with the user

Present the proposal and ask the user to confirm which items to apply. Accept
any of the following forms of confirmation:

- `all` — apply everything.
- `1,3,5` — apply only the listed items.
- `none` / `cancel` — apply nothing.
- free-form edits — if the user asks for changes to a specific proposed item,
  regenerate just that item and re-confirm.

Never assume confirmation. If the user replies ambiguously, ask again.

---

## Step 4 — Apply confirmed changes

For each confirmed item, run exactly one command and report the result
before moving on to the next item. Use:

- **Labels:** `gh issue edit <N> --repo <tracker> --add-label "..." --remove-label "..."`
- **Milestone (existing):** `gh issue edit <N> --repo <tracker> --milestone "<title>"`
- **Milestone (create then assign):** run the create call from 2b, then the edit.
- **Assignees:** `gh issue edit <N> --repo <tracker> --add-assignee @me` (or a named user).
- **Description:** `gh issue edit <N> --repo <tracker> --body-file <tmpfile>` — write the
  new body to a temporary file first so nothing is lost to shell quoting.
- **Comments:** `gh issue comment <N> --repo <tracker> --body-file <tmpfile>`.
  Before posting, **scrub the comment body for bare-name mentions** of
  anyone on the "Current release managers" or rotation-roster lists in
  [`AGENTS.md`](../../../AGENTS.md), and of known security-team members.
  Replace each bare name with the corresponding ``@``-handle (or
  `"<Full Name> (@handle)"` when readability warrants keeping the
  plain name too) so GitHub actually notifies the person. See the
  "Mentioning Airflow maintainers and security-team members" section
  of [`AGENTS.md`](../../../AGENTS.md). Concrete grep-list to check
  against: `Jarek Potiuk`, `Jens Scheffler`, `Vincent BECK`,
  `Shahar Epstein`, `Buğra Öztürk`, `Jedidiah Cunningham`,
  `Rahul Vats`, `Aritra Basu`, `Pierre Jeambrun`, `Kaxil Naik`,
  `Amogh Desai`, plus any name that appears in a `Reporter credited
  as` field without a confirmed external-credit decision.
- **Close / reopen:** `gh issue close <N> --repo <tracker> --reason completed` (or `not planned`).
- **Project-board column:** apply via the `updateProjectV2ItemFieldValue`
  GraphQL recipe in
  [`tools/github/project-board.md`](../../../tools/github/project-board.md#write--move-a-tracker-to-a-different-column).
  Substitute the project's board node ID, status-field node ID, and
  target-column option ID from
  [`projects/<PROJECT>/project.md`](../../../projects/<PROJECT>/project.md#github-project-board).
  Use the `itemId` captured in Step 1a's board read. If the issue
  does not yet have a project item, use the orphan-issue path from
  the same reference (`addProjectV2ItemById` then
  `updateProjectV2ItemFieldValue`). Re-fetch the option IDs via the
  introspection query in the same reference if a write mutation
  starts returning `not found`.
- **Gmail draft:** `mcp__claude_ai_Gmail__create_draft` — **prefer**
  passing the `threadId` from Step 1c. If Step 1c could not
  resolve a `threadId`, fall back to a subject-matched draft (omit
  `threadId`, keep `subject: Re: <root subject of the inbound
  message>`) — see the
  [fallback rule](../../../tools/gmail/threading.md#fallback--subject-matched-draft-when-threadid-is-unavailable)
  and the call-signature variants in
  [`tools/gmail/operations.md`](../../../tools/gmail/operations.md#create-draft).
  **Surface which path the draft took** (`threadId`-attached vs.
  subject fallback) in the proposal so the user can see the
  threading at a glance; record the reason on the tracker's status
  comment when fallback kicks in. **Never send.** Tell the user the
  draft is waiting for their review in Gmail.

If any command fails, stop the apply loop, report the failure, and ask the user
how to proceed — do not guess.

---

## Step 5 — Regenerate the CVE artifact via the project's CVE tool

After the apply loop finishes — **every time**, not as a proposal — regenerate the
CVE artifact via the project's declared CVE tool. For the active project (`cve_tool: vulnogram` —
see [`projects/<PROJECT>/project.md`](../../../projects/<PROJECT>/project.md#cve-tooling)) that means
running the
[`generate-cve-json`](../../../tools/vulnogram/generate-cve-json/SKILL.md) script with `--attach`
to refresh the CVE JSON attachment on the tracking issue. The Vulnogram-side
record mechanics (DRAFT / REVIEW / PUBLIC state machine, `#source` paste flow) live
in [`tools/vulnogram/record.md`](../../../tools/vulnogram/record.md). The attachment
lives **embedded in the issue body** (at the very end, right after the
*CVE tool link* field), not as a separate comment — this way it stays
above every status-change comment in the timeline and reads as part of
the tracker itself. Re-running the generator is cheap and idempotent: the
script brackets its block with a pair of HTML-comment markers
(``<!-- generate-cve-json: cve=CVE-YYYY-NNNN+ version=v1 -->`` …
``<!-- generate-cve-json:end cve=CVE-YYYY-NNNN+ version=v1 -->``) and on
every run **replaces the block between them in place**, leaving the rest
of the body untouched. If there is no previous attachment block yet, the
script appends a fresh one after the *CVE tool link* field.

Keeping the attachment in lock-step with the tracking issue body has two
payoffs:

1. The release manager can always grab the most-current JSON straight from
   the issue at advisory-publication time, without having to remember to
   regenerate, and without scrolling through the comment timeline.
2. The `#source` paste URL is visible on every sync, so if a reviewer
   notices the issue body drifting from the Vulnogram record they can
   jump straight to the paste-ready JSON.

### When to skip

Skip the regeneration **only** when one of the following is true, and call
it out explicitly in the Step 6 recap:

- **No CVE has been allocated yet** — the issue body's *CVE tool link*
  field is still `_No response_`. Running the generator in that state
  would embed a block with an `UNKNOWN` CVE marker, which is not useful.
  Remind the user to allocate a CVE via
  <https://cveprocess.apache.org/allocatecve> and mention that the next
  sync run will embed the JSON automatically once a CVE is set.
- **The tracking issue was closed as `invalid` / `not CVE worthy` /
  `duplicate`** and there is nothing to attach.

In every other case — including already-published CVEs — regenerate.

### How to run it

The minimum command, from the `<tracker>` clone root:

```bash
uv run --project tools/vulnogram/generate-cve-json generate-cve-json <N> --attach
```

That alone is enough. The script reads every template field from the
issue body, emits the full CVE 5.x record, and patches (or appends to)
the tracking issue body in place.

### Remediation-developer credit comes from the body field

The *Remediation developer* body field is the **single source of
truth** for the `type: "remediation developer"` credits in the
regenerated JSON. The generator reads the field directly via
`extract_field`, parses it newline-by-newline (same shape as
*Reporter credited as*), and emits one credit per non-empty line.
**No `--remediation-developer` CLI flag is needed in the normal
flow.**

The PR-author resolution that used to happen at regeneration time now
happens earlier: the table in Step 1d (the row that fires when
*"PR with the fix"* is set and *"Remediation developer"* is missing
the PR author) appends the resolved name to the body field. By the
time Step 5 runs, the field already contains the right names, the
generator picks them up, and the embedded JSON carries the credit.

This earlier hand-off matters for two reasons:

1. **The credit survives manual edits.** Co-authors added by the
   triager, name spelling corrections, or "Anonymous" overrides all
   live in the body field where they are visible at a glance and
   diffable in the issue history. The previous CLI-flag flow lost
   any such edit on the next regen.
2. **The credit survives lost overrides.** Re-running
   `generate-cve-json --attach` after a long gap no longer needs the
   triager to remember which `--remediation-developer` flag was
   passed last time — the field is in the body and survives any
   number of regen cycles.

**Pitfall caught on
[<tracker>#241](https://github.com/<tracker>/issues/241)** — the
body mentioned `<upstream>#44322` as prior-art context before the
actual fix `<upstream>#63028`, and a naive `grep | head` against the
whole body had picked the wrong PR. The Step 1d row scopes the URL
extraction to the *"PR with the fix"* section only (`awk` between the
section heading and the next `### ` heading) for exactly this
reason; the same scoping rule applies if you ever need to resolve
the author by hand.

```bash
uv run --project tools/vulnogram/generate-cve-json generate-cve-json <N> --attach
```

If the *"Remediation developer"* field is empty at regeneration time
(e.g. because the PR author lookup in Step 1d hasn't run yet on a
freshly-set *PR with the fix* field), the regen succeeds but the
embedded JSON carries no remediation-developer credit. Either run a
follow-up sync to populate the field, or pass `--remediation-developer
"<Name>"` once on the command line and let the next sync fold the
name into the body field for permanence.

### Don't override `--version-start`

The sync skill deliberately does **not** try to guess `--version-start`.
If the *Affected versions* body field has a `>= X, < Y` shape, the script
picks `X` automatically. If it has a bare `< Y` shape (the typical
Airflow case), the script's default `"0"` is used, and the reviewer can
tighten it later with a manual `--version-start 3.0.0` invocation that
patches the same embedded attachment block.

### Report the result

The script prints one of two lines on success:

- `Embedded CVE JSON in issue body on <tracker>#<N>` — first
  run (or first run after the legacy comment-based attachment was
  cleaned up).
- `Replaced CVE JSON in issue body on <tracker>#<N>` —
  subsequent run; the existing embedded block was replaced in place.

Capture the printed URL — it deep-links to the `## CVE JSON — paste-ready
for <CVE>` heading anchor inside the body — and include it in the Step 6
recap so the user has one-click access to the attached JSON.

---

## Step 6 — Recap

After the regeneration step finishes, print a short recap:

- what was changed, what was skipped;
- the drafts that are now waiting in Gmail (with a link to the thread);
- the next step from 2c, repeated so the user does not have to scroll;
- the CVE allocation link, if applicable;
- the embedded CVE JSON URL (deep-links to the
  `## CVE JSON — paste-ready for <CVE>` heading anchor inside the
  tracker body), or an explicit note that regeneration was skipped
  because no CVE has been allocated yet.

**Before presenting the recap**, apply the Golden rule 2 self-check to
the entire recap text: any mention of the tracking issue, any
cross-referenced `<tracker>` issue, any PR, any specific
comment anchor and any milestone must be a clickable markdown link.
The user has to be able to click every `airflow-s` reference in the
recap without manually pasting the number into the URL bar.

Concrete minimum that every recap must include as clickable links:

- the **tracking issue header** (e.g. *"Sync complete on
  [`<tracker>#233`](https://github.com/<tracker>/issues/233)"*);
- the **status-change comment** the sync just posted, as a
  `#issuecomment-<C>` anchor link;
- the **embedded CVE JSON section** from Step 5, deep-linked via the
  body's heading anchor (e.g.
  `https://github.com/<tracker>/issues/<N>#cve-json--paste-ready-for-<cve-id-slug>`);
- any **cross-referenced issues** mentioned by the proposal (for
  example *"similar to [`<tracker>#214`](…)"*);
- any **milestone** the sync moved the issue to, as a
  `…/milestone/<number>` link.

If a reference is missing from the above list, fetch its URL before
finalising the recap.

---

## Guardrails

- **Never send email.** Only create drafts.
- **Never force-push, never delete labels or milestones without confirmation,
  never close or reopen an issue without confirmation.**
- **Never fabricate** a CVE ID, CWE, severity score, or reporter name. If a field
  is missing, mark it as *unknown* in the proposal and ask the user to supply it.
- **Never propagate a reporter-supplied CVSS score or qualitative severity
  label** into the `Severity` field, the proposed body patch, the CVE JSON,
  the status-change comment, the draft email reply, or any other
  user-visible surface. Surface it in the *observed state* only, tagged as
  informational. The Airflow security team scores every accepted
  vulnerability independently during the CVE-allocation step. See the
  "Reporter-supplied CVSS scores are informational only" section of
  [`AGENTS.md`](../../../AGENTS.md) for the full rationale.
- **Never paraphrase the Security Model** in the draft email. Link to the
  relevant chapter on
  `https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html`
  instead, following the editorial guidance in [`AGENTS.md`](../../../AGENTS.md).
- **Tone of any drafted email must be polite but firm** — see the "Tone: polite
  but firm — no room to wiggle" section of [`AGENTS.md`](../../../AGENTS.md).
- **Brevity.** Every drafted email follows the three-paragraph shape in the
  "Brevity: emails state facts, not context" section of
  [`AGENTS.md`](../../../AGENTS.md): one sentence on what changed, one on
  what comes next, artifact URLs on their own line(s). No recap of earlier
  messages on the same thread, no re-introduction of the vulnerability, no
  process explanation. Messages to the ASF security team or to PMC members
  are even terser — they already know the process.
- **Milestone naming** must follow the project's convention. For the
  active project the formats (and the create-missing-milestone recipe)
  live in
  [`projects/<PROJECT>/milestones.md`](../../../projects/<PROJECT>/milestones.md).
  When a milestone does not yet exist in the tracker, the sync proposal
  creates it via `gh api` and then assigns the issue.
- **Scope label is mandatory once triage is complete** — exactly one
  of the scope labels defined in
  [`projects/<PROJECT>/scope-labels.md`](../../../projects/<PROJECT>/scope-labels.md).
  The `task-sdk` note (through Airflow 3.2.x the Task SDK ships bundled
  into `apache-airflow` and Task-SDK-only reports are classified under
  `airflow`; from 3.3+ a new `task-sdk` label is needed) lives with the
  release-train state in
  [`projects/<PROJECT>/release-trains.md`](../../../projects/<PROJECT>/release-trains.md).
- **Multi-scope reports must be split into one tracking issue per
  scope.** When an incoming report turns out to affect more than one
  scope (for example a bug whose root cause lives in
  `airflow.utils.*` but the same vector also exists in a provider's
  hook), the sync skill must **not** apply two scope labels to one
  issue. Instead, propose splitting the report so each scope has its
  own tracker. Concretely:

  1. Keep the original issue on the scope whose milestone family will
     ship *first* (usually core Airflow vs. a providers wave — core
     patch releases cut on a faster cadence, so core is typically the
     anchor). Drop the extra scope label from that issue.
  2. Create one new issue per remaining scope via `gh issue create
     --repo <tracker>`, copying the report body
     verbatim but with a one-line preamble that says *"Split from
     [#NNN](...) for the `<scope>` scope — see that issue for the
     full discussion history."* This preamble keeps the scope's
     auditable history on that issue without forcing readers to
     scroll through comments in another tracker.
  3. Apply to each split issue:
     - exactly one scope label (see
       [`projects/<PROJECT>/scope-labels.md`](../../../projects/<PROJECT>/scope-labels.md));
     - the same `cve allocated` label if a CVE is shared across
       scopes — CVE reuse is correct when the same upstream bug
       affects multiple products, with one `affected[]` entry per
       product in the CVE record;
     - the PR / advisory labels (`pr created` / `pr merged` /
       `fix released`) derived independently per scope from the same
       fix PR, because each scope rides a different release train;
     - the matching milestone for that scope (see
       [`projects/<PROJECT>/milestones.md`](../../../projects/<PROJECT>/milestones.md));
     - the same assignee set as the anchor issue.
  4. Post a cross-link comment on **each** issue pointing at the
     other(s), so the maintainers and the reporter can see the full
     picture at a glance.
  5. Update the reporter email draft (if one is open) to mention
     the split and link to every tracker, so the reporter does not
     have to chase separate notifications.

  Do **not** silently drop a scope label without splitting — both
  scopes need their own tracker so that scope-specific release
  managers can see the issue on their milestone without inheriting
  irrelevant context from the other scope. A single issue with two
  scope labels at once is a process bug; the sync skill should flag
  it as a **blocker** and propose the split action as a concrete
  numbered item.

---

## Process reference

The canonical handling process lives in [`README.md`](../../../README.md). When
in doubt, re-read the numbered step for the state you believe the issue to be
in rather than improvising. If the process document and the observed state
disagree, surface the disagreement in the proposal and let the user decide.

## Canned responses

When drafting an email reply, prefer a verbatim canned response from
[`canned-responses.md`](../../../projects/<PROJECT>/canned-responses.md) over ad-hoc text. The
currently available canned responses include: confirmation of receipt (now
including the credit-preference question), invalid Simple Auth Manager report,
invalid automated report, consolidated multi-issue report rejection, "not an
issue — please submit it", parameter injection in operators/hooks, DoS by
authenticated users, Dag-author user-input claims, image scan results, self-XSS
by authenticated users, positive and negative assessment, automated scanning
results, DoS/RCE/arbitrary read via connection configuration, and media-report
requests. If none of them fit, draft a new reply that follows the editorial
rules in `AGENTS.md` and offer to add it to
[`projects/<PROJECT>/canned-responses.md`](../../../projects/<PROJECT>/canned-responses.md)
as a follow-up.
