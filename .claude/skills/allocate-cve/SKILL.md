---
name: allocate-cve
description: |
  Walk a security team member through allocating a CVE for an
  <tracker> tracking issue. Prints the ASF Vulnogram
  allocation URL and a CVE-ready title (the issue title stripped of
  redundant `Apache Airflow:`, `[ Security Report ]`, trailing
  version parens and similar noise), waits for the allocated CVE ID
  (allocation is PMC-gated — non-PMC triagers relay to a PMC
  member), and then updates the tracker in place: fills in the
  *CVE tool link* field, adds the `cve allocated` label, posts a
  collapsed status-change comment, and runs `generate-cve-json
  --attach` to embed the paste-ready JSON in the body. Finishes by
  handing off to the `sync-security-issue` skill to reconcile the
  rest of the tracker (milestone, assignee, reporter drafts, fix-PR
  state) now that the CVE landing is complete.
when_to_use: |
  Invoke when a security team member says "allocate a CVE for NNN",
  "open the ASF CVE tool for NNN", "time to allocate NNN" — typically
  after the tracker has been assessed and the team has agreed the
  report is valid (process step 6). Not appropriate before the
  valid/invalid decision has been landed, nor for trackers that
  already carry a CVE ID in their *CVE tool link* body field.
---

<!-- Placeholder convention (see AGENTS.md#placeholder-convention-used-in-skill-files):
     <PROJECT>  → value of `active_project:` in config/active-project.md
                 (for this tree: airflow)
     <tracker>  → value of `tracker_repo:` in projects/<PROJECT>/project.md
                 (for this tree: airflow-s/airflow-s)
     <upstream> → value of `upstream_repo:` in projects/<PROJECT>/project.md
                 (for this tree: apache/airflow)
     Before running any bash command below, substitute these with the
     active-project values read from config/ + projects/<PROJECT>/project.md. -->

# allocate-cve

Walks a security team member through the CVE-allocation step of the
[handling process](../../../README.md) for a given
[`<tracker>`](https://github.com/<tracker>)
tracking issue. The work itself — filling in the Vulnogram allocation
form at `https://cveprocess.apache.org/allocatecve` — is a **human
step**; this skill prepares the clickable link + the exact title to
paste into the form, and captures the allocated CVE back into the
tracker in one coordinated pass so no step is forgotten.

**Golden rule — propose before applying.** Every write to the
tracker (label add, body-field update, status-change comment,
CVE-JSON regeneration) is a *proposal* the user must explicitly
confirm. The only action the skill performs unilaterally is
**reading** the tracker state and printing the allocation recipe for
the user to click through.

**Golden rule — only Apache Airflow PMC members can allocate CVEs.**
The ASF Vulnogram form at `https://cveprocess.apache.org/allocatecve`
requires ASF OAuth with PMC-level access on the Airflow project. The
full allocation mechanics (form-fill recipe, PMC-gated access, form
fields, fatal mis-allocation, after-allocation wire-back) live in
[`tools/vulnogram/allocation.md`](../../../tools/vulnogram/allocation.md);
the per-project URL templates live in
[`projects/<PROJECT>/project.md`](../../../projects/<PROJECT>/project.md#cve-tooling).
This is not something the skill can work around — a non-PMC user who
clicks *Allocate* sees the button grey out.

The current Airflow PMC roster lives on the ASF project page:
<https://projects.apache.org/committee.html?airflow>. Authoritative
GitHub handles for the subset of PMC members who also sit on the
security team are listed in
[`projects/<PROJECT>/release-trains.md`](../../../projects/<PROJECT>/release-trains.md)
(release-manager rosters + security-team roster) — use those as the
authoritative source when a non-PMC triager needs to ping a PMC
member to do the actual click-through.

If the user running this skill is **not** a PMC member, Step 3 will
produce a clickable URL + a CVE-ready title that the user forwards
to a PMC member (in the issue comments with an ``@``-mention, on
`security@airflow.apache.org`, or over any other channel the team
uses). Once the PMC member allocates and reports the allocated
`CVE-YYYY-NNNNN` back, the non-PMC user can re-invoke the skill with
the CVE ID as an override to resume from Step 4 — so the wiring-back
of the allocated ID does not need to be done by the PMC member.

**Golden rule — every `<tracker>` reference is a clickable
link**, per Golden rule 2 in
[`sync-security-issue`](../sync-security-issue/SKILL.md). The
allocation recipe, the post-allocation proposal, and the status-
change comment must all follow the link-form convention from
[`AGENTS.md`](../../../AGENTS.md).

---

## Inputs

- **Issue number** (required) — `#242`, `242`, or a full
  `https://github.com/<tracker>/issues/242` URL.
- **Optional: CVE ID override** — if the user has already allocated a
  CVE outside this flow and just wants the skill to wire it back
  into the tracker, accept a `CVE-YYYY-NNNNN` positional argument
  and skip straight to Step 4.

If the user does not supply a selector, ask for one before doing
anything else.

---

## Prerequisites

- **`gh` CLI authenticated** with collaborator access to
  `<tracker>` — the skill reads the tracker, adds
  labels, and posts the status-change comment via `gh`.
- **`uv` installed** — the embedded `generate-cve-json` regeneration
  step uses `uv run`.
- **Gmail MCP** connected — optional at this skill's scope, but
  required if the tracker carries a reporter thread that needs a
  status-update draft (Step 5).
- **A PMC member on call** — the Vulnogram allocation form is
  PMC-gated. If the user is not on the Airflow PMC, the skill
  still runs: it produces a relay message for a PMC member to
  click through instead of stopping.

See
[Prerequisites for running the agent skills](../../../README.md#prerequisites-for-running-the-agent-skills)
in `README.md` for the overall setup (including the ponymail-mcp
option on the horizon for non-personal-Gmail access).

---

## Step 0 — Pre-flight check

Before touching the tracker, verify:

1. **`gh` is authenticated** —
   `gh api repos/<tracker> --jq .name` must return
   `airflow-s`. A 401/403/404 means the user needs `gh auth login`
   or collaborator access; stop.
2. **`uv` is on the PATH** — `uv --version`. Without it the Step 4
   CVE-JSON regeneration would fail silently mid-flow; better to
   tell the user up front to install `uv` (one command:
   `curl -LsSf https://astral.sh/uv/install.sh | sh`).
3. **Resolve the user's PMC status.** First try to read it from
   [`config/user.md`](../../../config/user.md) → `role_flags.pmc_member`
   (see [`config/README.md`](../../../config/README.md) for the config
   layer explainer). If the file exists and the flag is set, use that
   value and surface it in the Step 0 recap (*"loaded config for
   `<handle>` (PMC: yes)"*). If the file is missing, the flag is
   unset, or the user did not copy the template, fall back to asking
   the PMC question up front (Step 3 asks it anyway, but prompting
   here gives the user a chance to abort if they did not realise they
   needed a PMC member to click through — it is friendlier than
   generating the relay recipe and then realising no PMC member is
   available to act on it).

If any check fails, stop with a clear message. Do not start
filling in the tracker until all three are green — a partial
allocation (label added, JSON regeneration skipped) is worse than
no allocation at all.

---

## Step 1 — Fetch the tracker state and run blocker checks

```bash
gh issue view <N> --repo <tracker> \
  --json number,title,state,body,labels,milestone,assignees,author
```

Blocker checks — if any fail, stop and surface the failure:

- **Issue is open.** Allocating a CVE for a closed tracker is
  almost always a mistake (the tracker may be closed as `invalid`,
  `duplicate` or already-announced). Surface as a blocker and ask
  the user what they intend.
- **No CVE already allocated.** Extract the *CVE tool link* body
  field; if it contains a `CVE-\d{4}-\d+` token, abort with a
  message pointing at the existing CVE. Also abort if the issue
  already carries the `cve allocated` label.
- **Not marked `duplicate`.** If the `duplicate` label is set, the
  canonical tracker already carries the CVE — abort and point the
  user at the kept tracker.
- **Scope label set.** The CVE record's `product` / `packageName`
  fields depend on the scope (`airflow` → `apache-airflow`,
  `providers` → `apache-airflow-providers-<name>`,
  `chart` → `apache-airflow-helm-chart`). If no scope label is
  set, stop and ask the user to confirm the scope before allocating
  — it is **much** easier to set the right product at allocation
  time than to correct it after the Vulnogram record has a CVE ID.
- **Not still `needs triage`.** If `needs triage` is still on the
  tracker, the valid/invalid decision has not been landed yet —
  allocating now would be premature. Surface as a soft warning and
  ask for confirmation before proceeding.

---

## Step 2 — Compute the CVE-ready title

The CVE record's `title` field is scoped to the product by the CNA
container (e.g. `Apache Airflow`, `Apache Airflow Providers Elasticsearch`),
so the Vulnogram title should be the **bare description** — no project
prefix, no redundant version suffix, no reporter-added tag like
`[ Security Report ]` or `Security Issue`.

The exact strip cascade is project-specific. For the currently active
project, the rules and their rationale live in
[`projects/<PROJECT>/title-normalization.md`](../../../projects/<PROJECT>/title-normalization.md).
The Python implementation below mirrors the cascade defined there; if
you are adapting this skill to a different project, replace the
patterns with that project's rules (and update its
`title-normalization.md` in lock-step).

Implementation recipe — keep it inline, do not create a separate
Python project for this one-shot transform:

```bash
python3 - <<'PY'
import re, subprocess

t = subprocess.check_output(
    ["gh", "issue", "view", "<N>", "--repo", "<tracker>",
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

Show the stripped title and the original title side by side in the
proposal so the user can spot any over-stripping before pasting
into Vulnogram. If the strip collapses the title to fewer than 3
words, surface that as a warning and propose a manual override —
over-stripping is worse than leaving one redundant word in.

---

## Step 3 — Print the allocation recipe

Compose a proposal block that carries everything the user needs in
one copy-paste pass:

```markdown
**Allocate a CVE for [<tracker>#<N>](https://github.com/<tracker>/issues/<N>).**

1. Open the ASF Vulnogram allocation form:
   <https://cveprocess.apache.org/allocatecve>
2. In the *Title* field, paste this:

   ```
   <stripped title>
   ```

3. Fill in the rest of the form from the tracker body — the key
   fields and where the skill reads them from:
   - **Product**: `<product, derived from scope — see table below>`
   - **CWE**: `<body.CWE if set, else "_No response_ — set during allocation"`>`
   - **Affected versions**: `<body.Affected versions>`
   - **Summary**: `<body.Short public summary for publish>`
   - **Reporter credits**: `<body.Reporter credited as>`
4. Click *Allocate*. Vulnogram returns a `CVE-YYYY-NNNNN` ID.
5. Paste the allocated CVE ID back into this conversation — the
   skill will pick it up and update the tracker automatically.
```

Scope → Vulnogram product table: the active project's scope labels
and their CVE product / package-name mappings are defined in
[`projects/<PROJECT>/scope-labels.md`](../../../projects/<PROJECT>/scope-labels.md).
Read the label off the tracker and look up the matching product /
`packageName` there.

Note in the recipe which provider / chart / task-sdk is involved
when the scope is not bare `airflow`, so the user does not have to
re-infer it from the tracker body at paste time.

**Before printing the recipe**, ask the user *"are you an Airflow
PMC member?"* — a one-line yes/no question. This determines which
of two handoff paths the recipe describes:

- **User is a PMC member** — the recipe is self-service: click the
  URL, paste the stripped title, fill the form, hit *Allocate*,
  paste the allocated `CVE-YYYY-NNNNN` back into this conversation.
- **User is NOT a PMC member** — the ASF CVE tool will not let them
  submit the allocation. Reshape the recipe into a **relay message**
  the user posts as a comment on the tracker (``@``-mentioning one
  or more current PMC members) or sends on the
  `security@airflow.apache.org` mail thread. **Keep it terse** — the
  PMC member already knows the allocation process, so the relay is a
  request, not a briefing, per the "Brevity: emails state facts, not
  context" section of [`AGENTS.md`](../../../AGENTS.md). The message
  contains only:
  - the clickable allocation URL,
  - the stripped title (ready for the Vulnogram form),
  - the derived scope / product / package-name block from Step 2,
  - one line: *"Paste the allocated `CVE-YYYY-NNNNN` back here when
    done."*

  Do not restate the vulnerability, the assessment history, or the
  handling process in the relay — the PMC member can read the
  tracker for any of that.

The relay message is just markdown — it does not go to Vulnogram
directly. The PMC member reads the message, clicks through, fills
the form, and replies with the allocated CVE. At that point the
original triager (or the PMC member) can re-invoke this skill with
the CVE ID as an override argument to resume from Step 4.

**Wait for the user** to report back a `CVE-\d{4}-\d+` token. Do
not proceed to Step 4 until that token has arrived. If the user
says they cannot allocate right now (no PMC member available, tool
down, etc.), stop and tell them the next invocation can be called
with the CVE ID as an override to resume from Step 4 without
re-doing Steps 1–3.

---

## Step 4 — Propose the tracker updates

Once the CVE ID is known, build a single combined proposal for the
user to confirm. Numbered items:

1. **Set the *CVE tool link* body field** to
   `https://cveprocess.apache.org/cve5/CVE-YYYY-NNNNN`. Patch only
   this one field; do not touch the rest of the body. Use the
   `sync-security-issue` skill's body-field-surgery recipe — read
   the full body, replace the *CVE tool link* field's value between
   its `### CVE tool link\n\n` header and the next `### ` or
   end-of-body, write back via `gh issue edit --body-file`.
2. **Add the `cve allocated` label.** `gh issue edit <N> --repo
   <tracker> --add-label "cve allocated"`.
3. **Post a status-change comment** with the collapsed-`<details>`
   shape mandated by
   [`sync-security-issue`](../sync-security-issue/SKILL.md) — bold
   headline, `**Next:**` line, reporter-notification line (when
   applicable), full rationale inside `<details>Details of
   update</details>`.
4. **Regenerate the CVE JSON attachment** in the tracker body by
   running
   ```bash
   uv run --project tools/vulnogram/generate-cve-json generate-cve-json <N> --attach
   ```
   This is how the CVE record first gets seeded with the allocated
   ID. Pass `--remediation-developer "<author>"` if the *PR with
   the fix* body field already has a `pull/<NNN>` URL; otherwise
   omit the flag and let a later sync run backfill it.
5. **Draft a reporter status update** — only when the real
   reporter's Gmail thread is known and the ball is in our court
   (see `sync-security-issue` Step 1c). Keep the draft short, per
   the "Brevity: emails state facts, not context" section of
   [`AGENTS.md`](../../../AGENTS.md): one sentence that the CVE has
   been allocated, one sentence that the advisory will be sent
   once the fix ships, the ASF CVE tool URL on its own line.
   Re-ask the credit-preference question **only if it has not yet
   been asked** on the thread — never ping twice. **Never send.**
   Always create a Gmail draft. **Prefer** attaching it by
   `threadId` (resolved from the tracker's *security-thread* body
   field — for Airflow, *"Security mailing list thread"*). If the
   `threadId` cannot be resolved from the field (it was never
   filled in, or the stored value is stale), **fall back to a
   subject-matched draft**: omit `threadId` and keep
   `subject: Re: <root subject of the inbound report>`. Subject is
   always the inbound root subject, never fabricated. Surface which
   path the draft took in the Step 5 proposal (`threadId`-attached
   vs. subject fallback). See
   [`tools/gmail/threading.md`](../../../tools/gmail/threading.md)
   for the full threading rule (including the few cases where the
   skill should stop rather than fall back) and
   [`tools/gmail/operations.md`](../../../tools/gmail/operations.md#create-draft)
   for the call-signature variants.

### Status-change comment template

```markdown
**Sync YYYY-MM-DD — CVE [`CVE-YYYY-NNNNN`](https://cveprocess.apache.org/cve5/CVE-YYYY-NNNNN) allocated for [<tracker>#<N>](https://github.com/<tracker>/issues/<N>).**

- Body *CVE tool link* field now points at the ASF CVE tool.
- Label `cve allocated` added.
- CVE JSON attachment embedded in the issue body — paste into
  [Vulnogram `#source`](https://cveprocess.apache.org/cve5/CVE-YYYY-NNNNN#source)
  to seed the record.

**Next:** <one-sentence next step — e.g. "design the fix
(`fix-security-issue` skill)", or "release manager completes
[process step 12](../../../README.md) once the fix ships">.

<details>
<summary>Details of update</summary>

Allocated via the ASF Vulnogram form at
<https://cveprocess.apache.org/allocatecve>; the CVE ID is now the
canonical reference in every downstream artifact (CVE JSON,
advisory email, credit lines, cross-links). Scope `<scope label>`
→ product `<product>` → `packageName` `<packageName>`.

Vulnogram paste-ready JSON was regenerated from the current body
state (CWE `<CWE>`, severity `<severity>`, affected
`<affected versions>`, `<N>` credits, `<N>` references) and
embedded in the issue body. Re-run
`uv run --project tools/vulnogram/generate-cve-json
generate-cve-json <N> --attach` after any body change to keep the
JSON in sync.

Reporter notification status: `<full per-reporter state — draft IDs,
pending credit questions, relay-channel notes>`.

</details>
```

Apply the Golden rule 2 self-check to both the visible part and
the `<details>` interior before emitting.

### Reporter-notification line options

End the visible part with exactly one of:

- *"Reporter has been notified on the original mail thread."* — when
  the draft was created in this sync.
- *"No reporter notification needed (reporter is on the security
  team)."* — for team-discovered issues.
- *"Reporter notification still pending — see draft `<draftId>`."* —
  when a draft was created but the user has not yet sent it.
- Omit the line entirely when no reporter notification is
  meaningful (e.g. an automated scanner report the team has decided
  to treat as non-actionable).

---

## Step 5 — Confirm and apply sequentially

Present the full proposal — numbered items from Step 4, plus the
rendered status-change comment body — and wait for confirmation.
Confirmation forms mirror the other skills:

- `all` — apply every proposed item.
- `1,3,4` — apply selected items only.
- `none` / `cancel` — bail.
- Free-form edits — regenerate the affected item(s) and re-confirm.

After confirmation, apply **sequentially** (not in parallel) so
partial failures stay legible:

1. `gh issue edit <N> --repo <tracker> --body-file <tmp>`
   — updated body with the *CVE tool link* field populated.
2. `gh issue edit <N> --repo <tracker> --add-label "cve allocated"`.
3. `gh issue comment <N> --repo <tracker> --body-file <tmp>`
   — status-change comment.
4. `uv run --project tools/vulnogram/generate-cve-json generate-cve-json <N> --attach`
   — embeds the CVE JSON in the body.
5. `mcp__claude_ai_Gmail__gmail_create_draft` on the original
   thread — reporter notification, if applicable.

If any step fails, stop and ask the user how to proceed — do not
guess. The body edit (step 1) is the only *load-bearing* step; if
steps 2–5 fail, a subsequent `sync-security-issue` run will pick up
the slack because it reads the CVE ID from the body.

---

## Step 6 — Hand off to `sync-security-issue`

Right after the apply loop finishes (and before the recap in Step
7), invoke the
[`sync-security-issue`](../sync-security-issue/SKILL.md) skill on
the same tracker. The CVE allocation touches every axis the sync
skill reconciles — labels, body fields, assignees, milestone,
reporter-notification drafts, cross-referenced fix PRs — and
running it immediately means:

- any stale `needs triage` label is cleared,
- the milestone is set (or surfaced as missing) now that the scope
  is known for real,
- the tracker's assignee is re-checked against the fix-PR author,
- the status-change comment from Step 4 and the embedded CVE JSON
  from Step 5 are cross-validated against the rest of the tracker,
- any drifted field the allocation revealed (e.g. a placeholder
  *Reporter credited as* that the Gmail thread already confirmed
  weeks ago) is surfaced as a concrete proposal.

Skipping this step leaves the tracker in a half-reconciled state
that the next triage sweep has to clean up from scratch. Always
run it.

**How to invoke.** The sync skill is prompt-driven, so this is a
meta-step: tell the user *"running `sync-security-issue` on
[<tracker>#<N>](...) to reconcile the rest of the
tracker"* and then run the sync skill's Step 1 (Gather state) on
the same issue. Sync produces its own numbered proposal with its
own confirmation loop — follow it through; do not short-circuit.

**Avoid re-allocation loops.** Sync's Step 2c no-longer proposes
allocating a CVE (the *CVE tool link* body field is now populated),
so the flow cannot loop back into this skill. Sync's Step 5 will
see the embedded CVE JSON block in the body and skip regeneration
if nothing has changed — no duplicate PATCH, no duplicate timestamp
bump.

**When the handoff is not appropriate.** Skip the sync handoff
**only** if the user explicitly says they are about to close the
tracker (e.g. allocated-then-decided-to-reject — a rare case, but
possible), or if sync was already running when `allocate-cve` was
invoked (nested invocation — sync's own Step 1 will detect the
fresh CVE on its next pass anyway). In every other case, run it.

---

## Step 7 — Recap

After the apply loop, print a short recap:

- The tracker as a clickable
  [`<tracker>#<N>`](...) link with a one-line summary of
  its new state (*CVE tool link* populated, `cve allocated` label
  set).
- The allocated CVE as a clickable
  [`CVE-YYYY-NNNNN`](https://cveprocess.apache.org/cve5/CVE-YYYY-NNNNN)
  link (before publication) per the "Linking CVEs" rule in
  [`AGENTS.md`](../../../AGENTS.md).
- The embedded CVE-JSON anchor
  (`...#cve-json--paste-ready-for-<cve-slug>`).
- The status-change comment's `#issuecomment-<C>` anchor.
- The Gmail draft ID (if one was created) plus a reminder that the
  user must open Gmail to review and send.
- The next handling-process step from the status-change comment's
  `**Next:**` line, repeated so the user does not have to scroll.

Apply the Golden rule 2 self-check to the entire recap text before
presenting.

---

## Hard rules

- **Never allocate on the user's behalf.** The Vulnogram form is a
  human step; the skill hands over the link and the stripped title,
  nothing more. Do not try to automate the form fill — the ASF CVE
  tool is ASF-OAuth-gated and agent automation of CNA allocation is
  explicitly out of scope.
- **Only an Airflow PMC member can allocate.** The Vulnogram
  allocation button is PMC-gated. If the user running this skill is
  not a PMC member, the recipe is a **relay message** they post for
  a PMC member to act on, not a form they can fill themselves.
  Never tell a non-PMC user to "just click Allocate" — they will
  see the form load and the button grey out, wasting a round trip.
- **Never fabricate a CVE ID.** If the user pastes a malformed token
  (not matching `CVE-\d{4}-\d{4,7}`), reject it and ask for the
  correct form.
- **Never allocate for a `duplicate`-labelled tracker.** The
  canonical tracker carries the CVE.
- **Never skip the scope check.** Allocating a CVE against the
  wrong product (`apache-airflow` when the fix lives in
  `apache-airflow-providers-smtp`, for example) is a multi-hour
  cleanup involving Vulnogram and the release manager.
- **Never send email.** Only create drafts; the reporter-
  notification rule from [`AGENTS.md`](../../../AGENTS.md) applies
  here the same way it applies to the other skills.

---

## References

- [`README.md`](../../../README.md) — the handling process, in
  particular step 6 (CVE allocation).
- [`AGENTS.md`](../../../AGENTS.md) — confidentiality, linking
  conventions, reporter-supplied CVSS rule.
- [`sync-security-issue`](../sync-security-issue/SKILL.md) —
  **mandatory follow-up** to this skill (Step 6). Reconciles the
  tracker, the mail thread, and any fix PR after the CVE landing
  touches labels, body fields, and comments. Always runs; only
  skipped in the explicit edge cases listed in Step 6.
- [`generate-cve-json`](../../../tools/vulnogram/generate-cve-json/SKILL.md) — Step 4
  regenerates the CVE JSON attachment in the body so Vulnogram can
  be seeded via the `#source` tab paste.
- [`import-security-issue`](../import-security-issue/SKILL.md) /
  [`deduplicate-security-issue`](../deduplicate-security-issue/SKILL.md)
  — the two on-ramps that feed trackers into this skill; running
  dedupe before allocation is how we avoid burning two CVE IDs on
  the same root-cause bug.
- [`fix-security-issue`](../fix-security-issue/SKILL.md) — the
  follow-up after allocation: open the public fix PR with the CVE
  context kept internal.
