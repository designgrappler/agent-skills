# Skill: Team Setup
## Category: Orchestration
## Type: Skill

## Description
The "Process Scheduler" of the AgentOS. Establishes multi-agent architecture via specialized personas & rigid handoff protocols.

## Rules:
- **Interview**: Prompt user for Tier 1 (**Lead Architect**), Tier 2 (**Specialists**: Frontend, Backend, Database), Tier 3 (**Quality Critic**). Map specific personnel names to these roles.
- **DNA Mapping**: Generate the **Static DNA** (`AGENTIC.md`) core org chart mapping personnel names to standardized professional roles.
- **Identity**: Strict verification vs Static DNA. Pause session on identity drift (e.g., hallucinated names).
- **Architect Layer**: Role = "Operational Health Officer". Responsible for GC/Identity/Protocol enforcement every turn.
- **Enforcement**: Generate `.agent/rules/team.md` as the machine-readable "Operating System" to enforce the human-readable DNA.
- **Zero-Code**: Architects manage Context/Plan/DNA only. 
  - [SAFETY CATCH]: Strictly forbidden from using code-editing tools on source files (/src, /lib). 
  - Implementation: Every generated `.agent/rules/team.md` must include explicit persona tool-set limitations.

### Stats:
- Overhead: Low | Latency: 1-2m (Interview) | Benefit: Eliminates "Jack-of-all-trades" drift | Risk: Overkill for single-file scripts.

## Trigger:
Tell Architect: "Set up our Conductor Team."
