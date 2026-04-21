---
name: import-security-issue
description: |
  Scan security@airflow.apache.org for reports that have not yet been
  copied into <tracker> as tracking issues, present the proposed
  imports to the user, and — defaulting to *import unless the user
  rejects upfront* — create the tracking issues with the
  `Needs triage` project-board status and draft a receipt-of-
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

<!-- Placeholder convention (see AGENTS.md#placeholder-convention-used-in-skill-files):
     <PROJECT>  → value of `active_project:` in config/active-project.md
                 (for this tree: airflow)
     <tracker>  → value of `tracker_repo:` in projects/<PROJECT>/project.md
                 (for this tree: airflow-s/airflow-s)
     <upstream> → value of `upstream_repo:` in projects/<PROJECT>/project.md
                 (for this tree: apache/airflow)
     Before running any bash command below, substitute these with the
     active-project values read from config/ + projects/<PROJECT>/project.md. -->

# import-security-issue

This skill is the **on-ramp** of the security-issue handling process.
It converts an inbound `security@airflow.apache.org` email thread into
an `<tracker>` tracking issue that follows the repo's issue
template, then drafts the receipt-of-confirmation reply to the reporter.

It never sends email. It never creates a tracker for a candidate the
user has explicitly rejected. It never assumes a report is valid —
the validity / invalid / CVE-worthy decision still happens later in
the discussion on the created tracker (Step 3 of
[`README.md`](../../../README.md)).

**Golden rule — propose, then default to import.** Every import this
skill performs is a *proposal* that lists the candidate emails, the
extracted fields, and the draft confirmation reply. The user's
default disposition for any `Report` / `ASF-security relay`
candidate is **"import as a new tracker landing in `Needs triage`"**;
the user only has to type back when they want to *deviate* from that
default — `skip NN` to reject a candidate upfront, or
`NN:alt-canned <name>` to swap the receipt-of-confirmation reply
for a specific canned negative-assessment / out-of-scope template.
A bare `all` (or no reply at all to the proposal — the user typing
*"go"*, *"proceed"*, *"yes, all"*) means *"import every
non-rejected candidate as proposed"*. The skill must still surface
each candidate one-by-one in the proposal so the user can scan and
override if needed; what the skill must *not* do is sit on a report
waiting for an explicit per-candidate green light. The bias is
toward landing trackers — a wrongly-imported report is cheap to
close at Step 5 / 6 of the handling process; a wrongly-skipped one
gets buried in the inbox and the reporter is left without a
disposition.

Non-import candidate classes (`automated-scanner`,
`consolidated-multi-issue`, `media-request`, `spam`,
`cross-thread-followup`, `cve-tool-bookkeeping`) keep the original
"propose first, apply only on explicit confirm" rule — those never
default to a tracker.

**Golden rule — confidentiality.** The inbound thread on
`security@airflow.apache.org` is private. The skill may paste the
email body verbatim into the created `<tracker>` tracking
issue (that repo is also private). It must **never** paste the
report content into a public surface — not into `<upstream>`, not
into a public GHSA, not into any comment on a public repo. The same
confidentiality rule documented in the "Confidentiality of
`<tracker>`" section of [`AGENTS.md`](../../../AGENTS.md)
applies in full.

---

## Prerequisites

Before running, the skill needs:

- **Gmail MCP** connected to a Gmail account subscribed to
  `security@airflow.apache.org`. The skill reads threads and
  creates drafts through this MCP; without it, there is no way
  to discover new reports.
- **`gh` CLI authenticated** (`gh auth status` returns OK) with
  collaborator access to `<tracker>`. The skill calls
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
   `gh api repos/<tracker> --jq .name`; if it errors
   (401, 403, 404), stop and tell the user to log in with
   `gh auth login` or get added to `<tracker>`.

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

Use the canonical candidate-listing query template from
[`tools/gmail/search-queries.md`](../../../tools/gmail/search-queries.md#import-security-issue--candidate-listing-query);
substitute the active project's `<security-list-domain>` (Airflow:
`security.airflow.apache.org`) and the project's GitHub-notification
exclusions — both declared in
[`projects/<PROJECT>/project.md`](../../../projects/<PROJECT>/project.md#gmail-and-ponymail).

**Do not exclude `-from:security@apache.org`.** That address is used
for three very different message types — CVE-tool bookkeeping,
**ASF Security Team forwarding of inbound reports**, and ad-hoc ASF
Security discussion / advice. Blanket-excluding the sender would drop
the forwarded reports along with the bookkeeping noise, so the
bookkeeping emails are filtered out at Step 3 by subject pattern
instead — see the `cve-tool-bookkeeping` row of the classification
table.

Adjust the time window per the user's selector (`since:` → `newer_than:`
or `after:`; `import all` → `newer_than:90d`).

Run the query via `mcp__claude_ai_Gmail__search_threads` (see
[`tools/gmail/operations.md`](../../../tools/gmail/operations.md#search-threads)).
For each result, record `threadId` — the downstream de-duplication
hinges on this.

**Do not read the thread bodies yet.** Body reads cost Gmail budget and
most threads will be filtered out at Step 2.

---

## Step 2 — Deduplicate against existing airflow-s issues

For each candidate `threadId`, check whether that ID already appears in
an `<tracker>` issue body. The sync skill records each thread
ID in the *"Security mailing list thread"* field of the tracking issue
(either as the `lists.apache.org/thread/<id>` URL or as a textual note
containing the Gmail `threadId`). One `gh search issues` call is
enough:

```bash
gh search issues "<threadId>" --repo <tracker> --match body --limit 5 \
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
   each hit, `gh search issues "<GHSA-ID>" --repo <tracker>
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
   <tracker> --state open --match body`. A match here means
   some other tracker already discusses the same code surface — often
   a partial overlap, possibly a duplicate.
3. **Subject root-cause keywords**: strip `[SECURITY]`, `[Security
   Report]`, `Re:`, `Fwd:`, `FW:`, `Airflow:` / `Apache Airflow:`
   prefixes from the root message's subject, then take the remaining
   3–5 noun-phrase tokens (for example
   `"RCE BaseSerialization.deserialize next_kwargs"`) and search:
   `gh search issues "<keywords>" --repo <tracker>
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

## Step 2b — Search Gmail for prior rejections of similar reports

Step 2a finds existing *trackers* that overlap with the candidate —
reports that became an issue. A different and equally-load-bearing
signal is **prior reports we rejected without creating a tracker**:
a reporter-sent a nearly-identical claim six weeks ago, the team
replied with a canned response from
[`canned-responses.md`](../../../projects/<PROJECT>/canned-responses.md),
and the thread ended there. That precedent is gold when the current
candidate is heading for a negative-response disposition (`skip`,
`reject-with-canned`, `alt-canned`, or a pending `automated-scanner`
/ `consolidated-multi-issue` / `media-request` class). Reusing the
same canned response keeps the team's messaging consistent across
reporters; missing the precedent means re-drafting wording that
already exists and risking a subtly different answer to the same
question.

**Run Step 2b on** every candidate that Step 3 is likely to classify
as a non-tracker disposition, AND on any `Report` / `ASF-security
relay` candidate where the Step 2a fuzzy match is WEAK/MEDIUM-only
and the body reads like a well-known negative pattern (a
Security-Model-fit claim, a Dag-author-supplied-input premise, a
"you should restrict environment-variable access from Dags"
suggestion, an unauthenticated-DoS-via-rate-limit request, an
image-scan dump). Skip Step 2b on candidates Step 2a flagged STRONG
(those route to dedupe, not rejection) and on `cve-tool-bookkeeping`
(dropped silently).

**Search recipe — two Gmail calls per candidate, maximum.** The
query templates and the substitution-values guide live in
[`tools/gmail/search-queries.md`](../../../tools/gmail/search-queries.md#import-security-issue--prior-rejection-search);
in short:

1. **Prior rejections by the security team.** Pick 2–3 distinctive
   noun phrases from the current report (reuse the Step 2a
   subject-keyword tokens) and search the security list for
   past outbound replies from team members. Canonical
   `mcp__claude_ai_Gmail__search_threads` query shape — substitute
   the project's `<security-list-domain>` from
   [`projects/<PROJECT>/project.md`](../../../projects/<PROJECT>/project.md#gmail-and-ponymail):

   ```text
   list:<security-list-domain> "<keyword-1>" "<keyword-2>"
   newer_than:180d -from:notifications@github.com -from:noreply@github.com
   ```

   Hits whose author is on the security-team roster AND whose body
   opens with a canned-response cue (*"Thank you for reporting …
   this isn't a security issue"*, *"Per the Airflow Security
   Model"*, *"This is expected behaviour for a Dag author"*, etc.)
   are prior rejections. Fetch each with
   `mcp__claude_ai_Gmail__get_thread` (MINIMAL is enough when you
   only need to confirm the canned-response shape; FULL_CONTENT is
   warranted only when the reporter pushed back and you want to
   read the clarification the team issued).

2. **Inbound reports that never became a tracker.** Same keywords,
   same 180-day window, filtered to **inbound** messages:

   ```text
   list:<security-list-domain> "<keyword-1>" "<keyword-2>"
   newer_than:180d -from:me -from:<security-team-member>
   -from:notifications@github.com -from:noreply@github.com
   ```

   For each hit, cross-reference the `threadId` against existing
   trackers — `gh search issues "<threadId>" --repo <tracker>` on
   the body field (the *Security mailing list thread* field or
   the rollup's threadId backfill note) — and keep the hits that
   have **no** corresponding tracker. Those are the "rejected
   without tracker" precedents.

**Surfacing in Step 5.** For each precedent found, attach to the
candidate's proposal entry:

- a clickable link to the prior thread (Gmail or PonyMail URL);
- the canned-response **name** the team used (exact section
  heading in [`canned-responses.md`](../../../projects/<PROJECT>/canned-responses.md),
  e.g. *"When someone claims Dag author-provided 'user input' is
  dangerous"*) — if identifiable;
- a one-line summary of the reporter's follow-up: *"accepted —
  thread closed"*, *"pushed back on X; team clarified Y"*, *"no
  reply after our response"*;
- a recommendation — *"use the same canned response verbatim"*,
  *"use the same canned response with an inline augmentation
  pre-empting X (the ambiguity the prior reporter stumbled on)"*,
  or *"treat as new ground — no suitable precedent found"*.

Absence of precedent is itself information. Record *"no prior
rejection of a similar report in the last 180 days"* explicitly in
the proposal so the user knows Step 2b ran and came back empty.
When absent, the user is drafting on new ground and the Step 5
canned-response discipline below still applies.

**Budget guardrail for Step 2b**: **≤ 2 Gmail calls per candidate**.
Do not iterate deeper — a third search yields diminishing returns
and blows the skill's overall Gmail budget. If the two searches
return nothing relevant, record *"no precedent"* and move on.

**Hard rule**: Step 2b is a **read-only** signal-gathering pass.
Do not draft, do not quote the prior reply verbatim back to the
reporter before the user has confirmed the canned response in Step
5. The precedent informs *which* canned response to propose and
*whether* to augment; the drafting itself still happens in Step 7
from the canned-responses file, not by pasting prior outbound mail.

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
| **Automated scanner dump**: SAST/DAST tool output, CodeQL/Dependabot alert paste, a string of "issues" with no human PoC | Body is machine-generated, contains multiple unrelated findings, no explanation of Security Model violation | Surface as a candidate with class `automated-scanner` and **do not** propose auto-import. In Step 5 the skill proposes a Gmail draft from the *"Automated scanning results"* canned response in [`canned-responses.md`](../../../projects/<PROJECT>/canned-responses.md) instead. |
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

The generic body-field schema (role → field-name contract, empty-field
convention, body-field surgery pattern) lives in
[`tools/github/issue-template.md`](../../../tools/github/issue-template.md);
the concrete field names for the active project are declared in
[`projects/<PROJECT>/project.md`](../../../projects/<PROJECT>/project.md#issue-template-fields).
The table below describes **what value to source** from the inbound
report for each field — that guidance is import-specific and stays
here.

| Template field | Source |
|---|---|
| **The issue description** | The root email body, **verbatim** (preserve paragraphs, PoC code blocks, and any quoted sections). The body is private — the triager will copy it into a public CVE description only after Step 13. |
| **Short public summary for publish** | Leave `_No response_`. Filled by the release manager at Step 13 in sanitised form. |
| **Affected versions** | Extract `Airflow <version>` / `>= X, < Y` / `<Y` phrases from the body. If the reporter gave only a single version they tested on (e.g. `3.1.5`), record that verbatim; the triager can widen the range later. Leave `_No response_` if no version is mentioned. |
| **Security mailing list thread** | **Keep the private thread handle, and — if possible — also link the PonyMail archive entry.** The full URL-construction recipe (search URL template, month-token format, user-pastes-back flow, Gmail-threadId fallback) lives in [`tools/gmail/ponymail-archive.md`](../../../tools/gmail/ponymail-archive.md#use-case--import-security-issue); the active project's private-search URL template is declared in [`projects/<PROJECT>/project.md`](../../../projects/<PROJECT>/project.md#gmail-and-ponymail). Propose the constructed search URL to the user at Step 5, wait for them to paste back the resolved `lists.apache.org/thread/<hash>?<security-list>` URL, and record both the PonyMail URL and the Gmail `threadId` in this field. The URL is **internal-only** — the `generate-cve-json` script will not export it to `references[]` — see the "CVE references must never point at non-public mailing-list threads" section of [`AGENTS.md`](../../../AGENTS.md). |
| **Public advisory URL** | `_No response_`. Populated at Step 14 by `sync-security-issue` once the advisory is archived. |
| **Reporter credited as** | The reporter's full display name from the email `From:` header (e.g. `Alice Example` from `"Alice Example" <alice@example.com>`). This is a **placeholder** — the receipt-of-confirmation reply in Step 7 asks the reporter to confirm their preferred credit form. |
| **PR with the fix** | `_No response_`. |
| **Remediation developer** | `_No response_`. Auto-populated by the `sync-security-issue` skill from the linked PR's author the first time *PR with the fix* is set; manual edits are preserved on subsequent syncs. |
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

- **Reports defaulting to import** (class `Report` / `ASF-security relay`):
  for each, show the proposed title, the extracted body (with `_No
  response_` placeholders visible), the receipt-of-confirmation reply
  preview, and a one-line *"unless you say otherwise, this lands as a
  new tracker in `Needs triage` with the receipt-of-confirmation reply
  drafted to the reporter"*. Surface any Step 2a fuzzy-duplicate
  matches (`STRONG`/`MEDIUM`/`WEAK`) and any classification ambiguity
  inline so the user can scan-then-override; do **not** pose them as
  open questions that gate the import.
- **Candidates not to import** (class `automated-scanner`,
  `consolidated-multi-issue`, `media-request`, `spam`,
  `cross-thread-followup`): show the class, the reporter, a one-line
  summary, and the proposed Gmail draft (from `canned-responses.md`)
  or the proposed follow-up action (e.g. *"comment on existing
  tracker [<tracker>#NNN](...)"*). These need explicit confirmation —
  no default-to-tracker. The draft **must** follow the
  canned-response discipline below.
- **Dropped silently** (class `cve-tool-bookkeeping`): do not even
  surface these to the user — they are consumed by
  `sync-security-issue` Step 1e. The skill should just report the
  count in the recap (*"N CVE-tool-bookkeeping emails dropped"*) so
  the user knows the filter is working but is not forced to scroll
  past them.

### Canned-response discipline for negative-response drafts

When the proposed disposition is a negative response — any of the
`NN:alt-canned`, `NN:reject-with-canned`, `automated-scanner`,
`consolidated-multi-issue`, `media-request`, `cross-thread-followup`
paths — **strongly prefer the canned response verbatim** over
drafting fresh prose. The canned library in
[`canned-responses.md`](../../../projects/<PROJECT>/canned-responses.md)
is a curated set of replies the team has iterated on across many
reports; a fresh draft that says "roughly the same thing" in
different words loses the collective wording discipline, and
re-introduces ambiguities the canned version has already ironed out.

**Pick the single canned response that best matches** the candidate's
shape. Name it explicitly in the proposal (use the exact section
heading from `canned-responses.md`, e.g. *"When someone claims Dag
author-provided 'user input' is dangerous"*). When Step 2b surfaced
a prior precedent, the canned response the team used last time is
the strong default — deviate only on a specific, defensible reason.

**Use the canned body verbatim** except for the SCREAMING_SNAKE_CASE
placeholders (reporter name, CVE ID, PR URL, etc.). Do not
paraphrase the canned text. Do not reorder its paragraphs. Do not
"polish" its wording. Changes to the canned wording belong in
`canned-responses.md` via a separate commit, not in a one-off draft.

**Add an inline augmentation only when** the canned response has a
specific ambiguity in the context of *this* report that a typical
reader would plausibly misread — for example:

- the canned response assumes the reporter's claim is X but the
  report actually claims X' (a stricter variant); the augmentation
  clarifies which variant the reply addresses;
- the reporter pre-empted the standard Security Model argument by
  citing a specific sentence from the model; the augmentation
  quotes that sentence and explains why the canned response still
  applies;
- the Step 2b precedent showed a prior reporter pushing back on
  ambiguity Y, and the current report carries Y too; the
  augmentation pre-empts Y.

**Clearly mark the augmentation** as a distinct inline block the
reviewer can strip cleanly. Concrete format: insert a
`> **[Inline addition for this report]** <augmentation text>` block
in-line at the point where the canned wording is ambiguous, leaving
the surrounding canned text untouched. The reviewer must be able to
tell at a glance which sentences are canned and which are
augmentation, and to delete the augmentation without leaving a
grammatical orphan.

**Coherence check before presenting the draft.** Re-read the proposed
reply once as the reporter would read it, with the report's text
beside it. Verify:

- the draft accurately characterises **this** report — e.g. do not
  claim "this requires Dag-author privileges" when the reporter
  described an unauthenticated attack; do not say "the behaviour is
  documented here" when the linked docs describe a different
  scenario; do not cite a Security Model chapter that does not
  actually cover the reporter's claim;
- the canned body and the augmentation (if any) do not contradict
  each other — a canned "we will not be issuing a CVE" paragraph
  sitting next to an augmentation that says "we plan to publish an
  advisory" is the failure mode the check is meant to catch;
- paragraph-to-paragraph tone is consistent — the canned responses
  are polite-but-firm (see AGENTS.md), augmentations must match
  that register, not drift into hedging or apology;
- every placeholder has been filled in (no literal
  `CVE_ID`/`PR_URL`/`REPORTER_NAME` tokens left behind);
- every artefact URL the draft cites actually exists and actually
  says what the draft claims it says — a dead link or a
  misrepresented doc is worse than no link at all.

If the coherence check surfaces **any** contradiction, mismatch,
or shaky claim, fix it before surfacing the draft in the proposal.
The user sees the draft in the proposal, and an incoherent draft
wastes a round-trip.

Confirmation forms (`Report` / `ASF-security relay` candidates default
to import; the user only types back to *deviate* from that default):

- `all` / `go` / `proceed` / `yes, all` / no reply at all — import
  every Report / ASF-relay candidate as proposed (each lands in
  `Needs triage` with its receipt-of-confirmation reply drafted),
  and apply every confirmed non-import action.
- `skip NN` — reject candidate `NN` upfront; no tracker created, no
  draft. Combine with `, ` to skip multiple (`skip 1, 3`).
- `NN:alt-canned <canned-response-name>` — for candidate `NN`, swap
  the default receipt-of-confirmation reply for the named canned
  response (typically a negative-assessment template like
  *"Dag-author user-input claims"*). Tracker is still created — the
  team triages-and-closes from there. **The team's bias should
  always favour creating the tracker; canned negative responses are
  for cases where the reporter deserves a substantive close-out
  reply and the disposition is genuinely obvious before triage.**
- `NN:reject-with-canned <canned-response-name>` — explicit upfront
  rejection that *also* drafts a canned reply (e.g. an obvious
  duplicate of a recently-closed tracker). No tracker created.
- `NN:edit <freeform>` — fold a freeform note (extra context, a
  different title, a smaller body excerpt) into the import; tracker
  is still created with the edits applied.
- `none` / `cancel` — bail entirely; no trackers, no drafts.

---

## Step 6 — User confirmation

The default is **import every Report / ASF-relay candidate** plus
**apply every confirmed non-import action**. If the user replies with
overrides (`skip 1`, `2:alt-canned dag-author-user-input`, etc.), apply
those overrides on top of the default. If the user replies ambiguously
(*"hmm not sure about #3"*), ask back specifically about #3 — but do
**not** stall the rest of the import waiting for a per-candidate green
light. Run the unambiguous defaults; ask back only on the ambiguous
ones.

A reply of `cancel` / `none` / *"hold off"* halts everything — no
trackers, no drafts.

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

   ### Remediation developer

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
   gh issue create --repo <tracker> \
     --title '<title>' \
     --body-file /tmp/issue-body-<threadId>.md \
     --label 'needs triage' \
     --label 'security issue'
   ```

3. **Set the project-board `Status` to `Needs triage`.** The newly-
   created issue may already have been added to the board by the
   *Auto-add to project* workflow (see the per-project `Auto-add
   workflow filter` section in
   [`tools/github/project-board.md`](../../../tools/github/project-board.md#auto-add-workflow-filter)
   — for the active project, the filter is
   `is:issue label:"security issue"`). Whether the workflow ran or
   not, run the orphan-issue path from
   [`tools/github/project-board.md`](../../../tools/github/project-board.md#orphan-issue-path)
   to **idempotently** ensure the item exists on the board *and* the
   `Status` field is set to `Needs triage`:

   - Resolve the new issue's node id, then `addProjectV2ItemById`
     (returns the existing item id if the workflow already added the
     issue, or creates a fresh one otherwise — both cases are safe).
   - Run `updateProjectV2ItemFieldValue` to set `Status` to the
     `Needs triage` option id from the project's
     `status_column_option_ids` table in
     [`projects/<PROJECT>/project.md`](../../../projects/<PROJECT>/project.md#github-project-board).

   This guarantees the new tracker is visible on the board the team
   uses for triage at-a-glance scanning, without depending on the
   workflow being correctly configured. The mutation is a no-op when
   the item is already on the board with the same Status.

4. Draft the receipt-of-confirmation reply. **The draft must be
   created on the inbound Gmail thread** — always pass the candidate's
   `threadId` to `mcp__claude_ai_Gmail__create_draft`. See
   [`tools/gmail/threading.md`](../../../tools/gmail/threading.md) for
   the full threading rule and
   [`tools/gmail/operations.md`](../../../tools/gmail/operations.md#create-draft)
   for the call signature. Never fabricate a new subject — subject is
   always `Re: <root subject>`, even when the recipient changes.
   `ccRecipients` always includes the active project's `security_list`
   (for Airflow: `security@airflow.apache.org`; see
   [`projects/<PROJECT>/project.md`](../../../projects/<PROJECT>/project.md#gmail-and-ponymail)).

   **Two variants depending on the candidate class:**

   - **Class `Report`** (a directly-reachable external reporter) —
     `toRecipients` is the reporter's email (the `From:` of the
     inbound root message). Body is the *"Confirmation of receiving
     the report"* canned response verbatim from
     [`canned-responses.md`](../../../projects/<PROJECT>/canned-responses.md). That
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

5. **Create the status-rollup comment** on the newly-created
   `<tracker>` issue. The import is the *first* entry on this
   tracker's rollup, so this is the only skill pass that uses
   the "create" branch of the upsert recipe; every subsequent
   sync / allocate / dedupe / fix pass appends to this comment
   instead of posting new ones.

   The full shape, upsert recipe, and legacy-comment folding rules
   live in
   [`tools/github/status-rollup.md`](../../../tools/github/status-rollup.md).
   Emit the rollup body below and post via
   `gh issue comment <N> --repo <tracker> --body-file <tmpfile>`:

   ```markdown
   <!-- airflow-s status rollup v1 — all bot-authored status updates fold into this single comment. -->
   <details><summary><YYYY-MM-DD> · @<author-handle> · Import (<classification>, <reporter>)</summary>

   **Imported from Gmail thread `<threadId>` on <YYYY-MM-DD>** (class: `<classification>`, reporter: `<reporter>`).

   **Next:** Step 3 — start the validity / CVE-worthiness discussion; tag at least one other security-team member.

   Provenance: <ASF-relay chain if any, GHSA reference if any, PonyMail URL if recorded>.
   Extracted fields: <summary of what landed in the template — Affected versions pre-filled, reporter-credited-as placeholder, Severity=Unknown, etc.>.
   Receipt-of-confirmation reply: draft `<draftId>` waiting for user review in Gmail.

   </details>
   ```

   Zero-whitespace rules from
   [`status-rollup.md`](../../../tools/github/status-rollup.md#the-rollup-comment-shape)
   apply: no leading spaces on any line inside the `<details>`
   block, exactly one blank line after `<summary>…</summary>`,
   exactly one blank line before `</details>`. Clickable
   `<tracker>` references (Golden rule 2 in
   [`AGENTS.md`](../../../AGENTS.md)) apply inside the entry the
   same way they did in the pre-rollup shape.

   Capture the returned comment ID — the recap (Step 8) links it,
   and if a later skill pass in the same invocation (for example,
   dedupe into an existing tracker surfaced by Step 2a) needs to
   append another entry, it can skip the Step 1 lookup.

For each confirmed non-import (automated-scanner / consolidated /
media / cross-thread-followup):

1. Draft the canned Gmail reply per the classification table in Step 3.
2. If it is a cross-thread follow-up, optionally post a comment on the
   existing `<tracker>` issue cross-linking the new Gmail
   thread ID so the next sync picks it up.

Apply sequentially (not in parallel): one `gh issue create` per
confirmed candidate, one draft per reply. If any step fails, stop and
report — do not guess.

---

## Step 8 — Recap

Print a short recap with:

- The issues created, as clickable
  [`<tracker>#NNN`](https://github.com/<tracker>/issues/NNN)
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
- **Never create an issue for a candidate the user has explicitly
  rejected.** The default disposition for `Report` / `ASF-security
  relay` candidates is *import* (see the *"propose, then default to
  import"* Golden rule above), but `skip NN` /
  `NN:reject-with-canned …` / `cancel` / `none` / *"hold off"* on
  the proposal must be honoured — those are the ways the user
  rejects upfront, and the skill must never override them.
- **Never import an already-tracked thread.** Step 2 is load-bearing
  — a duplicate tracker fragments the audit trail across two issues
  and is expensive to unwind.
- **Never copy a reporter-supplied CVSS / CWE** into the `Severity` /
  `CWE` fields. Surface them in the proposal observed-state for context
  only; the security team scores independently later.
- **Never leak report content to a public surface.** The entire
  tracking issue is private; its body, title, and comments belong in
  `<tracker>` only. See the "Confidentiality of
  `<tracker>`" section of [`AGENTS.md`](../../../AGENTS.md).
- **Never auto-close** an imported issue, even when the classification
  is `automated-scanner` / `spam`. The user's "do not import" response
  in Step 5 already prevents a tracker from being created; if the user
  confirms import and *then* the discussion concludes the report is
  invalid, the tracker is closed at Step 5 / 6 of `README.md` by the
  triager, not by this skill.
- **Never paraphrase a canned response** in a negative-response draft.
  Use the canned body from
  [`canned-responses.md`](../../../projects/<PROJECT>/canned-responses.md)
  verbatim, with placeholders filled in; add inline augmentations
  only where a context-specific ambiguity would plausibly mislead
  *this* reporter, and mark every augmentation as a distinct
  `> **[Inline addition for this report]** …` block the reviewer can
  strip cleanly. Wording changes to the canned text belong in a
  separate commit to the canned-responses file, not in a one-off
  draft. See the *"Canned-response discipline for negative-response
  drafts"* subsection of Step 5.
- **Never present a draft that contradicts the report.** The
  coherence check in Step 5 is mandatory before a negative-response
  draft appears in the proposal: the draft must accurately
  characterise *this* report, the canned body and any augmentation
  must not contradict each other, every placeholder must be
  filled, and every artefact URL cited must actually exist and say
  what the draft claims it says. An incoherent draft burns a
  round-trip with the user and erodes the reporter's trust that we
  actually read their report.

---

## References

- [`README.md`](../../../README.md) — the end-to-end handling process.
  Step 1 (report arrives) and Step 2 (triage) are what this skill
  automates.
- [`AGENTS.md`](../../../AGENTS.md) — confidentiality, release managers,
  CVSS rules, and security-team roster.
- [`canned-responses.md`](../../../projects/<PROJECT>/canned-responses.md) — the canned
  email bodies the skill uses for receipt-of-confirmation, invalid
  reports, automated scans, etc.
- [`sync-security-issue`](../sync-security-issue/SKILL.md) — the
  follow-up skill that runs on the tracker this one creates.
