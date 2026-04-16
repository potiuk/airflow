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

Before running the skill, you need:

- **Issue number** (required) — e.g. `#185` or just `185`.
- Optional: a hint from the user about what they want to focus on
  (*"has this been CVE-assessed yet?"*, *"is the PR merged?"*, etc.). Use it to
  prioritise but still run the full sync.

If the user does not supply an issue number, ask for it before doing anything else.

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
| Release manager's `[RESULT][VOTE] Release Airflow <version>` on `dev@airflow.apache.org` for a version that carries the fix | Record the release manager in the "Known release managers" subsection of [`AGENTS.md`](../../../AGENTS.md) if not already there; flag Step 12 (advisory) as assigned to that person. |
| Advisory message sent to `announce@apache.org` / `users@airflow.apache.org` for the CVE on the tracker | Propose adding the `announced - emails sent` label, filling the `--advisory-url` for the next `generate-cve-json` run with the `lists.apache.org/thread/<id>?announce@apache.org` URL, and closing the issue. |
| A comment saying *"merged"* / *"fix shipped in X.Y.Z"* on the private issue, or the referenced apache/airflow PR moving to `merged` | Propose `Not yet announced` if not set; update the `PR with the fix` body field with the merged PR URL; update the milestone to the shipping release if it is now known. |
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

Do **not** act on signals automatically; as always, each one becomes a
numbered proposal item in Step 2 and only applies after user
confirmation.

### 1e. Locate the process step

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
| CVE allocated, no fix yet | 7 |
| Fix in progress (PR exists, not merged) | 7 / 8 / 9 |
| apache/airflow PR merged, `Not yet announced` not set | 10 (set label + milestone, close private PR if any) |
| `Not yet announced`, release pending | 11 |
| Released, announcement emails sent, `vendor-advisory` not set | 12 |
| Closed, credits missing | 13 |

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
- **Milestone** — if a linked apache/airflow PR is merged into a release with a
  milestone, propose the matching `Airflow-X.Y.Z` / `Providers-…` / `Chart-…`
  milestone on the issue. **If the milestone does not yet exist**, the proposal
  must say so and include the exact `gh api` command to create it:

  ```bash
  gh api repos/airflow-s/airflow-s/milestones -f title='<Milestone>' -f description='<optional>'
  ```

- **Assignees** — when a fix PR exists in `apache/airflow` (found in
  Step 1b or named in the *"PR with the fix"* body field) **and the
  PR author is a member of the Airflow security team** (their GitHub
  handle appears in the roster in the *"Security team roster"*
  subsection of [`AGENTS.md`](../../../AGENTS.md) — when in doubt,
  run `gh api repos/airflow-s/airflow-s/collaborators --jq '.[] |
  select(.permissions.push == true) | .login'` as the authoritative
  check), **propose setting the tracking issue's assignee to that PR
  author**. The PR author is the natural owner for driving the issue
  through the rest of the process (review, merge, backport label,
  advisory coordination), and setting them as assignee gives the
  whole team a fast "who is on this?" answer in the issue list.

  If the PR author is **not** on the security-team roster (for
  example, an external contributor who submitted the fix via the
  public process), do **not** assign them — they are not part of the
  internal handling process and do not need the tracking-issue
  notifications. Instead, leave the assignee empty or propose a
  security-team member who is already engaged in the discussion.

  Also propose clearing a stale assignment if the person is no longer
  active on the issue, and propose self-assigning a team member only
  if the user explicitly asks.
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
  release manager at Step 12 needs **every** field filled in to send the
  advisory.

  **Special case for the "Security mailing list thread" field.** The
  default value of this field on a new issue is a placeholder
  `lists.apache.org/thread/<hash>` URL that *looks* like a public
  archive link but points at a non-publicly-archived
  `security@airflow.apache.org` thread. Those URLs **must not** survive
  into the CVE record as `vendor-advisory` references — they 404 for
  everyone outside the security team. Every sync run must either:
  (a) replace the placeholder with a short textual note naming the
  private Gmail thread ID (e.g. *"No public archive URL — tracked
  privately on thread `19d24534972f9686`"*), or (b) replace it with
  the **real** public advisory URL on `users@airflow.apache.org` once
  that advisory has been sent. Never leave the field with a fake
  `lists.apache.org/thread/<hash>` placeholder. See the "CVE references
  must never point at non-public mailing-list threads" section of
  [`AGENTS.md`](../../../AGENTS.md) for the full rationale.

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
  announced` now that apache/airflow#NNNN has merged"*, *"add `vendor-advisory`
  and link to lists.apache.org archive entry"*.

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

  Each status update should: (a) state plainly what has changed, (b) link to
  the relevant artifact (PR URL, CVE ID, advisory link), and (c) state what
  comes next. Always reply on the **original** Gmail thread (the one identified
  in Step 1c), not on the GitHub-notifications mirror thread.

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

  Whenever any of the trigger events listed above fires, propose a
  `gh issue comment` that says, in one short paragraph: what changed, the
  link to the artifact (PR URL, CVE ID, advisory link), the new label /
  milestone state, and what is expected next. End the comment with one of:

  - *"Reporter has been notified on the original mail thread."* — when a
    status-update draft has been created in the same sync, **or**
  - *"No reporter notification needed (reporter is on the security team)."*
    — only if the real reporter is themselves a member of the security team
    and is already in the loop, **or**
  - *"Reporter notification still pending — see draft `<draftId>`."* — if a
    draft was created but the user has not yet sent it.

- **Draft email to reporter (other reasons)** — whenever the ball is in our
  court on the email thread for any other reason (a question from the
  reporter, a follow-up needed for triage, communicating a negative
  assessment), propose a **Gmail draft** reply (not a sent message). State
  the intent of the draft in one line and prefer to reuse a canned response
  from [`canned-responses.md`](../../../canned-responses.md) verbatim where
  one applies. Show the exact subject, recipients, In-Reply-To, and body in
  the proposal.

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
- *"Step 6: allocate a CVE. Open the ASF CVE tool: https://cveprocess.apache.org/allocatecve"*
- *"Step 10: close the private PR at airflow-s/airflow-s#NNN now that apache/airflow#NNNN has merged."*
- *"Step 11: the release manager should now fill in the CVE tool fields taken from the issue — CWE, product, versions, severity, patch link, credits — and move the CVE to REVIEW → READY."*

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

**If a CVE needs to be allocated**, always include the allocation link explicitly
on its own line:

> Allocate a CVE via the ASF CVE tool: https://cveprocess.apache.org/allocatecve

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
- **Gmail draft:** `mcp__claude_ai_Gmail__gmail_create_draft` with the thread ID
  from Step 1c so the draft lands in the correct thread. **Never send.** Tell
  the user the draft is waiting for their review in Gmail.

If any command fails, stop the apply loop, report the failure, and ask the user
how to proceed — do not guess.

---

## Step 5 — Regenerate the CVE JSON attachment

After the apply loop finishes — **every time**, not as a proposal — run the
[`generate-cve-json`](../generate-cve-json/SKILL.md) script with `--attach`
to refresh the CVE JSON attachment on the tracking issue. Re-running the
generator is cheap and idempotent: the script's HTML-comment marker (the
``<!-- generate-cve-json: cve=CVE-YYYY-NNNN+ version=v1 -->`` line in the
attachment comment body) lets it find the existing attachment comment and
**patch it in place**, so a refresh never spawns a duplicate comment. If
there is no previous attachment comment yet, the script creates one.

Keeping the attachment in lock-step with the tracking issue body has two
payoffs:

1. The release manager can always grab the most-current JSON straight from
   the issue at advisory-publication time, without having to remember to
   regenerate.
2. The `#source` paste URL is visible on every sync, so if a reviewer
   notices the issue body drifting from the Vulnogram record they can
   jump straight to the paste-ready JSON.

### When to skip

Skip the regeneration **only** when one of the following is true, and call
it out explicitly in the Step 6 recap:

- **No CVE has been allocated yet** — the issue body's *CVE tool link*
  field is still `_No response_`. Running the generator in that state
  would create an attachment comment with an `UNKNOWN` CVE marker, which
  is not useful. Remind the user to allocate a CVE via
  <https://cveprocess.apache.org/allocatecve> and mention that the next
  sync run will attach the JSON automatically once a CVE is set.
- **The tracking issue was closed as `invalid` / `not CVE worthy` /
  `duplicate`** and there is nothing to attach.

In every other case — including already-published CVEs — regenerate.

### How to run it

The minimum command, from the `airflow-s/airflow-s` clone root:

```bash
uv run .claude/skills/generate-cve-json/generate_cve_json.py <N> --attach
```

That alone is enough. The script reads every template field from the
issue body, emits the full CVE 5.x record, and posts or patches the
attachment comment.

### Auto-resolve `--remediation-developer` from the fix PR

For the regenerated JSON to carry a `remediation developer` credit
alongside the `finder` credits, the sync skill should look up the author
of the first PR mentioned in the *PR with the fix* field and pass it via
`--remediation-developer`. One viable shell recipe:

```bash
pr_url=$(gh issue view <N> --repo airflow-s/airflow-s --json body --jq .body \
  | grep -oE 'https://github\.com/apache/airflow/pull/[0-9]+' | head -n1)
if [[ -n "$pr_url" ]]; then
  pr_number=${pr_url##*/}
  author_name=$(gh pr view "$pr_number" --repo apache/airflow \
    --json author --jq '(.author.name // "") | select(length > 0) // .author.login' 2>/dev/null || echo "")
fi

uv run .claude/skills/generate-cve-json/generate_cve_json.py <N> --attach \
  ${author_name:+--remediation-developer "$author_name"}
```

If the lookup fails for any reason (no PR URL yet in the body, URL is
not a `pull/` URL, `gh` errors out), run the script **without**
`--remediation-developer` — the attachment is still generated, just
missing that one credit. A later manual run with the correct flag
patches the comment in place.

### Don't override `--version-start`

The sync skill deliberately does **not** try to guess `--version-start`.
If the *Affected versions* body field has a `>= X, < Y` shape, the script
picks `X` automatically. If it has a bare `< Y` shape (the typical
Airflow case), the script's default `"0"` is used, and the reviewer can
tighten it later with a manual `--version-start 3.0.0` invocation that
patches the same attachment comment.

### Report the result

The script prints one of two lines on success:

- `Created attachment comment on airflow-s/airflow-s#<N>` — first run.
- `Updated attachment comment on airflow-s/airflow-s#<N>` — subsequent
  run; the existing attachment was patched in place.

Capture the printed `html_url` and include it in the Step 6 recap so
the user has one-click access to the attached JSON.

---

## Step 6 — Recap

After the regeneration step finishes, print a short recap:

- what was changed, what was skipped;
- the drafts that are now waiting in Gmail (with a link to the thread);
- the next step from 2c, repeated so the user does not have to scroll;
- the CVE allocation link, if applicable;
- the CVE JSON attachment comment URL (newly created or just patched),
  or an explicit note that regeneration was skipped because no CVE has
  been allocated yet.

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
- the **CVE JSON attachment comment** from Step 5, as a
  `#issuecomment-<C>` anchor link;
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
- **Milestone naming** must follow the process document exactly: `Airflow-2.6.2`,
  `Providers-June-2023-1`, `Chart-1.9.0`.
- **Scope label is mandatory once triage is complete** — exactly one of
  `airflow`, `providers`, or `chart`.

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
