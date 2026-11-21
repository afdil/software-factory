# QA Report — Run #<N>

- **Verdict:** `PASS` | `FAIL`
- **Commit / Branch:** `<branch>@<short-sha>`
- **Tester:** `qa-tester`
- **Timestamp (UTC):** `<ISO-8601>`

---

## Automated Check Matrix
| Check | Command / Tool | Result | Notes |
| :--- | :--- | :--- | :--- |
| Backend Check | `just be-check` | `PASS` / `FAIL` / `N/A` | ... |
| API Contract Sync | `just gen-api` | `PASS` / `FAIL` / `N/A` | ... |
| Frontend Check | `just fe-check` | `PASS` / `FAIL` / `N/A` | ... |
| Playwright E2E | `just e2e` | `PASS` / `FAIL` | ... |
| Orca Browser Visual & Console | `orca snapshot` + `screenshot` | `PASS` / `FAIL` | Zero console errors / HTTP 500s |
| Design System / Mockup Parity | `.factory/DESIGN_SYSTEM.md` | `PASS` / `FAIL` / `N/A` | ... |
| SEO Meta Check (`landing`) | `<title>`, meta, OG, sitemap | `PASS` / `FAIL` / `N/A` | ... |

---

## Acceptance Criteria Coverage (`.factory/SPEC.md`)
- [x] `US-M1-1`: Verified via `e2e/tests/...`
- [ ] `US-M2-1`: Failed — see Issue #1

---

## Issues Found

> **Gate Policy:** `BLOCKER` and `MAJOR` issues fail QA and MUST be fixed before `satpam` / `devops`. `MINOR` issues are non-blocking and forwarded to the final report.

1. **[BLOCKER] [owner: rust-dev]** `<Concise defect title>`
   - **Location:** `backend/src/routes/...`
   - **Steps to Reproduce:** ...
   - **Expected:** ...
   - **Actual / Error Log:** ...

2. **[MAJOR] [owner: vue-dev]** `<Concise defect title>`
   - **Location:** `frontend/src/pages/...`
   - **Steps to Reproduce:** ...
   - **Expected:** ...
   - **Actual:** ...

3. **[MINOR] [owner: vue-dev]** `<Non-blocking polish note>` *(non-blocking)*
