---
name: factory-protocol
description: >-
  Operating protocol for the Autonomous Software Factory. Defines English-only communication,
  .factory/ contract files, semi-parallel per-module wave pipelining, max-3 parallel worktree
  fan-out rules, file_scope boundaries, quality gates, and escalation caps. Used by project-manager
  and architect bots.
---

# Factory Protocol Skill

## 1. English-Only Policy
All communications, specifications, code, commits, reports, and memory logs MUST be written in **English**, regardless of the user's input language.

## 2. Canonical `.factory/` Artifacts
Every generated repository stores its durable contracts inside `.factory/`:
- `SPEC.md` — MVP requirements, user flows by module (`M1..Mn`), acceptance criteria, non-goals.
- `ARCHITECTURE.md` — PostgreSQL schema plan, API endpoints, frontend routes, security invariants.
- `DESIGN_SYSTEM.md` — Palette CSS variables, typography, spacing, component states, mockup refs.
- `TASKS.json` — Vertical-slice module DAG with `owner`, `depends_on`, `parallel_safe`, `file_scope`, `verify_cmd`, and retry counters.
- `HANDOFF_BE_<MODULE>.md` & `HANDOFF_FE_<MODULE>.md` — Per-module completion summaries & explicit minor assumptions.
- `QA_REPORT.md` — Functional/E2E/visual QA verdict (`PASS` / `FAIL`).
- `SECURITY_REPORT.md` — Pre-release security audit verdict (`PASS` / `FAIL`).
- `DEPLOY.json` — Coolify UUIDs, live URL, and smoke test evidence.

## 3. Semi-Parallel Wave & Fan-Out Scheduling
- **Module Pipelining (`saas`):** As soon as `BE-M1` merges into `develop` with an updated `backend/openapi.json`, immediately dispatch `FE-M1` to `vue-dev` while `rust-dev` proceeds to `BE-M2`.
- **Intra-Layer Fan-Out:** Only parallelize tasks where `parallel_safe: true` AND `file_scope` sets are strictly disjoint. Hard cap: **max 3 concurrent child worktrees**.
- **Serial Shared Wiring Files:** Never allow concurrent edits to `Cargo.toml`, `backend/migrations/*`, `backend/src/main.rs`, `backend/src/routes/mod.rs`, `frontend/package.json`, or `frontend/src/router/index.ts`.

## 4. Retry Caps & Escalation
- Per-task verification retries: **max 3**
- QA fix rounds: **max 3** (only `BLOCKER` & `MAJOR` block release)
- Security audit fix rounds: **max 2** (only `CRITICAL` & `HIGH` block release)
- Coolify deploy fix rounds: **max 2**
- Exceeding any cap requires halting immediately and raising an Orca Decision Gate (`orca orchestration gate-create`) with exact `.factory/` report paths.
