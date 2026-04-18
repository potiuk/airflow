<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Gmail — drafts stay on the inbound thread](#gmail--drafts-stay-on-the-inbound-thread)
  - [The rule](#the-rule)
  - [Fallback — subject-matched draft when `threadId` is unavailable](#fallback--subject-matched-draft-when-threadid-is-unavailable)
  - [Special case — ASF-security relay](#special-case--asf-security-relay)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# Gmail — drafts stay on the inbound thread

Every drafted email that relates to a tracking issue **should**
attach to the original inbound Gmail thread — the thread whose
`threadId` was recorded when the tracker was imported. The **Gmail
API** threads most reliably when a draft carries a `threadId`;
**other mail clients** (Thunderbird, Outlook, Apple Mail, the
recipient's own client) commonly fall back to subject-based
threading via the MIME `In-Reply-To` / `References` headers and the
subject line. Both paths are available to the skills — preferred
order:

1. **`threadId`-attached draft** — the first-choice path. Use
   whenever the inbound `threadId` is known.
2. **Subject-matched draft** — the pragmatic fallback. Use when the
   `threadId` cannot be resolved and starting a brand-new thread
   would be a worse outcome than a same-subject draft that threads
   via subject fallback on most clients.

The call shape (signature, kwargs, no-send rule) lives in
[`operations.md`](operations.md#create-draft); the rules on **which**
thread to use and what the other fields look like live here.

## The rule

- **Same thread every time, by `threadId` when known.** Whatever
  the recipient change — a reporter reply, an ASF-security relay
  request, a PMC credit question, a follow-up asking for a PoC —
  the draft should attach to the inbound tracker's `threadId`. A
  triager reading the Gmail conversation view should see every
  exchange on a single tracker in one place; if threading breaks,
  that history scatters across two conversations.
- **Subject is always `Re: <root subject>`**, never a fabricated
  new one. Gmail's own threading survives without matching
  subjects when `threadId` is set, but other clients commonly fall
  back to subject-based threading. A drifted subject looks like a
  broken conversation on half the world's mail readers. The root
  subject is the subject of the **first message** on the inbound
  thread — not the last reply's subject line, which Gmail may
  have displayed with a prefix trim.
- **`To:` may differ from the original correspondents.** It is
  fine to address a draft to a specific person (an ASF
  security-team member who relayed the report, a named PMC member,
  an individual reporter) even if the original inbound root was
  addressed to a list. Threading does not require recipient
  overlap; it requires `threadId` or (as the fallback) a matching
  subject plus the right `In-Reply-To` / `References` headers.

## Fallback — subject-matched draft when `threadId` is unavailable

`threadId` is the first-choice path, but the skills must also work
in cases where it cannot be resolved:

- the tracker's *security-thread* body field was never filled in
  (see
  [`../github/issue-template.md`](../github/issue-template.md#field-roles-the-skills-use)
  for the field role);
- the `threadId` in that field is stale (the thread was deleted
  or archived out of the user's Gmail search index);
- the draft is a brand-new outbound ask on a topic the inbound
  thread did not cover (e.g. a relay request to a PMC member who
  was not on the original thread), where re-threading on the
  original inbound is actually confusing;
- the Gmail MCP returns an error when attaching the supplied
  `threadId` (rare, but possible if the user has moved the thread
  between accounts).

In these cases, **create the draft with `threadId` omitted but with
the matching subject line from the inbound message**. Gmail will
start a new conversation on the MCP's side, but most other clients
(and Gmail's own subject-fallback behaviour on the recipient's
side) will still thread the reply by subject. This is not as good
as a `threadId`-attached draft, but it is substantially better than
either fabricating a new subject or not drafting at all.

**Surface the degraded threading in the skill's proposal** so the
user knows which path the draft took:

- *"Draft attached by `threadId`."* — the good case.
- *"Draft created by subject fallback — `threadId` was unavailable
  because `<reason>`. Gmail may show it as a new conversation
  server-side; the recipient's client will most likely thread it
  via the `Re: <subject>` match."* — the fallback case.

When the fallback kicks in, record the reason on the tracker's
status comment so the next sync run can see why a new Gmail thread
appeared. Do not silently drop to fallback — it changes the shape
of the conversation the reporter sees.

**When fallback is not appropriate.** Some cases genuinely warrant
stopping rather than drafting on a mismatched subject. Examples:

- You have neither a `threadId` **nor** a matching subject to use
  (typically when the tracker has never been linked to any inbound
  thread at all — a bug, usually a missed import step). Stop and
  surface it; drafting with no thread context at all is worse than
  no draft.
- The inbound subject itself is the reason you cannot thread (the
  reporter sent the report with an empty subject, a generic
  *"Security"*, or a subject that collides with dozens of unrelated
  threads in the user's inbox). A same-subject draft would attach
  to the wrong conversation on the recipient's side. Stop and ask
  the user to confirm a good subject manually.

## Special case — ASF-security relay

When the inbound report arrives via an ASF forwarder rather than
directly from the external reporter, the drafting shape changes
slightly (different `To:` / `Cc:`, relay-specific body language) but
the threading rules above are **unchanged**: prefer `threadId`;
fall back to the inbound subject when it is not available. See
[`asf-relay.md`](asf-relay.md).
