<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# Core API — Agent Instructions

## Runtime verification

A change to the public REST API is seen by API clients. The proof is the HTTP exchange: the request,
the response body and the status code.

These steps run against the instance started by the
[runtime verification skill](../../../../../.agents/skills/airflow-runtime-verification/SKILL.md),
up and healthy. `<web>` is its port. Most checks need data first: create it with the
[Dag run recipe](../../../../../task-sdk/AGENTS.md#runtime-verification).

Save the status code with the body, for example:

```bash
curl -s -w '\nhttp_status=%{http_code}\n' http://localhost:<web>/api/v2/dags \
  | tee -a files/verify/<run>/api.log
```

- **Error paths.** `GET /api/v2/dags/no_such_dag` returns `404` with a `detail` string. A body that
  fails validation returns `422`, and `detail[].loc` names the field.
- **A change and its read-back.** `PATCH /api/v2/dags/<dag_id>` with `{"is_paused": true}`, then
  `GET /api/v2/dags/<dag_id>`, then the same fact from the CLI with `airflow dags list -o plain`.
- **Routes of the UI.** The React application calls `/ui/...` routes, for example
  `/ui/dags?limit=5`. They are private and change freely. When a change claims an effect on the
  API, prove it on a public `/api/v2` route.

The running instance serves its API reference at `http://localhost:<web>/docs` and the OpenAPI
document at `http://localhost:<web>/openapi.json`.
