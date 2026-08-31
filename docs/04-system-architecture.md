# 04 — System Architecture

## 1. Style: modular monolith

One deployable API composed of strictly bounded modules, one presentation app, one worker process sharing the same codebase and image.

**Why not microservices:** the core aggregates (`catalog → product → order → entitlement → enrolment`) are *transactionally coupled*. Splitting them replaces local ACID transactions with distributed sagas and compensating actions — a hard problem for an expert team and an unreasonable one at 49 team-hours a week. Microservices solve an *organisational* problem (many teams, independent deploys) that we do not have. Full reasoning in ADR-0001.

**The one process boundary we accept:**

```
                          Browser
                             │
                    ┌────────▼────────┐
                    │  Next.js 15     │  SSR · SEO · BFF
                    │  ZERO business  │  session cookie only
                    │  logic          │
                    └────────┬────────┘
                             │ private network, server-to-server
                    ┌────────▼────────┐
                    │   FastAPI       │  SYSTEM OF RECORD
                    │   all domain    │  all rules, all authorization
                    │   logic         │
                    └────────┬────────┘
          ┌──────────┬───────┼────────┬──────────────┐
          ▼          ▼       ▼        ▼              ▼
     PostgreSQL   Redis   Object   External      ARQ Worker
     + pgvector           Storage  Providers    (same image,
     (system of   cache,  (private  payments,    same domain
      record)     queue,  media)    email,       code)
                  limits            meetings,
                                    LLM
```

Next.js holds **no business rules**. If a rule can be enforced client-side it must *also* be enforced in FastAPI, and FastAPI is authoritative.

## 2. Module boundaries

```
modules/
├── identity/      users, sessions, MFA, roles, permissions, audit
├── settings/      runtime configuration, feature flags, content, navigation
├── catalog/       type registry, catalog items, versions, relationships, publishing
├── learning/      courses, modules, lessons, progress, resources
├── live/          cohorts, sessions, meeting provider, attendance, recordings
├── assessment/    quizzes, exams, projects, submissions, grading
├── credential/    certificates: eligibility, issuance, verification, revocation
├── document/      brochures: generation, versioning, access, analytics
├── commerce/      products, prices, offers, coupons, checkout, orders
├── payments/      provider adapters, webhooks, reconciliation, refunds
├── entitlement/   entitlements and enrolments
├── careers/       jobs, applications, screening
├── community/     articles, events, showcases, profiles
├── ai/            gateway, guardrails, agents, tools, evaluations
├── analytics/     event ingest, aggregation, metrics
└── admin/         administrative surfaces over every module
```

**Each module owns its tables, its service layer, and its public interface.** Cross-module access goes through the target module's service functions or published domain events — **never** by importing another module's ORM models or querying its tables. `import-linter` enforces this in CI.

That rule is what makes the monolith *modular* rather than merely co-located, and it is what makes future service extraction a mechanical exercise rather than archaeology.

## 3. Request lifecycle

```
Browser
 → CDN (public pages, stale-while-revalidate)
 → Next.js Server Component
     ├ reads public settings (cached)
     └ calls FastAPI with the session cookie
 → FastAPI middleware chain
     ├ request id assigned / propagated
     ├ structured log entry opened
     ├ OTel span started
     ├ CORS + security headers
     ├ rate limit (Redis token bucket)
     ├ session resolution (opaque token → Redis → Postgres fallback)
     └ authorization (single PDP — permission or explicitly @public)
 → Router: validate (Pydantic) → delegate
 → Service: business rules, transaction boundary
 → Repository: parameterised queries, ownership filtered IN the query
 → PostgreSQL
 ← Response schema (never an ORM object)
 ← Audit row if mutating
 ← Span closed, metrics recorded, log entry closed
```

## 4. Write path with events

```
Service begins transaction
  ├ mutate aggregate
  ├ write audit_log row
  └ write outbox_event row          ← same transaction
Commit
  ↓
Outbox relay (ARQ, polls every 2s)
  ├ publish event
  └ mark dispatched
  ↓
Subscribers: cache invalidation · brochure regeneration · notifications · analytics
```

**The transactional outbox exists because the alternatives are both broken:** publishing before commit emits events for transactions that roll back; publishing after commit loses events when the process dies between the two. Writing the event in the same transaction and relaying it afterwards is the only correct option.

## 5. Read path and caching

Catalog reads are ~85% of traffic and highly cacheable.

```
CDN → Next.js ISR → Redis cache-aside → materialised read model → PostgreSQL
```

- **Materialised read model** `catalog_page_view` (JSONB per published version) assembled at publish time, turning a six-table join with recursive traversal into one primary-key lookup.
- **Version-keyed invalidation:** `catalog:v{schema}:{kind}:{slug}:{version}`. Publishing changes the key, so stale entries expire naturally and there is no invalidation race.
- **Never cached:** authorization decisions, entitlements, user-specific resolved prices, payment state, any PII. Enforced by a lint rule on the cache decorator plus a test.

## 6. Capacity model

Assumptions are labelled as mine and should be corrected once real traffic exists.

| Quantity | Assumption | Estimate |
|---|---|---|
| Registered users (year 1) | assumption | 300,000 |
| MAU | 15% | 45,000 |
| Peak concurrent | 2% of MAU | ~900 |
| Peak API RPS | 3 req/s per concurrent, ~85% cacheable | ~2,700 |
| Uncached DB RPS | remainder | ~400 |
| Progress writes | 1 event / 3 min / active learner | ~250/s |
| Catalog data | hundreds of items, thousands of lessons | < 10 GB |
| Video | **dominant cost** — object storage + CDN, not Postgres | see doc 13 |

**Reading:** a single well-indexed Postgres primary with a read replica, behind Redis and a CDN, absorbs this comfortably. **The scaling problem for this product is video egress and cache hit ratio, not database throughput.** The architecture is optimised accordingly — which is why we are not building for sharding we will not need.

## 7. Evolution path — do not pre-build

```
Modular monolith
  → horizontal stateless replicas
  → Redis + CDN tuning
  → dedicated worker pool
  → database read replica
  → table partitioning for event streams
  → selective service extraction
  → Kubernetes only when replica count or multi-team ownership justifies it
```

The application is written stateless and twelve-factor from day one, so each step is packaging, not rewriting.

## 8. Failure posture

| Dependency down | Behaviour |
|---|---|
| Redis | Cache misses fall through to Postgres; rate limiting fails **closed** for auth, **open** for reads |
| Object storage | Media unavailable; browsing, checkout and text lessons unaffected |
| Payment provider | Checkout disabled with an honest message; browsing and learning unaffected |
| Email | Queued with retry; nothing blocks on delivery |
| Meeting provider | Session marked disrupted; recording backfilled later |
| LLM provider | AI features hide themselves; **nothing in the learning or commerce path waits on a model** |
| CDN | Origin serves at reduced performance |

Every third-party sits behind a provider protocol with timeout, retry-with-jitter and a circuit breaker.
