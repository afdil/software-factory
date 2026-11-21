---
name: rust-vue-security
description: >-
  Stack-specific security audit addendum paired with cloudflare/security-audit-skill for satpam.
  Targets Axum extractors, SQLx PostgreSQL queries, cookie/JWT auth, Vue 3/Nuxt SSR hydration,
  and Coolify Docker container hardening.
---

# Rust + Vue + Nuxt + Coolify Security Addendum

Use this checklist inside Cloudflare's 6-phase `security-audit` workflow to ensure stack-specific traps are never missed.

## 1. Axum & Authorization (IDOR / Access Control)
- Verify every protected route extracts `AuthUser` (or applies auth middleware layer) — check router nesting so no mutating route accidentally lands on the public router.
- Verify every `GET`, `PATCH`, `PUT`, and `DELETE` by ID enforces tenant/user ownership (`AND user_id = $2` or explicit RBAC check).
- Check mass-assignment / over-posting: request DTOs must never accept privileged columns (`role`, `is_admin`, `plan_tier`, `user_id`) directly from client JSON.

## 2. SQLx & PostgreSQL
- Confirm zero string formatting (`format!`, `push_str`) constructs raw SQL with user-controlled input (including dynamic `ORDER BY` / `LIMIT` clauses — dynamic sorting must use an explicit Rust `enum` allowlist).
- Confirm `AppError` never leaks raw `sqlx::Error` messages, SQL text, or internal stack traces in HTTP responses.

## 3. Auth, Cookies & CORS
- Password hashing must use Argon2id (or bcrypt with safe cost), never plain SHA-256/MD5.
- JWT / session signing secret must be loaded strictly from `JWT_SECRET` env var (fail fast on startup if missing or weak default in production).
- Session cookies must set `HttpOnly`, `SameSite=Lax` (or `Strict`), and `Secure` whenever `APP_URL` is `https://`.
- Because single-container SaaS apps share one origin, CORS should NOT be configured as wildcard `*` with `allow_credentials(true)`.

## 4. Vue 3 & Nuxt Frontend Hygiene
- Audit all occurrences of `v-html`, `innerHTML`, and dynamic `:href` / `:src` bindings for XSS / `javascript:` URI injection.
- For Nuxt (`tpl-landing-nuxt`), inspect `nuxt.config.ts` to ensure no private API keys or secrets are exposed inside `runtimeConfig.public`.
- Confirm sensitive tokens are not stored in `localStorage` when cookie-based auth is configured.

## 5. Docker, Dependencies & Coolify Hygiene
- Run `cargo audit` (if available) and `pnpm audit --prod` in `frontend/`.
- Verify `.env`, private keys, and `.factory/` secret files are absent from Git history and excluded in `.dockerignore`.
- Verify the final `Dockerfile` runtime stage uses a minimal base image, runs as a non-root user where feasible, and does not bake secrets into `ENV` or `ARG`.
