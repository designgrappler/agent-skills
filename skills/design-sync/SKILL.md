# Skill: Design Sync (Stitch)
## Category: Quality
## Type: Interactive

## Description
The "Visual Graphics Driver" of the AgentOS. Syncs UI code with **Stitch** Design DNA to enforce pixel-perfection via automated browser auditing.

## Rules:
- **Ground**: Verify UI role (e.g., Max). Fetch tokens/screens via `stitch.get_screen_details`.
- **Pre-flight**: Update `/CONVENTIONS.md` with active Design DNA (colors/spacing).
- **Verify**: Capture local UI via Browser Subagent; compare vs Stitch source.
- **Audit**: Check hex codes/layout alignment. Report "Design Drift" if mismatches found.

### Stats:
- Overhead: ~400T | Latency: High (Browser cost) | Benefit: Eliminates "As-Designed" drift | Risk: Token-intensive verification loops.

## Trigger:
Tell Architect: "Verify UI against Stitch design."
