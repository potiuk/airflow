<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Apache Airflow — CVE title normalisation](#apache-airflow--cve-title-normalisation)
  - [Strip cascade](#strip-cascade)
  - [Implementation recipe](#implementation-recipe)
  - [Sanity check](#sanity-check)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- SPDX-License-Identifier: Apache-2.0
     https://www.apache.org/licenses/LICENSE-2.0 -->

# Apache Airflow — CVE title normalisation

The CVE record's `title` field is scoped to the product by the CNA
container (`Apache Airflow`, `Apache Airflow Elasticsearch Provider`,
etc.), so the Vulnogram title should be the **bare description** —
no `Apache Airflow:` prefix, no redundant version suffix, no
reporter-added tag like `[ Security Report ]` or `Security Issue`.

The [`allocate-cve`](../../.claude/skills/allocate-cve/SKILL.md) skill
reads this file for the exact strip cascade to apply to the tracker
title before pasting it into the Vulnogram allocation form.

The cascade is written against the shape of titles that Airflow
reporters tend to use. Other projects using this framework will have
a different cascade; they would replace this file with their own rules
(or simply drop this file if their titles are already normalised).

## Strip cascade

Apply the following patterns to the issue title, in order:

1. **Leading bracketed tags** — `^[ \t]*\[ ?Security (Report|Issue|Vulnerability|Bug) ?\][ \t:|\-–—]*`
2. **Leading plain tags** — `^[ \t]*Security (Report|Issue|Vulnerability|Bug)[ \t:|\-–—]+`
3. **Leading `Apache Airflow` (optional version, optional separator)** —
   `^[ \t]*Apache[ \t]+Airflow(?:[ \t]+v?\d+(?:\.\d+)*(?:\.x)?)?[ \t]*[:|\-–—]?[ \t]*`
4. **Leading `Airflow` (optional version, optional separator)** —
   `^[ \t]*Airflow(?:[ \t]+v?\d+(?:\.\d+)*(?:\.x)?)?[ \t]*[:|\-–—][ \t]*`
   (note: the separator is required here — *without* a separator
   `Airflow` is usually meaningful, e.g. "Airflow security model…")
5. **Re-apply 1 and 2** — after stripping a version prefix the title
   often reveals a nested `Security Issue |` tag, so run the
   bracketed- and plain-tag passes a second time.
6. **Trailing `in (Apache )?Airflow`** — `[ \t]+in[ \t]+(?:Apache[ \t]+)?Airflow[ \t]*\.?$`
7. **Trailing bare version parens** —
   `[ \t]*\((?:Apache[ \t]+)?Airflow(?:[ \t]+v?\d+(?:\.\d+)*(?:\.x)?)?\)\.?[ \t]*$`
8. **Trailing GHSA ID paren** — `[ \t]*\(GHSA-[\w-]+\)\.?[ \t]*$`
9. **Trailing "split from #NNN" paren** (a note the sync skill adds
   on scope-split trackers — never belongs in a CVE title) —
   `[ \t]*\([^)]*split from #\d+[^)]*\)\.?[ \t]*$`
10. **Trailing trivia** — strip trailing whitespace, trailing `.`,
    and collapse internal runs of whitespace.
11. **Capitalize** — upper-case the first letter; leave the rest
    alone (acronyms like `JWT`, `OAuth`, `DAG`, `RBAC` are load-
    bearing in these titles).

## Implementation recipe

Keep the transform inline in the skill, do not create a separate
Python project for this one-shot transform:

```bash
python3 - <<'PY'
import re, subprocess

t = subprocess.check_output(
    ["gh", "issue", "view", "<N>", "--repo", "airflow-s/airflow-s",
     "--json", "title", "--jq", ".title"],
    text=True,
).strip()

patterns_leading = [
    r"^[ \t]*\[ ?Security (?:Report|Issue|Vulnerability|Bug) ?\][ \t:|\-–—]*",
    r"^[ \t]*Security (?:Report|Issue|Vulnerability|Bug)[ \t:|\-–—]+",
    r"^[ \t]*Apache[ \t]+Airflow(?:[ \t]+v?\d+(?:\.\d+)*(?:\.x)?)?[ \t]*[:|\-–—]?[ \t]*",
    r"^[ \t]*Airflow(?:[ \t]+v?\d+(?:\.\d+)*(?:\.x)?)?[ \t]*[:|\-–—][ \t]*",
]
patterns_trailing = [
    r"[ \t]+in[ \t]+(?:Apache[ \t]+)?Airflow[ \t]*\.?$",
    r"[ \t]*\((?:Apache[ \t]+)?Airflow(?:[ \t]+v?\d+(?:\.\d+)*(?:\.x)?)?\)\.?[ \t]*$",
    r"[ \t]*\(GHSA-[\w-]+\)\.?[ \t]*$",
    r"[ \t]*\([^)]*split from #\d+[^)]*\)\.?[ \t]*$",
]

# Leading passes twice — strip order reveals nested tags.
for _ in range(2):
    for p in patterns_leading:
        t = re.sub(p, "", t, flags=re.IGNORECASE)
# Trailing passes until idempotent.
prev = None
while prev != t:
    prev = t
    for p in patterns_trailing:
        t = re.sub(p, "", t, flags=re.IGNORECASE)

t = re.sub(r"\s+", " ", t).strip().rstrip(".")
if t:
    t = t[0].upper() + t[1:]
print(t)
PY
```

## Sanity check

Show the stripped title and the original title side by side in the
proposal so the user can spot any over-stripping before pasting into
Vulnogram. If the strip collapses the title to fewer than 3 words,
surface that as a warning and propose a manual override — over-
stripping is worse than leaving one redundant word in.
