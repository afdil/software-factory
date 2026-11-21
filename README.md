# Autonomous Software Factory (Orca Desktop + Rust/Vue/Nuxt + Coolify)

An autonomous, solo-developer software factory powered by **Orca Desktop** multi-bot orchestration. It turns direct chat briefs into deployed, verified web SaaS apps, SEO-optimized landing pages, and Rust APIs/bots on a self-hosted **Coolify** VPS.

---

## Global Operating Rules

1. **English-Only Policy:** Every bot MUST use **English** for all activities—chat replies, `.factory/` specs, architecture docs, design systems, code, comments, commit messages, PR descriptions, test reports, and memory logs—even if the human user writes in Indonesian or mixed languages.
2. **File-as-Source-of-Truth, Message-as-Signal:** Inter-bot messages carry short status signals and file pointers. Detailed specifications, task DAGs, handoffs, and reports live under `.factory/` inside each generated repository.
3. **Deterministic Plumbing, AI for Creative Engineering:** Repository scaffolding, Coolify provisioning, and verification commands (`justfile`) are standardized scripts; AI bots focus on architecture, design, business logic, UI, testing, and security auditing.

---

## Golden Templates (Target Stacks)

| Template | Project Type | Stack | Coolify Deployment Model |
| :--- | :--- | :--- | :--- |
| `tpl-saas-rust-vue` | `saas` | Rust (Axum + SQLx + `utoipa`) + Vue 3 (Vite + TS + Tailwind + `shadcn-vue` + Pinia) + PostgreSQL | Single-container (`cargo-chef` + Axum serving `/api/*` and built Vue `dist/`) + Coolify Managed PostgreSQL |
| `tpl-landing-nuxt` | `landing` | Nuxt (SSR/SSG SEO, Tailwind, sitemap, OG/meta, JSON-LD) | Coolify Dockerfile App (no DB) |
| `tpl-service-rust` | `service` | Rust (Axum/Tokio + SQLx + `tracing`) + PostgreSQL | Coolify Dockerfile App + Coolify Managed PostgreSQL |

---

## Bot Roster & Responsibilities

| Bot ID | Display Name | Primary Responsibility | Active Model (Gemini — Nov 2026) | Secondary (Claude — Nov 2026) |
| :--- | :--- | :--- | :--- | :--- |
| `project-manager` | Project Manager | Chat entry point, intake, scaffolding, Wave DAG orchestration, merges, escalations, final report | Gemini 4 Hydrogen (`medium`) | Claude Sonnet 5.5 (`medium`) |
| `architect` | Architect | Interactive `grill-with-docs` PRD planning, `SPEC.md`, `ARCHITECTURE.md`, `TASKS.json` (`file_scope`), core SQL migration | Gemini 4 Neon (`xhigh`) | Claude Opus 5.5 (`high`) |
| `ui-designer` | UI Designer | `DESIGN_SYSTEM.md` + optional interactive mockups reviewed in Orca Browser | Gemini 4 Neon (`high`) | Claude Opus 5.5 (`medium`) |
| `rust-dev` | Rust Dev | Axum + SQLx + `utoipa` backend modules; parallel child-worktree fan-out (max 3) | Gemini 4 Neon (`medium`; escalate to `high` for complex logic) | Claude Sonnet 5.5 (`medium–high`) |
| `vue-dev` | Vue Dev | Vue 3 SaaS frontend (generated OpenAPI client + `DESIGN_SYSTEM.md`) or Nuxt SEO landing pages; parallel fan-out (max 3) | Gemini 4 Hydrogen (`high`) | Claude Sonnet 5.5 (`medium`) |
| `qa-tester` | QA Tester | High-volume functional, Playwright E2E, and Orca Browser visual/console/SEO testing | Gemini 4 Hydrogen (`medium`) | Claude Haiku 5.5 (`low–medium`) |
| `satpam` | Satpam | Pre-release deep security audit (Cloudflare 6-phase audit harness + Rust/Vue/Coolify rules) | Gemini 4 Neon (`xhigh`) | Claude Opus 5.5 (`high`) |
| `devops` | DevOps | Deterministic GitHub push + Coolify REST API deploy (Postgres + App + Env) + live smoke test | Gemini 4 Hydrogen (`medium`) | Claude Haiku 5.5 (`low`) |

---

## End-to-End Execution Pipeline (Semi-Parallel Waves)

```text
[Direct Chat with User] ──▶ project-manager (Intake: type, grill?, mockup?)
                                   │
                                   ▼
WAVE 0 — FOUNDATION (Serial)
  ├─ factory-init script    ──▶ Create private GitHub repo from template + `orca repo add`
  ├─ architect              ──▶ SPEC.md, ARCHITECTURE.md, TASKS.json, core SQL migration
  │                             (interactive `grill-with-docs` session if requested)
  └─ ui-designer            ──▶ DESIGN_SYSTEM.md (+ interactive Orca Browser mockup gate if requested)
                                   │
                                   ▼
WAVE 1..N — PIPELINED PER MODULE (Semi-Parallel + Intra-Layer Fan-Out)
  Module 1: [rust-dev: BE-M1] ──▶ openapi.json ──┬──▶ [vue-dev: FE-M1] ──▶ merge
                                                 │
  Module 2: [rust-dev: BE-M2a ‖ BE-M2b]* ────────┴──▶ openapi.json ──▶ [vue-dev: FE-M2a ‖ FE-M2b]*
            (*parallel child worktrees up to max 3 when file_scope is disjoint)
  • `landing` projects skip `rust-dev`
  • `service` projects skip `ui-designer` & `vue-dev`
                                   │
                                   ▼
WAVE FINAL — TIERED VERIFICATION & RELEASE
  1. qa-tester (Hydrogen)   ──▶ `just verify-all` + Playwright + Orca Browser visual/SEO check (max 3 fix loops)
  2. satpam (Neon xhigh)    ──▶ Cloudflare 6-phase audit + Rust/Vue security rules (max 2 fix loops)
  3. devops (Hydrogen)      ──▶ Coolify Postgres + App + Env + Deploy + Live Smoke Test (max 2 deploy loops)
  4. project-manager        ──▶ Deliver Live URL, repo link, screenshot, summary + update MEMORY.md
```

---

## How to Start a New Project

1. Open **Orca Desktop** and chat directly with **`project-manager`**.
2. Describe what you want to build (and optionally mention if you want a PRD grill session or UI mockup).
3. `project-manager` confirms 3 quick flags (`project_type`, `needs_grill`, `needs_mockup`) and launches the pipeline.
4. If `needs_grill` is enabled, `architect` interviews you with `grill-with-docs` until you approve (`LOCKED`).
5. If `needs_mockup` is enabled, `ui-designer` shows interactive prototypes in Orca Browser until you approve (`LOCKED`).
6. Everything after Wave 0 runs autonomously until `project-manager` delivers the verified Coolify live URL (or pauses at an Orca Decision Gate if a hard retry cap is exceeded).

---

## Directory Layout

- `config/` — Active/secondary LLM provider & effort mappings (`models.yaml`) and per-bot skill inventory (`skills.yaml`).
- `contracts/` — Canonical `.factory/` protocol, Markdown templates, and JSON Schemas shared across all bots.
- `bots/<bot-id>/` — `SOUL.md` (strict role persona, SOP, boundaries) and `MEMORY.md` (cross-project lessons learned) for each of the 8 Orca bots.
- `skills/` — Custom local agent skills authored specifically for this factory.
- `templates/` — Three Golden Templates (`tpl-saas-rust-vue`, `tpl-landing-nuxt`, `tpl-service-rust`) with Coolify-ready Dockerfiles, `justfile`, and Playwright smoke tests.
- `scripts/` — Deterministic tooling (`install-skills.ps1`, `factory-init.ps1`, `coolify-deploy.ps1`).
- `.env.factory.example` — Template for Coolify operator environment variables (copy to `.env.factory` for `devops` only; never commit).

---

## Host Machine Prerequisites

- **Orca Desktop** + **GitHub CLI (`gh`)** authenticated (`gh auth login`)
- **Docker Desktop** (for local PostgreSQL test databases and image verification)
- **Node.js 22+ & `pnpm`** (for Vue/Nuxt builds and Playwright)
- **Rust toolchain (`rustup` / `cargo`) + `just`** *(and optionally `sccache` + `cargo-audit` for faster builds and security audits)*
- **Coolify VPS** with wildcard DNS (`*.apps.yourdomain.com`) and Coolify GitHub App connected
