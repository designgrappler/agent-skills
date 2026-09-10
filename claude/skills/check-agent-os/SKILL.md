---
name: check-agent-os
description: Runs a read-only health check on the current project's Agent OS installation.
---
# Check Agent OS
Runs a read-only health check on the current project's Agent OS installation. Verifies the orchestrator skill is present, confirms CLAUDE.md is the lean bootstrap, checks agent definitions are in place, and confirms AGENTIC.md and the retired `report-track-status` skill do NOT exist. On a clean pass, writes a `.agent-os-checked` timestamp to the project root so the 30-day session-start reminder knows the check is current. Nothing is auto-fixed — every fail row includes a remediation hint and action is left to you.

## Trigger
When the user runs `/check-agent-os`, execute the following phases in order.

---

## Phase 1: Skill Install Check

1. Resolve the canonical skill names using the same source chain as `/update-agent-os`:
   - Check `skills-manifest.json` in the project root for a `canonical-registry` URL.
   - If present, attempt to fetch the manifest JSON from that URL and read its `skills` array.
   - **Fallback:** if the URL fetch fails, fall back to the local canonical clone at `$(git rev-parse --show-toplevel)/skills-manifest.json`. Notify the user that the fallback was used.
   - **If neither resolves:** stop and ask the user to supply a path or URL. Do not proceed to Phase 2.
2. Use the manifest's `renames` array to recognize legitimate renames: if a skill name in `~/.claude/skills/` matches a `"to"` value in `renames`, it is correctly installed — do not flag it as missing.
3. Compare the canonical `skills` array against subdirectory names in `~/.claude/skills/` that contain a `SKILL.md` file.
4. **Pass:** every canonical skill name has a corresponding `~/.claude/skills/<name>/SKILL.md` (accounting for renames).
5. **Fail rows:** list each canonical skill name that is absent or present only under a stale name. Remediation hint:
   > Run `/update-agent-os` to install missing or stale-named skills.

---

## Phase 1b: Canonical ↔ Installed Drift Detection

1. **Resolve repo root.** Run:
   ```bash
   git rev-parse --show-toplevel 2>/dev/null
   ```
   If the command fails or returns empty (not a git repo): emit `[check-agent-os] Phase 1b: not a git repository — drift check skipped.` and exit this phase. Phase 1c will see no drift report and will skip silently.

2. **Locate manifest.** Check for `<repo-root>/skills-manifest.json`. If absent: emit `[check-agent-os] Phase 1b: skills-manifest.json not found at repo root — drift check skipped.` and exit this phase.

3. **Read skill list.** Extract the `"skills"` array from `<repo-root>/skills-manifest.json` using python3 (no jq required):
   ```bash
   python3 -c "import json; [print(s) for s in json.load(open('<repo-root>/skills-manifest.json'))['skills']]"
   ```

4. **Compare canonical ↔ installed.** For each skill name in the array:
   - Canonical path: `<repo-root>/claude/skills/<skill>/SKILL.md`
   - Installed path: `~/.claude/skills/<skill>/SKILL.md`
   - If the canonical path does not exist: skip this skill (registry-only entry, not present in this repo).
   - If the installed path does not exist: record drift — installed copy missing.
   - If both exist: run `diff <canonical-path> <installed-path>`. If exit code is non-zero, record drift; capture line counts via `wc -l <canonical-path>` and `wc -l <installed-path>`.

5. **Emit result.**
   - **No drift:** emit `[check-agent-os] Phase 1b: canonical ↔ installed — all N skills match` (N = number of skills compared).
   - **Drift detected:** for each drifted skill, emit one row:
     ```
     DRIFT  <skill>  canonical: <N> lines  installed: <M> lines
     ```
     If the installed copy is missing:
     ```
     DRIFT  <skill>  canonical: <N> lines  installed: MISSING
     ```
     After all drift rows, emit: `[check-agent-os] Phase 1b: <D> of N skills have drift.`

**Phase 1c reads this phase's output.** If this phase emitted one or more `DRIFT` rows, Phase 1c surfaces the stale content sweep prompt. If this phase skipped or reported all-match, Phase 1c exits silently.

---

## Phase 1c: Drift-Triggered Stale Content Sweep

**Trigger condition:** This phase runs ONLY if Phase 1b (dev-to-installed drift detection, T81.3) was executed as part of this check AND detected drift (at least one installed skill file differs from its canonical counterpart).

- If Phase 1b is not present in this skill (T81.3 not yet installed): emit `[check-agent-os] T81.3 drift detection not yet installed — sweep skipped.` and exit this phase.
- If Phase 1b ran but detected NO drift: exit this phase silently.
- If Phase 1b ran and detected drift: emit the sweep prompt below and wait for the user's reply.

**Sweep prompt (emit when drift is detected):**

```
[check-agent-os] Drift detected. Run stale content sweep?
The installed skills have diverged from canonical. This sometimes leaves stale references in memory files (retired agent names, old skill paths, superseded patterns). A sweep will scan memory files and surface any references to retired or renamed skills/agents.
Reply "sweep" to run, or continue to skip.
```

**If user replies "sweep":**

1. Resolve the memory directory for the current project. Check in order:
   - Project-relative `.claude/memory/` (if this directory exists at the project root).
   - Global `~/.claude/projects/<project-slug>/memory/` where `<project-slug>` is derived from the project's absolute path (replace `/` with `-`, strip leading `-`).
   - If neither directory exists: emit `[check-agent-os] No memory directory found — sweep skipped.` and exit.
2. Build the current canonical reference set from the project root:
   - **Agent names:** filenames without extension for all files directly under `claude/agents/`.
   - **Skill names:** subdirectory names directly under `claude/skills/`.
   - **Hook filenames:** filenames for all files directly under `claude/hooks/`.
3. Scan every `.md` file in the resolved memory directory. For each file, check whether it contains any of the following that do NOT match the canonical reference set from step 2:
   - Slash-commands referencing a skill (e.g. `/old-skill-name`).
   - Bare agent or skill names that match a former directory name pattern.
   - File paths referencing `claude/agents/`, `claude/skills/`, or `claude/hooks/` entries.
4. Output: for each memory file with at least one stale reference, emit a row:
   ```
   <filename>: stale term "<term>" (not found in current claude/agents/, claude/skills/, or claude/hooks/)
   ```
   If no stale references are found across all memory files: emit `[check-agent-os] Stale content sweep: no stale references found.`
5. **Do NOT auto-edit any memory file.** Surface findings only. Remediation is left to the user.

**If user does not reply "sweep" (or this phase is running non-interactively):** skip silently.

---

## Phase 2: Orchestrator Skill Check

1. Confirm `claude/skills/orchestrator/SKILL.md` exists in the project.
2. **Pass:** the file exists and is non-empty.
3. **Fail rows:** if absent or empty. Remediation hint:
   > Run `/onboard-existing-project` or `/install-agent-scaffold` to install the orchestrator skill.

---

## Phase 3: CLAUDE.md Bootstrap Check

1. Confirm `CLAUDE.md` exists at the project root.
2. Check that it does NOT contain the old 181-line heavy-ceremony format (indicators: contains `## Initialization Loop`, references to `AGENTIC.md`, or contains `Sprint Coordinator constraint`).
3. **Pass:** `CLAUDE.md` exists and is the lean bootstrap format (contains `## Team`, `## Orchestrator Behavior`, and `## Tech Stack` sections; does not reference AGENTIC.md or Sprint Coordinator constraints).
4. **Fail rows:** if absent, or if it matches the old heavy format. Remediation hint:
   > CLAUDE.md is in the legacy format. Migrate manually:
   > 1. Back up any project-specific customizations from your current CLAUDE.md
   > 2. Open `~/.claude/skills/install-agent-scaffold/SKILL.md` and copy the template from section 4a
   > 3. Replace your CLAUDE.md with the template, re-applying your backed-up customizations
   > 4. Run `/check-agent-os` again to confirm Phase 3 passes

---

## Phase 4: Agent Definitions Check

### 4a: Expected Agents Present

1. List all files matching `~/.claude/agents/*.md`.
2. Confirm the following canonical agents are present:
   - `backend.md`
   - `critic.md`
   - `database.md`
   - `designer.md`
   - `frontend.md`
   - `marketing.md`
   - `mobile.md`
   - `ops.md`
   - `pm.md`
   - `qa.md`
   - `strategist.md`
   - `technical.md`
   - `user-researcher.md`
   - `writer.md`
3. **Always enumerate all agents** — one row per agent regardless of pass/fail:
   ```
   ✓ present   backend
   ✓ present   critic
   ✗ missing   database
   ✓ present   designer
   ...
   ```
4. **Pass:** all fourteen files exist — no `✗ missing` rows.
5. **Fail rows:** each `✗ missing` row is a fail row. Remediation hint:
   > Run `/update-agent-os` to install missing canonical agents.

### 4b: Model Format Check

1. For each file matching `~/.claude/agents/*.md`, parse the frontmatter `model:` line.
2. **Pass:** every `model:` value is one of the canonical short forms: `opus`, `sonnet`, or `haiku`.
3. **On full PASS:** emit a compact summary line only:
   > `4b: Model Format Check — PASSED (all N agents use short-form model values)`
4. **On any failure:** enumerate all agents — one row per agent showing name, model value, and status:
   ```
   ✓ valid    backend      model: sonnet
   ✓ valid    critic       model: opus
   ✗ invalid  designer     model: claude-sonnet-4-5 (use short form: sonnet)
   ...
   ```
5. **Fail rows:** each `✗ invalid` row is a fail row. Remediation hint:
   > Edit `~/.claude/agents/<name>.md` and change `model:` to the short form (`opus`, `sonnet`, or `haiku`).

**Note on `provider:` field:** `provider:` is an optional frontmatter field. Its absence is correct for the default Anthropic setup. Do NOT flag a missing `provider:` field as an error.

**Note on `mode:` field:** `mode:` is an optional field in `agent-setup.yml` (not agent frontmatter). Its absence or a blank value is correct and means `single-user`. Do NOT flag a missing, blank, or `single-user` `mode:` value as an error. (The non-blocking multi-user warning is added in T47.3.)

### 4c: WebFetch Tools Frontmatter Check

1. For each file matching `~/.claude/agents/*.md`, parse the frontmatter `tools:` list.
2. **Pass:** every agent file includes `WebFetch` in its `tools:` list.
3. **On full PASS:** emit a compact summary line only:
   > `4c: WebFetch Tools Check — PASSED (all N agents include WebFetch)`
4. **On any failure:** enumerate all agents — one row per agent showing name and status:
   ```
   ✓ valid    backend     WebFetch present
   ✓ valid    critic      WebFetch present
   ✗ invalid  designer    WebFetch absent
   ...
   ```
5. **Fail rows:** each `✗ invalid` row is a fail row. Remediation hint:
   > Run `/update-agent-os` to sync with canonical.

### 4d: Specialist `isolation: worktree` Check

1. For each file matching `~/.claude/agents/*.md`, determine whether the agent is a Specialist by checking for a `## Sign-Off Protocol` section that contains both `**Track:**` and `**Completed:**` fields.
2. For each identified Specialist, confirm `isolation: worktree` appears in frontmatter.
3. **Pass:** every Specialist agent has `isolation: worktree`.
4. **On full PASS:** emit a compact summary line only:
   > `4d: Specialist isolation Check — PASSED (all N specialists have isolation: worktree)`
5. **On any failure:** enumerate all Specialist agents — one row per Specialist showing name and status:
   ```
   ✓ valid    backend     isolation: worktree present
   ✓ valid    frontend    isolation: worktree present
   ✗ invalid  designer    isolation: worktree absent
   ...
   ```
6. **Fail rows:** each `✗ invalid` row is a fail row. Remediation hint:
   > Run `/update-agent-os` to sync with canonical.

---

## Phase 5: Retirement Verification

### 5a: AGENTIC.md Does NOT Exist

1. Check whether `AGENTIC.md` exists at the project root.
2. **Pass:** `AGENTIC.md` does NOT exist.
3. **Fail row:** if `AGENTIC.md` exists. Remediation hint:
   > `AGENTIC.md` is a retired file from the old Agent OS model. Delete it — its content has been replaced by `CLAUDE.md` and the orchestrator skill.

### 5b: `report-track-status` Does NOT Exist

1. Check whether `claude/skills/report-track-status/` exists in the project.
2. **Pass:** the directory does NOT exist.
3. **Fail row:** if `claude/skills/report-track-status/` exists. Remediation hint:
   > `report-track-status` is a retired skill. Delete `claude/skills/report-track-status/` — it has been replaced by `/track-status`.

---

## Phase 6: Required `docs/context/` Check

1. Check for the existence and non-emptiness of each required context file:
   - `docs/context/plan.md`
   - `docs/context/tracks.md`
2. A file passes if it exists **and** contains at least one non-whitespace character.
3. **Pass:** both files exist and are non-empty.
4. **Fail rows:** list each file that is missing or empty. Remediation hint:
   - For `docs/context/plan.md` or `docs/context/tracks.md`:
     > These files must be authored at sprint kickoff. Run `/start-sprint` to initialize them.

---

## Phase 6b: Multi-User `Owner:` Enforcement (informational — does not affect OVERALL)

This phase is **advisory only**. It never contributes a fail row and never changes `OVERALL`.

1. Read `agent-setup.yml` from the project root and take the top-level `mode:` value (trim whitespace, strip inline `#` comments). Apply the T47.2 defaulting: file absent / key absent / blank / `single-user` / any unrecognized value → `single-user`; only `multi-user` → `multi-user`.
2. **If mode resolves to `single-user`:** emit `Phase 6b: Multi-User Owner Enforcement — N/A (single-user mode)` and exit the phase. No enforcement in single-user.
3. **If mode resolves to `multi-user`:** read `docs/context/tracks.md`. For each track whose `**Status:**` is `IN_PROGRESS` or `DONE`, check its `**Owner:**` value. If the owner is blank or `null`, emit one warning line:
   > `⚠ Track <ID> is <STATUS> but has no Owner (blank/null). Assign a GitHub handle in docs/context/tracks.md, or leave it if intentional. (Non-blocking.)`
4. If no such tracks exist (or `tracks.md` is absent), emit `Phase 6b: Multi-User Owner Enforcement — PASS (all in-flight tracks owned)`.

These warnings are surfaced for visibility only. Do **not** count them in the `OVERALL: FAIL (N issues)` total — the FAIL count remains "fail rows across Phases 1–6" as defined in Phase 8.

---

## Phase 7: Claude Code Version Notice (informational only — does not affect OVERALL)

Run `claude --version` defensively:
```bash
version_output=$(claude --version 2>/dev/null)
```

Extract the version string (first whitespace-delimited token). Compare to threshold `2.1.172`.

- **version >= 2.1.172:** emit: `Claude Code version OK (v<X.Y.Z>)`
- **version < 2.1.172:** emit: `Claude Code v2.1.172+ recommended for autonomous mode (detected: v<X.Y.Z>)`
- **parse failed:** emit: `Claude Code v2.1.172+ recommended for autonomous mode (could not detect installed version)`

---

## Phase 8: Report

Emit one clearly-labeled section per phase. Each section states **PASSED** or **FAILED**, with fail rows and remediation hints. Phase 7, Phase 6b, and Phase 8b notices are informational — they do NOT affect OVERALL.

```
### Phase 1: Skill Install Check — PASSED
### Phase 1b: Canonical ↔ Installed Drift Detection — all 20 skills match
### Phase 2: Orchestrator Skill Check — PASSED
### Phase 3: CLAUDE.md Bootstrap Check — PASSED
### Phase 4: Agent Definitions Check
#### 4a: Expected Agents Present — PASSED
#### 4b: Model Format Check — PASSED
#### 4c: WebFetch Tools Frontmatter Check — PASSED
#### 4d: Specialist isolation: worktree Check — PASSED
### Phase 5: Retirement Verification
#### 5a: AGENTIC.md Does NOT Exist — PASSED
#### 5b: report-track-status Does NOT Exist — PASSED
### Phase 6: Required docs/context/ Check — PASSED
### Phase 6b: Multi-User Owner Enforcement — N/A (single-user mode)
### Phase 7: Claude Code Version Notice (informational)
Claude Code version OK (v2.1.200)

OVERALL: PASS
```

The final line **must** be exactly one of:
- `OVERALL: PASS`
- `OVERALL: FAIL (N issues)` — where N is the total count of fail rows across Phases 1–6 (Phase 7, Phase 6b, and Phase 8b excluded, all informational).

---

## Phase 8b: Execution Receipt Validation

**Informational only — does not affect OVERALL.**

1. Check whether `docs/context/skill-receipts.jsonl` exists and is non-empty.
   - **Absent or empty:** emit `[check-agent-os] Execution receipts: file absent — no lifecycle skills have run with receipt logging` and exit this phase. Do not fail.

2. Read `docs/context/plan.md` and extract the current sprint ID: match `## Current Sprint: <ID>` (e.g. `S81`). If not found, use `"unknown"` as the expected sprint.

3. Read `docs/context/skill-receipts.jsonl`. For each of the four lifecycle skills (`start-sprint`, `close-sprint`, `update-agent-os`, `check-agent-os`), find the last receipt line where `"skill"` matches. Parse as JSON.

4. Output a table:

   ```
   Phase 8b: Execution Receipt Validation
   
   Skill            Last Timestamp             Sprint       Match?
   start-sprint     2026-09-02T14:00:00Z       S81          YES
   close-sprint     —                          —            NO (absent)
   update-agent-os  2026-09-01T10:00:00Z       S80          NO (stale)
   check-agent-os   —                          —            NO (absent)
   ```

   - **Match:** `sprint` field equals the current sprint ID from `plan.md` → `YES`
   - **Stale:** `sprint` field differs from current sprint ID → `NO (stale)` — remediation: `Re-run /close-sprint to generate a current receipt` (or appropriate skill name)
   - **Absent:** no receipt line found for this skill → `NO (absent)` — remediation: `Re-run /<skill> to generate a current receipt`

5. This phase never adds fail rows to OVERALL. Findings are informational.

---

## Phase 9: Timestamp on Success

- **If `OVERALL: PASS`:** write today's ISO date (e.g. `2026-07-20`) to `.agent-os-checked` at the project root. Print:
  > `Wrote .agent-os-checked (next reminder in 30 days)`
- **If `OVERALL: FAIL`:** do NOT create or modify `.agent-os-checked`.

---

## Phase 10: Execution Receipt

On completion of all phases above (regardless of OVERALL result), append one line to `docs/context/skill-receipts.jsonl` (create the file if absent):
```json
{"skill":"check-agent-os","timestamp":"<ISO-8601 timestamp>","sprint":"<sprint-id>","version":"<release-version>","flags":[]}
```
- `timestamp`: current ISO-8601 datetime (e.g. `2026-09-02T14:30:00Z`)
- `sprint`: read from `docs/context/plan.md` — match `## Current Sprint: <ID>` (e.g. `S81`); if not found use `"unknown"`
- `version`: read `release-version` from `skills-manifest.json` in the project root; if not found use `"unknown"`
- Append only — never overwrite. Create the file and any missing parent directories silently if absent.

---

## Hard Constraints

- Read-only **except** for the single `.agent-os-checked` write at project root on PASS (Phase 9) and the execution receipt append to `docs/context/skill-receipts.jsonl` (Phase 10).
- Never auto-fix; only report. Remediation is up to the user.
- If the canonical source cannot be resolved, stop and ask the user before proceeding.
- Every fail row surfaces a remediation hint.

---

## Verification Checklist (Internal — Run Before Reporting Complete)
- [ ] Canonical source resolved before Phase 1 ran
- [ ] All phases (1–8) executed in order; Phase 8 Report, Phase 8b Receipt Validation, Phase 9 Timestamp, and Phase 10 Execution Receipt run last
- [ ] Phase 1b: repo root resolved via `git rev-parse --show-toplevel`; if not a git repo → skipped with note; if manifest absent → skipped with note; otherwise all skills in manifest compared canonical ↔ installed; drift rows emitted per drifted skill with line counts
- [ ] Phase 1c: if Phase 1b absent → skip note emitted; if Phase 1b ran with no drift → silent exit; if Phase 1b drift detected → sweep prompt shown; sweep findings not auto-edited
- [ ] Report ends with explicit `OVERALL: PASS` or `OVERALL: FAIL (N issues)` line
- [ ] Phase 8b: if skill-receipts.jsonl absent/empty → informational note; if present → table output with one row per lifecycle skill; stale/absent entries flagged with remediation hint
- [ ] On PASS, `.agent-os-checked` written with today's ISO date
- [ ] On FAIL, `.agent-os-checked` NOT created or modified
- [ ] Phase 10: execution receipt appended to `docs/context/skill-receipts.jsonl`
- [ ] Every fail row includes a remediation hint
- [ ] Phase 4a: all fourteen expected agents enumerated with `✓ present` or `✗ missing` — always, not only on failure
- [ ] Phase 4b: on full PASS → compact summary line only; on any failure → all agents enumerated with model value and `✓ valid` / `✗ invalid`
- [ ] Phase 4c: on full PASS → compact summary line only; on any failure → all agents enumerated with `✓ valid` / `✗ invalid`
- [ ] Phase 4d: on full PASS → compact summary line only; on any failure → all Specialists enumerated with `✓ valid` / `✗ invalid`
- [ ] Phase 5a: AGENTIC.md existence checked; presence is a FAIL
- [ ] Phase 5b: report-track-status existence checked; presence is a FAIL
- [ ] Phase 7: `claude --version` invoked defensively; never contributes fail rows to OVERALL
- [ ] Phase 6b: mode read; single-user → N/A; multi-user → advisory warnings only, never counted in OVERALL
