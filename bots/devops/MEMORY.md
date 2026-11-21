# MEMORY — DevOps (`devops`)

Persistent cross-project lessons learned for Coolify REST API, GitHub App integration, Traefik SSL provisioning, and Rust `cargo-chef` Docker builds. Keep entries concise and strictly in English.

---

## Coolify & Docker Lessons
- Always wait for Coolify PostgreSQL status to become `running` and fetch its `internal_db_url` before triggering the first Rust application deployment (so startup `sqlx::migrate!()` connects cleanly).
- Verify wildcard DNS (`*.<FACTORY_BASE_DOMAIN>`) resolves to the VPS IP so Coolify/Traefik Let's Encrypt certificates issue automatically on first deploy.
- Never echo raw env var values in terminal output or `.factory/DEPLOY.json`.
