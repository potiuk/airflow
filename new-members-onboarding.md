<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Welcome](#welcome)
- [How the team is composed](#how-the-team-is-composed)
- [Where things happen](#where-things-happen)
- [Your first week](#your-first-week)
- [Picking up a role](#picking-up-a-role)
- [Using the agent skills](#using-the-agent-skills)
- [Proactive work and process improvements](#proactive-work-and-process-improvements)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Welcome

Hello, new member of the Airflow security team. This document is the
soft-landing guide — it tells you how the team works, where the action
happens, and what is expected of you in the first few weeks.

Read this end-to-end once, then use [`README.md`](README.md) as the
operational reference when you start actually handling issues. The
README is organised by role (triager / remediation developer / release
manager); pick the role that matches what you are about to do and jump
into its section.

# How the team is composed

The Airflow security team is a group of people — mostly PMC members and
committers, but we also have security researchers and people who are not
yet committers but aspire to be, and who are already active and known in
the community. We also have members of the security teams of our
stakeholders who already deal with Airflow security outside of the
community projects — for example, when they provide Airflow-as-a-Service.

The team works on a voluntary basis. We understand that people have
other commitments and lives, and we do not expect them to be available
24/7 or to take part in every discussion. However, we do expect some
level of involvement and commitment — at least participating in
discussions, providing feedback, and voting on issues when needed.

Being a member of the security team is not a permanent assignment; we
rotate the team periodically (so far we have only rotated members once,
after about 8 months, but we expect shorter rotation periods in the
future). We are also open to new members joining the team at any
time — especially when PMC members wish to join.

We will likely re-evaluate the team composition and process in a few
months, taking into account the involvement of people and their
willingness to continue to be part of it.

All release managers are members of the security team by default, as
they are responsible for publishing CVE (Common Vulnerabilities and
Exposures) information about issues when affected software is released
with the fixes.

The authoritative source for who is currently on the team is the
collaborator list of `airflow-s/airflow-s` (everyone listed, regardless
of permission level). See
[`AGENTS.md` — Security team roster](AGENTS.md#security-team-roster) for
the lookup command.

# Where things happen

- **`security@airflow.apache.org` mailing list** — you are subscribed
  automatically. This is where external reporters land their reports,
  and where we reply to keep them informed. We are discussing moving
  inbound reporting to the
  [GitHub Private Issue reporting feature](https://github.com/airflow-s/airflow-s/discussions/70),
  but today `security@` is the primary channel.
- **`airflow-s/airflow-s` GitHub repository** (this one) — the private
  tracker. Every valid report becomes a tracking issue here. Everything
  that happens on an issue is automatically mirrored to the security
  mailing list so people who prefer email stay in the loop.
- **Security-issues board** —
  <https://github.com/orgs/airflow-s/projects/2>. This is the dashboard
  view: issues grouped by state, by scope, by owner. If you want one
  URL to bookmark, bookmark this one.
- **Private PRs on `airflow-s/airflow-s` `main` branch** — an
  exceptional path used for highly-critical fixes that need private
  code review before going public. See
  [Step 9](README.md#step-9--open-a-private-pr-exceptional-cases) of
  the process.

Some discussions with an obvious answer can be handled on the mailing
list without creating a tracker, but in general we prefer having issues
and discussions in the repository so they are searchable and
discoverable for everyone else on the team.

# Your first week

Take the pressure off. You do not have to drive any issue in your first
week. A good starting routine:

1. **Read [`README.md`](README.md) once, skim the role sections.** Pick
   the role you think you are most likely to take on first, and read it
   in full.
2. **Open the board** at
   <https://github.com/orgs/airflow-s/projects/2>. Get a feel for what
   states issues sit in and how they flow across columns.
3. **Subscribe to a few open issues** and read along. The mailing-list
   mirror means you will see new activity in your inbox. Seeing a few
   issues move from `needs triage` to `cve allocated` and onwards is
   the fastest way to internalise the process.
4. **Read [`canned-responses.md`](canned-responses.md).** These are the
   reply templates we send to reporters. They shape most of the tone
   you will eventually need to match when you draft a reply yourself.
5. **Read [`AGENTS.md`](AGENTS.md) at least the
   [Confidentiality](AGENTS.md#confidentiality-of-airflow-sairflow-s)
   section.** The rule of thumb: nothing about
   `airflow-s/airflow-s` — issue numbers, labels, discussions, even the
   repo name — leaves the private channels.

You can start commenting on issues on day one. Just commenting,
voting on validity, suggesting severity — those are valuable
contributions and do not require you to pick up a role.

# Picking up a role

Once you have observed the process for a while, you can start taking
on more of the work. Three roles rotate across the team (see
[`README.md` — Who this guide is for](README.md#who-this-guide-is-for)
for the overview):

- **Issue triager** (Steps 1–6 of the process) — imports new reports
  from `security@`, drives validity assessment in comments, and
  allocates CVEs. A good starter role once you are comfortable with
  the tone and the canned responses.
- **Remediation developer** (Steps 7–11) — picks up a triaged tracker
  with a CVE allocated and opens a fix PR in `apache/airflow`. Suits
  team members who are already regular Airflow contributors.
- **Release manager** (Steps 12–15) — for release managers of Airflow
  core, Providers, and the Helm Chart. You inherit this role
  automatically when you cut a release that contains a security fix;
  `sync-security-issue` hands the tracker to you with `fix released`.

You can volunteer to provide a fix for a specific issue even before
formally taking on the remediation-developer role — just comment on
the tracker and self-assign. You can also ask whether it makes sense
to involve someone else to provide the fix (see
[Step 7](README.md#step-7--self-assign-and-implement-the-fix) for the
delegation rules).

# Using the agent skills

A lot of the repetitive work on this team has been automated into
agent skills that live under
[`.claude/skills/`](.claude/skills/). They are plain `SKILL.md`
files with YAML frontmatter, so Claude Code picks them up
automatically and other agents that follow the emerging skill
convention can use them too.

You do **not** need an agent to participate on the team. For commenting
and discussing on the board, a browser is enough.

If you do use an agent, the three commands a rotational triager runs
a few times a week are:

- **`import new reports`** — converts un-imported `security@` threads
  into trackers and drafts the receipt-of-confirmation reply. See
  [Step 2](README.md#step-2--import-the-report).
- **`sync all issues`** — reconciles every open tracker with its mail
  thread, its fix PR, the release train, and the users@ archive.
- **`allocate CVE for issue #N`** — when a report is assessed as valid.
  See [Step 6](README.md#step-6--allocate-the-cve).

There is also a fourth command for anyone willing to take on a
remediation-developer turn:

- **`try to fix issue #N`** —
  [`fix-security-issue`](.claude/skills/fix-security-issue/SKILL.md)
  attempts to land the fix for a triaged tracker in one go. It runs a
  pre-fix sync, reads the discussion on the tracker to build a fix
  plan, shows you the plan, and — only after you confirm — writes the
  change in your local `apache/airflow` clone, runs the local checks
  and tests, and opens a public `gh pr create --web` PR from your fork.
  Every public surface (commit message, branch name, PR title, PR
  body, newsfragment) is scrubbed for CVE / `airflow-s` /
  `vulnerability` / `security fix` leakage before being written or
  pushed. The skill refuses to operate on reports that are still being
  assessed, or on issues that need the private-PR fallback of
  [Step 9](README.md#step-9--open-a-private-pr-exceptional-cases). See
  [For remediation developers — Steps 7–11](README.md#for-remediation-developers--steps-711)
  for the full expectations around a fix PR.

Every skill is a **proposal engine**, not an auto-pilot — it reads the
world, proposes changes, and waits for your explicit confirmation
before applying anything. This is deliberate: you stay in the loop
for every label change, every body edit, every email draft, and
every line of code the fix skill writes.

The full list of skills, and what each one does, is in
[`AGENTS.md` — Reusable skills](AGENTS.md#reusable-skills).

# Proactive work and process improvements

Beyond reacting to inbound reports, you are also welcome to
proactively look for security improvements in Airflow. Take a look at
the [Discussions](https://github.com/airflow-s/airflow-s/discussions)
tab — we occasionally start a discussion there when we see we can
improve something, process-wise or tooling-wise. Join those
discussions, share your perspective, or start new ones if you see
something worth fixing.

PRs against any part of our process are welcome. The documents that
shape the team are small enough to read in one sitting:

- [`README.md`](README.md) — the end-to-end handling process.
- [`canned-responses.md`](canned-responses.md) — reply templates.
- [`AGENTS.md`](AGENTS.md) — agent-facing conventions, confidentiality
  rules, current release-manager roster.
- [`how-to-fix-a-security-issue.md`](how-to-fix-a-security-issue.md) —
  high-level fix workflow.
- [`new-members-onboarding.md`](new-members-onboarding.md) — this
  document.

**That's about it. Welcome to the team!**
