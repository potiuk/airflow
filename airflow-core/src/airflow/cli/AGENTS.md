<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# CLI — Agent Instructions

## Runtime verification

These steps run against the instance started by the
[runtime verification skill](../../../../.agents/skills/airflow-runtime-verification/SKILL.md),
up and healthy. `verify-<run>` is its compose project, `<web>` its port.

Run a CLI command in its container:

```bash
breeze exec --project-name verify-<run> -- -c "AIRFLOW__CORE__LOAD_EXAMPLES=False airflow ..."
```

`breeze exec` runs what follows `--` with `bash` in the running container of that project, with
the Breeze environment and the Dags folder set up, and exits with the exit code of the command.
Breeze prints its own checks first; the output of the command comes last. The CLI process reads its
own configuration, so the command repeats `AIRFLOW__CORE__LOAD_EXAMPLES=False`.

Use `-o plain` where the command supports it, so the output is easy to compare. For a change to a
command that reads or writes state, read the result back from a second surface: the REST API
(`curl http://localhost:<web>/api/v2/...`) or the UI.
