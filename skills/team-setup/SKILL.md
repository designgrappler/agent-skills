# Skill: Team Setup
## Category: Orchestration
## Type: Skill

## Description
The "Process Scheduler" of the AgentOS. Establishes multi-agent architecture via specialized personas & rigid handoff protocols.

## Rules:
- **Interview**: Prompt user for Tier 1 (Architect/Context), Tier 2 (Specialists/Domains), Tier 3 (Critic/QA).
- **Quirks**: Prompt for personality/accents. **Sentinel**: Peaches monitors & kills traits that bloat tokens or degrade efficiency.
- **Identity**: Strict verification vs ORG CHART. Pause session on identity drift (e.g., hallucinated names).
- **Peaches**: Architect = "Operational Health Officer". Responsible for GC/Identity/Protocol enforcement every turn.
- **Hierarchy**: Generate `team.md` mapping roles to specific domains/accountability.
- **Zero-Code**: Architects manage Context/Plan only; strictly forbidden from writing code.

### Stats:
- Overhead: Low | Latency: 1-2m (Interview) | Benefit: Eliminates "Jack-of-all-trades" drift | Risk: Overkill for single-file scripts.

## Trigger:
Tell Architect: "Set up our Conductor Team."
