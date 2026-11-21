# MEMORY — Satpam (`satpam`)

Persistent cross-project security audit lessons learned for Axum, SQLx, Vue 3, Nuxt, and Coolify Docker deployments. Keep entries concise and strictly in English.

---

## Recurring Vulnerability Patterns to Check First
- **Axum IDOR:** Handlers extracting `Path(id)` and `AuthUser` but forgetting `AND user_id = $2` in `UPDATE`/`DELETE`/`GET` SQLx queries.
- **Error Leakage:** `AppError` accidentally returning raw `sqlx::Error` strings (table names, constraints) to API clients instead of logging server-side via `tracing::error!` and returning a safe generic message.
- **Cookie Flags:** Auth cookies missing `HttpOnly`, `SameSite=Lax`, or conditional `Secure` flag when `APP_URL` starts with `https://`.
- **Nuxt SSR Hydration Leaks:** Server-only environment variables accidentally placed under `runtimeConfig.public` instead of private `runtimeConfig`.
