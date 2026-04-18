<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Configuration](#configuration)
  - [Quick start (new team members)](#quick-start-new-team-members)
  - [What the project layer does](#what-the-project-layer-does)
  - [What the user layer does](#what-the-user-layer-does)
  - [How skills consume these layers](#how-skills-consume-these-layers)
  - [Tutorial — setting up your configuration end-to-end](#tutorial--setting-up-your-configuration-end-to-end)
    - [0. Prerequisites](#0-prerequisites)
    - [1. Confirm the active project](#1-confirm-the-active-project)
    - [2. Create your user config](#2-create-your-user-config)
    - [3. Verify](#3-verify)
    - [4. Run a skill](#4-run-a-skill)
    - [5. Update as needed](#5-update-as-needed)
  - [When to use memory instead](#when-to-use-memory-instead)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# Configuration

This directory declares **how this working tree is configured**. Two
layers, each with a different scope:

| Layer | File | Scope | Tracked? |
|---|---|---|---|
| Project | [`active-project.md`](active-project.md) | Which project under [`../projects/`](../projects/) this tree targets, and therefore which tools / lists / rosters apply | Yes (checked in) |
| User | [`user.md`](user.md) (each user's local copy of [`user.md.example`](user.md.example)) | This user's personal identity, tool preferences, PMC status, and local environment paths | No — **gitignored** |

The generic skills read both layers on every invocation. The project
layer tells them *"which flavour of security process is this?"*; the
user layer tells them *"how is **this human** set up to run it?"*.

## Quick start (new team members)

```bash
# 1. Copy the template and fill in your details.
cp config/user.md.example config/user.md
$EDITOR config/user.md

# 2. (Usually already set on clone) confirm the active project.
cat config/active-project.md       # should show `active_project: airflow`
```

That is the whole setup. Your `config/user.md` stays on your machine
(it is in `.gitignore`); you can commit to `airflow-s` without leaking
it.

## What the project layer does

`active-project.md` declares one value: the directory name under
`../projects/` whose manifest the skills should load. For the
Airflow tracker this is `airflow`, and the skills then load
[`../projects/airflow/project.md`](../projects/airflow/project.md) to
learn the project's identity, repositories, mailing lists, CVE
tooling, scope labels, milestone conventions, and the list of sibling
project-specific files (canned responses, release trains, security
model, …).

Adding a new project = create `projects/<name>/project.md` and a
sibling file set (the index at the bottom of the Airflow manifest is
the template) + flip `active_project:` above. See
[`active-project.md`](active-project.md) for the full explainer.

## What the user layer does

`user.md` is each triager's personal configuration. It captures:

1. **Your identity** — GitHub handle + email. Skills use these to
   recognise your own drafts / comments (so they do not, for
   example, propose replying to yourself), and to render `@`-mentions
   when a skill wants to credit you on a tracker comment.
2. **Role flags** — whether you are a PMC member of the active
   project. This affects the `allocate-cve` skill: PMC members get
   the self-service allocation recipe, non-PMC users get a relay
   recipe they forward to a PMC member.
3. **Tool preferences** — for each capability the active project
   declares (see the *Tools enabled* table in the project manifest),
   which implementation **you** have set up locally. Most
   capabilities have only one implementation today (GitHub for
   issue tracking, Vulnogram for the CVE tool), but inbound-email
   access will gain alternatives over time (Gmail MCP today,
   [`ponymail-mcp`](https://github.com/rbowen/ponymail-mcp) with
   ASF OAuth when it lands).
4. **Environment paths** — where your local `apache/airflow` clone
   lives, which `fix-security-issue` needs in order to write code
   changes locally.
5. **Free-form notes** — anything else an agent should remember
   about how you work (preferred editor, which keyboard shortcuts
   you bind, which skills you use most, …).

The template [`user.md.example`](user.md.example) walks through every
knob. Fields you leave at the default are treated as *"ask at runtime
like before"*; fields you fill in let the skills skip the corresponding
prompt.

## How skills consume these layers

When a skill starts, its Step 0 pre-flight reads both
`active-project.md` (to pick the project manifest) and `user.md` (to
pick up per-user preferences). If `config/user.md` does not exist, the
skill falls back to runtime prompts for every knob; nothing is broken,
it just asks more questions. Creating `config/user.md` is strictly an
opt-in convenience.

Concretely:

- `allocate-cve` Step 0 reads `role_flags.pmc_member`. If set, it
  skips the *"are you a PMC member?"* prompt and picks the
  self-service or relay recipe automatically.
- `fix-security-issue` Step 3 reads
  `environment.apache_airflow_clone`. If set and the path exists, it
  skips the clone auto-detection prompt.
- Every skill reads `identity.github_handle` to recognise your own
  activity on the tracker and your own Gmail drafts.

Future skills (and future tool adapters) will add more reads. The
template file will grow alongside them; existing `user.md` files stay
compatible — unrecognised keys are ignored, missing keys fall back to
"ask".

## Tutorial — setting up your configuration end-to-end

### 0. Prerequisites

Already covered by the first-week routine in
[`../new-members-onboarding.md`](../new-members-onboarding.md#your-first-week).
You should have:

- a clone of `airflow-s/airflow-s` (this repo),
- `gh auth login` done,
- Gmail MCP connected to your account (or another inbound-email tool —
  see the project's *Tools enabled* for accepted alternatives).

### 1. Confirm the active project

This should already be correct in a fresh clone — but check once:

```bash
cat config/active-project.md
```

Look for `active_project: airflow`. If you are running this framework
against a different project (unlikely in the `airflow-s` clone), edit
that value; otherwise leave it alone.

### 2. Create your user config

```bash
cp config/user.md.example config/user.md
```

Open `config/user.md` and fill in:

- `github_handle` — your GitHub handle (e.g. `potiuk`, `jscheffl`).
- `email` — the email address you send `security@` replies from.
- `pmc_member` — `true` if you are on the active project's PMC,
  otherwise `false`. (If unsure, check the ASF project page — for
  Airflow, <https://projects.apache.org/committee.html?airflow>.)
- `tools` → leave defaults unless you have explicitly configured an
  alternative (e.g. `ponymail-mcp` when that lands).
- `environment.apache_airflow_clone` — absolute path to your local
  `apache/airflow` clone, or leave empty to keep auto-detection.
- Notes — anything else worth remembering.

### 3. Verify

From the repo root:

```bash
# Your file exists and is gitignored:
ls -l config/user.md
git check-ignore -v config/user.md       # must print a match line

# You did not accidentally stage it:
git status | grep config/user.md          # must be empty
```

### 4. Run a skill

Any skill invocation now picks up your user config automatically. The
skill's Step 0 pre-flight prints a one-line *"loaded config for
`<handle>` (PMC: yes/no)"* line so you can confirm it found you.

### 5. Update as needed

Edit `config/user.md` whenever:

- you join / leave the PMC,
- you move your local `apache/airflow` clone,
- a new capability gets listed in
  [`../projects/airflow/project.md`](../projects/airflow/project.md#tools-enabled)
  and you want to pick a non-default implementation for yourself.

There is no versioning concern — the file is local; you edit it and
re-run whatever skill was asking.

## When to use memory instead

Agent-level memory (e.g. Claude Code's `memory/` system) is the right
place for preferences that are **global across your agent's entire
life**, not specific to this repo. `config/user.md` is the right place
for preferences that only make sense in the context of this
framework's skills (tool picks, PMC status, the apache/airflow clone
path).

A rule of thumb: if the preference answers *"how do you run
`airflow-s`'s skills?"*, it belongs in `config/user.md`. If it
answers *"how do you like to work in general?"*, it belongs in agent
memory.
