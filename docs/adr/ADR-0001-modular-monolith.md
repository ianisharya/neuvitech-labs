# ADR-0001 — Modular Monolith over Microservices

**Status:** Accepted · **Date:** 2026-08-30

## Context
Greenfield platform (repository verified empty). Two non-expert engineers at 49 team-hours per sprint. The domain spans catalog, commerce, payments, entitlements, LMS, credentials, careers, community and AI. Target scale is eventually hundreds of thousands of users; today it is zero.

## Decision
A modular monolith: one deployable API composed of strictly bounded modules under `modules/`, plus a presentation app and a worker sharing the same codebase and image. Boundaries enforced in CI by `import-linter`.

## Alternatives Considered
**Microservices** — rejected. Our core aggregates (`catalog → product → order → entitlement → enrolment`) are transactionally coupled; splitting them replaces local ACID transactions with distributed sagas and compensating actions. That is hard for an expert team and unreasonable at our capacity. Microservices solve an organisational problem — many teams needing independent deploys — that we do not have.

**Unstructured monolith** — rejected. Without enforced boundaries a codebase this size becomes unmaintainable within a year, and later extraction becomes archaeology.

**Serverless functions** — rejected. Cold starts hurt the catalog latency budget, local development parity is poor, and long-running work (PDF generation, video processing) fits badly.

## Consequences
**Positive:** one deploy, one log stream, one debugger · local transactions across aggregates · trivial local development · lowest operational burden · module extraction later is mechanical.
**Negative:** the whole application scales as a unit · a memory leak in one module affects all · CI runs everything · boundary discipline must be enforced, since the network does not enforce it.

## Trade-offs
Coarse-grained scaling in exchange for drastically lower operational and cognitive cost. Our load profile is ~85% cacheable catalog reads, so coarse scaling fits well regardless.

## Cost
Near-zero additional infrastructure — one application container plus one worker.

## Security
Fewer network hops, smaller attack surface, single auth boundary. Risk: no network-level isolation between modules — mitigated by the single policy decision point and import-linter enforcement.

## Scalability
Horizontal stateless replicas behind a load balancer. Modelled capacity (~2,700 peak RPS, ~85% cacheable, ~400 uncached DB RPS) is comfortably within a single primary plus a read replica.

## Migration Path
`Modular monolith → replicas → Redis/CDN → dedicated workers → read replicas → selective extraction → Kubernetes if justified`. Because modules already communicate through service interfaces and domain events, extraction means replacing an in-process call with HTTP or a queue.

## Revisit Trigger
Multiple teams needing independent deploy cadence · a module with a measured, genuinely divergent scaling profile · a module with different availability requirements.
