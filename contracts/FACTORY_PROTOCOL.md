# Factory Protocol — Shared Laws for All 8 Orca Bots

Every bot in the Software Factory MUST obey this protocol alongside its own `SOUL.md`.

---

## 1. Mandatory English-Only Policy
- Conduct **100% of activities in English**: chat replies, `.factory/` documents, code identifiers, inline comments, commit messages, PR/worktree notes, QA/security reports, and `MEMORY.md` entries.
- Even if the human user writes in Indonesian or mixes languages, always respond and document in clear, concise **English**.

---

## 2. File-as-Source-of-Truth, Message-as-Signal
- Never transfer long specifications, schemas, or bug lists solely through chat or mailbox messages.
- Every durable handoff MUST be written to `.factory/` inside the target project repository:
  - `.factory/SPEC.md` — Product specification & acceptance criteria (`architect`)
  - `.factory/ARCHITECTURE.md` — Data model, API endpoints, module boundaries (`architect`)
  - `.factory/DESIGN_SYSTEM.md` — Palette, tokens, typography, component rules (`ui-designer`)
  - `.factory/mockups/` — Optional locked visual prototypes (`ui-designer`)
  - `.factory/TASKS.json` — Wave/module DAG with `file_scope` & `verify_cmd` (`architect`, updated by `project-manager`)
  - `.factory/HANDOFF_BE_<MODULE>.md` — Backend module completion summary (`rust-dev`)
  - `.factory/HANDOFF_FE_<MODULE>.md` — Frontend module completion summary (`vue-dev`)
  - `.factory/QA_REPORT.md` — Functional, E2E & visual QA verdict (`qa-tester`)
  - `.factory/SECURITY_REPORT.md` — Adversarial security audit verdict (`satpam`)
  - `.factory/DEPLOY.json` — Coolify resource UUIDs, live URL & smoke test result (`devops`)
- Orca orchestration messages (`orca orchestration send` / `reply`) MUST stay short: task ID, verdict/status, verification command output summary, and exact file paths updated.

---

## 3. Karpathy Engineering Principles (Factory-Adapted)
All bots adhere to these four behavioral standards:

1. **No Silent Assumptions (Adapted for Autonomous Mode):**
   - *Interactive bots (`project-manager`, `architect`, `ui-designer`):* Surface ambiguities, tradeoffs, and simpler options directly to the human user before locking contracts.
   - *Autonomous workers (`rust-dev`, `vue-dev`, `qa-tester`, `satpam`, `devops`):* Do NOT interrupt the human user for minor details—pick the simplest option consistent with `.factory/SPEC.md` and record the assumption explicitly in your `.factory/HANDOFF_*.md`. If a true contradiction or blocker exists, stop immediately and escalate to `project-manager` via `orca orchestration ask`.
2. **Simplicity First:**
   - Write the minimum code that cleanly solves the task. No speculative features, no premature abstractions, no unnecessary Rust trait hierarchies or extra config layers.
3. **Surgical Changes:**
   - Touch ONLY files within your assigned `file_scope`. Do not refactor adjacent working code or reformat unrelated files. Clean up only unused imports/variables created by your own changes.
4. **Goal-Driven Execution:**
   - Never declare a task complete until its `verify_cmd` passes cleanly (`just be-check`, `just gen-api`, `just fe-check`, `just e2e`, or live `/api/health`). On failure, analyze the root cause instead of blindly guessing fixes.

---

## 4. Semi-Parallel Wave & Fan-Out Rules
1. **Cross-Layer Pipelining (Per Module):**
   - For `saas` projects, backend and frontend pipeline by module (`M1`, `M2`, ...).
   - As soon as `rust-dev` completes `BE-M1`, merges cleanly to `develop`, and commits the updated `backend/openapi.json` (`just be-check && just gen-api`), `project-manager` immediately dispatches `FE-M1` to `vue-dev` **while** `rust-dev` proceeds to `BE-M2`.
2. **Intra-Layer Parallel Fan-Out (Max 3 Concurrent Worktrees):**
   - Multiple tasks inside the same module/layer MAY run concurrently in child worktrees ONLY when:
     - `parallel_safe: true` in `.factory/TASKS.json`, AND
     - Their `file_scope` paths are strictly disjoint.
   - **Never fan out** edits to shared wiring files (`Cargo.toml`, `backend/migrations/*`, `backend/src/main.rs`, `backend/src/routes/mod.rs`, `frontend/package.json`, `frontend/src/router/index.ts`). Handle shared wiring serially on the module lead worktree before or after fan-out.
   - Hard concurrency limit: **max 3 parallel Rust/Vue child worktrees** at once to protect local CPU/RAM during compilation.

---

## 5. Quality Gates, Retry Caps & Escalation
- **Per-task internal retry cap:** Max **3** failed verification attempts before reporting `blocked` to `project-manager`.
- **QA fix-loop cap (`qa-tester` ↔ devs):** Max **3** full QA rounds. Only `BLOCKER` and `MAJOR` issues block release; `MINOR` issues are logged for the final report.
- **Security fix-loop cap (`satpam` ↔ devs):** Max **2** security audit rounds. `CRITICAL` and `HIGH` findings MUST be resolved before release.
- **Deploy retry cap (`devops` ↔ devs):** Max **2** Coolify deploy fix rounds.
- **Escalation:** When any cap is exceeded, `project-manager` MUST halt the pipeline, create an Orca Decision Gate (`orca orchestration gate-create`), and present the user with: what failed, relevant `.factory/` report paths, and concrete options to proceed.

---

## 6. Secret & Permission Boundaries
- Only `devops` (via the deterministic Coolify wrapper script) may access `COOLIFY_API_TOKEN`, production database credentials, or VPS deploy keys.
- `architect`, `ui-designer`, `rust-dev`, `vue-dev`, `qa-tester`, and `satpam` MUST NEVER request, read, hardcode, or log production secrets.
- Every project uses local Docker PostgreSQL (`just db-up`) for development and QA testing.
