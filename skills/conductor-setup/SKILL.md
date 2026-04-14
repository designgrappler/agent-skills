# Skill: Conductor Setup
## Category: Orchestration
## Type: Skill

## Description
The "Master Controller" of the AgentOS. Central governing logic for task orchestration & specialist alignment. [Dev blog reference](https://developers.googleblog.com/conductor-introducing-context-driven-development-for-gemini-cli/)

## Rules:
- **Env**: Initialize `AGENTIC.md` (Static DNA) and `CLAUDE.md` (Execution Pointer) at root.
- **Discovery**: Auto-build project baseline; categorize results into **Static DNA** (environment/stack) vs. **Dynamic DNA** (current tasks).
- **Rules**: Deploy `handoff-protocol.md` & `team.md` to `.agent/rules/` for system enforcement.
- **Sentinel**: Every rule must reference the **Static DNA** to prevent hierarchy hallucination.
- **Identity**: Pre-flight grounding; Agent confirms [Role] + [Project Personnel Name] vs. DNA.
- **Red Flag**: Mandatory RFA (3 Fails, Risk Matrix, Premortem, Pivots) before specialists.
- **Audit**: Architect verifies specialist state against **Dynamic DNA** (tracks.md) before turn closure.
- **Hygiene**: Auto-ignore `.agent/` and other non-essential paths in `.gitignore`.

### Stats:
- Overhead: ~150T | Latency: Low | Benefit: Coherent context | Risk: Potential orchestration lag.

## Trigger:
Tell Architect: "Initialize project with Conductor orchestration."
