---
name: conductor-bundle
description: The "OS Setup Wizard" that deploys the core Conductor OS hierarchy in a single pass.
Abbreviation: Cb
Category: Bundles
Type: Tier 1
Bundle: ARCHITECT
Capabilities: [fs_read, fs_write]
---

# Skill: Conductor Bundle

## Description
The "OS Setup Wizard" of the Agent OS. This bundle deploys the core hierarchy (Conductor, Team, Handoff) to establish a professional-grade multi-agent collaboration environment in a single pass.

## Operational Rules
- **Role Intro**: Start by introducing yourself: *"I am the Conductor Bundle. I will now guide you through the Agent OS initialization."* [Blue Banner]
- **Foundational Check**: Verify if `.agent/context/AGENTIC.md` already exists to avoid overwriting an existing project DNA.
- **Execution Sequence**:
    1. **Initialization**: Call `conductor-setup` to establish the project baseline and DNA file structure. Use the command `[Owner]` for the root personnel slot.
    2. **Orchestration**: Call `team-setup`. **STOP AND ASK** the user to provide the names for the Conductor, Architect, and Specialist roles. Do not proceed until names are confirmed.
    3. **Alignment**: Call `handoff-optimizer` to register the Manual-First transition protocol.
- **Summary of Deployment**: At the conclusion, generate a "Welcome Kit" that lists the active personnel (using the names provided during the interview), their Operational Levels, and the location of the project DNA.

## Verification (How to test if this skill is working)
1. **Deployment Audit**: Verify that all three core logic files (`.agent/context/AGENTIC.md`, `.agent/context/tracks.md`, and `.agent/rules/team.md`) have been successfully created.
2. **Personnel Match**: Confirm that the names you gave during the `team-setup` phase are correctly reflected in the "Welcome Kit."
3. **Hierarchy Check**: Verify that the Conductor (Level 1) and Architects (Level 2) have correctly established their boundaries before any tactical turns occur.

## Stats
- **Overhead**: ~1000 Tokens (Setup Phase)
- **Operational Level**: Level 1 (Meta-Orchestration)
- **Benefit**: Instant professional-grade framework deployment; eliminates manual configuration errors.

## Trigger
Tell Architect: "Deploy the Conductor OS bundle."
