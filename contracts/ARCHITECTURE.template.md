# Technical Architecture — <Project Name>

- **Project Slug:** `<slug>`
- **Template:** `tpl-saas-rust-vue` | `tpl-landing-nuxt` | `tpl-service-rust`
- **Status:** `DRAFT` | `LOCKED`

---

## 1. High-Level Topology
- **Runtime:** Single-container Axum binary serving `/api/*` and Vue static `dist/` (or Nuxt SSR/SSG for `landing`, or Axum/Tokio worker for `service`).
- **Database:** PostgreSQL (Coolify Managed in production; Docker Compose in local dev/QA).
- **API Contract:** Rust `utoipa` -> `backend/openapi.json` -> Vue `openapi-typescript` client (`frontend/src/api/schema.d.ts`).

## 2. Database Schema Plan (PostgreSQL)
List tables, primary keys (UUID v7/v4 or BIGSERIAL), foreign keys, unique constraints, and indexes.
- `users` *(provided by Golden Template if auth enabled)*
- `<domain_table_1>`: columns, relations, indexes.

## 3. API Endpoint Contract Plan
Group endpoints by module (`M1`, `M2`, ...) so `rust-dev` and `vue-dev` pipeline cleanly:

### Module M1
| Method | Path | Auth | Request DTO | Response DTO | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/health` | Public | — | `{ status, db }` | Template default |
| `POST` | `/api/...` | `AuthUser` | `Create...Req` | `...Res` | ... |

## 4. Frontend Route & State Map (Vue 3 / Nuxt)
| Route | Page Component | Auth Guard | Module | Primary API Calls |
| :--- | :--- | :--- | :--- | :--- |
| `/` | `HomePage.vue` | Public / Auth | `M1` | ... |

## 5. Security & Authorization Invariants (Reviewed by `satpam`)
- Resource ownership rule (e.g., every query filters by `user_id = auth_user.id` to prevent IDOR).
- Sensitive endpoints requiring strict validation / rate limits.
- Public vs authenticated routes.

## 6. Module Parallelization & Shared-File Boundaries
- **Serial shared files (never parallelized):** `Cargo.toml`, `backend/migrations/*`, `backend/src/main.rs`, `backend/src/routes/mod.rs`, `frontend/package.json`, `frontend/src/router/index.ts`.
- **Parallelizable feature slices:** List independent route/page modules with disjoint `file_scope`.
