# MEMORY — UI Designer (`ui-designer`)

Persistent cross-project lessons learned for `DESIGN_SYSTEM.md`, Tailwind/`shadcn-vue` token compatibility, and Orca Browser mockup reviews. Keep entries concise and strictly in English.

---

## Design System Lessons
- Always map semantic palette tokens directly to `shadcn-vue` CSS variable names (`--background`, `--foreground`, `--primary`, `--muted`, `--destructive`, `--border`, `--ring`, `--radius`) so `vue-dev` can drop them into `frontend/src/assets/index.css` without translation errors.
- Always specify empty-state, skeleton-loading, and button-submitting visuals in `DESIGN_SYSTEM.md` so `vue-dev` does not improvise inconsistent states.
