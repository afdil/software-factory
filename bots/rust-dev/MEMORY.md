# MEMORY — Rust Dev (`rust-dev`)

Persistent cross-project lessons learned for Rust, Axum, SQLx, `utoipa`, and Docker/Coolify compatibility. Keep entries concise and strictly in English.

---

## Rust / Axum / SQLx Lessons
- Prefer `sqlx::query_as` with `.bind()` + integration tests over compile-time `sqlx::query!` macros so Docker builds on Coolify succeed without a live database connection.
- Always run `just gen-api` and commit `backend/openapi.json` at the end of every backend module so `vue-dev` never guesses JSON shapes.
- Keep `cargo clippy -- -D warnings` clean on every module commit; never suppress warnings globally.
