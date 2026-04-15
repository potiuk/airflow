<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Handling security issues for Apache Airflow](#handling-security-issues-for-apache-airflow)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Handling security issues for Apache Airflow

We keep all security issues reported for Apache Airflow in this separate repository. This repository is
private, and only members of the security team have access to it.

The issues here are created from reports raised via the `security@airflow.apache.org` mailing list
and copied here by members of the security team.

Note that at various points we respond to the reporter with information about our assessment
of the issue. We use [canned responses](canned-responses.md) to handle some common cases, so
consult them if you need to send a response.

The process of handling an issue is as follows:

1) The reporter reports the issue to `security@airflow.apache.org` or `security@apache.org` (in the latter
   case, the security team of the Apache Software Foundation will forward the issue to the Airflow security
   mailing list).

2) A security team member picks it up and [creates an issue](https://github.com/airflow-s/airflow-s/issues/new/choose).
   The issue should have a label set — one of `airflow`, `providers`, or `chart`. The team member replies
   by email to the reporter to let them know we are looking at the report. The issue automatically receives
   the `needs triage` label. If the issue is "obviously invalid" (we've seen such issues before and triaged or
   responded to them), the response may simply explain why and clearly state that the issue is invalid; in
   that case this step (and all the following steps) may be skipped, and no issue needs to be created.

3) In the issue, we discuss and agree on whether it is worth having a CVE for it.

4) If the discussion stalls and we cannot make a decision in about 30 days, the next step
   is to seek assistance in making a decision from a broader audience:
   * `private@airflow.apache.org`
   * `security@apache.org`
   * the reporter(s) who raised the issue, asking them for their opinion and additional context

   Such a discussion should include additional context — a digest of the discussion so far, the options
   considered, the impact, pros and cons, and so on. This can help to get additional perspectives and
   possibly better ideas.

5) Finally, if we cannot reach consensus we follow [voting](https://www.apache.org/foundation/voting.html#apache-voting-process).
   A vote on code modification is used, which means that committers have binding votes, whereas everyone
   else has advisory votes — and all are encouraged to vote and express their opinion. If there is no major
   disagreement during the discussion, there is no need to formally vote via a mailing list thread — the
   voting is done in the PR. However, if there are differing opinions, voting is done on the
   `security@airflow.apache.org` list. The `needs triage` label should then be removed.

6) If we agree the issue is invalid, a team member closes the issue and responds to the reporter with
   that information. If the issue is valid, the team member [assigns a CVE via the ASF CVE tool](https://cveprocess.apache.org/allocatecve).
   The team member then responds in the email thread to confirm creation of the CVE to the reporter, including
   the CVE ID, asks the reporter how they would like to be credited, and updates the reporter name in the
   issue description when the reporter answers.

7) One of the team members self-assigns the issue (not necessarily the person who originally started
   the discussion) and implements the fix.

   NOTE: In some cases it is possible to delegate the fix to a trusted third-party individual. For example, if
   the security team member assigned to the issue has access to developers willing or otherwise dedicated to
   Airflow development, they may delegate to one such individual, provided that:
   1) The individual is trusted.
   2) The individual only receives the information required to implement a fix (no wholesale sharing of
      security team emails, GitHub issues, etc.).
   3) A LAZY CONSENSUS vote is conducted in either the email thread or the GitHub issue associated with the
      security issue (GitHub communications are synced to the email group for posterity).

8) If the issue is straightforward, it may be followed by a direct PR in the Airflow repository. The
   description in the PR should not reveal the CVE or the security nature of it.

9) In exceptional cases — when the issue is highly critical, or when code discussion is needed and the PR
   requires input and review before it gets merged — the person solving it can create a PR in the
   `airflow-s/airflow-s` repository with "Closes: #issue". The PR should be raised against the `main` branch
   of the `airflow-s/airflow-s` repository (not the default `airflow-s` branch). This allows for detailed
   code-change discussion in private. For now, CI is not run for PRs in the `airflow-s/airflow-s` repository,
   so static checks and tests should be run manually by the person creating the PR. We may improve this in
   the future. Once the PR has been reviewed, approved, and is ready to merge, the branch with the fix should
   be pushed to the Airflow repository and the PR should be re-opened in the Airflow repository by pushing
   the branch to public `apache/airflow` and merging it there.

10) Once the PR is created in the Airflow repository, the team member who creates it should link to the PR
    in the description of the issue.

11) The security team member merging the `apache/airflow` PR should mark the issue with the `Not yet announced`
    label in `airflow-s`. If there is a private variant of the PR in the `airflow-s/airflow-s` repository, it
    should be closed. The milestone of the issue should be set to the milestone when it is planned to be released.
    The milestones are in the format `Airflow-2.6.2`, `Providers-June-2023-1`
    (first June providers batch), or `Chart-1.9.0`. New milestones are created when needed.
    Sometimes, as a result of the triage discussions, the fix should not be applied in the next patch-level
    release — for example, because of high risk involved or because it needs to be correlated with other changes.
    In such cases, the milestone in the issue and the corresponding PR should be set to the next minor release
    rather than the next patch-level release.

12) During releases, the release manager looks through "Not yet announced" issues in `airflow-s`
    with the corresponding milestones, updates the [ASF CVE tool](https://cveprocess.apache.org), and
    updates the following fields, taking them from the issue:

    * CWE (Common Weakness Enumeration) — possible CWEs are available [here](https://cwe.mitre.org/data/index.html)
    * Product name (Airflow, affected Airflow Provider, or Airflow Helm Chart)
    * Version affected (`0, < Version released`)
    * Short public summary
    * Severity score — based on the [Severity Rating blog post](https://security.apache.org/blog/severityrating).
      The issue owner should, during discussion on the issue, propose the score and update the ticket.
      In obvious cases with no objections, this should work in lazy-consensus mode. If there are differing
      opinions, driving the discussion to achieve consensus is the preferred outcome. Voting may be cast if
      needed. If the severity has not been decided or consensus reached during earlier discussion, the
      Release Manager has the final say on the severity score (but should take into account the opinions of
      the security team). This is to prioritize getting the issue announcement out in a timely manner.
    * References:
        * `patch` — PR to the fix in the Apache Airflow repository
    * Credits:
        * `reporter` — reporter(s) of the issue
        * `remediation developer` — PR author(s)

    The release manager also generates the CVE description, sets the CVE to REVIEW if feedback is needed and
    then to READY, and eventually sends the announcement emails from the ASF CVE tool. The release manager
    then closes the issue.

13) After the emails have been delivered, the release manager updates the issue with information about the
    announcement, adding the `vendor-advisory` tag with a link to the `users@airflow.apache.org` mailing list
    retrieved via the [user list archive](https://lists.apache.org/list.html?users@airflow.apache.org).

14) If we need to add missing credits (which sometimes happens due to copy-and-paste errors and the
    brittleness of the process), the release manager:
    * responds to the announcement emails and mentions the missing credits
    * updates the [ASF CVE tool](https://cveprocess.apache.org) with the missing credits
    * asks the ASF security team to push the information to [cve.org](https://cve.org)
