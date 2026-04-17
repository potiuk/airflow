---
name: import-security-issue
description: |
  Scan security@airflow.apache.org for reports that have not yet been
  copied into airflow-s/airflow-s as tracking issues, and — after user
  confirmation — create the tracking issues and draft a receipt-of-
  confirmation reply to each reporter. This is the first step of the
  handling process: the entry point that converts an inbound email
  thread into a tracker the rest of the skills (sync-security-issue,
  fix-security-issue, generate-cve-json) operate on.
when_to_use: |
  Invoke when a security team member says "import new reports", "check
  for unimported security@ messages", "import #<threadId>", or when
  they start a morning-triage sweep and want to see what has landed on
  security@ overnight. Also appropriate as a recurring check — the
  skill is cheap to run against a 30-day Gmail window and a no-op when
  every recent thread is already tracked.
---

# import-security-issue

This skill is the **on-ramp** of the security-issue handling process.
It converts an inbound `security@airflow.apache.org` email thread into
an `airflow-s/airflow-s` tracking issue that follows the repo's issue
template, then drafts the receipt-of-confirmation reply to the reporter.

It never sends email. It never creates an issue without user
confirmation. It never assumes a report is valid — the validity /
invalid / CVE-worthy decision still happens later in the discussion on
the created tracker (Step 3 of [`README.md`](../../../README.md)).

**Golden rule — propose before applying.** Every import this skill
performs is a *proposal* that lists the candidate emails, the
extracted fields, and the draft confirmation reply. Only after the
user confirms each item does the skill run `gh issue create` and
`mcp__claude_ai_Gmail__create_draft`. There is no fast-path that
skips confirmation.

**Golden rule — confidentiality.** The inbound thread on
`security@airflow.apache.org` is private. The skill may paste the
email body verbatim into the created `airflow-s/airflow-s` tracking
issue (that repo is also private). It must **never** paste the
report content into a public surface — not into `apache/airflow`, not
into a public GHSA, not into any comment on a public repo. The same
confidentiality rule documented in the "Confidentiality of
`airflow-s/airflow-s`" section of [`AGENTS.md`](../../../AGENTS.md)
applies in full.

---

## Prerequisites

Before running, the skill needs:

- **Gmail MCP** connected to a Gmail account subscribed to
  `security@airflow.apache.org`. The skill reads threads and
  creates drafts through this MCP; without it, there is no way
  to discover new reports.
- **`gh` CLI authenticated** (`gh auth status` returns OK) with
  collaborator access to `airflow-s/airflow-s`. The skill calls
  `gh issue create` and `gh search issues` directly.

See
[Prerequisites for running the agent skills](../../../README.md#prerequisites-for-running-the-agent-skills)
in `README.md` for the overall setup and the ponymail-mcp
alternative on the horizon.

---

## Step 0 — Pre-flight check

Before touching any candidate thread, verify:

1. **Gmail MCP is reachable.** Run a trivial
   `mcp__claude_ai_Gmail__search_threads` with `pageSize: 1` and
   confirm it returns (not an auth error). If it fails, **stop
   immediately** and tell the user to configure Gmail MCP.
2. **`gh` is authenticated and has access.** Run
   `gh api repos/airflow-s/airflow-s --jq .name`; if it errors
   (401, 403, 404), stop and tell the user to log in with
   `gh auth login` or get added to `airflow-s/airflow-s`.

If either check fails, do **not** proceed — the skill would fail
mid-flow otherwise, leaving half-built state (a draft on the wrong
thread, or a tracker with no receipt reply). Fail fast instead.

---

## Inputs

Before running, resolve the user's selector into a concrete set of
candidate Gmail threads:

| Selector | Resolves to |
|---|---|
| `import new` (default) | every security@ thread received in the last **30 days** that has not yet been imported as an airflow-s issue |
| `import since:YYYY-MM-DD` | every security@ thread received since the given date that is not yet imported |
| `import thread:<id>` | the single Gmail thread with that `threadId` — useful for re-importing after a manual discard, or for picking up a single message the automatic scan missed |
| `import all` (explicit request only) | every security@ thread in the last **90 days** — a wider sweep; use when the skill has not been run in a while |

If the user supplies no selector, default to `import new`.

---

## Step 1 — List candidate threads from Gmail

Search `security@airflow.apache.org` for inbound reports, excluding the
tooling / GitHub-notification / mailing-list chatter that isn't a
report:

```text
list:security.airflow.apache.org
  -from:notifications@github.com
  -from:noreply@github.com
  -from:airflow-s@noreply.github.com
  -from:security-noreply@github.com
  newer_than:30d
```

**Do not exclude `-from:security@apache.org`.** That address is used
for three very different message types — CVE-tool bookkeeping
(*"CVE-YYYY-NNNNN reserved for airflow"* / *"Comment added on CVE-…"*),
**ASF Security Team forwarding of inbound reports** (*"Dear PMC, The
security vulnerability report has been received by the Apache Security
Team and is being passed to you for action …"*), and ad-hoc ASF
Security discussion / advice. Blanket-excluding the sender would drop
the forwarded reports along with the bookkeeping noise, so the
bookkeeping emails are filtered out at Step 3 by subject pattern
instead — see the `cve-tool-bookkeeping` row of the classification
table.

Adjust the time window per the user's selector (`since:` → `newer_than:`
or `after:`; `import all` → `newer_than:90d`).

Use `mcp__claude_ai_Gmail__search_threads` to run the query. For each
result, record `threadId` — the downstream de-duplication hinges on
this.

**Do not read the thread bodies yet.** Body reads cost Gmail budget and
most threads will be filtered out at Step 2.

---

## Step 2 — Deduplicate against existing airflow-s issues

For each candidate `threadId`, check whether that ID already appears in
an `airflow-s/airflow-s` issue body. The sync skill records each thread
ID in the *"Security mailing list thread"* field of the tracking issue
(either as the `lists.apache.org/thread/<id>` URL or as a textual note
containing the Gmail `threadId`). One `gh search issues` call is
enough:

```bash
gh search issues "<threadId>" --repo airflow-s/airflow-s --match body --limit 5 \
  --json number,title,state,url
```

If the search returns any hit, the thread is already imported — skip
it. Do **not** propose re-importing (that would create a duplicate
tracker). If the user explicitly passed `import thread:<id>` and the
thread is already imported, tell the user and link the existing issue
rather than trying to create a duplicate.

After de-duplication, the remaining candidates are the set the user
will confirm in Step 5.

**Budget guardrail**: if the de-dup step knocks the candidate set down
to zero, say so and stop. Do not read any email bodies, do not burn
Gmail quota on threads that have no work to do.

---

## Step 2a — Search for related (potentially-duplicate) existing trackers

The `threadId` dedup in Step 2 catches the *exact-same-thread* case:
the reporter follows up, or the skill is re-run, and the same email
surfaces again. It does **not** catch the *independent-rediscovery*
case: two reporters find the same vulnerability through different
channels (direct email vs. GitHub Security Advisory → ASF relay),
each with a different `threadId`, but the same root-cause bug and
the same fix. Both reporters deserve credit, but only **one** tracker
should exist per CVE.

For each candidate that survived Step 2, read the root message body
(this is the only place in the whole skill where we consume Gmail
budget on a thread we are about to propose importing) and run a
fuzzy-match search against existing issues on three orthogonal keys:

1. **GHSA IDs**: grep the body for `GHSA-[a-z0-9-]{4,}` tokens. For
   each hit, `gh search issues "<GHSA-ID>" --repo airflow-s/airflow-s
   --state open --match body,title` plus the same with `--state
   closed`. A GHSA ID is the strongest de-dup signal — a match means
   the report is the same GitHub Security Advisory, just arriving via
   a different channel.
2. **Code pointers**: grep the body for function names and file paths
   that look like load-bearing identifiers (regex:
   `[A-Z][A-Za-z0-9_]*\.[a-z_][a-zA-Z0-9_]*\(\)` for `ClassName.method()`,
   `airflow[a-zA-Z0-9_./]+\.py` for file paths, and
   `[a-z][a-zA-Z0-9_]*/[a-z][a-zA-Z0-9_/]+\.py` for repo-relative paths).
   Take the **two or three most specific** pointers (the longest
   Python-import-style names and the deepest file paths) and search
   existing issues: `gh search issues "<pointer>" --repo
   airflow-s/airflow-s --state open --match body`. A match here means
   some other tracker already discusses the same code surface — often
   a partial overlap, possibly a duplicate.
3. **Subject root-cause keywords**: strip `[SECURITY]`, `[Security
   Report]`, `Re:`, `Fwd:`, `FW:`, `Airflow:` / `Apache Airflow:`
   prefixes from the root message's subject, then take the remaining
   3–5 noun-phrase tokens (for example
   `"RCE BaseSerialization.deserialize next_kwargs"`) and search:
   `gh search issues "<keywords>" --repo airflow-s/airflow-s
   --state open --match title,body`. Title / body matches here are
   informational — a tracker with a similar title is worth a human
   glance but is not necessarily a duplicate.

For every candidate, surface the match results under a *Potential
duplicates* sub-item in the Step 5 proposal — format:

```
- thread <threadId> — "<candidate title>"
  - GHSA match: [#NNN](...) "GHSA-xxxx-yyyy-zzzz"  (STRONG)
  - Code-pointer match: [#MMM](...) "BaseSerialization.deserialize"  (MEDIUM)
  - Subject-keyword match: [#KKK](...) "RCE in deserialize"  (WEAK)
```

When at least one **STRONG** match is found (GHSA ID collision), do
**not** propose creating a new tracker. Instead, propose invoking
the [`deduplicate-security-issue`](../deduplicate-security-issue/SKILL.md)
skill to merge the new report's body, reporter credit, and
mailing-list-thread entries into the existing tracker, and to close
the new thread's would-be tracker with a `duplicate` label.

When only **MEDIUM** / **WEAK** matches are found, leave the
disposition to the user: offer *"create a new tracker"*, *"merge
into #NNN"*, and *"leave the new tracker but cross-link to #NNN"*
as the three possible actions. A match on code pointers alone might
be the same bug in the same function, or might be a different bug in
the same function — only the human can tell.

Skip Step 2a entirely when the candidate is class
`automated-scanner`, `consolidated-multi-issue`, `media-request`,
`spam`, or `cve-tool-bookkeeping` — those never get a tracker, so
the "is there already a tracker?" question is moot.

**Budget guardrail for Step 2a**: cap at **≤ 5 `gh search issues`
calls per candidate** (one per orthogonal key times up to two
GHSA/pointer hits). A candidate with more than 5 match keys is
almost certainly pulled from a noisy source; treat the excess as
WEAK signal only.

---

## Step 3 — Classify each candidate

For each remaining candidate, read the **root message only** (the one
with no `In-Reply-To`). Use `mcp__claude_ai_Gmail__get_thread` with
`messageFormat: FULL_CONTENT` and pick the first message.

Decide the candidate's class from the root message:

| Class | How to spot it | How to handle |
|---|---|---|
| **Report**: a reporter describes a vulnerability | The body has a description, a PoC / reproduction steps, an impact claim. Sender is an external address (not `@apache.org`, not on the security-team roster in [`AGENTS.md`](../../../AGENTS.md)). | Proceed to Step 4. |
| **ASF-security relay**: `security@apache.org` forwarded a report from a reporter via the Foundation channel | Sender is `security@apache.org`. The body almost always starts with the ASF forwarding preamble — *"Dear PMC, The security vulnerability report has been received by the Apache Security Team and is being passed to you for action …"* — and contains the original report underneath (often after a `====GHSA-…` separator when the report came in via GitHub Security Advisory). The preamble is the load-bearing signal: if you see it, treat as a report regardless of what follows. | Proceed to Step 4. **Credit extraction**: the forwarded body usually ends with a `Credit` line naming the discoverer (e.g. *"This vulnerability was discovered and reported by bugbunny.ai"*) — use that verbatim for the Reporter-credited-as placeholder, not the `From:` header (which is always `security@apache.org`). If the report has no credit line, fall back to the GHSA number or to the phrase *"ASF-relayed"* so the credit-preference question can be routed through `@raboof` / Arnout. |
| **CVE-tool bookkeeping**: an automated or human status-change notification on the ASF CVE tool | Sender is `security@apache.org` (or one of the security-team members acting on behalf of the CVE tool). Subject matches one of: `"CVE-YYYY-NNNNN reserved for airflow"`, `"Comment added on CVE-YYYY-NNNNN"`, `"CVE-YYYY-NNNNN is now READY"`, `"CVE-YYYY-NNNNN is now PUBLIC"`, `"CVE-YYYY-NNNNN is now PUBLISHED"`, `"CVE-YYYY-NNNNN REJECTED"`, or a verbatim `"<state-change>"` line in the body pointing at `cveprocess.apache.org/cve5/CVE-YYYY-NNNNN`. | Do **not** import and do **not** draft a reply — the CVE-tool notifications are consumed by the `sync-security-issue` skill's Step 1e review-comment check. Classify as `cve-tool-bookkeeping` and drop. |
| **Automated scanner dump**: SAST/DAST tool output, CodeQL/Dependabot alert paste, a string of "issues" with no human PoC | Body is machine-generated, contains multiple unrelated findings, no explanation of Security Model violation | Surface as a candidate with class `automated-scanner` and **do not** propose auto-import. In Step 5 the skill proposes a Gmail draft from the *"Automated scanning results"* canned response in [`canned-responses.md`](../../../canned-responses.md) instead. |
| **Consolidated multi-issue report**: one email bundles ≥3 unrelated vulnerabilities | The root message has headings like *"Issue 1"*, *"Issue 2"*, each of which would be its own tracker | Surface class `consolidated-multi-issue`; do not auto-import. Propose the "Sending multiple issues in consolidated report" canned reply. |
| **Media / research-disclosure request**: reporter wants to publish a blog or talk about a finding we already know about | Body asks about disclosure timing, mentions a talk / blog / CVE on another vendor | Surface class `media-request`; do not auto-import. Propose the "When someone submits a media report" canned reply. |
| **Obvious spam / scam / phishing / crypto-scheme** | Cryptocurrency addresses, "bug bounty program" framing on a project that does not have one, no actual Airflow-specific content | Surface class `spam`; propose no action (user deletes in Gmail). |
| **Follow-up on existing thread that Step 2 missed** | Root message mentions a CVE already allocated, or the body is *"re: <existing tracker>"* but with a new threadId because the reporter replied from a different address | Surface class `cross-thread-followup`; do not auto-import. Propose a comment on the existing tracker instead. |

**Classification is advisory, not dispositive.** When in doubt, class
the candidate as a `Report` and let the user make the call in Step 5 —
the worst outcome of a wrong classification is one round of user
rejection, whereas the worst outcome of *not* importing a real report
is missing a vulnerability.

---

## Step 4 — Extract template fields

For each `Report` / `ASF-security relay` candidate, extract the fields
the [issue template](../../../.github/ISSUE_TEMPLATE/issue_report.yml)
expects. Most fields the reporter did not explicitly supply stay as
`_No response_`; the subsequent `sync-security-issue` run will prompt
the triager to fill them as the discussion progresses.

| Template field | Source |
|---|---|
| **The issue description** | The root email body, **verbatim** (preserve paragraphs, PoC code blocks, and any quoted sections). The body is private — the triager will copy it into a public CVE description only after Step 13. |
| **Short public summary for publish** | Leave `_No response_`. Filled by the release manager at Step 13 in sanitised form. |
| **Affected versions** | Extract `Airflow <version>` / `>= X, < Y` / `<Y` phrases from the body. If the reporter gave only a single version they tested on (e.g. `3.1.5`), record that verbatim; the triager can widen the range later. Leave `_No response_` if no version is mentioned. |
| **Security mailing list thread** | **Keep the private thread handle, and — if possible — also link the PonyMail archive entry.** The security@ PonyMail archive is **not anonymously queryable** (the list is gated behind ASF LDAP), so the skill cannot fetch the archive URL programmatically. Instead, **construct a PonyMail search URL in the month the message was received** and propose it to the user at Step 5 as a one-click lookup. The search URL format is: `https://lists.apache.org/list?security@airflow.apache.org:YYYY-M:<url-encoded subject>` — where `YYYY-M` is the year plus the 1- or 2-digit month of the root message's `Date:` header (e.g. `2026-4` for April 2026, no leading zero), and `<url-encoded subject>` is the root message's subject with spaces encoded as `%20` (other punctuation can pass through literally — PonyMail tolerates `()`, `:`, and `/` in the query string). Tell the user *"open this URL in your ASF-logged-in browser, click into the thread, and paste the resulting `lists.apache.org/thread/<hash>?security@airflow.apache.org` URL back"*, and wait for the user's response before writing the issue body. Once the user pastes the URL back, record **both** lines in the *"Security mailing list thread"* field — the PonyMail `lists.apache.org/thread/<hash>?security@airflow.apache.org` URL on the first line, and *"Gmail thread `<threadId>`"* on the second line for cross-reference. If the user does not paste a URL back (the message is not in the archive yet, LDAP access is unavailable, whatever), fall back to the Gmail-threadId-only textual note: *"No public archive URL — tracked privately on Gmail thread `<threadId>`"*. Either way, the URL is **internal-only** and the `generate-cve-json` script will not export it to `references[]` — see the "CVE references must never point at non-public mailing-list threads" section of [`AGENTS.md`](../../../AGENTS.md). |
| **Public advisory URL** | `_No response_`. Populated at Step 14 by `sync-security-issue` once the advisory is archived. |
| **Reporter credited as** | The reporter's full display name from the email `From:` header (e.g. `Alice Example` from `"Alice Example" <alice@example.com>`). This is a **placeholder** — the receipt-of-confirmation reply in Step 7 asks the reporter to confirm their preferred credit form. |
| **PR with the fix** | `_No response_`. |
| **CWE** | `_No response_`. The security team scores CWE independently; a reporter-supplied CWE is informational only (per the *"Reporter-supplied CVSS scores are informational only"* rule in [`AGENTS.md`](../../../AGENTS.md)). Do **not** copy a CWE from the reporter's body into this field. |
| **Severity** | `Unknown`. Same reason as CWE — the team scores independently. Surface a reporter-supplied CVSS / severity label in the proposal's observed-state for context, but do not use it as the field value. |
| **CVE tool link** | `_No response_`. Filled at Step 6 once the CVE is allocated. |

**Issue title**: construct a short title from the report's topic. Prefer
the reporter's original subject if it is descriptive; otherwise
paraphrase in the format *"<Component>: <short vulnerability
description>"*. Strip `Re:` / `Fwd:` / `[SECURITY]` prefixes.

---

## Step 5 — Propose the imports

Present all candidates as a single numbered proposal grouped by class:

- **Reports ready to import** (class `Report` / `ASF-security relay`):
  for each, show the proposed title, the extracted body (with `_No
  response_` placeholders visible), and a preview of the draft
  receipt-of-confirmation reply.
- **Candidates not to import** (class `automated-scanner`,
  `consolidated-multi-issue`, `media-request`, `spam`,
  `cross-thread-followup`): show the class, the reporter, a one-line
  summary, and the proposed Gmail draft (from `canned-responses.md`)
  or the proposed follow-up action (e.g. *"comment on existing
  tracker [airflow-s/airflow-s#NNN](...)"*).
- **Dropped silently** (class `cve-tool-bookkeeping`): do not even
  surface these to the user — they are consumed by
  `sync-security-issue` Step 1e. The skill should just report the
  count in the recap (*"N CVE-tool-bookkeeping emails dropped"*) so
  the user knows the filter is working but is not forced to scroll
  past them.

Confirmation forms:

- `all` — apply every proposal (create every `Report` issue, draft every
  non-import reply, post every cross-thread follow-up comment).
- `NN:all` — apply everything proposed for candidate `NN`.
- `NN:1,3` — apply items `1` and `3` of candidate `NN`.
- `skip NN` — ignore candidate `NN` entirely.
- `none` / `cancel` — bail.

---

## Step 6 — User confirmation

Wait for explicit confirmation. If the user replies ambiguously, ask
again. Never assume.

---

## Step 7 — Apply confirmed imports

For each confirmed `Report` / `ASF-security relay`:

1. Write the extracted body to a temp file:
   ```bash
   cat > /tmp/issue-body-<threadId>.md <<'EOF'
   ### The issue description

   <verbatim root-message body>

   ### Short public summary for publish

   _No response_

   ### Affected versions

   <extracted or _No response_>

   ### Security mailing list thread

   No public archive URL — tracked privately on Gmail thread `<threadId>`.

   ### Public advisory URL

   _No response_

   ### Reporter credited as

   <reporter display name>

   ### PR with the fix

   _No response_

   ### CWE

   _No response_

   ### Severity

   Unknown

   ### CVE tool link

   _No response_
   EOF
   ```

2. Create the issue with the `needs triage` and `security issue` labels:
   ```bash
   gh issue create --repo airflow-s/airflow-s \
     --title '<title>' \
     --body-file /tmp/issue-body-<threadId>.md \
     --label 'needs triage' \
     --label 'security issue'
   ```

3. Draft the receipt-of-confirmation reply. **The draft must be
   created on the inbound Gmail thread** — always pass the candidate's
   `threadId` to `mcp__claude_ai_Gmail__create_draft`. Gmail does
   **not** thread by subject string; a fabricated `Re:` prefix on a
   new thread will not attach to the inbound thread. This is the
   "Threading: drafts stay on the inbound Gmail thread" rule in
   [`AGENTS.md`](../../../AGENTS.md).

   Shape of every create_draft call at this step:

   ```
   mcp__claude_ai_Gmail__create_draft(
     threadId="<candidate threadId from Step 1>",   # MANDATORY
     subject="Re: <root subject of the inbound thread>",
     toRecipients=[...],
     ccRecipients=["security@airflow.apache.org"],
     plaintextBody="<body>",
   )
   ```

   Never fabricate a new subject — subject is always
   `Re: <root subject>`, even when the recipient changes.

   **Two variants depending on the candidate class:**

   - **Class `Report`** (a directly-reachable external reporter) —
     `toRecipients` is the reporter's email (the `From:` of the
     inbound root message). Body is the *"Confirmation of receiving
     the report"* canned response verbatim from
     [`canned-responses.md`](../../../canned-responses.md). That
     canned response already includes the credit-preference
     question, so no additional wording is needed.

   - **Class `ASF-security relay`** (the external reporter is
     unreachable to us directly; only the ASF forwarder can relay
     questions back to them through the original external channel —
     GHSA, HackerOne, direct mail) — `toRecipients` is the
     **personal `@apache.org` address of the ASF forwarder** (the
     `From:` of the inbound relay message), not `security@apache.org`
     and not the unreachable external reporter. Body is **short**
     per the "Brevity: emails state facts, not context" rule in
     [`AGENTS.md`](../../../AGENTS.md):

     - one sentence acknowledging receipt, linking to the external
       reference (GHSA ID, HackerOne report URL);
     - one sentence asking the forwarder to relay the
       credit-preference question below through the original
       channel;
     - the credit-preference question itself (two or three lines,
       adapted from the canned response — *"We will credit you in
       the CVE record as <reporter-credited-as placeholder>. If
       you would prefer a different credit line — full name,
       handle, affiliation, or "anonymous" — please let us know
       before the advisory goes out."*).

     Do **not** restate the vulnerability, the severity, or the
     Airflow handling process — the ASF security team already
     knows all of that. See the
     "ASF-security-relay reports: a special case for drafting"
     section in [`AGENTS.md`](../../../AGENTS.md) for the full
     rationale.

   **Never send.** Always create a draft; the triager reviews in
   Gmail before sending.

4. Post a short status-change comment on the newly-created
   `airflow-s/airflow-s` issue. Use the same short-headline +
   collapsed-`<details>` shape described in the sibling
   [`sync-security-issue`](../sync-security-issue/SKILL.md) skill's
   *"Status update on the GitHub issue"* section — the scroller
   sees two or three lines, the auditor clicks **Details of
   update** for the full provenance trail:

   ```markdown
   **Imported from Gmail thread `<threadId>` on `<YYYY-MM-DD>`** (class: `<classification>`, reporter: `<reporter>`).

   **Next:** Step 3 — start the validity / CVE-worthiness discussion; tag at least one other security-team member.

   <details>
   <summary>Details of update</summary>

   Provenance: <ASF-relay chain if any, GHSA reference if any, PonyMail URL if recorded>.
   Extracted fields: <summary of what landed in the template — Affected versions pre-filled, reporter-credited-as placeholder, Severity=Unknown, etc.>.
   Receipt-of-confirmation reply: draft `<draftId>` waiting for user review in Gmail.

   </details>
   ```

   Keep the visible part under ~6 rendered lines. Clickable
   `airflow-s/airflow-s` references (Golden rule 2 from
   [`AGENTS.md`](../../../AGENTS.md)) apply both above and inside
   the `<details>` block.

For each confirmed non-import (automated-scanner / consolidated /
media / cross-thread-followup):

1. Draft the canned Gmail reply per the classification table in Step 3.
2. If it is a cross-thread follow-up, optionally post a comment on the
   existing `airflow-s/airflow-s` issue cross-linking the new Gmail
   thread ID so the next sync picks it up.

Apply sequentially (not in parallel): one `gh issue create` per
confirmed candidate, one draft per reply. If any step fails, stop and
report — do not guess.

---

## Step 8 — Recap

Print a short recap with:

- The issues created, as clickable
  [`airflow-s/airflow-s#NNN`](https://github.com/airflow-s/airflow-s/issues/NNN)
  links.
- The Gmail drafts waiting for user review, with `draftId`s.
- Any candidates that were skipped, and why.
- A reminder of the next step per [`README.md`](../../../README.md):
  *"Step 2: the triager starts the validity discussion on the newly
  created tracker, tagging at least one other security-team member."*

Apply the Golden-rule link-form self-check to the entire recap text
before presenting.

---

## Hard rules

- **Never send email**, ever. Only create drafts.
- **Never create an issue without user confirmation.**
- **Never import an already-tracked thread.** Step 2 is load-bearing
  — a duplicate tracker fragments the audit trail across two issues
  and is expensive to unwind.
- **Never copy a reporter-supplied CVSS / CWE** into the `Severity` /
  `CWE` fields. Surface them in the proposal observed-state for context
  only; the security team scores independently later.
- **Never leak report content to a public surface.** The entire
  tracking issue is private; its body, title, and comments belong in
  `airflow-s/airflow-s` only. See the "Confidentiality of
  `airflow-s/airflow-s`" section of [`AGENTS.md`](../../../AGENTS.md).
- **Never auto-close** an imported issue, even when the classification
  is `automated-scanner` / `spam`. The user's "do not import" response
  in Step 5 already prevents a tracker from being created; if the user
  confirms import and *then* the discussion concludes the report is
  invalid, the tracker is closed at Step 5 / 6 of `README.md` by the
  triager, not by this skill.

---

## References

- [`README.md`](../../../README.md) — the end-to-end handling process.
  Step 1 (report arrives) and Step 2 (triage) are what this skill
  automates.
- [`AGENTS.md`](../../../AGENTS.md) — confidentiality, release managers,
  CVSS rules, and security-team roster.
- [`canned-responses.md`](../../../canned-responses.md) — the canned
  email bodies the skill uses for receipt-of-confirmation, invalid
  reports, automated scans, etc.
- [`sync-security-issue`](../sync-security-issue/SKILL.md) — the
  follow-up skill that runs on the tracker this one creates.
