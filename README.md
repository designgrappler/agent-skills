# Agent Skills

A curated library of surgical, high-fidelity capabilities designed for the **Intelligent Agent Operating System**. 

These skills are not just code samples; they are tactical modules designed to be "installed" into agentic workflows via context injection, providing LLMs with consistent, high-performance logic for specific technical tasks.

[**Explore the Interactive Dashboard →**](https://designgrappler.github.io/agent-skills/)

---

## 🧩 The Library

Each skill in this repository follows a strict architecture for maximum portability and token efficiency:

- **Surgical Precision**: Focused on one specific outcome (e.g., Memory Indexing, Handoff Optimization).
- **Abbreviation System**: Each skill is identified by a unique 2-letter Adobe-style shorthand (e.g., `Cc` for Context Cleaner) for easy reference and mental mapping.
- **Standardized Metadata**: Every skill includes a `SKILL.md` file with standardized YAML front matter for automated discovery and categorization.

### Featured Skills

| Abbr | Skill Name | Description |
|:---|:---|:---|
| **Cc** | **Context Cleaner** | Tactically manages token bloat and context pruning. |
| **Mi** | **Memory Indexer** | Structured archival and retrieval strategies for long-term state. |
| **Ho** | **Handoff Optimizer** | Ensures seamless transition of intent and metadata between specialized agents. |
| **Sa** | **Security Audit** | Automated validation of agent-generated code against security baselines. |
| **Ds** | **Design Sync** | Bridges the gap between frontend implementation and design system tokens. |

---

## 🛠 Integration

### How to use these skills

1.  **Direct Injection**: Copy the contents of a `SKILL.md` directly into your Agent's system prompt or context window.
2.  **Context Catalog**: Point your Agentic CLI (like Conductor) to this repository to automatically discover and load capabilities.
3.  **Modular OS**: These skills are designed to be treated as external modules, separable from the core application logic to maintain a clean "Agent Operating System" architecture.

### 🏛 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*Questions or feedback? Contact [designgrappler@me.com](designgrappler@me.com)*
