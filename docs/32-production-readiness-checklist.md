# 32: Production Readiness Checklist

**Every box must be ticked before the Sprint 14 production deployment.** Not a formality, each line represents a way systems fail in production.

## Configuration
- [ ] All nine bootstrap environment variables set in the `production` GitHub Environment
- [ ] Every other setting resolves from the database
- [ ] No `os.getenv` outside `core/config.py` (CI-enforced)
- [ ] `ENVIRONMENT=production` verified; API docs return 404
- [ ] `robots.txt` allows indexing on PROD, `Disallow: /` on DEV and QA
- [ ] Canonical host `neuvitechlabs.com` set in settings

## Secrets
- [ ] No secret in code, images, logs, Jira or documentation
- [ ] Gitleaks full-history scan clean
- [ ] Provider keys encrypted in the database with `ENCRYPTION_KEY`
- [ ] `production` environment requires a reviewer
- [ ] Key rotation procedure documented and **rehearsed once**

## Security
- [ ] Every endpoint declares a permission or is explicitly `@public`; startup assertion passes
- [ ] Authorization matrix tested per role
- [ ] MFA enforced for all admin-tier principals
- [ ] Rate limiting active on auth, checkout and AI endpoints
- [ ] Security headers verified with an external scanner
- [ ] TLS 1.3, HSTS preload, valid certificate, auto-renewal configured
- [ ] **Human adversarial testing completed**: IDOR, privilege escalation, tampering
- [ ] DAST (ZAP) run with findings triaged
- [ ] Dependency, container and IaC scans clean of HIGH/CRITICAL
- [ ] Superuser account uses MFA; no hard-coded email comparison anywhere

## Data
- [ ] All migrations applied; head recorded on the release
- [ ] Every migration reversible or documented with a rollback runbook
- [ ] Indexes verified against `EXPLAIN ANALYZE` on production-like volumes
- [ ] **Backup taken and restore rehearsed**: RPO 5 min, RTO 1 h measured, not assumed
- [ ] Read replica configured and lag monitored
- [ ] Connection pool sized and saturation alert set
- [ ] Retention and erasure paths implemented for DSAR

## Application
- [ ] Health and readiness endpoints correct; `/health` touches nothing
- [ ] Graceful shutdown drains in-flight requests
- [ ] Every third-party call has timeout, retry with jitter and a circuit breaker
- [ ] Error handling returns code + correlation id; **no stack trace reaches a user**
- [ ] Idempotency on checkout and every webhook
- [ ] Background jobs have retry, backoff and dead-letter handling
- [ ] Feature flags default to a safe state

## Observability: proven, not configured
- [ ] Structured logs shipping to Loki, PII excluded by allow-list
- [ ] Metrics scraped; RED, USE and **business metrics** all present
- [ ] Traces end to end from browser to database
- [ ] All eight dashboards render with real data
- [ ] **All twelve alerts tested by deliberate failure injection (Sprint 13)**
- [ ] Every alert has a runbook
- [ ] Error tracking receiving events with correlation ids
- [ ] External uptime monitoring from outside our infrastructure

## Performance
- [ ] Load test at 2× expected peak passes
- [ ] p95 latency within budget for catalog and checkout
- [ ] Core Web Vitals in the green band on 4G mobile
- [ ] CDN cache-hit ratio measured and acceptable
- [ ] No N+1 queries on hot paths
- [ ] Resource limits set on every container

## Deployment
- [ ] Pipeline tested end to end, including all ten validation tests
- [ ] **Rollback executed successfully at least once**
- [ ] Canary deployment verified
- [ ] Zero-downtime deploy confirmed
- [ ] Release records image digest, Alembic head and Jira keys

## Commerce
- [ ] Live payment keys configured and a **real low-value transaction completed end to end**
- [ ] Webhook endpoint reachable from the provider; signature verification confirmed
- [ ] Reconciliation job scheduled and verified
- [ ] Refund path tested with a real refund
- [ ] Invoice numbering gap-free under concurrency
- [ ] Tax configuration confirmed for the launch jurisdiction

## Documentation
- [ ] Architecture, setup, API, schema, deployment, observability docs current
- [ ] Runbooks for all twelve alerts
- [ ] Rollback and disaster-recovery procedures written **and rehearsed**
- [ ] Known issues list published
- [ ] Onboarding guide validated by someone following it

## Legal and content
- [ ] Privacy policy, terms of service, refund policy published
- [ ] Cookie consent implemented, defaulting to decline non-essential
- [ ] **No unsubstantiated claims**: no accreditation, no fabricated placement or salary figures
- [ ] Contact and support routes working

## Sign-off
- [ ] UAT complete with findings resolved or explicitly accepted
- [ ] Both engineers sign off
- [ ] Rollback decision-maker and criteria agreed **before** deploying
- [ ] Post-deployment observation schedule agreed
