<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Active project](#active-project)
  - [Adding a new project](#adding-a-new-project)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# Active project

This file declares which project under [`projects/`](../projects/) the
skills, agents, and tools in this repository are currently configured
for. It is the **single source of truth** every skill reads to decide
which project-specific files (canned responses, release trains,
security model anchors, scope labels, milestone conventions, title-
normalisation rules, fix-workflow specifics, …) to load.

```yaml
active_project: airflow
```

The value above is the directory name under `projects/`. The skills
resolve project-scoped references by concatenating
`projects/<active_project>/<file>.md` — for this tree
(`active_project: airflow`), that means
`projects/airflow/canned-responses.md` and siblings. For the full
index of files in the active project's directory, see that project's
`README.md` (for Airflow:
[`projects/airflow/README.md`](../projects/airflow/README.md)).

## Adding a new project

To onboard a new ASF project (or any other project reusing this
framework), use the skeleton at
[`../projects/_template/`](../projects/_template/):

```bash
# From the repo root:
cp -R projects/_template projects/<name>
$EDITOR projects/<name>/project.md              # fill in identity, repos, lists, tools, CVE tooling
# then walk through the rest of the files — each one has a grep-friendly TODO list.
grep -rn TODO projects/<name>                    # see what still needs filling in
```

Once the skeleton is filled in:

1. Update `active_project:` above to the new directory name (if this
   working tree should target the new project).
2. Validate with a prek run; the skills pick up the change on the
   next invocation.

The full bootstrap walk-through (with a "Current projects" table and
tips for swapping tools per project) lives in
[`../projects/README.md`](../projects/README.md).

If a project does not use one of the optional tools (e.g. it uses
JIRA instead of GitHub issues), that preference is declared in its
`project.md` manifest; the skills branch on it rather than on this
file.
