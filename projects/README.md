<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Projects](#projects)
  - [Current projects](#current-projects)
  - [Bootstrapping a new project](#bootstrapping-a-new-project)
  - [Replacing tools per project](#replacing-tools-per-project)
  - [What lives in each project directory](#what-lives-in-each-project-directory)
  - [Cross-references](#cross-references)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# Projects

One directory per project that reuses this framework. The currently
active project is declared in
[`../config/active-project.md`](../config/active-project.md)
(`active_project: <dir-name>`). Every skill resolves project-scoped
references by loading
`projects/<active_project>/project.md` and its sibling files — so the
directory name here doubles as the resolution key for the `<PROJECT>`
placeholder used throughout the framework.

## Current projects

| Project | Directory | Index | Manifest |
|---|---|---|---|
| [Apache Airflow](https://airflow.apache.org/) | [`airflow/`](airflow/) | [`airflow/README.md`](airflow/README.md) | [`airflow/project.md`](airflow/project.md) |

Template / bootstrap skeleton (not a project):

| Role | Directory | Use for |
|---|---|---|
| **Skeleton** | [`_template/`](_template/) | Copy into `projects/<new-name>/` when onboarding a new project. Every file is TODO-filled. |

## Bootstrapping a new project

```bash
# From the repo root:
cp -R projects/_template projects/<name>
$EDITOR projects/<name>/project.md          # start with the manifest
grep -rn TODO projects/<name>                # punch-list for the rest
```

Walk-through:

1. **Copy the template.** `cp -R projects/_template projects/<name>`.
   The `_template` directory mirrors the shape of
   [`airflow/`](airflow/); refer to the Airflow files as a worked
   example whenever a TODO leaves you unsure what to fill in.
2. **Fill in [`project.md`](_template/project.md) first.** This is
   the manifest every skill reads. Identity + repositories + mailing
   lists + tools enabled + CVE tooling are the load-bearing
   sections; the rest (GitHub project board, Gmail / PonyMail, issue
   template fields) can be filled in as the corresponding tool is
   set up.
3. **Work through the remaining files.** Each one has a grep-friendly
   TODO list:
   - [`release-trains.md`](_template/release-trains.md) — at least
     one release branch + its RM.
   - [`scope-labels.md`](_template/scope-labels.md) — exactly-one-of
     scope label set.
   - [`security-model.md`](_template/security-model.md) — URL + at
     least a few anchors.
   - [`canned-responses.md`](_template/canned-responses.md) — the
     *Confirmation of receiving the report* template at minimum
     (the `import-security-issue` skill sends it verbatim).
   - [`milestones.md`](_template/milestones.md),
     [`title-normalization.md`](_template/title-normalization.md),
     [`fix-workflow.md`](_template/fix-workflow.md),
     [`naming-conventions.md`](_template/naming-conventions.md) —
     fill in as the team encounters the relevant situations.
4. **Rewrite this directory's `README.md`** (the copy of
   [`_template/README.md`](_template/README.md)) into your project's
   file index. Delete the sections your project does not use.
5. **Add a row to the *Current projects* table above.**
6. **Add a row to the *Current projects* table in the root
   [`../README.md`](../README.md).**
7. **Switch the active project** (if this working tree should target
   the new project) by editing
   [`../config/active-project.md`](../config/active-project.md)
   → `active_project: <name>`.
8. **Validate.** `prek run --all-files` should pass. Run a cheap
   skill (e.g. *"sync all"*) and confirm Step 0 picks up the new
   project's values without prompts.

## Replacing tools per project

The active project's *Tools enabled* table declares which tool
adapter the skills load for each capability:

- **Issue tracker**: today only [`../tools/github/`](../tools/github/)
  is implemented. Swapping for JIRA or another backend means
  creating a sibling `../tools/<name>/` directory with the same
  files (`tool.md`, `operations.md`, `issue-template.md`,
  `labels.md`, `project-board.md`) and updating
  `<project>/project.md → Tools enabled`.
- **Inbound email**: [`../tools/gmail/`](../tools/gmail/) today;
  [`ponymail-mcp`](https://github.com/rbowen/ponymail-mcp) is the
  planned migration target for ASF projects, at which point a
  `tools/ponymail-mcp/` adapter replaces `tools/gmail/` in the
  manifest.
- **CVE tool**: [`../tools/vulnogram/`](../tools/vulnogram/) today
  (ASF Vulnogram). A private Vulnogram instance, an in-house CNA
  system, or a commercial CVE management platform would each land
  as `tools/<name>/` with equivalent `tool.md` / `allocation.md` /
  `record.md` / CVE-JSON generator.

The skills' behaviour does not change when tools swap — they invoke
whichever adapter the project manifest names for each capability.

## What lives in each project directory

See [`_template/README.md`](_template/README.md) for the canonical
file list and per-file purpose; copy-rename that file when you
bootstrap a new project to give your directory its own index.

## Cross-references

- [`../config/README.md`](../config/README.md) — the two-layer
  configuration model (project + user) and per-user config tutorial.
- [`../config/active-project.md`](../config/active-project.md) — the
  one-value selector that picks which project directory this working
  tree targets.
- [`../AGENTS.md`](../AGENTS.md) — agent conventions, including the
  `<PROJECT>` / `<tracker>` / `<upstream>` placeholder convention
  used throughout skill files.
- [`../README.md`](../README.md) — the end-to-end
  security-issue-handling lifecycle (16 steps + role sections),
  project-agnostic.
