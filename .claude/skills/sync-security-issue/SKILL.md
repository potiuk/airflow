---
name: sync-security-issue
description: |
  Synchronize a security issue in airflow-s/airflow-s with the state of its
  GitHub discussion, the security@airflow.apache.org mailing thread, and any
  apache/airflow PRs that fix it. The skill gathers all relevant signals,
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

# sync-security-issue

This skill reconciles a single security issue in
[`airflow-s/airflow-s`](https://github.com/airflow-s/airflow-s) with:

1. the **GitHub issue** itself — comments, labels, milestone, assignee, description fields;
2. the **email thread** on `security@airflow.apache.org` that originated the report (and any follow-ups);
3. any **pull requests** in `apache/airflow` or `airflow-s/airflow-s` that reference or fix the issue;
4. the **handling process** documented in [`README.md`](../../../README.md).

**Golden rule 1 — propose before applying.** Every change this skill
performs is a *proposal*. The user running the sync must explicitly
confirm each update before it is applied. Do not mutate GitHub state, do
not send email, do not create, close, or edit anything without a clear
"yes" from the user for that specific action. Drafts are always created
as Gmail **drafts**, never sent directly.

**Golden rule 2 — every `airflow-s/airflow-s` reference is a clickable
link.** Whenever this skill mentions the tracking issue, any other
`airflow-s/airflow-s` issue, a `airflow-s/airflow-s` PR, a specific
issue comment, a milestone, or a label from this repository — in the
observed-state dump, in the proposal, in the confirmation prompt, in
the apply-loop output, in the regeneration output, in the recap, in
status-change comments posted to the issue itself, anywhere — render
it as a markdown link the user can click, **never** as a bare `#NNN`
or `airflow-s/airflow-s#NNN` or plain-text number. The link form is
defined in the "Linking `airflow-s/airflow-s` issues and PRs" section
of [`AGENTS.md`](../../../AGENTS.md):

- **Issue**: `[airflow-s/airflow-s#221](https://github.com/airflow-s/airflow-s/issues/221)`
  (or `[#221](https://github.com/airflow-s/airflow-s/issues/221)` when
  the repository is already obvious from context, e.g. inside a
  status-change comment *on* that same issue).
- **PR**: `[airflow-s/airflow-s#NNN](https://github.com/airflow-s/airflow-s/pull/NNN)`
  (`.../pull/N`, not `.../issues/N`).
- **Comment**: link to the `#issuecomment-<C>` anchor, e.g.
  `[airflow-s/airflow-s#216 — issuecomment-4252393493](https://github.com/airflow-s/airflow-s/issues/216#issuecomment-4252393493)`.
- **Milestone**: link to `https://github.com/airflow-s/airflow-s/milestone/<number>`
  (not the title), because milestone titles can change and the number
  is stable. Example: `[3.2.2](https://github.com/airflow-s/airflow-s/milestone/42)`.

**Self-check before presenting any user-visible text** (proposal body,
recap body, status-comment body, apply-loop progress messages): grep
the text for bare `#\d+` tokens and bare `airflow-s/airflow-s#\d+`
tokens and convert any match to the link form. If the scrub finds a
reference the skill does not have the full URL for yet, look it up
with `gh issue view <N> --repo airflow-s/airflow-s --json url --jq .url`
before emitting. The confidentiality rule still applies: these linked
references belong to the private surfaces listed in the
"Confidentiality of `airflow-s/airflow-s`" section of
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
- **Label**: `vendor-advisory ready`, `pr merged`, `cve allocated` —
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
   | `sync all` (or `sync all open`) | every open issue in `airflow-s/airflow-s` — run `gh issue list --repo airflow-s/airflow-s --state open --limit 100 --json number,title,labels` and use the full result |
   | `sync #212`, `sync 212`, `sync #212, #214, #218`, `sync #212-#218` | the issue number(s) verbatim — no resolution needed |
   | `sync CVE-2026-40913` or `sync CVE-2026-40913, CVE-2026-40690` | look up each CVE ID with `gh search issues "CVE-YYYY-NNNNN" --repo airflow-s/airflow-s --json number,title,body --jq '.[] | select(.body \| contains("CVE-YYYY-NNNNN")) \| .number'` (match against the body's *CVE tool link* field) and expand |
   | `sync <free-text>` (e.g. `sync JWT`, `sync KubernetesExecutor`) | title-substring match — run `gh issue list --repo airflow-s/airflow-s --state open --search "<free-text> in:title" --json number,title` and surface the matches back to the user for confirmation before dispatching (title matches are the fuzziest selector — always confirm, never auto-dispatch) |
   | `sync <label>` (e.g. `sync vendor-advisory ready`, `sync pr merged`) | all open issues carrying that label — run `gh issue list --repo airflow-s/airflow-s --state open --label "<label>" --json number,title` |
   | `sync open` | same as `sync all` (explicit alias) |
   | `sync closed` | open *and* closed issues — only run on explicit request; most sync actions are no-ops on closed issues |

   Selectors can be combined: `sync #212, CVE-2026-40690, JWT`
   resolves each independently and dispatches the union of the
   resulting issue numbers. After resolving, **echo the final list
   back to the user and ask for confirmation** before spawning
   subagents — this catches fuzzy-match surprises (a title-substring
   hit that was not intended, a CVE alias that matched two scope
   trackers) before they cost an API round-trip.

   For a plain `sync all`, default to open issues only; do not include
   closed issues unless the user explicitly asks. When the selector
   resolves to zero issues, tell the user and stop — do not fall back
   to `sync all`.

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
  url: <apache/airflow PR URL or null>
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
  same rule: no `airflow-s/airflow-s` content may leak into any
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
  `airflow-s/airflow-s` (read + issue-write) and `apache/airflow`
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
2. **`gh` is authenticated** with access to `airflow-s/airflow-s` —
   `gh api repos/airflow-s/airflow-s --jq .name` must return
   `airflow-s`. A 401/403/404 means the user needs
   `gh auth login` or collaborator access.
3. **Selector resolves to a concrete issue (or set of issues)** —
   if the user said `sync NNN` but the number does not exist in
   `airflow-s/airflow-s`, stop before Step 1 and ask which issue
   they meant.

If any check fails, stop and surface what is missing. Do **not**
proceed to Step 1 on a partial setup — half the observations would
be wrong and the proposals downstream would be junk.

---

## Step 1 — Gather the current state

Run these reads in parallel where possible. Do **not** make any changes yet.

### 1a. Read the GitHub issue

```bash
gh issue view <N> --repo airflow-s/airflow-s \
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
issues" board at
<https://github.com/orgs/airflow-s/projects/2> — the board is the
primary overview surface for the security team, and every issue
has exactly one `Status` option set (`Needs triage`, `Assessed`,
`CVE allocated`, `PR created`, `PR merged`, `Fix released`,
`Announced`). The board column
must match the issue's label-derived state; when it drifts, the
sync proposes a move. Read the current column with:

```bash
gh api graphql -f query='
query($n: Int!) {
  repository(owner: "airflow-s", name: "airflow-s") {
    issue(number: $n) {
      projectItems(first: 5) {
        nodes {
          id
          project { number }
          fieldValues(first: 20) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                field { ... on ProjectV2SingleSelectField { name } }
                name
              }
            }
          }
        }
      }
    }
  }
}' -F n=<N> --jq '.data.repository.issue.projectItems.nodes[] | select(.project.number == 2) | {itemId: .id, status: (.fieldValues.nodes[] | select(.name != null)).name}'
```

Record the item's `itemId` (needed for the Step 4 apply mutation)
and the current `status` column. See the "Project-board column
mapping" table in Step 2b for which column the issue *should* be
on given its labels and body state.

### 1b. Find referenced and referencing PRs

First, get the PRs that GitHub itself has linked to the issue via "fixes" /
"closes" / "resolves" keywords:

```bash
gh issue view <N> --repo airflow-s/airflow-s --json closedByPullRequestsReferences
```

Then look for any PR in either repo that mentions the issue number, in either
state. `gh search prs --state` only accepts `open` or `closed`, so run two
queries (or omit `--state` entirely for "any state"):

```bash
gh search prs "airflow-s#<N>" --repo apache/airflow         --json number,title,state,url,milestone,mergedAt
gh search prs "#<N>"          --repo airflow-s/airflow-s    --json number,title,state,url,milestone,mergedAt
```

If the issue body itself contains a PR URL (the report template has a "PR with
the fix" field), fetch that PR directly and trust it more than the search:

```bash
gh pr view <PR-NUMBER> --repo apache/airflow \
  --json number,title,state,url,milestone,mergedAt,mergeCommit,labels,reviews,isDraft
```

For each PR found, record: number, repo, title, state (open / merged / closed),
merge date, milestone. A PR that is merged into `apache/airflow` with a milestone
set is the strongest signal for what milestone the security issue should carry.

### 1c. Find the **real** reporter and read the mailing-list thread

> The author of the GitHub issue in `airflow-s/airflow-s` is **not** necessarily
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
   `To: airflow-s/airflow-s <airflow-s@noreply.github.com>`) first. That is
   *not* the original report — it is a mirror of the GitHub issue and its
   comments. Filter it out and keep digging.

2. **Search for the original mail by content, not by title.** The GitHub issue
   title is usually paraphrased by the security team member who copied it.
   The original email had a different subject line. Pick a *distinctive
   phrase* from the issue body (a function name, an endpoint, an error
   message) and search Gmail with it, **excluding GitHub notifications**:

   ```text
   "<distinctive phrase>" -from:notifications@github.com -from:noreply@github.com
   ```

   For example: `"HITL" "ui/dags" -from:notifications@github.com -from:noreply@github.com`.

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
| Advisory archived on `users@airflow.apache.org` (the announcement message is now visible in `lists.apache.org/list.html?users@airflow.apache.org` — scan the archive with the CVE ID when `announced - emails sent` is set and the *"Public advisory URL"* body field is empty) | Propose populating the *"Public advisory URL"* body field with the archive URL, regenerating the CVE JSON attachment (the generator picks the URL up automatically and tags it `vendor-advisory`), adding the `vendor-advisory ready` label, **and moving the project-board column from `Fix released` to `Announced`** on [`airflow-s/airflow-s` Project 2](https://github.com/orgs/airflow-s/projects/2). The `Announced` column is the board's representation of Step 14 — the advisory has landed and the CVE record is staged with `CNA_private.state = "PUBLIC"` ready for the release manager's single-paste Step 15. **Do not close the issue and do not add the `vendor-advisory` label** — that is Step 15, owned by the release manager after they move the record to PUBLIC in Vulnogram. |
| Project-board column drifted from the issue's label-derived state (e.g. a tracker carries `pr merged` but is still in the `PR created` column on [Project 2](https://github.com/orgs/airflow-s/projects/2), or `vendor-advisory ready` + *Public advisory URL* body field populated but the column is still `Fix released`) | Propose moving the project item to the correct column per the mapping table in Step 2b. The board is the primary security-team overview surface; a stale column hides ownership handoffs from the team at a glance. |
| `vendor-advisory ready` label set and CVE record on `cveprocess.apache.org` now reports state PUBLISHED (checked via `curl -s https://cveprocess.apache.org/cve5/<CVE-ID>.json` / the ASF CVE tool API, or an explicit release-manager comment on the issue stating the Vulnogram push is done) | Propose closing the issue. Do not update any labels. This is the terminal transition. |
| CVE record has open **review comments / reviewer proposals** (detected via the Gmail-search path in Step 1e — reviewer-comment notifications from Vulnogram land on `security@airflow.apache.org` with the CVE ID in the subject line; the `cveprocess.apache.org/cve5/<CVE-ID>.json` endpoint is behind ASF OAuth and is not readable from this skill's context, so Gmail is the load-bearing signal source). | Surface each open review comment in Step 2a with **clickable links** to the Gmail thread and to the CVE record on `cveprocess.apache.org` (the reader can authenticate in-browser to see live state), verbatim-quoted; then for each one that maps cleanly to a tracking-issue body field (CWE, Affected versions, Reporter credited as, Public advisory URL, Short public summary), **propose the matching body-field update** as a numbered item in Step 2b. The body is the source of truth for the CVE JSON — regeneration in Step 5 will pull the update back into the paste-ready attachment, and the release manager's only remaining action is the Vulnogram paste + comment-resolution click. Comments that do not map to a body field (severity/CVSS, out-of-scope challenges, free-form rewrites) are surfaced verbatim and flagged for human decision. See Step 1e for the full Gmail-search recipe and the reviewer-comment-to-field mapping table. |
| The referenced `apache/airflow` PR has been opened but is still in `open` state | Propose `pr created` label; update the *"PR with the fix"* body field with the PR URL. |
| The referenced `apache/airflow` PR moved to `merged` | Propose swapping `pr created` → `pr merged`; update milestone to the shipping release if now known. |
| A release carrying the fix has shipped (PR's milestone release is on PyPI / Helm registry, or an explicit *"fix shipped in X.Y.Z"* comment) | Propose swapping `pr merged` → `fix released` (Step 12). This is the release manager's cue to own Steps 13–15 (advisory send → URL capture → Vulnogram PUBLIC → close). **Also propose swapping the assignee from the remediation developer to the release manager** (looked up via the three-source cascade in Step 2c — `AGENTS.md` "Known release managers" → Release Plan wiki → `[RESULT][VOTE]` thread on `dev@`), so the issue list reflects ownership hand-off. See the *Assignee hand-off at the `fix released` transition* paragraph under **Assignees** in Step 2b for the full rule. |
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

**Search recipe.** Use Gmail's `search_threads` with the CVE ID in the
subject line and `security@airflow.apache.org` as a recipient, and
exclude the GitHub-notification mirror so the tracker's own comments do
not pollute the results:

```
<CVE-ID> -from:notifications@github.com -from:noreply@github.com -from:airflow-s@noreply.github.com list:security.airflow.apache.org
```

That narrows to messages where the CVE ID appears (Vulnogram puts the
CVE ID in the subject of every review-comment notification) and the
`security@` list is in `To:` / `Cc:`. Also search once without the list
filter (some ASF-CNA tooling emails go to individual security-team
members first), using just the CVE ID plus the GitHub-notification
exclusions:

```
<CVE-ID> -from:notifications@github.com -from:noreply@github.com -from:airflow-s@noreply.github.com
```

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
| *"Credit line `X` is missing"* / *"Move `X` from `finder` to `reporter`"* / *"`Y` asked to be credited as `Z` — please update"* | Propose updating the **Reporter credited as** body field (one line per credit; the generator preserves order). For `remediation developer` credits added via CLI, propose updating the regeneration command's `--remediation-developer` argument in the Step 5 recipe. |
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
| *Public advisory URL* populated, `vendor-advisory ready` label set (issue stays open — awaiting RM's Vulnogram push) | 14 |
| `vendor-advisory ready` set and CVE state is PUBLISHED on `cveprocess.apache.org` → close the issue (do not update labels) | 15 |
| Closed, credits missing | 16 |

The `pr created`, `pr merged`, and `fix released` labels describe the
fix-side flow; `cve allocated` and `announced - emails sent` describe
the advisory-side flow. Both can coexist on the same issue — for
example, a typical mid-flight issue carries `airflow`, `cve allocated`
and `pr merged` at the same time.

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
  issue. The milestone format depends on the scope label:

  - `airflow` → `Airflow-X.Y.Z` or the bare version (e.g. `3.2.2`).
    Take the version from the linked PR's own milestone when the PR
    is merged; otherwise default to the next patch release from the
    *"Release branches currently in flight"* section of
    [`AGENTS.md`](../../../AGENTS.md).
  - `providers` → **`Providers YYYY-MM-DD`**, keyed by the **cut
    date** on the
    [Release Plan wiki](https://cwiki.apache.org/confluence/display/AIRFLOW/Release+Plan)
    (not the PyPI publish date). Fetch the wiki page to find the
    next-upcoming cut date; for an already-released fix, use the
    cut date that corresponds to the release that carried the fix.
  - `chart` → `Chart-X.Y.Z`, taken from the Helm-chart release that
    will carry the fix.

  **If the milestone does not yet exist**, the proposal must say
  so and include the exact `gh api` command to create it. For a
  provider-wave milestone the description should name the release
  manager so the advisory owner is visible at a glance:

  ```bash
  # Core or chart:
  gh api repos/airflow-s/airflow-s/milestones \
    -f title='<Milestone>' -f state=open \
    -f description='<optional>'

  # Provider wave (cut date + RM from the Release Plan wiki):
  gh api repos/airflow-s/airflow-s/milestones \
    -f title='Providers YYYY-MM-DD' -f state=open \
    -f description='Providers release cut on YYYY-MM-DD, RM: <Name>'
  ```

  After the create call, assign the milestone to the issue via
  `gh issue edit <N> --milestone 'Providers YYYY-MM-DD'` (or by
  milestone number via the REST API if the milestone is closed).

- **Assignees** — when a fix PR exists in `apache/airflow` (found in
  Step 1b or named in the *"PR with the fix"* body field) **and the
  PR author is a member of the Airflow security team** (their GitHub
  handle appears in the roster in the *"Security team roster"*
  subsection of [`AGENTS.md`](../../../AGENTS.md) — when in doubt,
  run `gh api repos/airflow-s/airflow-s/collaborators --jq '.[].login'`
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
  collaborator on `airflow-s/airflow-s` yet, surface that as a
  blocker and ask the user whether to invite them before assigning
  — GitHub silently ignores assignee writes for non-collaborators.

  This swap is **only** appropriate at the `fix released`
  transition. Earlier transitions (`pr created`, `pr merged`) keep
  the remediation developer as assignee because the fix PR is still
  their responsibility. Later transitions
  (`announced - emails sent`, `vendor-advisory ready`,
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
     empty, **scan the users@ archive for the CVE ID**:
     ```
     gh api "https://lists.apache.org/api/thread.lua?list=users&domain=airflow.apache.org&q=<CVE-ID>" 2>/dev/null \
       || curl -s "https://lists.apache.org/list.html?users@airflow.apache.org:2026:<CVE-ID>"
     ```
     If the archive returns a hit, propose populating the field with
     the `lists.apache.org/thread/<id>?users@airflow.apache.org` URL,
     regenerating the CVE JSON attachment, and adding the
     `vendor-advisory ready` label.
  2. If the field is already populated, treat it as authoritative —
     no scan needed. Regenerate the CVE JSON attachment so the URL
     flows into `references[]` as `vendor-advisory`.
  3. The sync skill's responsibility ends when the label is
     `vendor-advisory ready`. **Do not propose closing the issue**
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
  announced` now that apache/airflow#NNNN has merged"*, *"add `vendor-advisory
  ready` now that the users@ advisory URL has been captured — the release
  manager will copy the CVE JSON to Vulnogram and close the issue"*.

- **Project-board column** on
  [Security issues — Project 2](https://github.com/orgs/airflow-s/projects/2).
  Every tracker has exactly one `Status` option set, and the column
  must match the issue's label-derived state. Reconcile whenever
  the labels and the column disagree — the board is the primary
  overview surface for the security team and scans of "who owns
  what right now" start there.

  **Mapping — labels + body state → board column:**

  | Issue state | Correct `Status` column |
  |---|---|
  | `needs triage` label set, no scope label yet | `Needs triage` |
  | Scope label (`airflow` / `providers` / `chart`) applied, no CVE yet | `Assessed` |
  | `cve allocated` label set, no fix PR yet | `CVE allocated` |
  | `pr created` label set | `PR created` |
  | `pr merged` label set (release has not shipped) | `PR merged` |
  | `fix released` label set, advisory not yet sent | `Fix released` |
  | `announced - emails sent` label set (Step 13) **or** *Public advisory URL* body field populated + `vendor-advisory ready` label set (Step 14) | **`Announced`** — one column for both Step 13 and Step 14; the RM's next move is the single-paste Step 15 |

  **One column covers Step 13 *and* Step 14.** A tracker lands on
  `Announced` as soon as the advisory is sent (`announced - emails
  sent`) and stays there through the URL-capture step
  (`vendor-advisory ready` label + *Public advisory URL* body field
  populated) until the RM copies the CVE JSON to Vulnogram (Step 15)
  and closes the issue. There is no `Closed` column — closed issues
  simply leave the board.
  The `vendor-advisory ready` label remains meaningful on the
  tracker — it is the load-bearing signal for the CVE JSON's
  `CNA_private.state` (REVIEW → PUBLIC) — but does not map to a
  separate column.

  Board-column mutations are applied via the GraphQL
  `updateProjectV2ItemFieldValue` mutation; see the
  *"Project board column"* entry in the Step 4 apply list.

- **Status update to the reporter** — **whenever the issue's status has changed
  since the last message we sent to the reporter, propose a Gmail draft that
  brings the reporter up to date.** The security team commits to keeping the
  reporter informed at every state transition, per the "Keeping the reporter
  informed" section of [`README.md`](../../../README.md). Concretely, draft a
  status update whenever any of the following has happened since our last
  message in the original mail thread:

  - the report has been acknowledged or assessed (valid / invalid);
  - a CVE has been allocated;
  - a fix PR has been opened;
  - a fix PR has been **merged**;
  - the issue has been scheduled for a specific release (milestone set);
  - the release has shipped and the public advisory has been sent;
  - any credits or fields visible in the eventual public advisory have changed.

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
  ``apache/airflow#65346`` or ``airflow-s/airflow-s#261`` does **not**
  render as a link and forces the reporter to reconstruct the URL by
  hand. Concretely:

  - For the internal tracking issue (allowed on the private mail
    thread), write the **full** URL:
    ``https://github.com/airflow-s/airflow-s/issues/<N>``. Do not use
    ``#<N>`` or ``airflow-s/airflow-s#<N>`` shorthand.
  - For fix PRs on ``apache/airflow``, write the **full** URL:
    ``https://github.com/apache/airflow/pull/<N>``. Do not use
    ``apache/airflow#<N>`` shorthand.
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
  ``airflow-s/airflow-s`` issue itself should still use the
  markdown-linked ``[#<N>](url)`` / ``[apache/airflow#<N>](url)``
  form per Golden rule 2, because GitHub does render that markdown.

  **Confidentiality:** the existence of `airflow-s/airflow-s` is private (see
  the "Confidentiality of `airflow-s/airflow-s`" section of
  [`AGENTS.md`](../../../AGENTS.md)). A status-update email to the reporter on
  the `security@airflow.apache.org` thread *may* include the `airflow-s`
  tracking-issue URL — the reporter is already on the private thread — but
  the same text **must not** be reused in any public location: do not put it
  in the public `apache/airflow` PR description, in any public comment, or in
  the eventual public advisory. When linking from public surfaces, link to
  the public artifact instead (the merged `apache/airflow` PR, the published
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

- **Status update on the GitHub issue (`airflow-s/airflow-s`)** — **every
  status change must also be recorded as a comment on the issue itself**, not
  only sent by email. The two channels serve different audiences: the email
  keeps the reporter informed; the issue comment keeps the rest of the
  security team and the release manager informed without forcing them to
  reconstruct the state from labels and timestamps.

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
  Clickable `airflow-s/airflow-s` references (Golden rule 2) apply
  to both the visible part and the `<details>` interior.

  **The first line of every status-change comment MUST be a bold-
  markdown headline.** It starts with `**` and ends with `**` (or
  `**...**.`), and it names the kind of change inline — `**Sync …`,
  `**Status update …`, `**Merged [airflow-s/airflow-s#<drop>] …`,
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
  repos/airflow-s/airflow-s/issues/comments/<id> --input <json>`
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
  from [`canned-responses.md`](../../../canned-responses.md) verbatim where
  one applies. Show the exact subject, recipients, In-Reply-To, and body in
  the proposal.

  **Brevity** applies here too — if no canned response fits and you are
  drafting fresh wording, keep it to the facts the reporter needs (the
  question being answered, the decision being communicated) plus one
  artifact link. See the "Brevity: emails state facts, not context"
  section of [`AGENTS.md`](../../../AGENTS.md).

  **Never send.** Always create a draft. The draft must always be created on
  the original mail thread (`threadId` from Step 1c) so that
  In-Reply-To/References are set automatically and the reply lands in the
  right conversation. Note that the Gmail MCP exposes only `create`, `list`
  and `read` for drafts — there is no update or delete tool, so if you find
  yourself drafting a *correction* to a prior draft from this same sync,
  surface that explicitly to the user and tell them which prior `draftId` to
  discard manually in Gmail.

### 2c. Next-step recommendation

A single short paragraph describing what the user should do *after* these
updates land, based on the process step. Examples:

- *"Step 3: start the CVE-worthiness discussion in a comment on the issue, tagging at least one other security team member."*
- *"Step 4: draft a consultation message for `private@airflow.apache.org` — the discussion has been stalled for 34 days."*
- *"Step 6: allocate a CVE. Run the [`allocate-cve`](../allocate-cve/SKILL.md) skill (it prints the ASF Vulnogram form URL plus a CVE-ready title and wires the allocated ID back into the tracker)."*
- *"Step 10: close the private PR at airflow-s/airflow-s#NNN now that apache/airflow#NNNN has merged."*
- *"Step 11: `pr merged` — tracker parked until the release train ships. No action needed from the security team; the next sync run will detect the PyPI / Helm release and propose the `fix released` swap (Step 12)."*
- *"Step 12: `fix released` — the release carrying the fix is now on PyPI / the Helm registry. Ownership of the issue has transferred to the release manager; the label swap was the hand-off."*
- *"Step 13: the release manager should now fill in the CVE tool fields taken from the issue — CWE, product, versions, severity, patch link, credits — move the CVE to REVIEW → READY, and send the advisory to `announce@apache.org` / `users@airflow.apache.org`."*
- *"Step 14: scan the users@ archive for the CVE ID, populate the *Public advisory URL* body field, regenerate the CVE JSON attachment, and move the issue to `vendor-advisory ready`. Sync does all of this automatically on the next run once the advisory is archived."*
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

If the release manager is not yet in `AGENTS.md` after you look them up,
surface that in the proposal and propose appending them (with the source
link to the `[RESULT][VOTE]` thread and the release date) to the
"Known release managers" subsection in the same sync run. **Do not
substitute a "plausible" name** (e.g. a frequent release manager from
previous releases) — the release manager rotates per cut, and a wrong
name in a status update leads to the advisory sitting on nobody's desk.

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
`airflow-s/airflow-s` reference in the proposal must be a clickable
markdown link. Do not emit bare `#NNN` or `airflow-s/airflow-s#NNN`.

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

- **Labels:** `gh issue edit <N> --repo airflow-s/airflow-s --add-label "..." --remove-label "..."`
- **Milestone (existing):** `gh issue edit <N> --repo airflow-s/airflow-s --milestone "<title>"`
- **Milestone (create then assign):** run the create call from 2b, then the edit.
- **Assignees:** `gh issue edit <N> --repo airflow-s/airflow-s --add-assignee @me` (or a named user).
- **Description:** `gh issue edit <N> --repo airflow-s/airflow-s --body-file <tmpfile>` — write the
  new body to a temporary file first so nothing is lost to shell quoting.
- **Comments:** `gh issue comment <N> --repo airflow-s/airflow-s --body-file <tmpfile>`.
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
- **Close / reopen:** `gh issue close <N> --repo airflow-s/airflow-s --reason completed` (or `not planned`).
- **Project-board column:** `gh api graphql` with
  `updateProjectV2ItemFieldValue`. The Security-issues Project 2
  on `airflow-s` uses a `Status` single-select field; move the
  project item to the target column by passing the `itemId` (from
  Step 1a's board read) and the target option ID. Re-verify the
  option IDs with the query in Step 1a if any write mutation starts
  returning `not found` — `updateProjectV2Field` regenerates every
  ID whenever the column list is edited.

  | Column | Option ID |
  |---|---|
  | `Needs triage` | `aee65beb` |
  | `Assessed` | `ce6377ce` |
  | `CVE allocated` | `aae2beb3` |
  | `PR created` | `af56c90c` |
  | `PR merged` | `b21b5352` |
  | `Fix released` | `1f2dbb6c` |
  | `Announced` | `12e22331` |

  If the IDs above stop working (a column was renamed, added, or
  removed), re-fetch them with the introspection query in Step 1a.
  The GraphQL `updateProjectV2Field` mutation replaces the whole
  option list rather than editing it in place, so any schema
  change regenerates every ID at once.

  Project ID: `PVT_kwDOCAwKzs4BUzbt`. Status field ID:
  `PVTSSF_lADOCAwKzs4BUzbtzhD08bw`.

  ```bash
  gh api graphql -f query='
    mutation($pid: ID!, $iid: ID!, $fid: ID!, $oid: String!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $pid
        itemId: $iid
        fieldId: $fid
        value: { singleSelectOptionId: $oid }
      }) { projectV2Item { id } }
    }' \
    -F pid=PVT_kwDOCAwKzs4BUzbt \
    -F iid=<itemId from Step 1a> \
    -F fid=PVTSSF_lADOCAwKzs4BUzbtzhD08bw \
    -F oid=<option ID from the table above>
  ```

  If the issue does not yet have a project item (a freshly-created
  tracker that the board automation has not picked up), first add
  it via `addProjectV2ItemById` with the issue's node ID, then
  call `updateProjectV2ItemFieldValue` on the returned item ID.
- **Gmail draft:** `mcp__claude_ai_Gmail__create_draft` — **always**
  pass the `threadId` from Step 1c so the draft threads onto the
  inbound Gmail thread. Gmail does not thread by subject string;
  omitting `threadId` creates a fabricated new thread that neither
  the reporter's client nor the ASF security team will recognise
  as a reply. Subject is `Re: <root subject>`, never a fabricated
  one. See the "Threading: drafts stay on the inbound Gmail thread"
  rule in [`AGENTS.md`](../../../AGENTS.md). **Never send.** Tell
  the user the draft is waiting for their review in Gmail.

If any command fails, stop the apply loop, report the failure, and ask the user
how to proceed — do not guess.

---

## Step 5 — Regenerate the CVE JSON attachment (embedded in the issue body)

After the apply loop finishes — **every time**, not as a proposal — run the
[`generate-cve-json`](../generate-cve-json/SKILL.md) script with `--attach`
to refresh the CVE JSON attachment on the tracking issue. The attachment
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

The minimum command, from the `airflow-s/airflow-s` clone root:

```bash
uv run --project .claude/skills/generate-cve-json generate-cve-json <N> --attach
```

That alone is enough. The script reads every template field from the
issue body, emits the full CVE 5.x record, and patches (or appends to)
the tracking issue body in place.

### Auto-resolve `--remediation-developer` from the fix PR

For the regenerated JSON to carry a `remediation developer` credit
alongside the `finder` credits, the sync skill should look up the author
of the PR mentioned in the *PR with the fix* body field and pass it via
`--remediation-developer`.

**Scope the URL extraction to the *PR with the fix* section only** —
the issue body routinely mentions unrelated `apache/airflow/pull/NNN`
URLs elsewhere (prior-art references, cross-link to sibling
scope-split trackers, "similar to…" context). A naive
`grep … | head -n1` against the whole body will happily pick the
first of those and credit the wrong person. Caught on
[airflow-s/airflow-s#241](https://github.com/airflow-s/airflow-s/issues/241)
where the body mentioned `apache/airflow#44322` as context before the
actual fix `apache/airflow#63028` — the CVE JSON ended up with the
wrong author on the first regen and had to be re-run with
`--remediation-developer` passed explicitly.

```bash
# Extract the PR URL from the "PR with the fix" body section only —
# awk keeps lines from the "### PR with the fix" heading up to the
# next "### " heading, and the grep then scopes to apache/airflow PRs.
pr_url=$(gh issue view <N> --repo airflow-s/airflow-s --json body --jq .body \
  | awk '/^### PR with the fix$/{flag=1; next} /^### /{flag=0} flag' \
  | grep -oE 'https://github\.com/apache/airflow/pull/[0-9]+' | head -n1)

author_name=""
if [[ -n "$pr_url" ]]; then
  pr_number=${pr_url##*/}
  author_name=$(gh pr view "$pr_number" --repo apache/airflow \
    --json author --jq '(.author.name // "") | select(length > 0) // .author.login' 2>/dev/null || echo "")
fi

# Pass --remediation-developer conditionally — never use the
# ${var:+--flag "$var"} trick, it breaks quoting when the name has
# spaces (e.g. "Amogh Desai" splits into two arg words).
if [[ -n "$author_name" ]]; then
  uv run --project .claude/skills/generate-cve-json generate-cve-json <N> --attach \
    --remediation-developer "$author_name"
else
  uv run --project .claude/skills/generate-cve-json generate-cve-json <N> --attach
fi
```

If the lookup fails for any reason (no PR URL yet in the body, URL is
not a `pull/` URL, `gh` errors out), the script runs **without**
`--remediation-developer` — the attachment is still generated, just
missing that one credit. A later manual run with the correct flag
patches the embedded block in place.

### Don't override `--version-start`

The sync skill deliberately does **not** try to guess `--version-start`.
If the *Affected versions* body field has a `>= X, < Y` shape, the script
picks `X` automatically. If it has a bare `< Y` shape (the typical
Airflow case), the script's default `"0"` is used, and the reviewer can
tighten it later with a manual `--version-start 3.0.0` invocation that
patches the same embedded attachment block.

### Report the result

The script prints one of two lines on success:

- `Embedded CVE JSON in issue body on airflow-s/airflow-s#<N>` — first
  run (or first run after the legacy comment-based attachment was
  cleaned up).
- `Replaced CVE JSON in issue body on airflow-s/airflow-s#<N>` —
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
cross-referenced `airflow-s/airflow-s` issue, any PR, any specific
comment anchor and any milestone must be a clickable markdown link.
The user has to be able to click every `airflow-s` reference in the
recap without manually pasting the number into the URL bar.

Concrete minimum that every recap must include as clickable links:

- the **tracking issue header** (e.g. *"Sync complete on
  [`airflow-s/airflow-s#233`](https://github.com/airflow-s/airflow-s/issues/233)"*);
- the **status-change comment** the sync just posted, as a
  `#issuecomment-<C>` anchor link;
- the **embedded CVE JSON section** from Step 5, deep-linked via the
  body's heading anchor (e.g.
  `https://github.com/airflow-s/airflow-s/issues/<N>#cve-json--paste-ready-for-<cve-id-slug>`);
- any **cross-referenced issues** mentioned by the proposal (for
  example *"similar to [`airflow-s/airflow-s#214`](…)"*);
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
- **Milestone naming** must follow the process document exactly:
  - `Airflow-X.Y.Z` or bare `3.2.2` for core releases.
  - `Providers YYYY-MM-DD` for provider-wave cuts. The date is the
    **cut date** from the
    [Release Plan wiki](https://cwiki.apache.org/confluence/display/AIRFLOW/Release+Plan),
    not the PyPI publish date. If the needed milestone does not yet
    exist in `airflow-s/airflow-s`, the sync proposal creates it via
    `gh api repos/airflow-s/airflow-s/milestones -f title='Providers
    YYYY-MM-DD' -f state=open -f description='Providers release cut
    on YYYY-MM-DD, RM: <Name>'` and then assigns the issue. The
    description should carry the rotation-roster release-manager name
    so the advisory owner is visible from the milestones list.
  - `Chart-X.Y.Z` for Helm chart releases.
- **Scope label is mandatory once triage is complete** — exactly one of
  `airflow`, `providers`, or `chart`. *Note on Task SDK*: through
  Airflow 3.2.x the Task SDK ships bundled into `apache-airflow`, so a
  Task SDK-only vulnerability is classified under the `airflow` scope.
  Starting with Airflow 3.3 the Task SDK ships as a separately-released
  component (see the "Release branches currently in flight" section of
  [`AGENTS.md`](../../../AGENTS.md)) and will need its own `task-sdk`
  scope label; add it here and in the scope lists above the first time
  a 3.3+ Task SDK report is triaged.
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
     --repo airflow-s/airflow-s`, copying the report body
     verbatim but with a one-line preamble that says *"Split from
     [#NNN](...) for the `<scope>` scope — see that issue for the
     full discussion history."* This preamble keeps the scope's
     auditable history on that issue without forcing readers to
     scroll through comments in another tracker.
  3. Apply to each split issue:
     - exactly one scope label (`airflow` / `providers` / `chart`);
     - the same `cve allocated` label if a CVE is shared across
       scopes — CVE reuse is correct when the same upstream bug
       affects multiple products, with one `affected[]` entry per
       product in the CVE record;
     - the PR / advisory labels (`pr created` / `pr merged` /
       `fix released`) derived independently per scope from the same
       fix PR, because each scope rides a different release train;
     - the matching milestone for that scope (`Airflow-X.Y.Z` /
       `Providers YYYY-MM-DD` / `Chart-X.Y.Z`);
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
[`canned-responses.md`](../../../canned-responses.md) over ad-hoc text. The
currently available canned responses include: confirmation of receipt (now
including the credit-preference question), invalid Simple Auth Manager report,
invalid automated report, consolidated multi-issue report rejection, "not an
issue — please submit it", parameter injection in operators/hooks, DoS by
authenticated users, Dag-author user-input claims, image scan results, self-XSS
by authenticated users, positive and negative assessment, automated scanning
results, DoS/RCE/arbitrary read via connection configuration, and media-report
requests. If none of them fit, draft a new reply that follows the editorial
rules in `AGENTS.md` and offer to add it to `canned-responses.md` as a follow-up.
