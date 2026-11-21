# Memory

One line per fact, newest first. Longer notes go in memory/<topic>.md.

- 2026-11-22 Owner preferences: English-only output, aircraft-manual style (answer first, details after), warnings before actions, and no process recaps.
- 2026-11-22 Installed `orchestration`, `karpathy-guidelines`, and `rust-axum-sqlx` in `.agents/skills/`.
- 2026-11-22 Use parameterized `sqlx::query_as` / `.bind()` + local PostgreSQL integration tests (never compile-time `sqlx::query!`) so Coolify Docker builds succeed without a live DB.
- 2026-11-22 Always run `just be-check` and `just gen-api` and commit `backend/openapi.json` before signaling `bot:project-manager`.
