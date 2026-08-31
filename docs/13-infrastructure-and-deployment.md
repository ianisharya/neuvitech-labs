# 13 — Infrastructure & Deployment

## 1. Environments

| | Local | DEV | QA | PROD |
|---|---|---|---|---|
| Runs in | Dev Container | Cloud | Cloud | Cloud |
| URL | localhost | dev.neuvitechlabs.com | qa.neuvitechlabs.com | **neuvitechlabs.com** |
| Database | Container Postgres | Isolated managed | Isolated, anonymised seed | Managed, PITR, replica |
| Deploy | — | Auto on merge to `main` | Manual promotion | Manual + required reviewer |
| Payments | Test keys | Test keys | Test keys | **Live keys** |
| Mail | Mailpit | Sandbox domain | Sandbox domain | Live sending domain |
| Robots | — | `Disallow: /` | `Disallow: /` | Allow |
| Secrets | `.env` (git-ignored) | GitHub Env `development` | GitHub Env `qa` | GitHub Env `production` |

**Absolute rules:** no environment holds another's credentials · QA never points at the PROD database · no production data reaches a lower environment without irreversible anonymisation · **non-production robots is `Disallow: /`** (an indexed QA environment is a real and common incident).

## 2. Build and promotion

```
Commit → CI builds ONE image, tagged with the commit SHA
  → deploy that image to DEV
  → promote THE SAME image to QA
  → promote THE SAME image to PROD
```

**Rebuilding per environment means you never tested what you shipped.** The image digest is recorded on the GitHub Release alongside the Alembic head, so a rollback is deterministic.

Images: multi-stage, non-root user, slim base, pinned digests, `HEALTHCHECK`, SBOM generated, Trivy-scanned, no secrets baked in.

## 3. Production topology

```
                    Cloudflare (DNS · CDN · WAF · TLS)
                              │
                    ┌─────────▼─────────┐
                    │   Load balancer   │
                    └────┬─────────┬────┘
                         │         │
                 ┌───────▼──┐  ┌───▼──────┐
                 │ Web (2+) │  │ API (2+) │   stateless, horizontally scaled
                 └──────────┘  └───┬──────┘
                                   │
              ┌──────────┬─────────┼──────────┬─────────────┐
              ▼          ▼         ▼          ▼             ▼
        Managed      Managed    Object    Worker (1+)   Observability
        PostgreSQL   Redis      Storage    (ARQ)        (OTel → Grafana)
        + replica               + CDN
```

**Rationale:** managed PostgreSQL because losing the database is unrecoverable and two part-time engineers should not be responsible for PITR configuration, failover and patching. Everything else is stateless containers, which is the cheapest thing to operate and the easiest to scale.

**Kubernetes is deliberately deferred** (ADR-0013). At this scale a container platform with managed data services delivers the same availability at a fraction of the operational cost, and Kubernetes' failure modes would consume sprint capacity that belongs to the product. The application is stateless and twelve-factor, so migrating later is packaging, not rewriting. Revisit at >8 replicas or multi-team ownership.

## 4. Infrastructure as code

**OpenTofu** (Terraform-compatible, MPL-licensed, no BUSL exposure) under `infrastructure/tofu/`, with remote state and locking. Everything is code: networking, database, Redis, object storage, DNS records, TLS, container services, secrets references (**never secret values**), monitoring, alerts.

Human-written infrastructure code is expected and welcomed here — this is one of the areas where you will likely write more than I do, because it interacts with account-specific details I cannot see.

## 5. Secrets

| Where | Holds |
|---|---|
| GitHub Environment secrets | The nine bootstrap variables, per environment, reviewer-gated on `production` |
| Database (encrypted with `ENCRYPTION_KEY`) | **Everything else** — payment keys, mail credentials, Zoom, LLM keys |
| Nowhere ever | Secrets in code, images, logs, Jira, or documentation |

Rotating a payment key is an admin action, not a deployment (doc 05).

## 6. Deployment procedure

```
1. Pre-flight: CI green · QA signed off · migrations reviewed · rollback plan stated
2. Announce start; enable maintenance banner if the migration is destructive
3. Run migrations (expand phase only — always backward-compatible)
4. Deploy the new image to one instance (canary)
5. Health check the canary; watch error rate and latency for 5 minutes
6. Roll out to remaining instances
7. Smoke tests (automated + manual)
8. Watch dashboards for 30 minutes
9. Record the release: image digest, Alembic head, Jira keys included
10. Contract-phase migration in a later release, once the old code is gone
```

**Rollback:** redeploy the previous image tag (fast path, under 5 minutes). Database rollback via the down-migration when reversible, otherwise via the documented runbook. Because migrations are expand/contract, the previous image always works against the current schema — **which is the entire reason for the pattern**.

## 7. DNS and TLS

`neuvitechlabs.com` on Cloudflare. Records: apex and `www` → load balancer, `dev` and `qa` → their environments, MX and SPF/DKIM/DMARC for the sending domain, CAA restricting issuance.

TLS via automated certificates with auto-renewal; expiry alert at 14 days as a backstop, because auto-renewal failing silently is a classic outage.

## 8. Scaling plan — in order, and only when measured

1. Increase CDN cache-hit ratio (cheapest win by a wide margin)
2. Add web/API replicas (stateless, trivial)
3. Tune Redis cache coverage
4. Add a PostgreSQL read replica for catalog reads
5. Add worker replicas
6. Partition high-volume event tables
7. Optimise the top ten slow queries from `pg_stat_statements`
8. Only then consider service extraction

**Never scale on intuition.** Each step is triggered by a dashboard metric, not a feeling.

## 9. Business continuity

Daily full backup plus continuous WAL for PITR. **Restore rehearsed quarterly** — a scheduled ticket, not an intention. Object storage versioned with lifecycle rules. **RPO 5 minutes, RTO 1 hour**, both validated in the Sprint 14 disaster-recovery exercise, not assumed.

## 10. Cost posture

Free and open source by default across frameworks, database engine, CI, observability, IaC, testing and security scanning.

**Unavoidable costs, disclosed:** domain · production compute · managed PostgreSQL · **object storage and CDN egress — the dominant variable cost, scaling with video watch time** · transactional email above free tier · payment gateway fees · LLM usage (mitigated by caching, small models for classification and hard budgets) · Zoom plan for live cohorts.

A cost model with sensitivity analysis is a Sprint 11 deliverable, once the hosting provider is chosen.
