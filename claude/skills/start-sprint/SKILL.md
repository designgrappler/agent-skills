---
name: start-sprint
description: Opens a new sprint — sets sprint goal, defines tracks, initializes plan.md and tracks.md.
whenToUse: When the user wants to start a new sprint or begin a structured work session with multiple tracks.
---

## Instructions

### Step 1 — Gather sprint context

**Scaffold pre-flight (run before everything else):** Check whether `CLAUDE.md` exists in the current directory. If it does not exist, stop immediately and surface:
> "This project has no Agent OS local scaffold. Run `/install-agent-scaffold` (new project) or `/onboard-existing-project` (existing project with code) first, then re-run `/start-sprint`."
Do not proceed with any further steps. If `CLAUDE.md` is present, continue normally.

**Infrastructure check (run first):** Review the proposed sprint tracks. If any track touches `claude/skills/`, `claude/agents/`, or lifecycle skills (`/start-sprint`, `/close-sprint`, `/clean-context`), run a lightweight system scan before proceeding: check `docs/` root for temp file accumulation, check `docs/archive/plan-docs/` against the 3-sprint window, and surface any structural issues before asking for the sprint goal.

**GitHub issues check (non-blocking):** Resolve the target repo and list open issues:

1. Read `agent-setup.yml` from the project root. If a top-level `github_repo:` key is present, use its value as the repo (e.g. `owner/repo`).
2. If no `github_repo:` key is found, run:
   ```bash
   git remote get-url origin 2>/dev/null
   ```
   Parse the output to extract `owner/repo` — handle both HTTPS (`https://github.com/owner/repo`) and SSH (`git@github.com:owner/repo.git`) formats.
3. If a repo was resolved and `gh` is available, run:
   ```bash
   gh issue list --repo <resolved-repo> --state open 2>/dev/null
   ```
   Format the output as:
   ```
   Open GitHub issues (<resolved-repo>):
     #28  [feedback] ...
     ... (all open issues listed)
   ```
   If no issues are open, print: `No open GitHub issues on <resolved-repo>.`
4. If no repo can be resolved from either source, or if `gh` is not installed, print `GitHub issues check skipped — no repo configured.` and continue.
5. If the command fails for any reason: print `GitHub issues check failed — continuing.` and continue.
6. Never block or halt sprint open due to this check.

Run /triage to surface prioritized backlog candidates and open GitHub issues.

**Systemic-drift triage (run right after the backlog check):** Before asking for the sprint goal, scan the backlog items just surfaced and ask: *"Does any open backlog item represent an architectural spec that agents are actively following incorrectly?"* If yes, that item heads the sprint. Distinguish the two cases:
- **Stop-and-fix** — the issue causes active drift on every sprint that runs. It heads the current sprint.
- **Queue** — a missing improvement that does not get worse with time. It stays in the backlog.

Check whether a temp plan doc already exists at `docs/temp-sprint*.md` (glob pattern). If one is found, read it and extract the sprint goal and track list from it. Then surface the plan doc to Tim for review before proceeding:

> "Existing temp plan doc found. Plan doc ready for review:
> - [docs/temp-sprint\<N>-plan.md](docs/temp-sprint\<N>-plan.md)
> Review each track's filled section, confirm scope and verification criteria, then confirm to proceed."

If Tim's feedback changes scope for any track, re-fill the affected stubs before re-surfacing. Repeat until Tim confirms the full set.

**Do not proceed to Step 2 until Tim confirms.**

(A temp plan doc takes precedence over the backlog prompt; if a temp plan doc exists, surface it rather than the raw backlog.)

If no temp plan doc exists and no backlog file exists, ask the user:

1. What is the sprint goal? (one sentence)
2. What tracks will this sprint include? (list each track with a short description and owner if known)

Wait for the user's response before continuing.

### Step 1a — Write orchestrator-owned plan doc

Trigger: as soon as the sprint goal and track list are established — whether they arrived as direct structured answers or emerged through conversational back-and-forth — write the plan doc immediately. Do not defer, and do not treat structured input as a precondition.

Write `docs/temp-sprint<N>-plan.md` with the orchestrator-owned top section:
- Header block: Sprint ID, Status: OPEN, Authored-by: Orchestrator, Date, Release target
- Sprint Objective
- Tracks table (one row per track: Track ID | Description | Owner | Status)
- Constraints — include explicit exclusions/non-goals
- Sequencing — dependency order across tracks
- Sprint Close Conditions
- Sentinel: `<!-- ORCHESTRATOR SECTION END — do not edit above this line -->`

Immediately after the sentinel, append one Element (c) stub per Tracks table row:

```
## T<N> — <Track Description>

**Owner:** <role-key>
**Status:** STUB

<!-- <role-key>: fill this section before executing -->

**Description:**

**Scope:**

**Key files:**

**Verification criteria:**
```

Do not write any track content. The stub is the full orchestrator contribution below the sentinel.

Each stub's `**Status:** STUB` is the required initial state — it signals "not yet planned." Domain agents are responsible for flipping it to `**Status:** FILLED` when they complete their section. The STUB/FILLED state in the plan doc is the coordination primitive; do not create a separate manifest file.

Format defined in `docs/context/plan-doc-format.md`.

### Step 1b — Identify domains involved

From the sprint goal and proposed tracks surfaced in Step 1, identify which domain agents are relevant. Match tracks to agent roles:

- Design work → `designer`
- Product requirements / user stories → `pm`
- Technical architecture / complex decisions → `technical`
- Research / competitive analysis → `researcher`
- Strategic direction / opportunity framing → `strategist`

This step repeats if Tim's feedback on sub-plans changes sprint scope — re-identify affected domains and re-spawn those agents before proceeding.

### Step 1c — Spawn domain agents in planning mode (parallel)

Instruct each domain agent to fill their assigned stub section in-place in `docs/temp-sprint<N>-plan.md` before executing. Each agent reads the full top section (above the sentinel), fills only their own stub (Description, Scope, Key files, Verification criteria), and flips Status from STUB to FILLED. No separate per-domain files.

Every dispatch brief must include two explicit fields at the top, before the scoped instruction:

```
Sprint goal: <one sentence from the Sprint Objective>
Expected outcome: <track-level definition of done for this agent's assigned tracks>
```

Do not dispatch a domain agent without both fields. An agent briefed with only a scoped instruction plans against that instruction in isolation and may miss sprint-level scope.

Domain agents run in parallel where independent. Run sequentially where one domain's scope depends on another (e.g. strategist or pm before technical or frontend).

**Gap coverage rule (hard):** If a proposed track has no matching domain agent, the sprint always blocks for Tim input — the orchestrator does not fill the gap. Surface explicitly:
> "Track [X] has no domain agent. Define its scope manually or remove it before proceeding."

**Fill method (hard):** Instruct each domain agent to fill their stub using `Edit` (targeted replace of the stub block), not `Write` of the whole plan doc. A whole-file `Write` is not section-safe and can clobber a sibling agent's section during parallel dispatch.

**Post-dispatch reconciliation (mandatory before Step 1d):** After all domain agents have returned, read `docs/temp-sprint<N>-plan.md` and verify every row in the Tracks table has a corresponding `## T<N>` section that passes the complete-fill definition in `docs/context/plan-doc-format.md`: `**Status:** FILLED` AND Description, Scope, Key files, and Verification criteria all non-empty. This is a mechanical check against the Tracks table, not a judgment call.

- If any track still shows `**Status:** STUB` or has any required field empty: treat it as a dispatch failure. Name the specific track ID and Owner. Re-dispatch only that domain agent. Repeat up to 3 re-dispatch attempts for the same track.
- After 3 failed re-dispatch attempts on the same track: stop and surface to Tim:
  > "Track T<N> (Owner: <role>) failed to fill after 3 dispatch attempts. Manual intervention required before proceeding."
- Do not advance to Step 1d until reconciliation passes for every track in the Tracks table.

### Step 1d — Tim review gate (soft gate)

**Pre-gate STUB check:** Before surfacing the plan doc to Tim, read `docs/temp-sprint<N>-plan.md` and confirm every `## T<N>` section shows `**Status:** FILLED`. If any section still shows `**Status:** STUB`, do not surface to Tim — treat it as a dispatch failure:
> "Dispatch failure: Track T<N> (Owner: <role>) is still STUB. Re-dispatching before Tim review."
Re-dispatch the named agent. Repeat until all tracks are FILLED. The Tim review gate does not open until all tracks show Status: FILLED.

Once all tracks show Status: FILLED, surface the plan doc to Tim:

> "Domain agent stubs filled. Plan doc ready for review:
> - [docs/temp-sprint\<N>-plan.md](docs/temp-sprint\<N>-plan.md)
> Review each track's filled section, confirm scope and verification criteria, then confirm to proceed."

If Tim's feedback changes scope for any domain, re-spawn those domain agents with updated context to re-fill their stubs. Repeat until Tim confirms the full set.

**Do not proceed to Step 2 until Tim confirms.**

### Step 2 — Determine sprint ID

Read `docs/context/plan.md` if it exists. Find the highest sprint number currently referenced (look for `## Current Sprint: S<N>` or `## Completed Sprint: S<N>`). The new sprint ID is that number plus one. If no prior sprint is found, start at S1.

### Step 2b — Prior-sprint open-PR pre-check (warn-only)

Before opening the new sprint, check whether any pull requests from the prior sprint
are still open against `feature/*` branches. This is a **warning only** — it never
blocks sprint open, and it degrades silently when GitHub CLI is unavailable.

1. If `gh` is not installed, skip this step entirely — no output:
   ```bash
   command -v gh >/dev/null 2>&1 || :   # skip silently when gh absent
   ```

2. Otherwise, query open feature-branch PRs (stderr suppressed so an
   unauthenticated `gh`, a repo with no GitHub remote, or any other failure
   produces no output):
   ```bash
   gh pr list --state open \
     --json number,title,headRefName,url \
     --limit 100 \
     --jq '.[] | select(.headRefName | startswith("feature/")) | "  #\(.number)  \(.headRefName)  —  \(.title)  (\(.url))"' \
     2>/dev/null
   ```

3. If the command produced no output (no matching PRs, gh not authenticated,
   no GitHub remote, or any error) — emit nothing and continue to Step 3.

4. If the command produced one or more lines, print this warning, then continue
   to Step 3 (the sprint still opens — this does not block):
   ```
   These PRs from the prior sprint are still open — merge or close them before opening the new sprint:

   <captured lines>
   ```

### Step 2c — Backlog promotion (mandatory move operation)

This step is **mandatory and non-skippable.** When a backlog item enters a sprint, it is moved — not copied. The backlog must reflect only work that has not yet been pulled into a sprint. This step is the mechanism for that move.

Run this step BEFORE writing plan.md or tracks.md — the sprint is not yet marked OPEN, so the backlog write is not blocked by the active-sprint hook.

Read `docs/backlog.md`. For every item in the file, ask: *"Is this work being done in this sprint?"* Match on ANY of the following signals — be liberal, not conservative:
- Item is explicitly tagged with the track ID (e.g. `(T54.1)`)
- Item title closely matches a track description or sprint goal keyword
- Item describes a feature, bug, or capability that the sprint tracks are implementing — **same domain and intent counts, even if the exact wording differs**
- Item is in a backlog section whose heading corresponds to this sprint's domain

**When in doubt, surface the item.** A false positive costs one confirmation. A missed item leaves completed work in the backlog indefinitely — that is the failure mode to avoid.

**If matches found**, surface them:
> "These backlog items correspond to work in this sprint and should be removed from the backlog. Confirm?
> - [B<n>] [item title]"
> Wait for confirmation, then remove the matched line(s). Do not remove section headers or surrounding items.

**If no matches found**, state explicitly: "Backlog scan complete — no items match the tracks in this sprint." Do not skip silently. The confirmation that the scan ran is part of the sprint open record.

### Step 3 — Write `docs/context/plan.md`

Create or overwrite the Current Sprint section at the top of `docs/context/plan.md`:

```markdown
## Current Sprint: S<N> — <sprint goal>

### Sprint Goals:
- [ ] <Track ID> — <description> — <owner or TBD>

---
*Last updated: <today's date>*
```

If the file already contains completed sprint entries (lines matching `## Completed Sprint: S<N> ✓`), preserve them below the new current sprint section.

If `docs/` does not exist, create it silently before writing.

### Step 4 — Write `docs/context/tracks.md`

**Determine collaboration mode (read once).** Read `agent-setup.yml` from the project root and take the top-level `mode:` value (trim whitespace, strip inline `#` comments). Defaulting — never error: file absent, key absent, blank, `single-user`, or any unrecognized value → treat as **`single-user`**; only the exact value `multi-user` → **`multi-user`**. This is the T47.2 Canonical Read Contract.

Add one entry per track to `docs/context/tracks.md`. Each entry follows this shape:

```markdown
## Track <ID>: <Task Name>
- **Owner:** <OWNER_VALUE>
- **Status:** OPEN
- **Sprint:** S<N>
- **Opened:** <today's date>
- **Exit Record**
  - **Status:**
  - **What happened:**
  - **Next steps:**
```

Resolve `<OWNER_VALUE>` by mode:
- **`single-user` (default):** emit exactly `<agent name, or null if unclaimed>` — i.e. **identical to the prior behavior**; write `null` when unclaimed. Do **not** prompt. (This is byte-for-byte the pre-T47.3 line.)
- **`multi-user`:** before writing each track entry, prompt the user: `Owner for Track <ID> — GitHub handle, or leave blank to claim later:`. If a handle is given, use it verbatim as `<OWNER_VALUE>`. If the user leaves it blank, use `null` (claim-later is valid).

If the file already has entries from a prior sprint, append the new entries below them.

### Step 5 — Confirm

Output a short confirmation when all steps complete.

**The "Sprint plan:" line must use markdown link syntax — `[path](path)` — not plain text.**

```
Sprint S<N> open.

Goal: <sprint goal>
Tracks: <count> track(s) added to docs/context/tracks.md
Plan: docs/context/plan.md updated
Sprint plan: [docs/temp-sprint<N>-plan.md](docs/temp-sprint<N>-plan.md)

Next step: review the tracks, then dispatch work.
```

Format defined in `docs/context/plan-doc-format.md`.

**Execution receipt:** On successful completion of all steps above, append one line to `docs/context/skill-receipts.jsonl` (create the file if absent):
```json
{"skill":"start-sprint","timestamp":"<ISO-8601 timestamp>","sprint":"<sprint-id>","version":"<release-version>","flags":[]}
```
- `timestamp`: current ISO-8601 datetime (e.g. `2026-09-02T14:30:00Z`)
- `sprint`: read from `docs/context/plan.md` — match `## Current Sprint: <ID>` (e.g. `S81`); if not found use `"unknown"`
- `version`: read `release-version` from `skills-manifest.json` in the project root; if not found use `"unknown"`
- Append only — never overwrite. Create the file and any missing parent directories silently if absent.