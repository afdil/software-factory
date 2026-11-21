# MEMORY — QA Tester (`qa-tester`)

Persistent cross-project lessons learned for Playwright E2E stability, Orca Embedded Browser inspection, and common Rust/Vue runtime bugs. Keep entries concise and strictly in English.

---

## QA & Playwright Lessons
- Always assert zero `pageerror` and zero HTTP `>= 500` responses in Playwright tests so silent runtime failures never slip past a green build.
- Always test form submission twice rapidly or verify button `disabled` state while submitting to catch double-submit bugs early.
- When using Orca Browser, always re-run `orca snapshot` after every navigation before clicking or filling refs.
