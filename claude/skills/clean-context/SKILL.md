---
name: clean-context
description: Sanitize the project environment — archive scratchpads, remove merged worktrees and branches, update Context Health in tracks.md. Bail if uncommitted work is detected.
---

## Safety check

Run `git status`. If there is any uncommitted work in the current branch, **bail immediately** with a warning and do not proceed.

Run `git worktree list`. Note any dirty worktrees (other than the main one) — these are not an immediate bail condition. Each dirty worktree is evaluated individually in the Merged worktree sweep below: if its branch is merged into `main`, it will be force-removed with a log line; if its branch is NOT merged (or branch state cannot be determined), the existing bail logic fires at that point.

Only continue when the uncommitted-work check passes.

## Scratchpad and temp-artifact archival

Scan for `scratchpad_*.md` files and temporary build artifacts in the project root and subdirectories.

Also scan for `docs/temp-*.md` files — this project uses the `temp-*.md` naming convention under `docs/` for sprint plans, interview docs, and other sprint-scoped artifacts. Apply the same lifecycle logic:

- **Temp documents** (sprint-scoped, disposable after sprint close): move to `docs/archive/` or delete per the instructions below.
- **Permanent documents**: skip entirely — do not archive or delete.

**Exclusions (never touch):**
- `docs/archive/**` — already archived; skip.
- `docs/context/temp-architectural-assessment.md` — permanent artifact despite the `temp-` prefix; skip.

**How to distinguish temp from permanent for `docs/temp-*.md` files:**
- If the file's sprint is closed (sprint appears in `docs/context/plan.md` Completed Sprint sections OR in `docs/archive/plan-docs/`), treat as temp → archive to `docs/archive/` or delete if content has no residual value.
- If the sprint is still active, or the file cannot be attributed to a sprint, treat as permanent → skip.

Move `docs/temp-*.md` files for closed sprints to `docs/archive/` (creating the directory if absent) or delete them if the project policy is to delete and the file has no useful content. Log each action.

Move `scratchpad_*.md` files to `.agent/archives/` per project policy, or delete if the project has no archive directory and the file has no useful content. Log each action.

## Open-PR guard (warn-only)

Belt-and-suspenders check: warn if any pull requests are still open against
`feature/*` branches before the worktree and branch sweeps run. This is a
**warning only** — it never bails and never blocks cleanup, and it degrades
silently when GitHub CLI is unavailable.

1. If `gh` is not installed, skip this section entirely — no output:
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

3. If the command produced no output — emit nothing and continue to the
   Merged worktree sweep.

4. If the command produced one or more lines, print this warning, then continue
   (cleanup does NOT stop):
   ```
   Warning: the following PRs are still open against feature/* branches. Cleanup will continue, but their branches will not be swept until the PRs are merged or closed:

   <captured lines>
   ```

## Merged worktree sweep

For each directory under `.claude/worktrees/` (and `.worktrees/` if present), check whether its branch is merged into `main`. Resolve `<repo-root>` from `$CLAUDE_PROJECT_DIR` or `pwd` at the start of this step.

```
git -C <repo-root> branch --merged main
```

**For clean (non-dirty) worktrees:** if merged, run `git -C <repo-root> worktree remove <path>` and log it. If not merged, log and skip.

**For dirty worktrees**, apply the following three-case logic before taking any action:

1. **Determine the worktree's branch.** Run `git -C <repo-root> -C <path> branch --show-current` to get the branch name.

2. **If the branch is in `git -C <repo-root> branch --merged main` output (branch is merged):**
   Force-remove the worktree:
   ```
   git -C <repo-root> worktree remove --force <path>
   ```
   Then emit a mandatory log line in exactly this format:
   ```
   force-removed merged worktree: <path> (branch: <branch-name>, last commit: <SHA>)
   ```
   where `<SHA>` is the output of `git -C <repo-root> -C <path> rev-parse --short HEAD` captured before removal. Continue to the next worktree.

3. **If the branch is NOT in `git -C <repo-root> branch --merged main` output (branch is not merged):**
   Bail with a warning naming the affected worktree:
   > `Worktree <path> is dirty and its branch (<branch-name>) is not merged into main. Resolve or commit the work before running /clean-context.`
   Stop the cleanup phase.

4. **If branch state cannot be determined** (e.g. detached HEAD, `git -C <repo-root> -C <path> branch --show-current` returns empty, or the git command errors):
   Treat as "not merged" and bail per the existing logic above. Do NOT auto-force-remove a worktree whose branch state is ambiguous.

The log line on every force-remove is **mandatory**. Without it, the user has no audit trail of what was destroyed. Log to stdout so the line appears in the cleanup summary.

Log any skipped worktrees (non-merged or ambiguous) with the reason.

## Merged branch sweep

Run `git branch --merged main`. Delete every `feature/*` branch that appears:

```
git branch -d <branch>
```

**Never use `-D` (force-delete).** If a branch is not fully merged, log it and skip.

## Bridge file sweep

Delete all files in `docs/bridges/` except `README.md`. Bridge files (both `*-bridge.md` and `*-signoff.md`) are working documents — once a sprint is closed and its tracks are merged to `main`, git history is the complete audit record. No archival is needed; deletion is the policy.

This step runs **unconditionally** at clean-context time — it does not check sprint boundaries. Any bridge file present at clean-context time is by definition from a closed sprint, because clean-context only runs after sprint close.

Steps:

1. Check that `docs/bridges/` exists. If absent, log `docs/bridges/ not found — skipping` and continue without error.
2. Delete all files in `docs/bridges/` except `README.md`:
   ```
   find docs/bridges/ -maxdepth 1 -type f ! -name 'README.md' -delete
   ```
3. Stage the deletions:
   ```
   git add -A docs/bridges/
   ```
4. Log the count of files deleted. If zero, log `docs/bridges/ — no bridge files to delete`.

**Archive bridge cleanup:** `docs/archive/bridges/` accumulated files from an earlier archival policy that has since been replaced by deletion. Run this sub-step unconditionally after the main bridge sweep:

1. Check whether `docs/archive/bridges/` exists.
2. If it exists, remove the entire directory:
   ```
   git rm -r docs/archive/bridges/
   ```
   Log: `docs/archive/bridges/ removed (N files) — git history is the audit record`
3. If it does not exist, log `docs/archive/bridges/ not found — skipping` and continue.

## Collapse closed sprint in context files

Run after the Bridge file sweep and before the Memory hygiene scan. This step collapses the just-closed sprint's full content in `docs/context/plan.md` and `docs/context/tracks.md` down to one-line pointers, so context files do not accumulate every sprint's full content indefinitely.

1. **Find the sprint number.** Read `docs/context/plan.md` and locate the `## Current Sprint: SN —` heading. Extract the sprint number `N` from it (the integer after `S`).

2. **Verify the archive exists.** Confirm `docs/archive/plan-docs/SN.md` exists.
   - **If it does NOT exist, bail this step immediately** with the warning:
     ```
     Sprint SN archive not found at docs/archive/plan-docs/SN.md — cannot collapse context files. Run /clean-context only after the sprint has been archived.
     ```
     Do not touch either file. Do not stage anything. Continue to the next step of the skill (Memory hygiene scan) — bailing this step does not abort the whole run.

3. **If the archive exists, collapse both files:**

   a. **`docs/context/plan.md`:** Replace the entire `## Current Sprint: SN` block — from the `## Current Sprint: SN —` heading line through the blank line immediately before the next line that begins with `## ` or `---`, including all goal checkboxes and any trailing content under it — with this single line:
      ```
      ## Completed Sprint: SN ✓ — see docs/archive/plan-docs/SN.md
      ```

   b. **`docs/context/tracks.md`:** Replace the entire `## Sprint N Tracks` block — from the `## Sprint N Tracks` heading line through the blank line immediately before the next line that begins with `## ` or `---`, including all track entries and any trailing content under it — with this single line:
      ```
      ## Sprint N Tracks ✓ — see docs/archive/plan-docs/SN.md
      ```

   Replace only the single named block in each file. Stop at the first boundary (`## ` heading or `---` divider). Never delete past it during this sub-step — the rolling-window prune in step 6 handles removal of older pointer lines.

4. **Stage both files:**
   ```
   git add docs/context/plan.md docs/context/tracks.md
   ```

5. **Log:** `Collapsed Sprint SN in plan.md and tracks.md`

6. **Prune old pointer lines in `docs/context/plan.md` (rolling-window enforcement):** After collapsing, retain only the 3 most-recent `## Completed Sprint` pointer lines (S(N), S(N-1), S(N-2)); remove all older pointer lines. If the footer line `*Older sprints: see docs/archive/plan-docs/ — rolling window keeps last 3 completed sprints.*` is not already present at the end of the file, append it. Stage the result: `git add docs/context/plan.md`. Log: `Pruned plan.md to rolling window — kept S(N), S(N-1), S(N-2).`

## Memory hygiene scan

Run after the merged-branch sweep and before the Context Health update.

Locate the memory directory at `~/.claude/projects/<sanitized-cwd>/memory/` where `<sanitized-cwd>` is the value of `CLAUDE_PROJECT_DIR` (or current working directory) with the leading `/` stripped and all remaining `/` replaced with `-`.

If the memory directory does not exist, print `Memory hygiene scan: no memory directory found at <path> — skipping` and continue without error.

### File classification

For each file in the memory directory (excluding `MEMORY.md` itself), classify by filename prefix:

- **`reference_*`** — reference memory (pointers to external systems)
- **`feedback_*`** — feedback memory (behavioral rules)
- **`project_*`** — project memory (sprint/initiative state)
- **unclassified** — any file not matching the above prefixes

### Per-category staleness policy

**`reference_*` — never auto-flag for prune.** Only flag as `RETIRE candidate` if the concrete artifact referenced in the body no longer exists at that path.

**`feedback_*` — never auto-flag for prune.** Only flag as `RETIRE candidate` if the behavioral rule has been codified verbatim into any `claude/agents/*.md` or any `claude/skills/**/SKILL.md` (i.e. the rule is now enforced as a system constraint and the memory file is redundant).

**`project_*` — flag as `RETIRE candidate` only if BOTH of the following signals are present (two-signal rule):**
1. The sprint referenced in the file (extracted from the `Created:` field or body content) closed more than **3 sprints ago**, relative to the most recently closed sprint. Determine the most recently closed sprint by reading the first `## Completed Sprint: S<N> ✓` line from `docs/context/plan.md`. Count backwards 3 sprints from that number — any `project_*` file referencing a sprint ≤ (N-3) is a stale candidate. Files with no sprint reference fall through to Signal 2.
2. The referenced sprint is archived (appears in `docs/context/plan.md` Completed Sprint sections OR in `docs/archive/plan-docs/`), OR the file contains no sprint reference AND is not referenced in `MEMORY.md`'s index.

A single signal alone is **not sufficient** to flag a `project_*` file. Both signals must be independently satisfied.

If the `Created:` field is missing, surface the file as `stale-undatable` — the two-signal rule still applies.

**Unclassified — never auto-flag.** Surface as `manual review required` with no action proposed.

### Report format

Print findings as a markdown table:

| File | Category | Stale signals matched | Action proposed |
|---|---|---|---|
| `path/to/file.md` — first-line summary | reference / feedback / project / unclassified | explicit list | RETAIN / RETIRE candidate / MERGE candidate (duplicate of X) / manual review required |

If no findings: print `Memory hygiene scan: no findings — all memory files current.`

### Hard constraints

**Never delete any memory file.** This step is read-only with respect to memory file content and existence. The Conductor decides whether to mark a candidate `STATUS: retired`.

When the Conductor approves a retirement, the skill writes two lines into the file in-place (no deletion):
```
STATUS: retired — <one-line reason>
Retired: YYYY-MM-DD
```
The file remains on disk as part of the learning record.

### Tombstone retirement workflow

After the report is displayed, ask: "Approve any retirements? (list file numbers, or 'none')"

For each approved file:
1. Write `STATUS: retired — <reason from Conductor>` and `Retired: YYYY-MM-DD` as the first content lines.
2. Print confirmation: `Retired: <filename>`.
3. Do NOT delete the file.
4. Remove the corresponding index entry from `MEMORY.md`: locate the line that references `<filename>` (format: `- [title](<filename>) — ...`) and delete it. Stage the change with `git add <memory-dir>/MEMORY.md`. This prevents the index from containing a dangling pointer to a retired file.

For declined files: log as `Retained — Conductor decision`.

## Canonical file scope

Canonical agent files (`claude/agents/*.md`) and skill files (`claude/skills/*/SKILL.md`) are eligible for stale content removal when they contain stale cross-references, dead protocol sections, or redundant content. These files are protected by the hook layer, not by verbosity — removal of outdated content is safe.

## Backlog file check

Confirm `docs/backlog.md` exists. This file is the standalone backlog owned by the orchestrator and Conductor — do not archive or delete it.

If `docs/backlog.md` is absent, print a warning: `docs/backlog.md not found — backlog file is missing. Expected at docs/backlog.md.`

If present, log: `docs/backlog.md present — no action taken (presence-check only).`

**Do not modify the file contents.** This step is read-only and verification-only.

## Context Health update

Open `docs/context/tracks.md`. Update the "Context Health" status line to reflect the current state (branches pruned, worktrees removed, scratchpads archived, memory hygiene scan run). Record the date.

## Push to origin

Run `git push origin main`. This triggers the distribute workflow on the private repo and syncs the public mirror. If the push fails (e.g. remote has diverged), surface the error to the Conductor — do not force-push.

## Verification checklist

- Safety gate fires: skill refuses to proceed when `git status` shows uncommitted work on the current branch.
- Dirty worktrees whose branch IS merged into `main` are force-removed with the mandatory log line in the format `force-removed merged worktree: <path> (branch: <branch-name>, last commit: <SHA>)` using `git -C <repo-root> worktree remove --force <path>`.
- Dirty worktrees whose branch is NOT merged into `main` trigger the bail with a warning naming the affected worktree — cleanup stops.
- Dirty worktrees with ambiguous branch state (detached HEAD, empty branch output, or git error) are treated as "not merged" and trigger the bail — cleanup stops.
- `scratchpad_*.md` files were moved or deleted; `.agent/archives/` updated where applicable.
- `docs/temp-*.md` files for closed sprints were archived to `docs/archive/` or deleted; `docs/archive/**` and `docs/context/temp-architectural-assessment.md` were never touched.
- Merged worktrees under `.claude/worktrees/` (and `.worktrees/` if present) were removed via `git -C <repo-root> worktree remove <path>`; unmerged ones were logged and skipped.
- No `feature/*` branch that was already merged to `main` remains; unmerged ones were logged.
- Open-PR guard: warned when open PRs target `feature/*` branches, or emitted nothing when none matched / `gh` unavailable; never bailed.
- Memory hygiene scan: the pruning report fired (or "no findings" was printed); no memory file was deleted.
- `tracks.md` Context Health entry updated with the current date.
- `git push origin main` was run successfully (or surfaced to Conductor on failure with no force-push attempt).
- `docs/bridges/` was swept: all bridge/sign-off files deleted except `README.md`, and deletions staged with `git add -A docs/bridges/` — or `docs/bridges/ not found — skipping` / `no bridge files to delete` was logged when applicable.
- `docs/archive/bridges/` was removed via `git rm -r` with file count logged — or `docs/archive/bridges/ not found — skipping` was logged when absent.
- `docs/context/plan.md` current sprint section collapsed to one-line pointer (or bail message printed when archive absent).
- `docs/context/tracks.md` current sprint tracks section collapsed to one-line pointer (or bail message printed when archive absent).
