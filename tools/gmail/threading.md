<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Gmail — drafts stay on the inbound thread](#gmail--drafts-stay-on-the-inbound-thread)
  - [The rule](#the-rule)
  - [Special case — ASF-security relay](#special-case--asf-security-relay)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# Gmail — drafts stay on the inbound thread

Every drafted email that relates to a tracking issue **must** be
created on the original inbound Gmail thread — the thread whose
`threadId` was recorded when the tracker was imported. Gmail does
**not** thread by subject string; a `Re: <subject>` fabricated
locally will not attach to any existing thread. Threading is bound
by `threadId` or by the MIME `In-Reply-To` / `References` headers,
and the Gmail API abstracts both via the `threadId` parameter to
`mcp__claude_ai_Gmail__create_draft`. **Always pass it.**

The call shape (signature, mandatory kwargs, no-send rule) lives in
[`operations.md`](operations.md#create-draft); the rules on **which**
thread to use and what the other fields look like live here.

## The rule

- **Same thread every time.** Whatever the recipient change — a
  reporter reply, an ASF-security relay request, a PMC credit
  question, a follow-up asking for a PoC — the draft stays on the
  inbound tracker's `threadId`. A triager reading the Gmail
  conversation view should see every exchange on a single tracker
  in one place; if threading breaks, that history scatters across
  two conversations.
- **Subject stays as `Re: <root subject>`**, never a fabricated
  new one. Gmail's own threading survives without matching
  subjects when `threadId` is set, but other clients (Thunderbird,
  Outlook, Apple Mail) and the recipient's own client commonly
  fall back to subject-based threading. A drifted subject looks
  like a broken conversation on half the world's mail readers.
- **`To:` may differ from the original correspondents.** It is
  fine to address a draft to a specific person (an ASF
  security-team member who relayed the report, a named PMC member,
  an individual reporter) even if the original inbound root was
  addressed to a list. Threading does not require recipient
  overlap; it requires `threadId`.
- **Not knowing the `threadId` is a blocker, not a licence to
  fabricate a new thread.** If the skill cannot resolve the
  inbound `threadId` from the tracker body (the *security-thread*
  field — for Airflow, *"Security mailing list thread"*; see
  [`../github/issue-template.md`](../github/issue-template.md#field-roles-the-skills-use)
  for the role name) or from the skill's own Step 1 context,
  stop and surface the gap to the user before drafting. A
  standalone draft with no thread context is worse than no draft.

## Special case — ASF-security relay

When the inbound report arrives via an ASF forwarder rather than
directly from the external reporter, the drafting shape changes
slightly (different `To:` / `Cc:`, relay-specific body language) but
the threading rule is **unchanged**: same thread, same subject. See
[`asf-relay.md`](asf-relay.md).
