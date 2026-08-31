# 21 — CI/CD Pipeline

## 1. The pipeline

```
Commit / PR
  → Lint (Ruff, ESLint, Prettier)
  → Typecheck (mypy --strict, tsc --noEmit)
  → Unit tests + coverage gate
  → Integration tests (Postgres + Redis service containers)
  → Migration up AND down test
  → Contract tests (Schemathesis vs generated OpenAPI)
  → Generated-types drift check
  → Build ONE image, tag with commit SHA
  → Security scans (Semgrep, Gitleaks, Trivy, Checkov, pip-audit, npm audit)
  → E2E smoke (Playwright)
  ─────────────────────────── merge to main ───────────────────────────
  → Deploy that image to DEV
  → Run migrations
  → Smoke test
  → [manual] Promote SAME image to QA
  → Regression suite + DAST (ZAP baseline)
  → UAT sign-off
  → [manual + required reviewer] Promote SAME image to PROD
  → Migrate (expand phase) → canary → health check → full rollout
  → Production smoke tests → 30-minute watch → record release
```

**One image, built once, promoted unchanged.** Rebuilding per environment means you never tested what you shipped.

## 2. Required status checks on `main`

Lint · typecheck · unit · integration · migration reversibility · contract · security (blocking severities) · build. **Merge is impossible without all of them green.**

Plus: PR required · ≥1 approval from the other track · conversation resolution required · linear history · signed commits · force-push and deletion blocked · CODEOWNERS review on `migrations/`, `security/`, `payments/`, `.github/`, `infrastructure/`.

## 3. Environments and gates

| Environment | Trigger | Gate | Secrets |
|---|---|---|---|
| DEV | Auto on merge to `main` | Status checks | GitHub Env `development` |
| QA | Manual promotion | DEV smoke green | GitHub Env `qa` |
| PROD | Manual promotion | UAT signed off + **required reviewer** | GitHub Env `production` |

A DEV workflow **physically cannot read production secrets** — that is what GitHub Environments enforce, and it is why we use them rather than repository-level secrets.

## 4. Migration safety in the pipeline

- **Expand/contract only.** Every deploy is backward-compatible with the previous image.
- Migrations tested `upgrade` **and** `downgrade` in CI on every PR.
- Destructive changes require a separate, explicitly reviewed migration.
- The Alembic head is recorded on the GitHub Release alongside the image digest, so rollback is deterministic.

## 5. Rollback

| Scenario | Action | Time |
|---|---|---|
| Bad application code | Redeploy previous image tag | **< 5 min** |
| Bad migration (reversible) | Down-migration + previous image | 10–20 min |
| Bad migration (irreversible) | PITR restore per runbook | 30–60 min |
| Bad configuration | **Toggle the setting in admin** — no deploy | **< 1 min** |
| Bad feature | **Turn the feature flag off** — no deploy | **< 1 min** |

**Two of the five fastest recovery paths require no deployment at all.** That is the operational payoff of the database-driven configuration and feature-flag decisions in doc 05.

## 6. Pipeline validation — Sprint 12

The pipeline is not "configured and moved on from". It is tested end to end:

| # | Test | Expected |
|---|---|---|
| 1 | Push a lint error | CI fails at lint; merge blocked |
| 2 | Push a failing test | CI fails at test; merge blocked |
| 3 | Push a secret | Gitleaks blocks it |
| 4 | Push a vulnerable dependency | Scan blocks it |
| 5 | Push an irreversible migration | Down-migration test fails |
| 6 | Merge a good change | Deploys to DEV, smoke passes |
| 7 | Promote to QA | Same image digest deployed |
| 8 | Attempt PROD without approval | Blocked pending reviewer |
| 9 | Promote to PROD with approval | Canary, health check, rollout |
| 10 | **Roll back a deployed release** | Previous image live in under 5 minutes |

**Test 10 is the one that matters.** A rollback path that has never been executed is a hope, not a plan.

## 7. Runners and cost

GitHub-hosted runners on the free tier. Caching for `uv`, npm and Docker layers keeps runs under ten minutes. If minutes become a constraint, path filters skip frontend jobs on backend-only changes before we consider paying for self-hosted runners.
