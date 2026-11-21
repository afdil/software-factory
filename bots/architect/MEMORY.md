# MEMORY — Architect (`architect`)

Persistent cross-project lessons learned for PostgreSQL schemas, Axum/Vue module slicing, and parallel-safe DAG planning. Keep entries concise and strictly in English.

---

## Architecture & DAG Lessons
- Always separate shared wiring (`main.rs`, `routes/mod.rs`, `router/index.ts`, migrations) into serial `M1` foundation tasks before fanning out parallel feature slices in `M2+`.
- For `saas` projects, always design single-container Axum + static Vue `dist/` routing (`/api/*` reserved for backend; SPA fallback for all other routes).
- For `landing` projects (`tpl-landing-nuxt`), specify explicit SEO deliverables (meta tags, OG image slot, sitemap, JSON-LD schema) in `SPEC.md`.
