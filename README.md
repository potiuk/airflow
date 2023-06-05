## Handling security issues for Apache Airflow.

We keep all the security issues reported for Apache Airflow in this separate repository. This repository is
private, and only members of the security team have access to it.

The issues created here are created from the reports raised via the `security@apache.org` mailing list
and copied here by the security team members.

The process of handling issue looks as follows

1) The reporter reports the issue to `security@airflow.apache.org` or `security@apache.org` (in the latter
   case the security team of the Apache Software Foundation will forward the issue to the Airflow security
   mailing list.

2) A security team member picks it up and proposes interpretation in the mailing thread. Here we should
   agree if the issue is worth to be fixed and if it is a security issue. In case we agree it is invalid,
   the team member responds to the reporter without creating an issue. If we cannot reach consensus we follow
   [voting](https://www.apache.org/foundation/voting.html#apache-voting-process). Vote on code modification
   is used, which means that committers have binding votes, whereas everyone else have advisory votes - and
   are encouraged to vote and express their opinion. If there is no major disagreement during discussion,
   there is no need to formally vote with mailing list thread - the voting is done in the PR. However, if
   there are various opinions, voting is done at the security@airflow.apache.org list.

3) When the issue is plausible, and we agree we should fix it, a security team member who has access
   [assigns CVE in the ASF CVE tool](https://cveprocess.apache.org/allocatecve) for the issue and
   [creates an issue](https://github.com/airflow-s/airflow-s/issues/new/choose). The team member responds
   in the email thread and confirms creation of the CVE issue created to the reporter including the CVE_ID
   and asks the reporter how they want to be credited and updates the reporter name in the issue description.
   When issue gets created, a new thread is automatically created in the security@airflow.apache.org mailing
   list. The label indicates if it is an `airflow` or `providers` or `chart` issue.

4) One of the team members self-assigns to the issue (not necessarily the person who originally started
   the discussion) and implements the fix.

5) If the issue is straightforward it might be followed with direct PR in Airflow repository. The description
   in the PR should not reveal the CVE or security nature of it.

6) In exceptional cases: when highly critical issue or when code discussion is needed and PR needs input and
   review before it gets merged, the person solving it can create a PR in the `airflow-s/airflow-s`
   repository with "Closes: #issue". The PR should be raised against the `main` branch of `airflow-s/airflow-s`
   repository (not the default `airflow-s`). This allows for detailed code change discussion in private.
   For now CI is not run for the PRs in the `airflow-s/airflow-s` repository (for now so static checks
   and tests should be run manually by the person creating the PR). We might improve it in the future. 
   Once the PR gets reviewed/approved and ready-to-merge, the branch with the fix should be pushed to the 
   airflow repository and PR should be re-opened in the Airflow repository by pushing the branch to 
   public `apache/airflow` and merged there.

7) Once PR is created in the Airflow repository, the team member who creates it should link to the PR
   in the Airflow repository in the description of the issue.

8) In cases there is a doubt whether the fix should be applied in the next patch-level release,
   for example because of high risk involved or need to be correlated with other changes. In such cases the
   `apache/airflow` PR should contain recommendation from the person who implemented the fix on how to
   proceed. Milestone in the `apache/airflow` PR should be set as usual for regular PRs.

9) The security team member merging the `apache/airflow` PR, should close the issue in `airflow-s`. If there
   is the private variant of the PR in the `airflow-s/airflow-s` repository, it should be closed as well.
   The milestone of the issue should be set to milestone when it is planned to be released.
   The milestones are in the format `Airlfow-2.6.2` or `Providers-June-2023-1`
   (first June providers batch) or `Chart-1.9.0`. New milestones are created when needed.

10) During the releases, the release manager will look through closed issues in the "airflow-s"
    with the corresponding milestones, updates the [ASF CVE tool](https://cveprocess.apache.org) and
    sends the announcements when the release is published.
