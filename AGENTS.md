<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [AGENTS instructions](#agents-instructions)
  - [Repository purpose](#repository-purpose)
  - [Commit and PR conventions](#commit-and-pr-conventions)
  - [Writing and editing documentation](#writing-and-editing-documentation)
  - [Before submitting](#before-submitting)
  - [References](#references)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# AGENTS instructions

These instructions apply to any AI agent (or agent-assisted contributor) working on
this repository. The repository is private and hosts the Airflow security team's
processes, canned responses, and onboarding documentation — it is read by security
team members and, through the canned responses, indirectly by external reporters.
Small wording choices matter.

## Repository purpose

This repository contains:

- [`README.md`](README.md) — the end-to-end process for handling security issues reported against Apache Airflow.
- [`canned-responses.md`](canned-responses.md) — reusable replies that the security team sends to reporters.
- [`how-to-fix-a-security-issue.md`](how-to-fix-a-security-issue.md) — high-level description of the fix workflow.
- [`new-members-onboarding.md`](new-members-onboarding.md) — onboarding guide for new security team members.

There is no source code to build or test. Changes are reviewed and merged by the security team.

## Commit and PR conventions

- **Never use `Co-Authored-By:` with an AI agent as co-author.** Agents are assistants, not authors. This matches the
  rule in [`apache/airflow/AGENTS.md`](https://github.com/apache/airflow/blob/main/AGENTS.md). Use a
  `Generated-by:` trailer instead, e.g.:

  ```
  Generated-by: Claude Opus 4.6 (1M context) following the guidelines at
  https://github.com/apache/airflow/blob/main/contributing-docs/05_pull_requests.rst#gen-ai-assisted-contributions
  ```

- **Always open PRs with `gh pr create --web`** so the human reviewer can check the title,
  body, and the generative-AI disclosure in the browser before submission. Pre-fill `--title`
  and `--body` (including the Gen-AI disclosure block) so they only need to review, not edit.
- **Target branch is `airflow-s`**, not `main`. The default branch of this repository is `airflow-s`;
  `main` exists only as a staging branch for the occasional private-PR workflow described in
  [`README.md`](README.md). Unless the user explicitly says otherwise, base PRs on `airflow-s`.
- Keep the commit message focused on the user-visible change, not the mechanics of how the edit
  was made.

## Writing and editing documentation

The documents in this repository are short and opinionated. When editing them, prefer small,
targeted improvements over rewrites, and preserve the existing structure (including the
`doctoc`-generated tables of contents) unless the change is explicitly about structure.

### Tone: polite but firm — no room to wiggle

The canned responses in [`canned-responses.md`](canned-responses.md) are the public face of the
security team. They are often sent to reporters whose submissions have been assessed as invalid
or out of scope. The tone must be:

1. **Polite and professional.** Thank the reporter, acknowledge the intent, stay neutral.
2. **Firm and unambiguous.** State the outcome as a decision, not as a negotiation. The response
   is an expectation, not a suggestion.
3. **Free of accusation, sarcasm, and condescension.** Never imply the reporter "didn't bother
   to read", never say things like "Two reasons indicate that you did not", never tell them to
   "digest" the security model. These phrasings leave bad taste and, worse, invite argument.
4. **Free of hedging.** Avoid phrases like "feel absolutely free", "we would appreciate if you
   stopped", or "we would kindly ask you to consider" — they weaken the message and imply the
   expectation is optional. Prefer "please do not use this address for such requests" or "we are
   unable to treat this as a security issue unless…".

Concrete phrasing patterns that work well:

- Lead with: *"Thank you for the report."* Then state the outcome.
- State the decision in plain terms: *"We do not consider this a vulnerability."* / *"We cannot
  accept this report."* / *"This is explicitly out of scope for our security process."*
- Anchor the decision in an authoritative document, not in the responder's opinion:
  *"… is documented in our Security Model under '…': <link>."*
- When describing consequences of repeated policy violations, use passive, factual language:
  *"Accounts that repeatedly send reports which do not meet the policy are added to a deny list."*
  Do not threaten.
- End with a constructive alternative where one exists: *"We would welcome a PR through the
  regular contribution process."*

### Point reporters to the Security Model, don't re-explain it

The [Airflow Security Model](https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html)
is the authoritative source for what is and is not considered a security vulnerability. Canned
responses must link directly to the relevant chapter instead of paraphrasing it. Paraphrases
drift over time and create a second source of truth that has to be maintained.

Known-useful anchors:

- `#capabilities-of-dag-authors`
- `#dag-authors-executing-arbitrary-code`
- `#dag-author-code-passing-unsanitized-input-to-operators-and-hooks`
- `#limiting-dag-author-capabilities`
- `#connection-configuration-users`
- `#connection-configuration-capabilities`
- `#denial-of-service-by-authenticated-users`
- `#self-xss-by-authenticated-users`
- `#simple-auth-manager`
- `#third-party-dependency-vulnerabilities-in-docker-images`
- `#automated-scanning-results-without-human-verification`

When adding a new canned response, identify the matching chapter in the Security Model first.
If no chapter covers the case, that is a signal the Security Model should be updated in
[`apache/airflow`](https://github.com/apache/airflow) rather than duplicated here.

### Other editorial guidelines

- Do not include concrete contributor counts (e.g., "4000 contributors", "3600 contributors").
  Use *"thousands of contributors"* — the number changes constantly and hard-coding it dates the
  document immediately.
- Use **`Dag`** (not `DAG`) when referring to Airflow DAGs in prose — e.g. *"Dag author"*,
  *"Dag run"*, *"serialized Dags"*. This matches the Airflow Security Model chapter titles
  (*"Capabilities of Dag authors"*, *"Dag authors executing arbitrary code"*, etc.) and the
  convention used throughout `apache/airflow`'s own documentation and `AGENTS.md`. Do not
  use the all-caps `DAG` form in documentation in this repository; leave it only inside
  quoted content, URLs, anchor slugs, or code identifiers where it already appears.
- Prefer *PoC*, *DoS*, *CVE* as the canonical capitalisations for those acronyms.
- Use em dashes (`—`) sparingly; prefer shorter sentences to dash-heavy ones.
- Preserve the `doctoc` TOC markers at the top of each document. If you rename a heading, update
  the corresponding TOC entry in the same change.
- Do not add emojis.

## Before submitting

- Re-read the diff and check that every change is intentional.
- Check that any renamed headings have matching TOC updates.
- Verify that links to the Airflow Security Model use an anchor that exists on the current
  stable version.
- Self-review the tone of any modified canned response against the "polite but firm" guidance above.

## References

- [`apache/airflow/AGENTS.md`](https://github.com/apache/airflow/blob/main/AGENTS.md) — the parent convention these instructions mirror.
- [Airflow Security Model](https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html) — authoritative source for what is and is not a vulnerability.
- [Airflow security policy](https://github.com/apache/airflow/security/policy) — public-facing rules reporters are expected to follow.
