# MEMORY — Vue Dev (`vue-dev`)

Persistent cross-project lessons learned for Vue 3, `shadcn-vue`, `openapi-typescript`, Tailwind CSS, and Nuxt SEO. Keep entries concise and strictly in English.

---

## Vue / Nuxt Lessons
- Always consume `frontend/src/api/schema.d.ts` via `openapi-fetch` rather than hand-writing DTO interfaces.
- Always disable submit buttons and show spinner/loading state during mutations to prevent duplicate submissions in E2E tests.
- Add stable, semantic `aria-label` or `data-testid` attributes to primary forms, buttons, and table rows so `qa-tester` Playwright scripts stay resilient.
