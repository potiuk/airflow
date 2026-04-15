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

```bash
gh issue view <N> --repo airflow-s/airflow-s --json timelineItems
gh search prs "airflow-s#<N>" --repo apache/airflow --state all --json number,title,state,url,milestone,mergedAt,mergeCommit
gh search prs "<N>" --repo airflow-s/airflow-s --state all --json number,title,state,url,milestone,mergedAt,mergeCommit
```

For each PR found, record: number, repo, title, state (open / merged / closed),
merge date, milestone. A PR that is merged into `apache/airflow` with a milestone
set is the strongest signal for what milestone the security issue should carry.

### 1c. Read the mailing-list thread

Search Gmail in the mailbox connected to the user running the sync:

1. Look for the original report thread. Start with the issue title as the query,
   then fall back to the reporter's email address if the title does not match.
   Use `mcp__claude_ai_Gmail__gmail_search_messages` with queries like:
   - `list:security@airflow.apache.org "<issue title>"`
   - `list:security@airflow.apache.org from:<reporter-email>`
2. When you find the thread, read its full content with
   `mcp__claude_ai_Gmail__gmail_read_thread`.
3. Extract:
   - the reporter's **preferred credit** (name, affiliation, handle, or anonymous);
   - any additional technical context or PoC the reporter supplied;
   - the latest message in the thread and whether it is *from* us or *to* us
     (i.e. is the ball in our court?);
   - any indication that the reporter is waiting on us.

If you cannot find the thread, say so explicitly in the proposal and ask the
user whether to proceed without email context.

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
- **Draft email to reporter** — whenever the ball is in our court on the email
  thread, propose a **Gmail draft** reply (not a sent message). State the
  intent of the draft in one line (*"acknowledge receipt and ask for credit
  preference"*, *"communicate negative assessment"*, *"confirm CVE ID and ask
  about credit"*, etc.) and prefer to reuse a canned response from
  [`canned-responses.md`](../../../canned-responses.md) verbatim where one
  applies. Show the exact subject, recipients, In-Reply-To, and body in the
  proposal.

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
