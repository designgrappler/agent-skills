# Agent Skills: The Conductor Specification

A curated library of surgical, high-fidelity capabilities for an **Agent Operating System**. This repository establishes the standard for reliable, multi-agent orchestration through **Middleware Isolation** and **Artifact-Driven State.**

## 🧩 The Core Framework
This library is more than a set of prompts; it is a **Technical System Specification** designed for professional agentic workflows.

- **[Product Strategy](./context/product.md)**: The "Team" metaphor and reliability-first vision.
- **[Technical Spec](./context/techstack.md)**: Requirements for Middleware Isolation and Capability Bundles.
- **[Team Hierarchy](./context/team.md)**: The 3-Tier operational model (Orchestration, Strategic, Tactical).
- **[Implementation Guide](./GUIDE.md)**: How to integrate the Conductor OS into your workspace.

## 🎨 Knowledge Graph & Gallery
The full library of skills is available in a vibrant, searchable dashboard.
**[View the Live Skill Gallery →](https://designgrappler.github.io/agent-skills/)**

## 🚀 Key Architectural Pillars
1.  **Middleware Isolation**: Professional-grade role discipline via hardware-level tool filtering.
2.  **Active Enforcement**: An "Operational Health Officer" (OHO) that pauses execution if the agent drifts from the plan.
3.  **Artifact-Driven State**: intent is carried via `.agent/context/` files, not expensive conversation history.

## 📚 Skill Library (Middleware-Compatible)

| Skill | Tier | Bundle | Mission |
| :--- | :--- | :--- | :--- |
| [Conductor Setup](./skills/conductor-setup/SKILL.md) | 1 | ARCHITECT | Establish project baseline and DNA. |
| [Team Setup](./skills/team-setup/SKILL.md) | 2 | ARCHITECT | Standardize Org Chart and Personnel DNA. |
| [Handoff Optimizer](./skills/handoff-optimizer/SKILL.md) | 2 | ARCHITECT | Lossless transition of intent between roles. |
| [Conductor Bundle](./skills/conductor-bundle/SKILL.md) | 1 | ARCHITECT | One-click OS initialization. |
| [Context Cleaner](./skills/context-cleaner/SKILL.md) | 3 | SPECIALIST | Tactical token pruning and archival. |
| [Memory Indexer](./skills/memory-indexer/SKILL.md) | 3 | SPECIALIST | Long-term decision and milestone archival. |
| [Security Audit](./skills/security-audit/SKILL.md) | 3 | SENTINEL | Security sweeps and architectural drift audit. |
| [Design Sync](./skills/design-sync/SKILL.md) | 3 | SPECIALIST | UI alignment with Stitch design tokens. |

## 🛠 Usage
This framework is intended for host environments that support the **Conductor Spec**.

### Option A: Professional CLI (Recommended)
```bash
gemini skills install https://github.com/designgrappler/agent-skills --path skills/conductor-bundle
```

### Option B: Surgical Bootstrap (Zero-Dependency)
```bash
curl -sSL https://raw.githubusercontent.com/designgrappler/agent-skills/main/scripts/bootstrap.sh | bash
```
