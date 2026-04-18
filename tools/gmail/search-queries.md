<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Gmail — search query templates](#gmail--search-query-templates)
  - [Gmail operator cheat-sheet](#gmail-operator-cheat-sheet)
  - [GitHub-notification exclusions](#github-notification-exclusions)
  - [Query templates by skill](#query-templates-by-skill)
    - [`import-security-issue` — candidate-listing query](#import-security-issue--candidate-listing-query)
    - [`sync-security-issue` — reporter-thread lookup by distinctive phrase](#sync-security-issue--reporter-thread-lookup-by-distinctive-phrase)
    - [`sync-security-issue` — CVE-review-comment search](#sync-security-issue--cve-review-comment-search)
    - [Release `[RESULT][VOTE]` attribution](#release-resultvote-attribution)
  - [Budget discipline](#budget-discipline)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# Gmail — search query templates

The Gmail search-expression language the `mcp__claude_ai_Gmail__search_threads`
call accepts (see [`operations.md`](operations.md#search-threads) for the
call shape). This file catalogues the **generic** operator patterns the
skills use plus the **skill-specific** query templates.

Placeholder convention:

- `<security-list>` — the project's security mailing list (for Airflow,
  `security@airflow.apache.org`; see
  [`../../projects/airflow/project.md`](../../projects/airflow/project.md#mailing-lists)).
- `<security-list-domain>` — the domain suffix of that list (for
  `security@airflow.apache.org`, the value is
  `security.airflow.apache.org`). Gmail's `list:` operator uses the
  domain form, not the plain address.
- `<dev-list>` — the project's public release-vote list (for Airflow,
  `dev@airflow.apache.org`).

## Gmail operator cheat-sheet

| Operator | Purpose |
|---|---|
| `list:<domain>` | Match messages sent to a mailing list. Domain form — `list:security.airflow.apache.org`, not `list:security@airflow.apache.org`. |
| `from:<addr>` / `-from:<addr>` | Match (or exclude) a sender. |
| `to:<addr>` / `cc:<addr>` | Match a recipient / copy-recipient. |
| `subject:"<substring>"` | Match a substring in the subject line (quoted for multi-word). |
| `"<quoted phrase>"` | Match a phrase anywhere in the message (body + headers). |
| `newer_than:<Nd>` | Time window — e.g. `newer_than:30d`. Preferred over `since:` / `after:` for relative windows. |
| `after:YYYY/MM/DD` / `before:YYYY/MM/DD` | Absolute date bounds. |
| `-<operator>:<value>` | Negation — applies to any operator. |

## GitHub-notification exclusions

The project's tracker repo mirrors GitHub issue activity onto its
security list, producing a large volume of bot messages that match
most content searches. Every skill that searches beyond a pure list
scan excludes the mirror senders up front:

```text
-from:notifications@github.com
-from:noreply@github.com
-from:airflow-s@noreply.github.com
-from:security-noreply@github.com
```

For projects that host their tracker elsewhere (or do not mirror to
the list), trim or replace these as needed.

## Query templates by skill

### `import-security-issue` — candidate-listing query

Inbound threads that might be new reports, minus GitHub-notification
bots, within a time window:

```text
list:<security-list-domain>
  -from:notifications@github.com
  -from:noreply@github.com
  -from:airflow-s@noreply.github.com
  -from:security-noreply@github.com
  newer_than:30d
```

**Do not exclude `-from:security@apache.org`.** That address is used
for CVE-tool bookkeeping *and* for ASF-security-team forwarding of
inbound reports *and* for ad-hoc ASF Security discussion.
Blanket-excluding the sender would drop forwarded reports along with
the bookkeeping noise, so the bookkeeping emails are filtered out in
the import skill's Step 3 classification table by subject pattern
instead.

Adjust the time window per the user's selector (`since:` →
`newer_than:` or `after:`; `import all` → `newer_than:90d`).

### `sync-security-issue` — reporter-thread lookup by distinctive phrase

When a tracking issue's GitHub title does not match the original
email subject (common — the triager paraphrases the subject when
copying into GitHub), search Gmail with a distinctive phrase from
the issue body, excluding the GitHub-notification mirror:

```text
"<distinctive phrase>" -from:notifications@github.com -from:noreply@github.com
```

Example: `"HITL" "ui/dags" -from:notifications@github.com -from:noreply@github.com`.

Pick a phrase that is rare in the security list's volume — a
function name, an endpoint path, an error string — rather than a
common word.

### `sync-security-issue` — CVE-review-comment search

The project's CVE tool (Vulnogram for ASF) notifies the security
list by email when a reviewer leaves a comment on the CVE record.
The tool's JSON API is OAuth-gated and not readable from skill
context, so Gmail is the load-bearing signal path.

```text
<CVE-ID> -from:notifications@github.com -from:noreply@github.com -from:airflow-s@noreply.github.com list:<security-list-domain>
```

A second search without the `list:` filter catches CNA-tooling
emails that went to individual security-team members first:

```text
<CVE-ID> -from:notifications@github.com -from:noreply@github.com -from:airflow-s@noreply.github.com
```

Sync-style skills impose a hard per-issue Gmail-call budget. Keep
this path to **≤ 2 extra searches per issue** on top of the
reporter-thread search.

### Release `[RESULT][VOTE]` attribution

When resolving *"who was the release manager of X.Y.Z"*, the
authoritative source is the `[RESULT][VOTE]` thread on the project's
public dev list (the sender of the `[RESULT][VOTE]` message **is**
the release manager). For Airflow:

```text
"[RESULT][VOTE]" "Airflow Providers" from:<dev-list>
```

Narrow with a date range if needed. Per-project lookup rules live in
the project's release-trains file (for Airflow,
[`../../projects/airflow/release-trains.md`](../../projects/airflow/release-trains.md#current-release-managers)).

## Budget discipline

Gmail MCP calls are metered. Skill-level rules:

- `import-security-issue` runs exactly one list scan per invocation.
- `sync-security-issue` runs at most one reporter-thread search +
  two CVE-review searches per tracking issue (i.e. ≤ 3 per tracker;
  ≤ ~60 on a 20-tracker sweep).
- No skill retries on its own. If a search fails, surface the
  failure and ask the user before retrying.
