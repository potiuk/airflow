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
`projects/<active_project>/<file>.md`, for example
`projects/airflow/canned-responses.md`.

## Adding a new project

To onboard a new ASF project (or any other project reusing this
framework):

1. Create a sibling directory under `projects/`, e.g.
   `projects/<name>/`.
2. Populate it with, at a minimum, a `project.md` manifest following
   the same shape as [`projects/airflow/project.md`](../projects/airflow/project.md).
3. Add the per-project files the skills reference — the manifest
   lists the expected filenames.
4. Update `active_project:` above when the new project is the one the
   current working tree targets.

If a project does not use one of the optional tools (e.g. it uses
JIRA instead of GitHub issues), that preference is declared in its
`project.md` manifest; the skills branch on it rather than on this
file.
