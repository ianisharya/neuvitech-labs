# 14 — Observability Architecture

**Observability is part of the product, not an afterthought.** It is built from Sprint 2 and validated by deliberately breaking things in Sprint 13. **It is not complete until it has been tested.**

## 1. Stack

| Signal | Tool | Why |
|---|---|---|
| Instrumentation | **OpenTelemetry** | Vendor-neutral. Changing backends is a collector config change, not a code change |
| Logs | **Loki** | Label-based, cheap, integrates with Grafana |
| Metrics | **Prometheus** | The standard; excellent query language |
| Traces | **Tempo** | Native OTel, integrates with Loki and Prometheus |
| Dashboards & alerts | **Grafana** | One pane over all three signals |
| Errors | **GlitchTip** | Sentry-compatible API, self-hostable, free |
| Uptime | **External synthetic checks** | Must be outside our infrastructure to catch total outages |

All self-hostable and free. No student PII leaves our infrastructure.

## 2. Logs

Structured JSON, one line per event, always carrying `request_id`, `user_id` (when authenticated), `route`, `method`, `status`, `latency_ms`, `environment`, `version`.

```python
logger.info("order.placed", order_id=str(order.id), total_minor=order.total_minor,
            currency=order.currency, user_id=str(user.id))
```

- **Event names are `noun.verb` and stable** — they are queried, so renaming one breaks dashboards.
- **PII excluded by an allow-list serialiser**, never a blocklist. A blocklist fails silently the moment someone adds a field.
- **Never logged:** passwords, tokens, card data, full request bodies on sensitive routes, prompt or completion text.
- Levels: `DEBUG` local only · `INFO` business events · `WARNING` recoverable · `ERROR` needs attention · `CRITICAL` pages someone.
- Log level is **per-module and settings-driven**, so raising verbosity on `payments` in production is an admin toggle, not a deploy.

## 3. Metrics

**RED per endpoint** — Rate, Errors, Duration (p50/p95/p99).
**USE per resource** — Utilisation, Saturation, Errors: CPU, memory, DB connection pool, Redis memory, disk.

**Business metrics, which are the ones that actually matter:**
`signups` · `checkout_started` · `checkout_completed` · `payment_success_rate` · `webhook_lag_seconds` · `webhook_backlog` · `entitlements_granted` · `enrolments_created` · `lessons_completed` · `certificates_issued` · `brochures_downloaded` · `ai_cost_per_day` · `video_cdn_hit_ratio` · `job_queue_depth` · `job_failure_rate`.

**Why business metrics belong in Prometheus:** a 200-OK API with zero completed checkouts is an outage that no infrastructure metric will show you.

## 4. Traces

OpenTelemetry across Next.js → FastAPI → PostgreSQL / Redis / providers. **One correlation id from browser to database.** Auto-instrumentation for FastAPI, SQLAlchemy, Redis and httpx; manual spans around business operations (`checkout.complete`, `certificate.issue`, `brochure.generate`).

Sampling: 100% for errors and slow requests, configurable percentage otherwise, rate set in settings.

## 5. Health checks

| Endpoint | Checks | Used by |
|---|---|---|
| `/health` | Process alive. **Touches nothing.** | Load balancer liveness |
| `/ready` | Postgres and Redis reachable, migrations at head, per-dependency status and latency | Deploy gate, readiness probe |
| `/health/deep` | Object storage, mail, payment provider reachability | Scheduled monitor only |

`/health` must never query the database. A liveness probe that touches the database restarts healthy application containers during a database blip, turning a small incident into an outage.

## 6. Alerts — symptom-based, each with a runbook

| Alert | Condition | Severity |
|---|---|---|
| Payment success rate low | < 95% over 15 min | **Page** |
| Webhook backlog | > 50 unprocessed or age > 10 min | **Page** |
| API error rate | 5xx > 1% over 5 min | **Page** |
| Service down | `/ready` failing 3 consecutive checks | **Page** |
| Database connections | Pool > 85% for 5 min | Warn |
| API latency | p95 > 1 s on catalog or checkout | Warn |
| Job dead-letter | Queue non-empty | Warn |
| Certificate issuance failure | Any failure | Warn |
| AI cost budget | > 80% of daily cap | Warn |
| Disk | > 80% | Warn |
| Certificate expiry (TLS) | < 14 days | Warn |
| Backup failure | Any | **Page** |

**An alert without a runbook is noise.** Enforced at review: adding an alert requires adding a runbook section in `33-runbooks-and-operations.md`.

**Noise reduction:** alerts group by service, inhibit downstream alerts when an upstream one fires, and use `for:` durations so a five-second blip does not page anyone at 3am.

## 7. Dashboards

| Dashboard | Contents |
|---|---|
| **Service health** | RED per endpoint, error budget, deploy markers |
| **Business** | Signups, checkouts, payment success, enrolments, completions, certificates |
| **Infrastructure** | CPU, memory, disk, network, container restarts |
| **Database** | Connections, slow queries, cache hit ratio, replication lag, table sizes |
| **Jobs** | Queue depth, throughput, failures, retries, dead letters |
| **Payments** | Attempts, success rate, webhook lag, reconciliation gaps, refunds |
| **AI** | Invocations, tokens, cost, latency, guardrail events, refusals |
| **Frontend** | Core Web Vitals, JS errors, slowest routes |

## 8. Operational validation — Sprint 13, and this is the part people skip

**Observability is not complete when it is configured. It is complete when a deliberately broken system produces the expected alert, log, trace and dashboard change.**

The Sprint 13 exercise, executed by you:

| # | Injected failure | Must observe |
|---|---|---|
| 1 | Stop PostgreSQL | `/ready` 503, alert fires, log shows the failure, dashboard turns red |
| 2 | Stop Redis | Cache misses in traces, degraded latency, warn alert, **service still serving** |
| 3 | Send a malformed webhook | Signature rejection logged, no entitlement granted, security event recorded |
| 4 | Force a 500 in an endpoint | Error in GlitchTip with correlation id, trace shows the failing span |
| 5 | Fill the job queue | Depth alert, dead-letter behaviour correct |
| 6 | Exhaust the DB connection pool | Saturation alert before user-visible failure |
| 7 | Deploy a broken build | CI blocks it; if forced, health check fails and rollback triggers |
| 8 | Simulate a payment provider outage | Circuit breaker opens, checkout disabled with an honest message, browsing unaffected |
| 9 | Expire a TLS certificate (staging) | Expiry alert fires |
| 10 | Delete a row and restore from backup | PITR works; RPO and RTO measured against targets |

**Each of these is a Jira subtask with human execution time.** They are how we find out that an alert was misconfigured *before* it matters.

## 9. Post-deployment observation — Sprint 14

Production is not "done" at deploy. A **72-hour observation window** with scheduled check-ins:

| When | Check |
|---|---|
| +15 min | Smoke tests, error rate, all dashboards green |
| +1 hour | Latency percentiles, first real user flows, no unexpected 4xx pattern |
| +4 hours | Background jobs completing, no queue growth, webhook lag normal |
| +24 hours | Full daily cycle: scheduled jobs, backups ran, no memory growth |
| +48 hours | Performance under real traffic, DB query plans on real data volumes |
| +72 hours | Formal sign-off, or issue list with owners |

**The project is not complete until the 72-hour window closes clean.**
