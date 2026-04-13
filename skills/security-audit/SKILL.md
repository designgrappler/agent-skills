# Skill: Security Audit
## Category: Quality
## Type: Hook

## Description
The "Kernel Guard" of the AgentOS. Automated security sweeps for code changes to prevent logic regressions & vulnerabilities.

## Rules:
- **Trigger**: Execute `/audit-security` tailored to project baseline.
- **Audit**: Verify specialist compliance (BE/DB/API) before plan reintegration.
- **Report**: Log potential risks to `.agent/security_brief.md`.
- **Standard**: Cross-ref new code vs `api-standards.md` in `.agent/rules/`.

### Stats:
- Overhead: ~500-1000T | Latency: 15-30s | Benefit: Catches pre-CI vulnerabilities | Risk: False positives in unconventional code.

## Trigger:
Tell Architect: "Perform security review on backend changes."
