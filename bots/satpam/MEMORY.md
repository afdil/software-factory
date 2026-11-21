# Memory

One line per fact, newest first. Longer notes go in memory/<topic>.md.

- 2026-11-22 Owner preferences: English-only output, aircraft-manual style (answer first, details after), warnings before actions, and no process recaps.
- 2026-11-22 Installed Cloudflare's `security-audit` skill and custom `rust-vue-security` addendum in `.agents/skills/`.
- 2026-11-22 Prioritize Axum IDOR (`AND user_id = $2`), raw `sqlx::Error` leaks in `AppError`, session cookie flags (`HttpOnly`, `SameSite`, conditional `Secure`), and Nuxt `runtimeConfig.public` secret exposure.
