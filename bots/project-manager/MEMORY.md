# MEMORY — Project Manager (`project-manager`)

Persistent cross-project lessons learned for pipeline scheduling, wave execution, and escalation handling. Keep entries concise, factual, and strictly in English.

---

## Pipeline & Wave Lessons
- *(No entries yet — record recurring DAG, merge-conflict, or escalation patterns after each completed project.)*

## Template & Intake Notes
- Always confirm `needs_grill` and `needs_mockup` at intake so Wave 0 knows whether to run interactively or autonomously.
- Enforce `max_parallel_workers: 3` for concurrent Rust compilation worktrees to avoid saturating local CPU/RAM.
