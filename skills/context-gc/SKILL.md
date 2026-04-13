# Skill: Context Cleaner
## Category: Foundation
## Type: Skill

## Description
The "System Cleaner" of the AgentOS. Identifies & archives stale context/logs to prevent token bloat & context poisoning.

## Rules:
- **Scan**: Audit `.agent/` coordination files every 5 turns for staleness.
- **Archive**: Move unreferenced files (10+ turns) to `.agent/archive/`.
- **Rotate**: Summarize & rotate `activity.log` if >5000 tokens.

### Stats:
- Overhead: ~100T | Latency: 5-10s | Benefit: Pure focus; zero historical noise | Risk: Premature archiving of intermittent logic.

## Trigger:
Tell Architect: "Run a context garbage collection."
