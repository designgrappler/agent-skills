# Technical Specification: Conductor-Compatible Environments

This document defines the technical requirements for any host environment (UI, CLI, or API) that implements the Agent Orchestration framework.

## 1. Middleware Isolation (Enforcement)
The host environment MUST implement **Tool-Packet Filtering**. Relying solely on system prompts for role discipline is prohibited.
- **Mechanism**: Before the payload is sent to the LLM, the host must compare the active agent's `Capability Bundle` against its available toolset.
- **Action**: Any tool not explicitly permitted by the bundle must be physically removed from the API call.

## 2. Standard Capability Bundles
Host environments must support the following "Out of the box" bundles:

| Bundle | Allowed Action Categories | Forbidden Tools (Examples) |
| :--- | :--- | :--- |
| **ARCHITECT** | `fs_read`, `net_fetch`, `planning` | `edit_file`, `write_to_file`, `run_command` |
| **SPECIALIST** | `fs_read`, `fs_write`, `cmd_exec` | `net_fetch` (if restricted), `generate_image` |
| **SENTINEL** | `fs_read`, `audit_exec` | `fs_write`, `edit_file` |

## 3. Operational Health Officer (OHO)
The OHO is an active monitoring process that sits between the Agent and the Tool-Execution layer.
- **Active Enforcement**: The OHO must validate every tool call against the `implementation_plan.md`.
- **Interrupt Logic**: If a tool call deviates significantly from the plan (e.g., trying to use a different framework or modifying files outside of the plan's scope), the system must **pause** and return a `CHANGE_APPROVAL_REQUIRED` state to the User.

## 4. State & DNA Management
The framework relies on a stateless agent model where identity and context are injected every turn.
- **Static DNA (`AGENTIC.md`)**: A JSON/YAML file at the root containing the Org Chart and Tech Stack.
- **Dynamic DNA (`tracks.md`)**: A log of the current task status, open blockers, and completed steps.
- **Artifact-Driven Handoff**: When switching roles, the host must use the latest `implementation_plan.md` as the "Transfer of Intent."

## 5. Visual Signal Standards
To manage user confidence, the UI should implement:
- **Introduction Banners**: A color-coded banner when a new agent enters the thread.
    - Level 1 (Orchestration): Blue
    - Level 2 (Planning): Purple
    - Level 3 (Tactical): Orange
- **Action Logs**: Clear indication of *which* tool is being called and *who* is calling it.
