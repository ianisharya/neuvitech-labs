# 25: Master Roadmap

**Start Mon 31 Aug 2026 · Sprint = 14 days = Mon→Sun · 49 team-hours per sprint**
**Every day and every sprint requires explicit approval. Nothing advances automatically.**

---

## Phase A: Foundation & Environment · Sprints 1–2 · 31 Aug → 27 Sep 2026

| S | Dates | Theme | Outcome | Pts |
|---|---|---|---|---|
| 1 | 31 Aug – 13 Sep | **Environment & Repository Foundation** | Both machines run the identical Dev Container; repo governed; first CI green | 32 |
| 2 | 14 – 27 Sep | **Platform Skeleton & Data Layer** | API + web boot; settings from DB; Postgres, Redis, migrations, logging, errors, health; deploys to DEV | 32 |

## Phase B: Core Platform · Sprints 3–7 · 28 Sep → 6 Dec 2026

| S | Dates | Theme | Outcome | Pts |
|---|---|---|---|---|
| 3 | 28 Sep – 11 Oct | **Identity & Security** | Argon2id, sessions, MFA, RBAC, audit, rate limiting, security scanning in CI | 38 |
| 4 | 12 – 25 Oct | **Settings, Content & Observability** | Everything database-driven; admin settings UI; OTel → Grafana live | 38 |
| 5 | 26 Oct – 8 Nov | **Catalog Core & Design System** | Type registry, versioning, relationships, publishing; design tokens; restyled components | 38 |
| 6 | 9 – 22 Nov | **Public Catalog, Discovery & SEO** | Programs/Tracks/Specializations live, indexable, fast | 42 |
| 7 | 23 Nov – 6 Dec | **Commerce, Subscriptions & Payments** | **REVENUE CAPABLE**: three-tier access (free, subscription, one-time), verified webhook, entitlement, enrolment; no EMI (docs 09, ADR-0016) | **36** |

## Phase C: Learning, Commerce & Credentials · Sprints 8–11 · 7 Dec 2026 → 31 Jan 2027

| S | Dates | Theme | Outcome | Pts |
|---|---|---|---|---|
| 8 | 7 – 20 Dec | **LMS Core & Video Foundations** | Enrol, learn, track progress; adaptive-bitrate recorded video over CDN, one player (docs 10, 41); near-live streaming at scale hardened later in Sprint 22 | 42 |
| 9 | 21 Dec – 3 Jan | **Assessments, Projects & Free Certifications** | Free certification courses end to end with real assessment | 42 |
| 10 | 4 – 17 Jan | **Certificates, Brochures & Portfolio** · *track swap* | Verifiable credentials; brochures generated from catalog; co-branded partner certificates (`docs/39` §4, added via ADR-0015) | 42 |
| 11 | 18 – 31 Jan | **Masterclasses, Live Learning, Subscriptions & Cloud Setup** | Live cohorts; recurring revenue; production infrastructure provisioned | 42 |

## Phase D: Launch · Sprints 12–14 · 1 Feb → 14 Mar 2027

| S | Dates | Theme | Outcome | Pts |
|---|---|---|---|---|
| 12 | 1 – 14 Feb | **Admin, Analytics & CI/CD to Production** | Full admin console; investor metrics; pipeline proven end to end to PROD | 38 |
| 13 | 15 – 28 Feb | **Hardening: Security, Performance & Observability Validation** | Load tested, pen-tested, **failure injection proves alerts fire** | 38 |
| 14 | 1 – 14 Mar | **Production Deployment, UAT & Observation** | **PRODUCTION LAUNCH + 72-hour observation window closed clean** | 38 |

## Phase E: Extended Scope & Scale · Sprints 15–24 · 15 Mar → 1 Aug 2027

| S | Dates | Theme | Pts |
|---|---|---|---|
| 15 | 15 – 28 Mar | Billing, Tax & Invoicing (subscription and one-time; no EMI) | 40 |
| 16 | 29 Mar – 11 Apr | Careers & Job Board | 40 |
| 17 | 12 – 25 Apr | Community & Content | 40 |
| 18 | 26 Apr – 9 May | AI Foundation, gateway, guardrails, RAG | 40 |
| 19 | 10 – 23 May | Agentic AI, tutor, advisor, learning paths, **AI Interview Coach** (`docs/39` §5, formalizes a capability anticipated but unbuilt since Sprint 1) | 40 |
| 20 | 24 May – 6 Jun | ITES/Solutions, Performance at Scale & v2 Release | 40 |
| 21 | 7 – 20 Jun | **Enterprise: Corporate Sponsorship & Employer Talent Pipeline**: added via ADR-0015, closes a competitive gap found 3 Sep 2026 | 40 |
| 22 | 21 Jun – 4 Jul | **Video pipeline and near-live streaming at scale**: adaptive bitrate, CDN delivery, live broadcast plus recording, processing pipeline (docs 41, ADR-0017) | 40 |
| 23 | 5 – 18 Jul | **Problem-solving platform and AI tutor memory**: exercises with solutions, AI-tutor chat help, persistent tutor memory (docs 10, 12, ADR-0018) | 40 |
| 24 | 19 Jul – 1 Aug | **Karma, streaks and goodies store**: verified-event karma, streak multiplier, karma-priced goodies through existing commerce (doc 40) | 40 |

---

## Why this sequence

**Setup before code (S1).** You cannot review code on a machine that cannot run it.

**Skeleton and data layer before features (S2).** Config, database, migrations, logging and error handling are touched by every later ticket. Building them once, properly, is far cheaper than retrofitting.

**Identity before everything (S3).** No authorization without principals.

**Settings and observability early (S4).** Both are cross-cutting. Adding observability at the end means retrofitting instrumentation into every module; adding the settings system late means ripping out hard-coded values everywhere. **Doing them in Sprint 4 makes every subsequent sprint database-driven and observable by default.**

**Catalog before commerce (S5–S7).** You cannot sell what you cannot model.

**Payments at Sprint 7 with reduced points.** Highest-risk sprint in the programme, external integration, ×2.0 rework multiplier, money at stake. Committed at 36 points rather than 42.

**Certificates (S10) before Masterclasses (S11).** Credentials are the credibility proposition; live learning depends on Zoom, which can slip without blocking launch.

**Cloud infrastructure in Sprint 11**, three sprints before launch, so provisioning problems surface with time to fix them.

**Three full sprints for launch (S12–S14).** Not "deploy on the last day". Pipeline proven (S12), system hardened and observability *validated by breaking it* (S13), production deployed with a 72-hour observation window (S14).

**Phase E is entirely additive.** Careers and community are new bounded contexts; financing plugs into the existing `PaymentProvider` protocol; AI attaches through the gateway; ITES is content-only. Nothing requires re-architecting Phase A–D.

---

## Milestones

| M | End of | Date | Demonstrates |
|---|---|---|---|
| M1 | S1 | 13 Sep | **Both machines byte-identical**; repo governed; CI green |
| M2 | S2 | 27 Sep | Walking skeleton; **settings load from the database**; deploys to DEV |
| M3 | S3 | 11 Oct | Secure identity: auth, MFA, RBAC, audit |
| M4 | S4 | 25 Oct | **Nothing hard-coded**; traces visible end to end in Grafana |
| M5 | S5 | 8 Nov | **Catalog extensibility proven**: new product kind by configuration, zero code |
| M6 | S6 | 22 Nov | Public product live, indexable, meeting Core Web Vitals budgets |
| M7 | S7 | 6 Dec | **First real payment → entitlement → enrolment** |
| M8 | S8 | 20 Dec | Learning works end to end with video |
| M9 | S10 | 17 Jan | Verifiable certificate from real completion |
| M10 | S12 | 14 Feb | **Pipeline proven to production** |
| M11 | S13 | 28 Feb | **Alerts proven by deliberate failure injection** |
| M12 | S14 | **14 Mar** | **PRODUCTION LAUNCH, 72-hour observation clean** |
| M13 | S20 | 6 Jun | ITES/Solutions and v2 release complete |
| M14 | S21 | 20 Jun | Corporate sponsorship, employer talent pipeline live |
| M15 | S24 | **1 Aug** | **Full brief scope**: video at scale, problem-solving, AI tutor with memory, karma and goodies all live |

## External dependencies: start early

| Ticket | Dependency | Needed by | **Start in** | Lead time |
|---|---|---|---|---|
| NVL-EXT-01 | **Razorpay merchant KYC** | S7 | **S2** | **2–4 weeks, longest in the programme** |
| NVL-EXT-02 | Email sending domain (DNS) | S5 | S2 | 2–5 days |
| NVL-EXT-03 | `neuvitechlabs.com` + Cloudflare | S6 | S2 | Hours |
| NVL-EXT-04 | Cloud hosting + managed Postgres | S11 | S8 | Days |
| NVL-EXT-05 | Object storage + CDN | S8 | S7 | Hours |
| NVL-EXT-06 | Zoom account + API app | S11 | S9 | Days |
| NVL-EXT-07 | LLM provider key | S18 | S17 | Immediate |

## Out of scope, all phases

Mobile apps · live proctoring · translated content (i18n scaffolding only) · instructor-marketplace self-publishing · SCORM/xAPI · enterprise SSO/SAML · microservices · Kubernetes · multi-tenancy. Each has a revisit trigger in `adr/`.
