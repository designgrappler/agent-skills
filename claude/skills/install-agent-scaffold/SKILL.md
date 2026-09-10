---
name: install-agent-scaffold
description: Bootstraps a new project with the Agent OS structure.
---
# Install Agent Scaffold
Bootstraps a new project with the Agent OS structure. Drops a setup file for the user to fill in — no files are generated until it's complete.

> **Existing project?** Stop. Use `/onboard-existing-project` instead. This skill assumes a blank slate.

## Trigger
When the user runs `/install-agent-scaffold`.

---

## Step 0 — Choose Project Folder

Runs before ALL pre-flight checks, git detection, and file creation.

**If `agent-setup.yml` already exists in the current folder**, setup is mid-flight — do not re-prompt. Read `project_root:` from it, set `PROJECT_ROOT` to that value, and skip to Step 1.

Otherwise, ask the user:

> **Where would you like to set up your project?** Enter a folder path, or press Enter to use the current folder. Example: `~/Projects/my-project`
>
> **VS Code users:** if you opened your target folder in VS Code before running this skill, just press Enter — that folder is already the working directory.

Resolve the answer into `PROJECT_ROOT` (always an absolute path) and `FOLDER_CREATED`:

- **Empty / Enter pressed:** run `pwd`; set `PROJECT_ROOT` to its output, `FOLDER_CREATED=false`.
- **A path is provided:** expand a leading `~` to `$HOME`, resolve to absolute, then check whether it exists and is empty/non-empty/missing:
  - **Missing** → confirm: "`[TARGET]` doesn't exist. Create it and install there? (yes/no)". On **yes**: `mkdir -p "$TARGET"`, set `PROJECT_ROOT="$TARGET"`, `FOLDER_CREATED=true`. On **no**: stop.
  - **Exists, non-empty** → warn: "`[TARGET]` already exists and is not empty — installing here mixes Agent OS files with existing content. Continue? (yes/no)". On **yes**: `PROJECT_ROOT="$TARGET"`, `FOLDER_CREATED=false`. On **no**: stop.
  - **Exists, empty** → `PROJECT_ROOT="$TARGET"`, `FOLDER_CREATED=false`.

`PROJECT_ROOT` is the root for every subsequent step. Every bash block in subsequent steps must begin with `cd "$PROJECT_ROOT"`. Every Write/Edit must target an absolute path under `$PROJECT_ROOT`.

---

## Step 1: Pre-flight

**Working directory check (runs before anything else).** Run:

```bash
pwd
```

Validate the result. Stop immediately if cwd matches any of these:
- `/`
- `/Users` or `/home`
- The user's home directory exactly (matches `$HOME`)

If cwd is on that list:
> **Install location looks wrong.**
>
> Agent OS is about to install into `[cwd]`, which is not a project folder.
>
> To fix: open a specific project folder in VS Code (File → Open Folder), then re-run `/install-agent-scaffold`. Or tell me the path you want to install into and I'll use that instead.

Stop. Do not proceed until the user either opens a project folder or confirms a target path.

If cwd is NOT on the blocklist, proceed.

**Git detection (always run first).** Check whether the current folder is inside a git repository:

```bash
git rev-parse --git-dir 2>/dev/null
```

- **If the command succeeds (exit 0):** set `GIT_PRESENT=true`. Proceed normally.
- **If the command fails (non-zero exit):** set `GIT_PRESENT=false`. Continue installation with the following adjustments active throughout:
  - In Step 4a (`CLAUDE.md`): omit the `## Worktree Protocol` section and `## Sprint Workflow` section. In their place, emit:
    ```
    > **Note:** No git repo detected — sprint workflow and worktree isolation are unavailable in this session. Run `git init` to activate the full Agent OS feature set on next session start. No reinstall needed — all `.claude/` files remain valid.
    ```
  - In Step 4g (`.claude/settings.json`): omit the `worktree.baseRef` field from the generated JSON.
  - In Step 4h (`.gitignore` additions): skip this step — no git repo means no `.gitignore` to update.
  - In Step 6 (Confirm output): add a notice line: `**Git repo:** Not detected — sprint workflow and worktree isolation unavailable. Run \`git init\` to enable the full feature set on next session start.`

Run these checks in order — stop at the first match:

```bash
[ -f CLAUDE.md ] && grep -q "## Orchestrator Behavior" CLAUDE.md && echo "INITIALIZED"
[ -f AgentOS-Setup.md ] && echo "SETUP_EXISTS"
[ -f agent-setup.yml ]  && echo "YML_EXISTS"
```

- If output contains `INITIALIZED` → stop. Tell the user this project is already initialized. Suggest `/onboard-existing-project`.
- If output contains neither `SETUP_EXISTS` nor `YML_EXISTS` → go to Step 2.
- If output contains `SETUP_EXISTS` but not `YML_EXISTS` → go to Step 2b.
- If output contains both `SETUP_EXISTS` and `YML_EXISTS` → go to Step 3.

---

## Step 2: Drop Setup Files

Write `AgentOS-Setup.md` to the project root (content below). Also write `agent-setup.yml` to the project root (content below). Then stop and tell the user:

> **Step 1 of 2 complete — setup files created.**
>
> Fill in your project details:
> - **`AgentOS-Setup.md`** — your project name, tech stack, and optional doc migration
> - **`agent-setup.yml`** — your model tier and provider (edit the values, comments explain the options)
>
> When you're done filling in both files, run `/install-agent-scaffold` again. Step 2 will generate: `CLAUDE.md`, agent definitions, `docs/context/` files, and `skills-manifest.json`.

`AgentOS-Setup.md` content:
```markdown
# Agent OS Setup

Fill in the fields below, then run `/install-agent-scaffold` in Claude Code.
This file will be deleted automatically when setup is complete.

---

## Project

**Project name:** 
**Short description:** 

---

## Define Your Tech Stack

Defaults are pre-selected. Replace any value you want to change. Leave blank to skip optional fields.

**Runtime:** Node.js <!-- alternatives: Bun · Python · Go · Deno -->
**Framework:** Express <!-- alternatives: Hono · FastAPI (Python) · Gin (Go) · Koa -->
**Database:** PostgreSQL via Supabase <!-- alternatives: PlanetScale · MongoDB · SQLite · leave blank if none -->
**Frontend framework:** React + Vite <!-- alternatives: Next.js · SvelteKit · Nuxt · Remix · leave blank if none -->
**Styling:** Tailwind CSS <!-- alternatives: CSS Modules · Styled Components · Sass · leave blank if none -->
**Build command:** npm run build <!-- alternatives: bun run build · python -m build -->
**Type check command:** <!-- e.g. bunx tsc --noEmit · mypy · leave blank if none -->
**Linter:** ESLint + Prettier <!-- alternatives: Biome · Ruff (Python) · leave blank if none -->

---

## Existing docs to migrate *(optional)*

Update the paths below to match your actual files. Delete rows that don't apply.

| Current file | Maps to |
|---|---|
| README.md | docs/context/product.md |
| [roadmap, backlog, or requirements doc] | docs/context/plan.md |
| [design spec or product brief] | docs/context/product.md |
| [sprint notes or task list] | docs/context/tracks.md |

---

## Tools / Connectors (optional)

List any MCP servers or external tools you use. Leave blank to add later.

> Entries here are written to `~/.claude/connectors.md` (global — shared across all your projects) and symlinked into this project at `docs/context/connectors.md`.
> If `~/.claude/connectors.md` already exists, it will not be overwritten — add new entries to it manually after setup.

| Name | Type | Command | Purpose | Notes |
|------|------|---------|---------|-------|
|      |      |         |         |       |
```

`agent-setup.yml` content:
```yaml
# Agent OS — Install Configuration
# Fill in values below, then re-run /install-agent-scaffold

# model_tier: tier of model to use for this agent
# Options: fast | balanced | powerful
# fast = lightweight/mechanical tasks, balanced = default, powerful = reasoning-heavy tasks
model_tier: balanced

# provider: AI provider for this agent (optional — omit or leave blank for default Anthropic/Claude)
# Options: anthropic (default) | google | openai | other
# If "other", replace with your provider's identifier string
provider: anthropic

# project root: absolute path where this project is installed (recorded at install time)
project_root: "$PROJECT_ROOT"
```

Stop here. Do not generate any other files.

---

## Step 2b: Missing agent-setup.yml (edge case)

Reached only when `AgentOS-Setup.md` exists but `agent-setup.yml` does not.

Write the following content to `agent-setup.yml` at the project root:

```yaml
# Agent OS — Install Configuration
# Fill in values below, then re-run /install-agent-scaffold

# model_tier: tier of model to use for this agent
# Options: fast | balanced | powerful
# fast = lightweight/mechanical tasks, balanced = default, powerful = reasoning-heavy tasks
model_tier: balanced

# provider: AI provider for this agent (optional — omit or leave blank for default Anthropic/Claude)
# Options: anthropic (default) | google | openai | other
# If "other", replace with your provider's identifier string
provider: anthropic

# project root: absolute path where this project is installed (recorded at install time)
project_root: "$PROJECT_ROOT"
```

Then stop and tell the user:

> **`agent-setup.yml` created.** Confirm the `model_tier` and `provider` values look right, then re-run `/install-agent-scaffold`.

---

## Step 3: Parse AgentOS-Setup.md and agent-setup.yml

Read `AgentOS-Setup.md`. Extract values as follows.

**Project fields** — read `**Project name:**` and `**Short description:**`, take the value after the colon.

**Tech stack fields** — for each `**Field:** value <!-- comment -->` line, take the text between `:` and `<!--` (trim whitespace). If blank, the field is not configured.

**Docs migration** — for each row in the migration table where the "Current file" cell is not a placeholder (not blank, not bracketed), record `{from: "path", to: "docs/context/X.md"}`.

**Extracted values:**
- `NAME` = Project name
- `DESCRIPTION` = Short description
- `RUNTIME`, `FRAMEWORK`, `DATABASE`, `FRONTEND`, `STYLING`, `BUILD_CMD`, `TYPECHECK_CMD`, `LINTER`
- `MIGRATIONS` = list of confirmed doc migration pairs

**Validation** — stop and list what's missing if any of these are blank:
- `NAME`, `DESCRIPTION`, `BUILD_CMD`

Read `agent-setup.yml`. Extract provider and tier as follows.

**`model_tier`** — read the `model_tier:` value (trim whitespace, strip inline comments).
- Valid values: `fast`, `balanced`, `powerful`.
- If missing or not one of the three valid values → stop and tell the user: "Fill in `agent-setup.yml`: `model_tier` must be `fast`, `balanced`, or `powerful`."

**`provider`** — read the `provider:` value (trim whitespace, strip inline comments).
- If the field is absent, blank, or the value is `anthropic` → treat as default; set `PROVIDER` = `anthropic`.
- Any other non-empty value → set `PROVIDER` = that value.

**Map `model_tier` to agent frontmatter alias:**
- `fast` → `haiku`
- `balanced` → `sonnet`
- `powerful` → `opus`

Store the resolved alias as `MODEL_ALIAS`.

If all required values are present → proceed to Step 3b.

---

## Step 3b: Pre-Generation Roster Validation

Run this step using the values extracted in Step 3 (`NAME`, `DESCRIPTION`, `RUNTIME`, `FRONTEND`, `DATABASE`, `BUILD_CMD`). This step fires after parsing and before any file is written.

Evaluate each check below. A check triggers when its condition is true.

**Check 1 — Frontend specialist missing for UI project**
Condition: `DESCRIPTION` contains any of `web app`, `SaaS`, `website`, `frontend`, `UI`, `dashboard`, `interface`, `portal` (case-insensitive) AND `FRONTEND` is blank.
Flag: "Web/UI project description but no frontend framework configured — a frontend specialist may have nothing to own."

**Check 2 — Database specialist missing for data-heavy project**
Condition: `DESCRIPTION` contains any of `API`, `data pipeline`, `database`, `backend`, `data store`, `persistence`, `storage` (case-insensitive) AND `DATABASE` is blank.
Flag: "Data/API project description but no database configured — a database specialist may have nothing to own."

**Check 3 — Lean roster for single-responsibility repo**
Condition: `FRONTEND` is blank AND `DATABASE` is blank AND `DESCRIPTION` contains any of `tool`, `CLI`, `library`, `protocol`, `utility`, `script`, `plugin` (case-insensitive).
Flag: "Single-responsibility repo detected (no frontend, no database). The full specialist roster will be installed but specialists may have limited scope — confirm the lean setup is intentional."

**Check 4 — Runtime / build command mismatch**
Condition: (`RUNTIME` contains `Python` AND `BUILD_CMD` contains `npm`, `npx`, or `node`) OR (`RUNTIME` contains `Node`, `Bun`, `JavaScript`, or `TypeScript` AND `BUILD_CMD` contains `python` or `pip`).
Flag: "Runtime is `[RUNTIME]` but build command is `[BUILD_CMD]` — this combination looks unusual."

**If one or more checks triggered:**

Surface all triggered flags as a bulleted list, then ask:

> **Roster check — [count] item(s) to confirm:**
>
> - [triggered flag 1]
> - [triggered flag 2 if applicable]
>
> These role/stack combinations look unusual — confirm they're intentional or amend the roster before generation proceeds. Reply `confirm` to proceed as-is, or update `AgentOS-Setup.md` and re-run `/install-agent-scaffold`.

Stop. Do not proceed to Step 4 until the user replies `confirm` or re-runs the skill with an amended setup file.

**If no checks triggered:** proceed to Step 4 silently — no output, no prompt.

---

## Step 4: Generate Files

Create all files below. Before writing each file, run `[ -f <path> ] && echo "EXISTS"`. If output is `EXISTS`, show the diff between the existing file and the new content and ask: merge, replace, or skip.

> **Note:** `task.md` is NOT created during scaffold. It is created by the orchestrator at session start when ephemeral mode is detected. Scaffold creates `product.md` for new project initialization only.

---

### Model and provider guidance (read before generating any agent)

Every generated agent file uses the `MODEL_ALIAS` resolved in Step 3. Emit `model: <MODEL_ALIAS>` in all agent frontmatter.

Only emit `provider: <PROVIDER>` when `PROVIDER` is not `anthropic`. Omit the `provider:` field entirely for the default Anthropic setup — this keeps existing installs clean.

Examples:
- `model_tier: balanced` + `provider: anthropic` → emit `model: sonnet` only (no `provider:` line)
- `model_tier: powerful` + `provider: google` → emit `model: opus` and `provider: google`

Default tier-to-role mapping (override with `MODEL_ALIAS` from `agent-setup.yml`):

| Role | Default Tier |
|---|---|
| Technical Architect | `opus` — heavy reasoning, plan synthesis |
| Orchestrator / Specialist / QA | `sonnet` — standard execution |
| Lightweight / fast tasks | `haiku` — quick lookups, reformatting |

When `agent-setup.yml` specifies a tier, use `MODEL_ALIAS` for all generated agents (overrides the default role-based tiers above).

---

### 4a. `CLAUDE.md`

```markdown
# [NAME] — Claude Code Configuration

## Team

| Role | Function |
|---|---|
| **Tim** | Owner — vision and approval |
| **Orchestrator** | Routes tasks, triage decisions |
| **Specialist** | Domain expert for complex tasks |
| **Task Agent** | Executes scoped work |
| **QA** | Read-only quality gate |

Agents are defined in `.claude/agents/`.

---

## Orchestrator Behavior

Orchestrator behavior is defined in `claude/skills/orchestrator/SKILL.md` — loaded at session start.

---

## Sprint Workflow

Sprint workflow: invoke `/start-sprint` to enter sprint mode.

---

## Tech Stack

- **Runtime:** [RUNTIME]
- **Framework:** [FRAMEWORK]
- **Database:** [DATABASE or "none configured"]
- **Frontend:** [FRONTEND or "none configured"]
- **Styling:** [STYLING or "none configured"]
- **Build Command:** `[BUILD_CMD]`
- **Type Check:** [TYPECHECK_CMD or "none configured"]
- **Linter:** [LINTER or "none configured"]

---

## Worktree Protocol

Worktree isolation is automatic via agent frontmatter (`isolation: worktree`) and `.claude/settings.json` (`worktree.baseRef: "head"`). No manual git commands needed.

---

## Hooks

Stop hook: prints hygiene reminder at session end.
```

---

### 4b. `claude/skills/orchestrator/SKILL.md`

Copy from the canonical source at `claude/skills/orchestrator/SKILL.md`. This is a verbatim copy — do not modify its content.

---

### 4c. `.claude/agents/` — Global prerequisite check

Before writing any other project files, verify that the global Agent OS layer is installed:

Run:

```bash
ls ~/.claude/agents/*.md 2>/dev/null | head -1
```

- **If output is empty:** stop immediately and surface:
  > "Global Agent OS layer not found at `~/.claude/agents/`. Run `/update-agent-os` to install the canonical agent set before scaffolding a project."
  Do not proceed to 4d or any subsequent step.
- **If output shows a file:** continue to 4d. No agent files are copied to `.claude/agents/` — canonical agents live in `~/.claude/agents/` and are available globally.

---

### 4d. `docs/context/plan.md`

If a migration source was confirmed for `plan.md`, copy that file and prepend:
```
<!-- Migrated from [original path] — review and update stale content. -->
```
Otherwise create:

```markdown
# [NAME] — Active Plan

## Current Sprint: Initial Setup

- [ ] Review CLAUDE.md and confirm the team configuration looks right.
- [ ] Open your first sprint with `/start-sprint`.

---

*Last updated: [TODAY'S DATE]*
```

---

### 4e. `docs/context/tracks.md`

```markdown
# Active Tracks

No active tracks. Add tracks as work begins.

---

*Last updated: [TODAY'S DATE]*
```

---

### 4f. `skills-manifest.json`

Create `skills-manifest.json` at the project root pointing to the canonical registry:

```json
{
  "canonical-registry": "https://raw.githubusercontent.com/designgrappler/agent-os/main/skills-manifest.json",
  "release-version": "v2.0.0"
}
```

---

### 4g. `.claude/settings.json`

Run `[ -f .claude/settings.json ] && echo "EXISTS"`. If output is `EXISTS`, merge the canonical fields below into the existing file — do not remove existing entries. Otherwise create:

```json
{
  "worktree": {
    "baseRef": "head"
  },
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Session ended. Reminder: archive completed tracks, verify plan.md is current, confirm no uncommitted changes.'"
          }
        ]
      }
    ]
  },
  "permissions": {
    "defaultMode": "default",
    "allow": [
      "Bash(git status)",
      "Bash(git diff *)",
      "Bash(git log *)",
      "Bash(git branch *)",
      "Bash(find *)",
      "Bash(grep *)"
    ]
  }
}
```

**Settings.json tiers (canonical vs project-specific).** The `.claude/settings.json` this step writes contains two tiers of fields:

- **Canonical tier** — part of the distributed Agent OS system, identical across installs: `worktree.baseRef` and the standard `Stop` hook (both written above). `operatingMode`, when present, is canonical but is managed by `/streamline-approvals`, not by this scaffold.
- **Project-specific tier** — owned by the user, never overwritten by any Agent OS skill: `permissions` (allow/deny lists), user-added custom hooks, and any `mcpServers` entries.

This scaffold supplies the canonical tier once, at install. `/update-agent-os` patches a **canonical** field into an existing `.claude/settings.json` only when that field is **absent** (e.g. `worktree.baseRef` or the standard `Stop` hook is missing) — it never overwrites a canonical field that is already present, and it never touches a project-specific field. The project-specific tier is always the user's to own.

---

### 4h. `.gitignore` additions

Run:
```bash
grep -q "\.worktrees/" .gitignore 2>/dev/null && echo "HAVE_WORKTREES"
grep -q "settings\.local\.json" .gitignore 2>/dev/null && echo "HAVE_LOCAL"
```
Append only the lines whose marker is absent from the output:
```
.worktrees/
.claude/settings.local.json
```

---

### 4i. `~/.claude/connectors.md`

Check whether the connectors table in `AgentOS-Setup.md` has any filled rows (rows where the `Name` cell is not blank):

- **If rows are filled:** create `~/.claude/connectors.md` with the following structure, using the entries from the filled table rows. Set `Status` to `active` for each entry. Before writing, run `[ -f ~/.claude/connectors.md ] && echo "EXISTS"`. If output is `EXISTS`, skip silently and log: `~/.claude/connectors.md already exists — skipped.`

  ```markdown
  # Connectors

  ## [name from table]
  - **Type:** [type]
  - **Command:** [command from table, or blank]
  - **Purpose:** [purpose]
  - **Status:** active
  - **Notes:** [notes or blank]
  ```

- **If table is empty or all rows blank:** skip silently. Do not create the file.

---

### 4i-b. Connectors symlink

After writing (or skipping) `~/.claude/connectors.md`:

1. Create a symlink for in-project access:
   ```bash
   ln -sf ~/.claude/connectors.md docs/context/connectors.md
   ```
   Run `[ -L docs/context/connectors.md ] && echo "EXISTS"`. If output is `EXISTS`, skip silently.
2. Run `grep -q "docs/context/connectors.md" .gitignore 2>/dev/null && echo "HAVE_CONNECTORS"`. If output is absent, append:
   ```
   docs/context/connectors.md
   ```

---

### 4j. Delete setup files

After all files are created successfully, delete both `AgentOS-Setup.md` and `agent-setup.yml`.

---

## Coupled-file contract

`install-agent-scaffold` (install path) and `update-agent-os` (update path) govern the same distributed system from two directions. They are a **coupled pair**:

- Any change that adds, removes, or renames a **canonical** field in the `.claude/settings.json` template (section 4g above), or adds/removes a scaffold-generated canonical file, MUST be reflected in `update-agent-os/SKILL.md` so the install and update paths stay in sync — and vice versa.
- **Hash manifest files** (`~/.claude/agent-os-manifest.json` for global skills/agents; `.claude/agent-os-manifest.json` for project hooks) are written exclusively by `update-agent-os` Phase 5. This scaffold does not write to the manifest directly — global skills and agents are installed by `/update-agent-os`, which records the base hash at that time. This note satisfies the coupled-file contract acknowledgement that both files reference the manifest write targets.
- **QA directive:** when either `install-agent-scaffold/SKILL.md` or `update-agent-os/SKILL.md` is in a track's scope, the reviewer must open the coupled file and confirm it needs no matching change. Changing one without a recorded decision on the other is a review failure.

---

## Step 5: Verify Installation

Run these exact commands and capture all output:

```bash
[ -f CLAUDE.md ] && grep -q "## Orchestrator Behavior" CLAUDE.md && echo "CHECK:claude_md:PASS"     || echo "CHECK:claude_md:FAIL"
[ -s claude/skills/orchestrator/SKILL.md ]                        && echo "CHECK:orchestrator:PASS" || echo "CHECK:orchestrator:FAIL"
ls ~/.claude/agents/*.md 2>/dev/null | head -1 | grep -q .        && echo "CHECK:agents:PASS"       || echo "CHECK:agents:FAIL"
[ -f skills-manifest.json ]                                        && echo "CHECK:manifest:PASS"     || echo "CHECK:manifest:FAIL"
```

For every line containing `FAIL`, surface the specific check that failed. Do not print the Step 6 confirmation until all four lines contain `PASS`.

---

## Step 6: Confirm

```
## Agent OS Installed

**Project:** [NAME]
**Files created:** [count]
**Project folder:** $PROJECT_ROOT[  ← created new folder (first-time install)]

**Next steps:**
1. Review CLAUDE.md — confirm tech stack is correct.
2. Open your first sprint with `/start-sprint`.
3. Run `[BUILD_CMD]` to confirm the build environment is clean.

**Activate skills:** Close and reopen your IDE window — installed skills load on session start.
```
