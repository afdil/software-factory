---
name: rust-axum-sqlx
description: >-
  Opinionated backend engineering playbook for this Software Factory's Rust stack: Axum, SQLx
  (Coolify-safe query_as + auto-migrations), PostgreSQL, utoipa OpenAPI export, typed AppError,
  and justfile verification commands. Used by rust-dev.
---

# Rust + Axum + SQLx Factory Playbook

## 1. Coolify-Safe SQLx Rules
- Always use parameterized runtime queries (`sqlx::query_as::<_, Row>(...)` / `sqlx::query(...)` with `.bind(...)`) instead of compile-time `sqlx::query!` macros so `docker build` on Coolify succeeds without a live database.
- NEVER interpolate variables into SQL strings with `format!`.
- Keep all schema changes in sequential, idempotent files under `backend/migrations/` (e.g., `0002_invoices.sql`) so `sqlx::migrate!("./migrations").run(&pool).await?` succeeds cleanly on container startup.

## 2. Axum Handler & Error Discipline
- Return `Result<Json<T>, AppError>` (or appropriate status + `Json<T>`).
- Never call `.unwrap()` or `.expect()` on fallible runtime request, parsing, or DB operations.
- Log internal `sqlx::Error` details server-side via `tracing::error!`, and return sanitized, structured JSON errors (`{ "error": { "code": "...", "message": "..." } }`) to clients.
- Always enforce resource ownership using the `AuthUser` extractor (`WHERE id = $1 AND user_id = $2`) on every user-owned read, update, and delete query.

## 3. OpenAPI Contract Sync (`utoipa`)
- Derive `utoipa::ToSchema` on every request and response DTO.
- Annotate every route handler with `#[utoipa::path(...)]` and register paths & schemas in `ApiDoc`.
- After implementing a module, always run `just gen-api` to regenerate `backend/openapi.json` and commit it so `vue-dev` can immediately generate strongly typed TypeScript clients.

## 4. Mandatory Verification Commands
Before declaring any backend task done:
```bash
just db-up
just be-check
just gen-api
```
`just be-check` runs `cargo fmt --check`, `cargo clippy -- -D warnings`, and `cargo test` against the local Docker PostgreSQL instance.
