## Handling security issues for Apache Airflow.

We keep all the security issues reported for Apache Airflow in this separate repository. This repository is
private, and only members of the security team have access to it.

The issues created here are created from the reports raised via the `security@airflow.apache.org` mailing list
and copied here by the security team members.

The process of handling issue looks as follows

1) The reporter reports the issue to `security@airflow.apache.org` or `security@apache.org` (in the latter
   case the security team of the Apache Software Foundation will forward the issue to the Airflow security
   mailing list.

2) A security team member picks it up and [creates an issue](https://github.com/airflow-s/airflow-s/issues/new/choose).
   The issue should have a label set - one of `airflow` or `providers` or `chart`. The team member responds
   in the email thread with the link to the issue just created.

3) In the issue we discuss and agree if it is worth to have a CVE for it. If we cannot reach consensus we follow
   [voting](https://www.apache.org/foundation/voting.html#apache-voting-process). Vote on code modification
   is used, which means that committers have binding votes, whereas everyone else have advisory votes - and
   are encouraged to vote and express their opinion. If there is no major disagreement during discussion,
   there is no need to formally vote with mailing list thread - the voting is done in the PR. However, if
   there are various opinions, voting is done at the `security@airflow.apache.org` list.

4) In case we agree the issue is invalid, a team member closes the issue and responds to the reporter with
   the information. In case the issue is valid, the team member creates CVE via
   [assigns CVE in the ASF CVE tool](https://cveprocess.apache.org/allocatecve). The team member responds
   in the email thread and confirms creation of the CVE to the reporter including the CVE_ID,
   asks the reporter how they want to be credited and updates the reporter name in the issue description when
   the reporter answers.

5) One of the team members self-assigns to the issue (not necessarily the person who originally started
   the discussion) and implements the fix.

   NOTE: In some cases it is possible to delegate the fix to a trusted 3rd party individual. For example, if
   the security team member assigned to the issue has access to developers willing or otherwise dedicated to
   Airflow development, they may delegate to one such individual, providing that: 1) the individual is trusted,
   2) the individual only receives the requisite information to implement a fix (no wholesale sharing of
   security team emails, GitHub issues, etc) and 3) that a LAZY CONSENSUS vote is conducted in either the
   email thread or GitHub Issue associated to the security issue (GitHub communications are synced to the
   email group for posterity).

6) If the issue is straightforward it might be followed with direct PR in Airflow repository. The description
   in the PR should not reveal the CVE or security nature of it.

7) In exceptional cases: when highly critical issue or when code discussion is needed and PR needs input and
   review before it gets merged, the person solving it can create a PR in the `airflow-s/airflow-s`
   repository with "Closes: #issue". The PR should be raised against the `main` branch of `airflow-s/airflow-s`
   repository (not the default `airflow-s`). This allows for detailed code change discussion in private.
   For now CI is not run for the PRs in the `airflow-s/airflow-s` repository (so static checks
   and tests should be run manually by the person creating the PR). We might improve it in the future.
   Once the PR gets reviewed/approved and ready-to-merge, the branch with the fix should be pushed to the
   airflow repository and PR should be re-opened in the Airflow repository by pushing the branch to
   public `apache/airflow` and merged there.

8) Once PR is created in the Airflow repository, the team member who creates it should link to the PR
   in the Airflow repository in the description of the issue.

9) The security team member merging the `apache/airflow` PR, should close the issue in `airflow-s`. If there
   is the private variant of the PR in the `airflow-s/airflow-s` repository, it should be closed as well.
   The milestone of the issue should be set to milestone when it is planned to be released.
   The milestones are in the format `Airlfow-2.6.2` or `Providers-June-2023-1`
   (first June providers batch) or `Chart-1.9.0`. New milestones are created when needed.
   Sometimes, (as result of the triage discussions) the fix should not be applied in the next patch-level
   release, for example because of high risk involved or need to be correlated with other changes.
   In such cases, the milestone in the issue and the corresponding PR should be set to the next minor release
   rather than the next patch-level release.

10) During the releases, the release manager will look through closed issues in the "airflow-s"
    with the corresponding milestones, updates the [ASF CVE tool](https://cveprocess.apache.org) and
    Updates the following fields taking it from the issue:

    * CWE (Common Weakness Enumeration) - Possible CWEs available [here](https://cwe.mitre.org/data/index.html)
    * Product name (Airflow, affected Airflow Provider or Airflow Helm Chart)
    * Version affected (0, < Version released)
    * Severity score - based on [Severity Rating blog post](https://security.apache.org/blog/severityrating)
    * References:
        * `patch` - PR to the fix in the Apache Airflow repository
    * Credits:
        * `reporter` - reporter(s) of the issue
        * `remediation developer` - PR author(s)

    The release manager also generates the CVE description, set the CVE to READY and
    sends the announcement emails from the ASF CVE tool.

12) After emails get delivered, the release manager updates the issue with the information about the
    announcement with `vendor-advisory` tag with link to the `users@airflow.apache.org` mailing list retrieved
    via [user list archive](https://lists.apache.org/list.html?users@airflow.apache.org)
