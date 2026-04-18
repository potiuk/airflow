<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Gmail — MCP operation catalogue](#gmail--mcp-operation-catalogue)
  - [Pre-flight](#pre-flight)
  - [Read](#read)
    - [Search threads](#search-threads)
    - [Get thread](#get-thread)
  - [Write — drafts only, never send](#write--drafts-only-never-send)
    - [Create draft](#create-draft)
    - [List drafts](#list-drafts)
  - [Hard limitation — no update, no delete](#hard-limitation--no-update-no-delete)
  - [Confidentiality of drafts](#confidentiality-of-drafts)
  - [Error handling](#error-handling)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# Gmail — MCP operation catalogue

Shared reference for the `mcp__claude_ai_Gmail__*` tool calls the
skills make against the active user's Gmail account. The skills
reference this file for the call shape and for the limitations that
constrain their flow.

Placeholder convention used below:

- `<security-list>` — the project's private security mailing list (the
  list the user's Gmail account subscribes to). For Airflow, the value
  is `<project manifest>.security_list` =
  `security@airflow.apache.org`; see
  [`../../projects/airflow/project.md`](../../projects/airflow/project.md#mailing-lists).
- `<threadId>` — an opaque Gmail thread identifier.

## Pre-flight

Every skill that talks to Gmail does a one-call pre-flight in Step 0
to confirm the MCP is reachable and the user's account subscribes to
the project's security list:

```
mcp__claude_ai_Gmail__search_threads(
  query='list:<security-list-domain>',
  pageSize=1,
)
```

Substitute the `<security-list-domain>` with the domain suffix of the
project manifest's `security_list` (for
`security@airflow.apache.org`, the value is
`security.airflow.apache.org`).

A non-empty result means Gmail is connected and indexed; an empty
result means either the account does not subscribe, or the MCP is
misconfigured. In either case the skill stops and asks the user to
fix the setup rather than guessing.

## Read

### Search threads

```
mcp__claude_ai_Gmail__search_threads(
  query='<gmail search expression>',
  pageSize=<N>,
)
```

Returns an array of `{threadId, snippet, …}` objects. Use `pageSize`
deliberately — some skills (e.g. `sync-security-issue`) impose a
hard Gmail-call budget per issue to avoid running up the MCP quota
on many-tracker sweeps.

For the search expression syntax and the canonical query templates
the skills use, see [`search-queries.md`](search-queries.md).

### Get thread

```
mcp__claude_ai_Gmail__get_thread(
  threadId='<threadId>',
  messageFormat='FULL_CONTENT',   # or 'METADATA' when bodies are not needed
)
```

Returns the full message history of a thread. Body reads are
expensive — most skills filter candidates down on metadata first and
only fetch bodies for the narrow set that actually warrants it
(`import-security-issue` does this explicitly at Step 3).

## Write — drafts only, never send

### Create draft

```
mcp__claude_ai_Gmail__create_draft(
  threadId='<threadId>',                          # MANDATORY
  subject='Re: <root subject of the thread>',
  toRecipients=['<primary>'],
  ccRecipients=['<security-list>', ...],
  plaintextBody='<body>',
)
```

- **`threadId` is mandatory.** Drafts without a thread attachment
  are a hard error; see [`threading.md`](threading.md) for the full
  rule and why.
- **Subject is `Re: <root subject>`**, never fabricated. Other mail
  clients fall back to subject-based threading when GitHub's
  thread-ID hint is not honoured.
- **Never send.** The skills only *create* drafts; a human
  review-and-send step is required before every outbound message.

For the ASF-security-relay special case (different `toRecipients` /
`Cc:` shape), see [`asf-relay.md`](asf-relay.md).

### List drafts

```
mcp__claude_ai_Gmail__list_drafts(
  query='<optional filter>',    # e.g. 'list:<security-list-domain>'
)
```

Used by `sync-security-issue` to verify that a draft flagged as stale
in a previous status comment still exists before carrying the flag
forward. See the *"self-replicating stale-draft flag"* paragraph in
that skill.

## Hard limitation — no update, no delete

The Gmail MCP exposes **`create`, `list`, and `read` only** for
drafts. There is no `update_draft` and no `delete_draft` tool. The
skills must treat every existing draft as immutable:

- If a correction is needed, surface the existing draft's `draftId`
  to the user with an explicit *"discard this one manually in Gmail"*
  note, then create a fresh draft with the corrected content.
- Do **not** silently create a second draft that shadows the first —
  that leaves two near-identical drafts in the user's Gmail and
  invariably one of them gets sent by accident.
- On the sync skill's stale-draft-forward-flagging path: verify the
  `draftId` still exists via `list_drafts` before copying the flag
  into a new sync status comment. Without verification, a one-time
  flag self-replicates forever.

## Confidentiality of drafts

Drafts land in the user's personal Gmail account and are visible only
to that user until sent. Draft content may reference the private
tracker's URL (reporter is on the private thread and is expected to
keep it confidential), but anything destined for a public list must
obey the confidentiality rules in
[`../../AGENTS.md`](../../AGENTS.md) — no `airflow-s` URLs, no CVE
IDs before publication, no *"security fix"* leakage.

## Error handling

If any Gmail call fails (MCP unreachable, 429, transient 5xx),
**stop** and report the failure. The skills explicitly budget Gmail
calls; silently retrying turns one flaky call into a quota-exhaustion
storm.
