#!/usr/bin/env bash
# .claude/hooks/block-orchestrator-execution.sh
#
# PreToolUse hook: blocks Edit/Write tool calls from the Orchestrator (main
# thread) targeting Agent OS execution files. Tool-layer enforcement of the
# CLAUDE.md §3 EM-no-execution rule (codified in S18.4).
#
# Behavior:
#   - Reads PreToolUse stdin JSON.
#   - If `agent_id` is present in the JSON → call is from a subagent
#     (Specialist, Architect, QA). Allow.
#   - If `agent_id` is absent → call is from the Orchestrator (main thread).
#     Block via exit code 2 with a remediation message on stderr.
#
# Notes:
#   - Path-pattern matching is delegated to the `if`-clause in
#     .claude/settings.json (see R1 in the Bridge Research Basis). This script
#     only decides on caller identity.
#   - Requires `jq` at runtime; exits 2 with an actionable message if absent
#     (install via: brew install jq).
#
# Blocked path coverage:
#   CLAUDE.md, claude/**, .claude/agents/**, .claude/skills/**,
#   docs/tasks.json,
#   docs/context/product.md,
#   docs/context/CONVENTIONS.md, docs/context/tasks-schema.md,
#   docs/context/temp-architectural-assessment.md
#
#   Intentionally OUTSIDE the blocked path (coordination-tier state):
#     docs/backlog.md — now separately protected by block-backlog-write.sh
#       (all callers blocked). See backlog.md write policy in orchestrator skill.
#     docs/context/tracks.md — Sprint Coordinator can write status updates
#       directly without Skylar routing. See S29 T29.A for rationale.
#     docs/context/plan.md — coordination-tier (pointers + sprint objective,
#       same treatment as docs/context/tracks.md per S31 T31.D).

set -euo pipefail

command -v jq >/dev/null 2>&1 || { echo "block-orchestrator-execution.sh: requires jq — install via: brew install jq" >&2; exit 2; }

# Read all stdin
INPUT="$(cat)"

# Extract agent_id; .agent_id // empty produces empty string when the field is
# absent or null.
AGENT_ID="$(printf '%s' "$INPUT" | jq -r '.agent_id // empty')"

if [ -n "$AGENT_ID" ]; then
  # Subagent invocation — allow.
  exit 0
fi

# Main-thread (Orchestrator) invocation hitting an execution-file pattern.
# Block.
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // "unknown"')"
FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // "unknown"')"

cat >&2 <<EOF
Orchestrator execution blocked by tool-layer hook.

Tool:  $TOOL_NAME
Path:  $FILE_PATH

The Orchestrator (main thread) is forbidden from editing Agent OS execution
files (CLAUDE.md, claude/**, .claude/agents/**, .claude/skills/**,
docs/tasks.json, docs/context/{product,CONVENTIONS,tasks-schema,temp-architectural-assessment}.md)
— see CLAUDE.md §3 Orchestrator Constraints. Note: docs/context/tracks.md and
docs/context/plan.md are excluded from this block (coordination-tier state,
S29 T29.A and S31 T31.D).

When a Specialist is blocked, the only valid Orchestrator moves are:
  (1) surface the blocker to the Conductor, OR
  (2) call the Architect for an unblock plan.

Direct execution is forbidden regardless of urgency.
EOF

exit 2
