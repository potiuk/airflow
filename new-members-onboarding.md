<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Welcome](#welcome)
- [How the team is composed](#how-the-team-is-composed)
- [Where things happen](#where-things-happen)
- [What are you expected to do?](#what-are-you-expected-to-do)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Welcome

Hello, new member of the Airflow security team. Here are a few helpful tips to get you started:

# How the team is composed

The Airflow security team is a group of people — mostly PMC members and committers, but
we also have security researchers and people who are not yet committers but aspire to
be, and who are already active and known in the community. We also have members of the
security teams of our stakeholders who already deal with Airflow security outside of
the community projects — for example, when they provide Airflow-as-a-Service.

The team works on a voluntary basis. We understand that people have other commitments
and lives, and we do not expect them to be available 24/7 or to take part in every
discussion. However, we do expect some level of involvement and commitment — at least
participating in discussions, providing feedback, and voting on issues when needed.

Being a member of the security team is not a permanent assignment; we rotate the team
periodically (so far we have only rotated members once, after about 8 months, but we expect
shorter rotation periods in the future). We are also open to new members joining the team
at any time — especially when PMC members wish to join.

We will likely re-evaluate the team composition and process in a few months, taking into
account the involvement of people and their willingness to continue to be part of it.

All release managers are members of the security team by default, as they are responsible
for publishing CVE (Common Vulnerabilities and Exposures) information about issues
when affected software is released with the fixes.

# Where things happen

* We have the `security@airflow.apache.org` mailing list, to which you are subscribed. For now,
  all reports raised to us from outside come to that security list. We are, however,
  discussing improving this by using the [GitHub Private Issue reporting feature](https://github.com/airflow-s/airflow-s/discussions/70).

* We handle all issues and discussions in a more "organized way" in the `airflow-s/airflow-s` project
  (this project). Everything that happens in that project is automatically forwarded to the
  security mailing list. Some discussions, when they have an obvious answer, can be handled
  without creating an issue in the `airflow-s/airflow-s` repository, but in general we
  prefer to have issues and discussions in the project.


# What are you expected to do?

There are two kinds of activities you can take part in:

* reacting to issues raised by security researchers, pen-test reporters, and so on
* proactively looking for improvements in the security of Airflow

Handling issues is described in detail in [Handling security issues](README.md). Read the
process to familiarize yourself with it, but it is probably best to observe what happens
first and then read in detail why we are doing what we are doing — it will be easier to
understand the process afterwards.

Initially, simply take part in the discussions and follow them.

You can also volunteer to provide a fix for an issue, or ask whether you can involve someone
else to provide a fix.

To proactively work on security improvements, take a look at the
[Discussions](https://github.com/airflow-s/airflow-s/discussions) we have. We occasionally
start a discussion there when we see we can improve something — process-wise or
tooling-wise. You are absolutely welcome to join the discussion and provide your input, or
even start new discussions if you see something we can improve.

Feel free also to create PRs for any part of our process:

* [Handling security issues](README.md) - this is where our process is described
* [Canned responses](canned-responses.md) - this is where we keep typical answers we send to reporters
* [New members onboarding](new-members-onboarding.md) - this document

**That's about it. Welcome to the team!**
