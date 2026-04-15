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

**Golden rule:** Every change this skill performs is a *proposal*. The user running
the sync must explicitly confirm each update before it is applied. Do not mutate
GitHub state, do not send email, do not create, close, or edit anything without a
clear "yes" from the user for that specific action. Drafts are always created as
Gmail **drafts**, never sent directly.

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
     (name, affiliation, handle, or anonymous);
   - any additional technical context or PoC the reporter supplied beyond
     what made it into the GitHub issue;
   - **all status updates already sent to the reporter by the security team**
     — this is what tells you whether a new status update is needed (see
     Step 2b);
   - the latest message in the thread, *who* sent it, and whether the ball
     is in our court.

5. **If you cannot find the original thread**, say so explicitly in the
   proposal and ask the user whether the GitHub issue author is also the
   reporter (which does happen for issues a security team member discovered
   themselves). Do not assume.

### 1d. Locate the process step

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

- **Assignees** — propose self-assigning a team member only if the user asks, or
  propose clearing a stale assignment if the person is no longer active on the issue.
- **Description fields** — if the issue body is missing any of the fields the
  release manager will eventually need (CWE, product, affected versions, severity,
  CVE ID, credits, links to PRs), propose a patched description. Show the full
  replacement body in the proposal, not a diff, so the user can review it.
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

**Whenever an `airflow-s/airflow-s` issue, PR, or comment is referenced** —
in the proposal, in the status-change comment, in the recap, in any internal
note — render it as a clickable markdown link per the "Linking
`airflow-s/airflow-s` issues and PRs" section of
[`AGENTS.md`](../../../AGENTS.md):

- Issue: `[airflow-s/airflow-s#221](https://github.com/airflow-s/airflow-s/issues/221)` (or `[#221](https://github.com/airflow-s/airflow-s/issues/221)` when the repo is obvious from context).
- PR: `[airflow-s/airflow-s#NNN](https://github.com/airflow-s/airflow-s/pull/NNN)`.
- Specific comment: link to the `#issuecomment-<C>` anchor.

Do not emit bare `#NNN` or `airflow-s/airflow-s#NNN` — always link. The
confidentiality rule still applies: these links are for private surfaces
only (this repo, the private issue itself, the `security@` mail thread)
and must **never** appear in any `apache/airflow` PR description, public
comment, mailing-list post, or other public surface.

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
- **Close / reopen:** `gh issue close <N> --repo airflow-s/airflow-s --reason completed` (or `not planned`).
- **Gmail draft:** `mcp__claude_ai_Gmail__gmail_create_draft` with the thread ID
  from Step 1c so the draft lands in the correct thread. **Never send.** Tell
  the user the draft is waiting for their review in Gmail.

If any command fails, stop the apply loop, report the failure, and ask the user
how to proceed — do not guess.

---

## Step 5 — Recap

After the apply loop finishes, print a short recap:

- what was changed, what was skipped;
- the drafts that are now waiting in Gmail (with a link to the thread);
- the next step from 2c, repeated so the user does not have to scroll;
- the CVE allocation link, if applicable.

---

## Guardrails

- **Never send email.** Only create drafts.
- **Never force-push, never delete labels or milestones without confirmation,
  never close or reopen an issue without confirmation.**
- **Never fabricate** a CVE ID, CWE, severity score, or reporter name. If a field
  is missing, mark it as *unknown* in the proposal and ask the user to supply it.
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
