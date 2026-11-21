---
name: web-qa-checklist
description: >-
  Repeatable QA verification workflow for Rust+Vue SaaS apps, Nuxt SEO landing pages, and Rust
  services. Covers justfile checks, Playwright E2E coverage, Orca Embedded Browser visual/console
  checks, design-system parity, and structured QA_REPORT.md output. Used by qa-tester.
---

# Web QA Verification Checklist

## 1. Deterministic Build & Unit Gate
1. Start test PostgreSQL if applicable (`just db-up`).
2. Run `just verify-all`. If this fails, record a `[BLOCKER]` with exact command output immediately.

## 2. Playwright E2E Suite (`just e2e`)
Ensure `e2e/tests/` covers:
- Health endpoint (`/api/health`) returns `200` and confirms DB connectivity (`saas`/`service`).
- Auth flow (register, login, protected route redirect, logout) when auth is enabled.
- Every user story acceptance criterion in `.factory/SPEC.md` (happy path + key invalid input returning `4xx`, never `500`).
- Double-submit protection (submit button disabled / loading state active during network mutation).
- Global Playwright assertions failing on any uncaught `pageerror` or HTTP `>= 500` API response.

## 3. Orca Embedded Browser Inspection
Inspect the running local app using `orca-cli`:
1. Open desktop viewport (`1280x800`): `orca tab create --url http://localhost:8080`, run `orca snapshot` and `orca screenshot`.
2. Switch to mobile (`orca set device --name "iPhone 12"`): verify zero horizontal overflow, readable text, and accessible navigation.
3. Verify visual parity with `.factory/DESIGN_SYSTEM.md` (and `.factory/mockups/` if locked).
4. For `landing` (`tpl-landing-nuxt`), verify via `orca eval`:
   - Non-empty `<title>` and `<meta name="description">`
   - OpenGraph (`og:title`, `og:description`) tags present
   - Single `<h1>` on page, valid heading hierarchy
   - `/robots.txt` and `/sitemap.xml` return `200`

## 4. Severity & Verdict Rules
- **`BLOCKER`**: Build/test failure, HTTP 500, uncaught console error, broken core flow, broken auth guard.
- **`MAJOR`**: Broken secondary flow, missing loading/double-submit guard, severe mobile layout break, missing SEO tags on Nuxt landing page, clear design-system violation.
- **`MINOR`**: Small visual polish notes (non-blocking).
- Set `Verdict: PASS` in `.factory/QA_REPORT.md` ONLY when zero `BLOCKER` and zero `MAJOR` issues remain.
