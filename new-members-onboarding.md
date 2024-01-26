<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Welcome](#welcome)
- [How the team is composed ?](#how-the-team-is-composed-)
- [Where things happen ?](#where-things-happen-)
- [What are you expected to do?](#what-are-you-expected-to-do)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Welcome

Hello, new Member of the security team of Airflow. Here are a few helpful tips to get you started:

# How the team is composed ?

The security team of Airflow is a group of people - mostly PMC members and committers, but
we also have security researchers and people who are not yet committers but aspire to
be ones and are already active and known to the community, also we have members of the
security teams of our Stakeholders who already deal with Airflow security outside of
the community projects - for example when they provide Airflow-As-A-Service.

The team works on a voluntary base, we understand that people have other commitments
and life and we do not expect them to be available 24/7 nor take part in all the
discussions, however we do expect some level of involvement and commitment to at least
participation in the discussions, providing feedback and voting on the issues if needed.

Being a member of security team is not a permanent assignment, we are rotating the team
periodically (so far we've only rotated members once after about 8 months but we expect
shorter rotation periods in the future). We are also open to new members joining the team
at any time - especially when PMC members wish to join the team.

We will likely re-evaluate the team composition and process in a few months taking into
account the involvement of people and their willingness to continue to be part of it.

All release managers are by default members of the security team as they are responsible
for publishing CVE (Common Vulnerabilities and Exposures) information about the issues
when affected software gets release where the issues are fixed.

# Where things happen ?

* we have security@airflow.apache.org mailing list to which you are subscribed. For now
  all the reports raised to us from outside come to that security list, we are however
  discussing to improve it using [Github Private Issue reporting feature](https://github.com/airflow-s/airflow-s/discussions/70)

* we handle all issues and discussions in a more "organized way" in the `airflow-s/airflow-s` (this
  project). Everything that happens in that project is automatically forwarded to the
  security mailing list. Some discussions when they have obvious answer can be handled
  without creating an issue in the `airflow-s/airflow-s` repository, but in general we
  prefer to have issues/discussions in the project.


# What are you expected to do?

There are two kinds of activities you can take part in:

* reacting to issues raised by the security researchers/reporters of pen tests etc.
* proactively looking for improvements in the security of Airflow

Handling issues is described in detail in [Handling security issues](README.md). Read the
process to familiarize yourself with it, but probably best is to observe what happens and
then read in detail why we are doing what we are doing, it will be easier to understand
the process then.

Initially - simply take part in the discussions and follow them.

You can also volunteer to provide a fix for an issue, or ask if you can involve someone
else to provide a fix.

For proactively working on security improvements, you can look at the
[Discussions](https://github.com/airflow-s/airflow-s/discussions) we have - we occasionally
start a discussion there, when we see we can improve something - process wise, or
tools wise - you are absolutely welcome to join the discussion and provide your input or
even start new discussions if you see we can improve something.

Feel free also to create PR-s to any part of our process:

* [Handling security issues](README.md) - this is where our process is described
* [Canned responses](canned-responses.md) - this is where we keep typical answers we send to reporters
* [New members onboarding](new-members-onboarding.md) - this document

**That's about it. Welcome to the team!**
