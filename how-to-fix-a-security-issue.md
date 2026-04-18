<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Fixing security issues](#fixing-security-issues)
  - [Process](#process)
  - [Best practices](#best-practices)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Fixing security issues

High-level overview of how the security team handles a vulnerability
report from inbound email through published CVE. This page is
project-agnostic; the concrete lists, repos, release trains, and
tooling for the currently active project live under
[`projects/<PROJECT>/`](projects/) — for Airflow, see
[`projects/airflow/project.md`](projects/airflow/project.md).

The end-to-end 16-step lifecycle is in [`README.md`](README.md). This
page is the two-minute summary.

## Process

1. **Vulnerability identification.**
   The active project's community monitors the project's
   `<security-list>` (declared in
   `projects/<PROJECT>/project.md → Mailing lists`) for inbound
   reports. Reports from elsewhere (GHSA, HackerOne, the ASF
   `security@apache.org` relay) are forwarded onto that list so the
   security team has a single inbox.

2. **Triage.**
   A rotating triager imports new reports into the private
   `<tracker>` repository (see the
   [`import-security-issue`](.claude/skills/import-security-issue/SKILL.md)
   skill), classifies each candidate, and drafts a
   receipt-of-confirmation reply to the reporter. The team then
   discusses CVE-worthiness in the issue comments and — once the
   report is assessed valid — applies a project-specific scope label
   (see `projects/<PROJECT>/scope-labels.md`).

3. **CVE allocation.**
   A PMC member of the active project allocates a CVE through the
   project's CVE tool (for Airflow, ASF Vulnogram). The allocation
   is PMC-gated; non-PMC triagers use the
   [`allocate-cve`](.claude/skills/allocate-cve/SKILL.md) skill to
   produce a relay message for a PMC member to click through.

4. **Remediation.**
   A security-team member writes the fix in the public `<upstream>`
   repository (see the
   [`fix-security-issue`](.claude/skills/fix-security-issue/SKILL.md)
   skill, which can draft the PR automatically). The public PR is
   scrubbed of CVE references, tracker-repo references, and any
   *"security fix"* signal — per the confidentiality rules in
   [`AGENTS.md`](AGENTS.md#confidentiality-of-the-tracker-repository).

5. **Release + advisory.**
   The release manager for the cut that carries the fix sends the
   public advisory to the project's users + announce lists, captures
   the archive URL, and moves the CVE record to `PUBLIC` in the CVE
   tool.

6. **Continuous improvement.**
   The security team encourages responsible vulnerability disclosure
   and continues to improve the project's security posture, security
   features, and handling process. The active project's security
   model (for Airflow, [`projects/airflow/security-model.md`](projects/airflow/security-model.md))
   is the authoritative reference for what counts as a vulnerability.

## Best practices

* **Avoid labelling low-severity fixes as "security fixes" in public
  commits.** When we implement low-severity security fixes —
  sometimes ones that are not even worthy of a CVE — we avoid
  describing them as security features in public commit messages,
  newsfragments, and release notes. This prevents automated scrapers
  from raising reports about issues they were not originally aware
  of. Such tools may themselves violate our security practices.
* **Keep the reporter informed at every status transition** — see
  the [*Keeping the reporter informed*](README.md#keeping-the-reporter-informed)
  section of `README.md` for the full list of transitions and the
  drafting rules.
* **Confidentiality first.** Nothing about the private `<tracker>`
  repository — issue numbers, labels, discussions — may appear on a
  public surface. See the
  [Confidentiality of the tracker repository](AGENTS.md#confidentiality-of-the-tracker-repository)
  section of `AGENTS.md`.
