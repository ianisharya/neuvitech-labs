# 33: Runbooks & Operations

**Every alert has a runbook. An alert without one is noise.** Enforced at review.

## Runbook template
```
ALERT: <name>
SEVERITY: page | warn
MEANING: what is actually wrong, in one sentence
IMPACT: who is affected and how
FIRST CHECK: the single most likely cause
INVESTIGATE: ordered steps
MITIGATE: how to stop the bleeding now
FIX: how to resolve properly
ESCALATE: when to wake the other person
POST: what to record afterwards
```

---

## RB-01: Payment success rate below 95%
**Impact:** learners cannot buy. Revenue stopped.
**First check:** provider status page. Is it them or us?
**Investigate:** payments dashboard → failure codes → recent deploys → webhook backlog → provider API latency.
**Mitigate:** if it is us and a recent deploy correlates, **roll back immediately**: do not debug forward with money on the line. If it is the provider, enable the maintenance banner via settings (no deploy) and monitor.
**Fix:** address the failure code class. Reconcile any orders stuck in `PENDING_PAYMENT`.
**Escalate:** immediately. This is the highest-severity alert in the system.
**Post:** count affected orders, confirm every one either completed or refunded, write an incident note.

## RB-02: Webhook backlog above 50 or older than 10 minutes
**Impact:** paid learners not receiving access. Silent, and worse than a visible outage.
**First check:** is the worker running? `make ps` / platform console.
**Investigate:** queue depth, worker logs, dead-letter queue, provider retry status.
**Mitigate:** restart the worker; scale up a replica. **Run reconciliation manually** to grant entitlements the webhooks would have.
**Fix:** address the underlying error class.
**Post:** verify every affected learner has correct access. Contact anyone who waited more than an hour.

## RB-03: API 5xx above 1%
**First check:** GlitchTip for the dominant exception; correlate with deploy markers.
**Investigate:** which route, which exception, since when, which deploy.
**Mitigate:** roll back if a deploy correlates. If a single feature, **turn its flag off**: no deploy needed.
**Escalate:** if error rate exceeds 5% or continues past 15 minutes.

## RB-04: `/ready` failing
**First check:** which dependency does the response name?
**Investigate:** Postgres reachable? Redis reachable? Connection pool exhausted? Migrations at head?
**Mitigate:** restart the affected service; fail over the database if managed failover is available.
**Note:** `/health` should still return 200, if it does not, the process itself is unhealthy, not a dependency.

## RB-05: Database connection pool above 85%
**Investigate:** `pg_stat_activity` for long-running queries; recent deploy introducing an N+1; traffic spike.
**Mitigate:** terminate long-running queries; increase pool size (a **setting**, no deploy); scale replicas.
**Fix:** add the missing index or eager-load. **Add a regression test.**

## RB-06: Job dead-letter queue non-empty
**Investigate:** which job, which error, how many.
**Mitigate:** fix and replay. Never silently discard, a discarded certificate-issuance job is a learner without their credential.

## RB-07: Certificate issuance failure
**Impact:** learners completed but received nothing. **High reputational cost.**
**Investigate:** worker logs, eligibility evaluation, signing key availability, PDF rendering.
**Mitigate:** fix and re-run. Issuance is idempotent, so replay is safe.
**Post:** proactively notify affected learners. Do not wait for them to ask.

## RB-08: AI cost above 80% of daily budget
**Mitigate:** reduce sample rate or **disable the AI feature flag**: no deploy. AI is never in a critical path, so disabling it degrades nothing essential.
**Investigate:** which capability, which user, is it a loop or abuse?

## RB-09: TLS certificate expiring within 14 days
**Investigate:** why did auto-renewal not run? DNS validation failing?
**Mitigate:** renew manually.
**Note:** this alert exists because silent auto-renewal failure is a classic total outage.

## RB-10: Backup failure
**Escalate immediately.** Investigate storage quota, credentials, database load. **Verify the last successful backup is still restorable**: do not assume.

## RB-11: Deployment failed
**Mitigate:** the previous version is still live; there is no user impact yet. Stop, do not retry blindly.
**Investigate:** which stage, build, migration, health check, smoke?
**If the migration ran but the deploy failed:** the database may be ahead of the code. Because migrations are expand/contract, the previous image still works, **this is exactly the scenario that pattern exists for.**

## RB-12: Suspected security incident
1. **Preserve evidence.** Do not delete logs.
2. Contain: revoke affected sessions, rotate the credential, block the source.
3. Assess: what was accessed? Consult the audit log.
4. Notify per obligations if personal data is involved.
5. Fix the root cause, add a regression test.
6. Write a post-incident review.
**Escalate immediately, always. Both engineers involved.**

---

## Routine operations

| Task | Frequency | Owner |
|---|---|---|
| Check dashboards | Daily | Rotating |
| Review error tracker | Daily | Rotating |
| Dependency update PRs | Weekly | Track B |
| **Backup restore rehearsal** | **Quarterly** | Both |
| Disaster-recovery exercise | Quarterly | Both |
| Access review | Quarterly | You |
| Cost review | Monthly | You |
| Performance review (slow queries, Web Vitals) | Monthly | Track A |
| Security scan review | Weekly | Track B |

## Incident severity

| Sev | Meaning | Response | Examples |
|---|---|---|---|
| **1** | Platform down, or money/data at risk | Immediate, both engineers | Site down, payments broken, data breach |
| **2** | Major feature broken | Within hours | Checkout failing for a subset, video not playing |
| **3** | Minor feature broken | Next session | A page renders wrong |
| **4** | Cosmetic | Backlog | Copy error |

Every Sev-1 and Sev-2 gets a written post-incident review: timeline, root cause, impact, what worked, what did not, actions with owners. **Blameless, the target is the system, not the person.**
