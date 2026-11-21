---
name: coolify-deploy
description: >-
  Deterministic Coolify REST API deployment and live smoke-test playbook for single-container
  Rust+Vue SaaS apps, Nuxt landing pages, and Rust services. Used exclusively by the devops bot.
---

# Coolify Deployment Playbook

## 1. Required Host Environment (Loaded Only by `devops` Script)
The deterministic deploy wrapper expects these environment variables on the operator host (never committed to Git or logged):
- `COOLIFY_BASE_URL` (e.g., `https://coolify.yourdomain.com`)
- `COOLIFY_API_TOKEN`
- `COOLIFY_SERVER_UUID`
- `COOLIFY_PROJECT_UUID`
- `COOLIFY_GITHUB_APP_UUID`
- `FACTORY_BASE_DOMAIN` (e.g., `apps.yourdomain.com` with wildcard DNS pointing to the VPS)

## 2. Provisioning & Deploy Sequence
1. **Verify Gates First:** Confirm `.factory/QA_REPORT.md` and `.factory/SECURITY_REPORT.md` both state `Verdict: PASS` on the commit being deployed.
2. **Push `main`:** Push the verified commit to the private GitHub repository.
3. **Provision PostgreSQL (`saas` and `service` only):**
   - If `.factory/DEPLOY.json` has no `coolify_db_uuid`, call `POST /api/v1/databases/postgresql` (`image: postgres:16-alpine`, `instant_deploy: true`).
   - Poll `GET /api/v1/databases/{uuid}` until running and read `internal_db_url`.
4. **Create / Update Coolify Application:**
   - If `.factory/DEPLOY.json` has no `coolify_app_uuid`, create the GitHub App application (`build_pack: dockerfile`, `ports_exposes: "8080"`, `fqdn: "https://<project_slug>.<FACTORY_BASE_DOMAIN>"`, `health_check_enabled: true`, `health_check_path: "/api/health"` for `saas`/`service` or `"/"` for `landing`).
5. **Configure Environment Variables:**
   - Inject `PORT=8080`, `APP_URL=https://<project_slug>.<FACTORY_BASE_DOMAIN>`, `RUST_LOG=info`.
   - For `saas`/`service`, also inject `DATABASE_URL=<internal_db_url>` and a freshly generated 64-byte hex `JWT_SECRET` (only on initial provision; preserve on re-deploys).
6. **Deploy & Poll:**
   - Trigger deployment (`GET/POST /api/v1/deploy?uuid=<app_uuid>`) and poll deployment status until `finished` or `failed`.

## 3. Live Smoke Test & Evidence
1. Verify HTTPS health endpoint (`https://<project_slug>.<FACTORY_BASE_DOMAIN>/api/health` -> HTTP `200` and DB healthy; or `/` -> HTTP `200` for `landing`).
2. Open the live HTTPS URL in **Orca Embedded Browser** (`orca tab create`, `orca wait`, `orca screenshot`) for `saas` and `landing` to confirm clean render and valid TLS.
3. Save `.factory/DEPLOY.json` conforming to `contracts/DEPLOY.schema.json` (zero secret values).

## 4. Failure Handling
- On failed build or unhealthy container, fetch the deployment log via Coolify API, strip/redact any env secrets, and return the concise root-cause tail to `project-manager` (max 2 fix loops).
