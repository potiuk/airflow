## Handling security issues for Apache Airflow.

We keep all the security issues reported for Apache Airflow in this separate repository. This repository is
private, and only members of the security team have access to it.

The issues created here are created from the reports raised via the `security@airflow.apache.org` mailing list
and copied here by the security team members.

Note that at various points we are responding to the reporter with the information about our assessment
of the issue. We are using [canned responses](canned-responses.md) to handle some common cases, so
consult the responses if you want to send a response.

The process of handling issue looks as follows:

1) The reporter reports the issue to `security@airflow.apache.org` or `security@apache.org` (in the latter
   case the security team of the Apache Software Foundation will forward the issue to the Airflow security
   mailing list.

2) A security team member picks it up and [creates an issue](https://github.com/airflow-s/airflow-s/issues/new/choose).
   The issue should have a label set - one of `airflow` or `providers` or `chart`. The team member responds
   in the email to the reporter that we are looking at the report. The issue gets `needs triage` label
   automatically. In case the issue is "obviously invalid" (we've seen such issues before and triaged/responded
   to them), the response might be the explanation why and clear statement that the issue is invalid and
   this step (and all the following steps) might be skipped. No issue needs to be created in such case.

3) In the issue we discuss and agree if it is worth to have a CVE for it. 

4) In case the discussion is stalled and we cannot make a decision in about 30 days, the next step
   is to seek assistance in making a decision from a broader audience:
   * private@airflow.apache.org
   * security@apache.org
   * reporter(s) who raised the issue asking them for opinion and additional context
   
   Such discussion should have additional context - digest from the discussion so far, considered options,
   impact, pros/cons etc. This might help to get additional perspective and possibly better ideas.

5) Finallly, if we cannot reach consensus we follow [voting](https://www.apache.org/foundation/voting.html#apache-voting-process). Vote on code modification
   is used, which means that committers have binding votes, whereas everyone else have advisory votes - and
   are encouraged to vote and express their opinion. If there is no major disagreement during discussion,
   there is no need to formally vote with mailing list thread - the voting is done in the PR. However, if
   there are various opinions, voting is done at the `security@airflow.apache.org` list. The "needs triage"
   label should be removed.

5) In case we agree the issue is invalid, a team member closes the issue and responds to the reporter with
   the information. In case the issue is valid, the team member creates CVE via
   [assigns CVE in the ASF CVE tool](https://cveprocess.apache.org/allocatecve). The team member responds
   in the email thread and confirms creation of the CVE to the reporter including the CVE_ID,
   asks the reporter how they want to be credited and updates the reporter name in the issue description when
   the reporter answers.

6) One of the team members self-assigns to the issue (not necessarily the person who originally started
   the discussion) and implements the fix.

   NOTE: In some cases it is possible to delegate the fix to a trusted 3rd party individual. For example, if
   the security team member assigned to the issue has access to developers willing or otherwise dedicated to
   Airflow development, they may delegate to one such individual, providing that:
   1) The individual is trusted.
   2) The individual only receives the requisite information to implement a fix (no wholesale sharing of
      security team emails, GitHub issues, etc).
   3) A LAZY CONSENSUS vote is conducted in either the email thread or GitHub Issue associated to the
      security issue (GitHub communications are synced to the email group for posterity).

7) If the issue is straightforward it might be followed with direct PR in Airflow repository. The description
   in the PR should not reveal the CVE or security nature of it.

8) In exceptional cases: when highly critical issue or when code discussion is needed and PR needs input and
   review before it gets merged, the person solving it can create a PR in the `airflow-s/airflow-s`
   repository with "Closes: #issue". The PR should be raised against the `main` branch of `airflow-s/airflow-s`
   repository (not the default `airflow-s`). This allows for detailed code change discussion in private.
   For now CI is not run for the PRs in the `airflow-s/airflow-s` repository (so static checks
   and tests should be run manually by the person creating the PR). We might improve it in the future.
   Once the PR gets reviewed/approved and ready-to-merge, the branch with the fix should be pushed to the
   airflow repository and PR should be re-opened in the Airflow repository by pushing the branch to
   public `apache/airflow` and merged there.

9) Once PR is created in the Airflow repository, the team member who creates it should link to the PR
   in the Airflow repository in the description of the issue.

10) The security team member merging the `apache/airflow` PR, should mark the issue with `Not yet announced` label
    in `airflow-s`. If there is the private variant of the PR in the `airflow-s/airflow-s` repository, it should be closed.
    The milestone of the issue should be set to milestone when it is planned to be released.
    The milestones are in the format `Airlfow-2.6.2` or `Providers-June-2023-1`
    (first June providers batch) or `Chart-1.9.0`. New milestones are created when needed.
    Sometimes, (as result of the triage discussions) the fix should not be applied in the next patch-level
    release, for example because of high risk involved or need to be correlated with other changes.
    In such cases, the milestone in the issue and the corresponding PR should be set to the next minor release
    rather than the next patch-level release. 

11) During the releases, the release manager will look through "Not yet announced" issues in the "airflow-s"
    with the corresponding milestones, updates the [ASF CVE tool](https://cveprocess.apache.org) and
    Updates the following fields taking it from the issue:

    * CWE (Common Weakness Enumeration) - Possible CWEs available [here](https://cwe.mitre.org/data/index.html)
    * Product name (Airflow, affected Airflow Provider or Airflow Helm Chart)
    * Version affected (0, < Version released)
    * Short public summary 
    * Severity score - based on [Severity Rating blog post](https://security.apache.org/blog/severityrating)
      The issue owner should - during discussion on the issue - propose the score and update the ticket.
      In obvious cases no objections, this should work in lazy-consensus mode, if there are different opinions
      driving the discussion to achieve the consensus is preffered outcome. Voting might be cast if needed.
      If the severity has not been decided/consensus reached during earlier discussion, the Release Manager
      has the final say on the severity score (but should take into account the opinions of the security team)
      this is in order to prioritize getting the issue announcement out in a timely manner.
    * References:
        * `patch` - PR to the fix in the Apache Airflow repository
    * Credits:
        * `reporter` - reporter(s) of the issue
        * `remediation developer` - PR author(s)

    The release manager also generates the CVE description, set the CVE to REVIEW if feedback is needed and
    then READY and eventually sends the announcement emails from the ASF CVE tool. Release manager closes the issue.

12) After emails get delivered, the release manager updates the issue with the information about the
    announcement with `vendor-advisory` tag with link to the `users@airflow.apache.org` mailing list retrieved
    via [user list archive](https://lists.apache.org/list.html?users@airflow.apache.org)

13) In case we need to add missing credits (which sometimes happens due to copy&paste and brittleness of
    the process, the release manager:
    * responds to the announce emails and also mentions the missing credits
    * updates the [ASF CVE tool](https://cveprocess.apache.org) with the missing credits
    * asks the security team of ASF to push the information to [cve.org](cve.org)
