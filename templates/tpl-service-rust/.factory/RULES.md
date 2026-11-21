# Template Rules — `tpl-service-rust`

1. **English-Only:** All code, comments, SQL migrations, logs, commits, and `.factory/` docs MUST be in English.
2. **Coolify-Safe SQLx:** Use parameterized `sqlx::query_as` / `sqlx::query` with `.bind(...)` and sequential migrations in `backend/migrations/`. Never use compile-time `sqlx::query!` macros or string-formatted SQL.
3. **Graceful Background Workers:** If this service spawns autonomous background loops or bot listeners, pass a `tokio_util::sync::CancellationToken` (or broadcast shutdown channel) so Coolify zero-downtime redeploys shut down cleanly.
4. **Health Endpoint Mandatory:** Always preserve `GET /api/health` returning HTTP `200` + PostgreSQL connectivity check.
5. **Standard Commands Only:** Use `just db-up`, `just be-check`, `just gen-api`, and `just verify-all`.
