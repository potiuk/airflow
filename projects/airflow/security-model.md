<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Apache Airflow — Security Model reference](#apache-airflow--security-model-reference)
  - [Authoritative URL](#authoritative-url)
  - [Known-useful anchors](#known-useful-anchors)
  - [Drafting rule](#drafting-rule)
  - [Public security policy](#public-security-policy)
  - [ASF-level severity-rating reference](#asf-level-severity-rating-reference)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# Apache Airflow — Security Model reference

This file is the project-specific reference to the **Airflow Security
Model**, which the canned responses and validity assessments cite as
the authoritative answer to *"is this a vulnerability in Apache
Airflow?"*. It is referenced from [`project.md`](project.md) and from
the repo-level [`../../AGENTS.md`](../../AGENTS.md) section on drafting
reporter replies.

Project-agnostic drafting rules (tone, brevity, threading) live in
the repo-level [`../../AGENTS.md`](../../AGENTS.md). The *content* the
responses link to is what lives here.

## Authoritative URL

The [Airflow Security Model](https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html)
is the authoritative source for what is and is not considered a
security vulnerability in Apache Airflow. Canned responses must link
directly to the relevant chapter instead of paraphrasing it.
Paraphrases drift over time and create a second source of truth that
has to be maintained.

## Known-useful anchors

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

## Drafting rule

When adding a new canned response, identify the matching chapter in
the Security Model first. If no chapter covers the case, that is a
signal the Security Model should be updated in
[`apache/airflow`](https://github.com/apache/airflow) rather than
duplicated in
[`canned-responses.md`](canned-responses.md).

## Public security policy

The public-facing rules reporters are expected to follow live at
<https://github.com/apache/airflow/security/policy>.

## ASF-level severity-rating reference

For assigning severity scores, Airflow follows the ASF's
[Severity Rating blog post](https://security.apache.org/blog/severityrating)
as the authoritative rubric. Reporter-supplied CVSS scores are
informational only — the ASF-level rule that governs this is in the
repo-level [`../../AGENTS.md`](../../AGENTS.md#reporter-supplied-cvss-scores-are-informational-only--never-propagate-them)
(it is not Airflow-specific).
