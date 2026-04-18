<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [TODO: `<Project Name>` — canned responses](#todo-project-name--canned-responses)
  - [TODO — minimum viable canned responses](#todo--minimum-viable-canned-responses)
    - [Confirmation of receiving the report](#confirmation-of-receiving-the-report)
    - [Negative assessment — out of scope per the Security Model](#negative-assessment--out-of-scope-per-the-security-model)
    - [Negative assessment — not a vulnerability](#negative-assessment--not-a-vulnerability)
  - [TODO — common "known-invalid" categories](#todo--common-known-invalid-categories)
    - [Automated scanning results](#automated-scanning-results)
    - [Consolidated multi-issue report](#consolidated-multi-issue-report)
    - [Media / research-disclosure request](#media--research-disclosure-request)
    - [Publicly-disclosed issue (reported after public disclosure)](#publicly-disclosed-issue-reported-after-public-disclosure)
  - [TODO — status-update templates](#todo--status-update-templates)
    - [CVE allocated](#cve-allocated)
    - [Fix PR opened](#fix-pr-opened)
    - [Fix released + advisory sent](#fix-released--advisory-sent)
  - [Drafting rules](#drafting-rules)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# TODO: `<Project Name>` — canned responses

Reusable reporter-facing reply templates. These are sent **verbatim**
as email replies on the original inbound thread, so tone matters —
follow the *"Tone: polite but firm"* and *"Brevity: emails state
facts, not context"* rules in
[`../../AGENTS.md`](../../AGENTS.md). Every template links into the
project's Security Model (see
[`security-model.md`](security-model.md)) rather than paraphrasing
it.

The [`import-security-issue`](../../.claude/skills/import-security-issue/SKILL.md)
skill sends the *Confirmation of receiving the report* template
verbatim on every new inbound report — that one is **load-bearing**
and must exist before the skill is useful. The rest can be filled in
gradually as real reports surface categories the team wants to
canonicalise.

## TODO — minimum viable canned responses

At a minimum, the following templates should exist before a tracker
team goes live. Copy one of the shapes from
[`../airflow/canned-responses.md`](../airflow/canned-responses.md)
and adapt the wording to the project.

### Confirmation of receiving the report

TODO: short confirmation that the report has been received, the
security team will assess it, and what the reporter should expect
next. Include the credit-preference question. Sent verbatim by
`import-security-issue`.

### Negative assessment — out of scope per the Security Model

TODO: polite-but-firm reply used when a report describes behaviour
the project's Security Model explicitly considers out of scope.
Link to the specific Security-Model chapter.

### Negative assessment — not a vulnerability

TODO: reply for reports that describe a bug or design question that
is not a vulnerability.

## TODO — common "known-invalid" categories

Fill these in as the team encounters repeat categories. Each template
is addressed to a specific reporter shape (automated scanner,
consolidated multi-issue report, media-disclosure request, etc.).

### Automated scanning results

TODO.

### Consolidated multi-issue report

TODO.

### Media / research-disclosure request

TODO.

### Publicly-disclosed issue (reported after public disclosure)

TODO.

## TODO — status-update templates

These go out at lifecycle transitions (per
[`../../README.md#keeping-the-reporter-informed`](../../README.md#keeping-the-reporter-informed)).

### CVE allocated

TODO.

### Fix PR opened

TODO.

### Fix released + advisory sent

TODO.

## Drafting rules

- **Do not paraphrase the Security Model.** Link to the chapter.
- **Do not echo reporter-supplied CVSS scores.** See the rule in
  [`../../AGENTS.md`](../../AGENTS.md#reporter-supplied-cvss-scores-are-informational-only--never-propagate-them).
- **Do not include tracker-repo URLs in these templates.** They go
  out as email and must never reveal the tracker. See the
  confidentiality section of
  [`../../AGENTS.md`](../../AGENTS.md#confidentiality-of-the-tracker-repository).
- **Every transition that warrants a reply is listed in
  [`../../README.md`](../../README.md#keeping-the-reporter-informed)** —
  treat that list as authoritative.
