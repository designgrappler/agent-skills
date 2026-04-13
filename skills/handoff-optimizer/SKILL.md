# Skill: Handoff Optimizer
## Category: Foundation
## Type: Skill

## Description
The "Data Bus" of the AgentOS. Streamlines context transition between models to prevent amnesia, save tokens, and maintain momentum.

## Rules:
- **Synth**: Pre-flight summary of state, branch, and breaking-changes.
- **Contract**: Force 'API Contract' (Strict Input/Output) in every specialist prompt.
- **Handshake**: Receiver MUST confirm [Role Name] + verify dependency logic (e.g., FE audits BE API).
- **Template**: Generate structured `HANDOFF.md` in `.agent/handoffs/` for quality audit.
- **Verify**: Conduct post-task validation against `plan.md` before turn closure.

### Stats:
- Overhead: ~300-800T | Latency: 5-10s (Synth) | Benefit: Zero-breakage transitions | Risk: Potential loss of edge-case detail.

## Trigger:
Tell Architect: "Prepare handoff for [Specialist Name]."
