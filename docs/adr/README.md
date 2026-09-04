# Architecture Decision Records

**Format:** Context · Decision · Alternatives Considered · Consequences · Trade-offs · Cost · Security · Scalability · Migration Path · Revisit Trigger · Status.

**ADRs exist to be challenged.** Bring evidence and we change them. The default, absent evidence, is that we execute what is recorded.

| ADR | Decision | Ratified |
|---|---|---|
| 0001 | Modular monolith over microservices | Sprint 1 |
| 0002 | Python 3.12 + FastAPI; async SQLAlchemy retained | Sprint 1 |
| 0003 | PostgreSQL 16 as the single system of record | Sprint 1 |
| 0004 | Next.js 15 as presentation/BFF, zero business logic | Sprint 1 |
| 0005 | uv as the Python project manager | Sprint 1 |
| 0006 | Single-repository monorepo with enforced module boundaries | Sprint 1 |
| 0007 | **VS Code Dev Containers as the cross-platform contract** | Sprint 1 |
| 0008 | Database-driven runtime configuration; nine bootstrap env vars | Sprint 2 |
| 0009 | ARQ over Celery for background jobs | Sprint 2 |
| 0010 | Catalog type registry: hybrid JSONB + capability extension tables | Sprint 5 |
| 0011 | shadcn/ui vendored, restyled to our own tokens | Sprint 5 |
| 0012 | Trunk-based Git with environment promotion, over GitFlow | Sprint 2 |
| 0013 | Kubernetes deferred; container platform + managed Postgres (amended 3 Sep 2026 for the 5,000-concurrent scale target; decision holds) | Sprint 11 |
| 0014 | Self-hosted OpenTelemetry stack over SaaS APM | Sprint 4 |
| 0015 | Enterprise sponsorship, employer talent pipeline, interview coaching, added via competitive gap analysis | 3 Sep 2026 |
| 0016 | **Three-tier access model, subscription-primary, EMI removed** | 3 Sep 2026 |
| 0017 | **Video: adaptive bitrate over CDN, near-live broadcast for live** | 3 Sep 2026 |
| 0018 | **AI tutor: agentic, open-source models, persistent memory, no third-party tracing** | 3 Sep 2026 |
