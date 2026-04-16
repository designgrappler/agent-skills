---
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
    1. **Initialization**: Call `conductor-setup` to establish the project baseline and DNA file structure.
    2. **Orchestration**: Call `team-setup` to define personnel names and mandatory role Tiers (1-3).
    3. **Alignment**: Call `handoff-optimizer` to register the Manual-First transition protocol.
- **Summary of Deployment**: At the conclusion, generate a "Welcome Kit" that lists the active personnel, their Operational Levels, and the location of the project DNA.

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
