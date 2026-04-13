# Skill: Conductor Setup
## Category: Orchestration
## Type: Skill

## Description
The "Master Controller" of the AgentOS. Central governing logic for task orchestration & specialist alignment. [Dev blog reference](https://developers.googleblog.com/conductor-introducing-context-driven-development-for-gemini-cli/)

## Rules:
- **Env**: Check/Install Conductor extension/tooling.
- **Discovery**: Auto-build project baseline (stack, linting, structure).
- **Rules**: Deploy `handoff-protocol.md` & `persona.md` to `.agent/rules/`.
- **Sentinel**: Every rule must contain forced "Zero-Hallucination" header (Org Chart only).
- **Identity**: Pre-flight grounding; Agent confirms [Role] + [Orchestrator Name].
- **Red Flag**: Mandatory RFA (3 Fails, Risk Matrix, Premortem, Pivots) before specialists.
- **Audit**: Architect verifies specialist domain against `team.md` before task assignment.
- **GC**: Auto-ignore non-essential paths (`node_modules`, `build`, `dist`).

### Stats:
- Overhead: ~150T | Latency: Low | Benefit: Coherent context | Risk: Potential orchestration lag.

## Trigger:
Tell Architect: "Initialize project with Conductor orchestration."
