# Template Rules — `tpl-landing-nuxt`

1. **English-Only:** All code, comments, SEO metadata, commits, and `.factory/` docs MUST be in English (unless the product brief explicitly requests target-market copy).
2. **SEO-First Nuxt Architecture:** Every landing page MUST include semantic HTML (`<header>`, `<main>`, `<section>`, `<footer>`), single `<h1>`, `useSeoMeta()` (`title`, `description`, `ogTitle`, `ogDescription`, `ogImage`, `twitterCard`), canonical URL, `/robots.txt`, `/sitemap.xml`, and JSON-LD structured data.
3. **Zero Secret Leaks:** Never put private keys or tokens in `runtimeConfig.public`.
4. **Design System Compliance:** Apply exact tokens from `.factory/DESIGN_SYSTEM.md` inside `app/assets/css/main.css`.
5. **Standard Commands Only:** Use `just fe-check`, `just e2e`, and `just verify-all`.
