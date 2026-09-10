---
name: research
description: Two-phase research skill — grounds a question in system state, surveys external patterns, then reconciles the two into an actionable gap analysis.
whenToUse: When you need to answer a domain question by first reading the current system state and then comparing it against external conventions, best practices, or published guidance. Applicable to engineering, tooling, process, and design questions — not limited to user research.
---

## Instructions

### Phase 1 — Read the system

Read the codebase, existing docs, and current state relevant to the research question. Do not consult external sources in this phase. The goal is a grounded "current state" summary that reflects what is actually present, not what was intended or documented elsewhere.

1. Identify the relevant source locations: file paths, directories, or known doc sections named in the research question or its brief.
2. Read each identified source in full. Do not skim or infer — read the actual content.
3. Produce a **Current State Summary**: a structured, factual description of what the system currently does, defines, or contains, organized by the dimensions most relevant to the question. Every claim in this summary must be traceable to a file and line range read in this phase.
4. Identify gaps in the current state: places where the system is silent on a topic the question requires an answer about.

Output of Phase 1: a Current State Summary with source tracings, plus a list of silences (topics the current state does not address).

---

### Phase 2 — Survey external patterns

Survey external sources — official documentation, published research, recognized best-practice guides — to find how the question is addressed outside the system. Every finding must carry its source URL or citation. A finding without a locatable source is flagged as a gap rather than asserted.

1. Identify the relevant external sources for the question: official documentation pages, published standards, peer-reviewed research, or widely adopted reference implementations.
2. Fetch and read each source (WebFetch). Record the source URL alongside each finding.
3. For each finding, state: what the source says, what it applies to, and whether it is prescriptive (normative guidance) or descriptive (observed practice).
4. Flag any claim you are unable to ground in a locatable source as: **"Unverified claim — source not located. Treating as a gap, not asserting."** Do not present unverified claims as findings.

Output of Phase 2: a Findings List — each item carries the source URL, the claim, and its type (prescriptive or descriptive).

---

### Phase 3 — Reconcile

Diff the Phase 1 Current State Summary against the Phase 2 Findings List. Produce an actionable output block.

The reconcile output has four required sections:

**What matches** — dimensions where the current system state conforms to the external findings. Cite the specific Phase 1 source and Phase 2 finding for each match.

**What diverges** — dimensions where the current system state differs from external findings. For each divergence, state: what the system currently does, what the external finding prescribes or describes, and the direction of the recommended delta.

**Recommended deltas** — a prioritized, actionable list of changes the system should make to close the divergence. Each delta is scoped and specific — not a general principle. If no delta is warranted (the divergence is intentional or out of scope), say so explicitly.

**Gaps** — topics that neither the current state nor the external survey resolved. State the gap, why it matters to the research question, and what type of source would close it.

---

## Hard Constraints

- **No fabricated citations.** If a source does not exist in the located corpus or could not be fetched, it cannot be cited. If you find yourself about to write a citation that is not grounded in a source you actually read: STOP. Flag: "I do not have a verified source for this claim. Omitting rather than fabricating. If load-bearing, supply the source."

- **Explicit insufficient-evidence statement over hedged synthesis.** If the evidence base is thin relative to the question — too few sources, too narrow, or unlocatable — output an explicit "**Evidence is Insufficient**" statement rather than a hedged synthesis that masks the gap. State what is missing and what would unblock the synthesis. Do not produce soft conclusions that imply more confidence than the evidence supports.

- **Correlation is not causation.** If two findings co-occur in the evidence, do not present the relationship as causal unless the source explicitly supports causation. Flag the logical gap: "The evidence shows correlation between X and Y but does not establish causation."

- **Undocumented-behavior stop-and-flag rule.** If a research finding relies on undocumented behavior — a tool parameter, runtime guarantee, API assumption, or format convention not confirmed in official docs — STOP and flag to the task owner before including it in the output. Do not assert undocumented behavior as established practice.

- **Read-only on source materials.** Never modify, annotate, or delete a source under analysis.

- **Never expand scope without explicit confirmation.** If the research question expands mid-session beyond what was stated, stop and surface: "This appears to be expanding the scope beyond the original question. I cannot proceed without confirmation from the Owner."
