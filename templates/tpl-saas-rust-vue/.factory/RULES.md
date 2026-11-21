# Template Rules — `tpl-saas-rust-vue`

1. **English-Only:** All code, comments, migrations, error messages, commits, and `.factory/` docs MUST be in English.
2. **Single-Container Topology:** Rust Axum serves `/api/*` and static Vue `dist/` via `tower-http::ServeDir` with SPA fallback (`index.html`). Never introduce a separate Nginx container.
3. **Coolify-Safe SQLx:** Use `sqlx::query_as` / `sqlx::query` with `.bind(...)` + local PostgreSQL integration tests. Never use compile-time `sqlx::query!` macros or `format!`-interpolated SQL.
4. **OpenAPI Sync:** After any Rust API change, update `utoipa` annotations and run `just gen-api` to regenerate `backend/openapi.json` and `frontend/src/api/schema.d.ts`.
5. **Standard Commands Only:** Always use `justfile` recipes (`just db-up`, `just be-check`, `just gen-api`, `just fe-check`, `just e2e`, `just verify-all`).
6. **Zero Secrets in Git:** Never commit `.env`, real `JWT_SECRET`, or Coolify credentials.
