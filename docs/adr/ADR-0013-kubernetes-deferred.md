# ADR-0013: Kubernetes Deferred; Container Platform + Managed PostgreSQL

**Status:** Accepted · **Date:** Sprint 11

## Context

Production infrastructure needs to run a modular monolith API, a Next.js presentation app, and an ARQ worker, backed by PostgreSQL, Redis and object storage (`docs/04`, `docs/13`). Modelled capacity (`docs/04` §6) is comfortably within a small number of stateless replicas. The team is two engineers, provisioning production infrastructure for the first time in Sprint 11.

## Decision

A managed container platform plus managed PostgreSQL and Redis (`docs/13` §3), not Kubernetes.

## Alternatives Considered

**Kubernetes**, self-managed or via a managed offering (EKS, GKE, AKS). Seriously considered, since it is the default reach for "how do we run containers in production" in much of the industry. Rejected at this scale: Kubernetes' value proposition is workload flexibility, multi-team ownership boundaries, and sophisticated scheduling, none of which we need with one deployable API, one presentation app, and one worker, all scaling together. What Kubernetes does add at this team size is operational surface: cluster upgrades, node pool management, ingress and networking configuration, RBAC on top of the application's own authorization, and a genuinely large set of new failure modes two engineers would need to learn while also building the product. That learning cost would consume sprint capacity that belongs to the product, for capability we are not using.

**A fully serverless model (Lambda-style functions for the API).** Rejected in ADR-0001 already, for the modular monolith decision generally, cold starts hurt the catalog latency budget and local development parity is poor. The reasoning carries over here: serverless does not fit a stateful, session-heavy, latency-sensitive monolith.

**Self-managing PostgreSQL and Redis on the same container platform, rather than using managed services for them.** Rejected specifically for PostgreSQL, losing the database is unrecoverable, and PITR, failover, and patching are exactly the kind of operational burden two part-time-on-infrastructure engineers should not be responsible for getting right under pressure. Redis is lower-stakes (cache-aside, recoverable from cold) but managed Redis removes an entire category of "did we configure persistence correctly" risk for a small cost difference.

## Consequences

**Positive:** dramatically lower operational burden, no cluster to patch, no node pools to size, no Kubernetes-specific failure modes to learn under pressure · the application is already stateless and twelve-factor (`docs/04` §7), so migrating to Kubernetes later is packaging work, not a rewrite, if the revisit trigger below is ever hit · sprint capacity in Sprint 11 goes to provisioning and validating the actual production path, not to a Kubernetes learning curve.

**Negative:** less workload flexibility if requirements genuinely diverge later (different scaling profiles per component, multi-team ownership) · fewer of the sophisticated deployment patterns (canary via service mesh, fine-grained traffic shaping) that Kubernetes ecosystems make easy, though `docs/13` §6's canary approach does not require them at this scale.

## Trade-offs

We give up Kubernetes' flexibility and its large ecosystem of tooling, in exchange for an infrastructure footprint two engineers can actually operate correctly under real production pressure. Given the modelled load (`docs/04` §6) does not need that flexibility yet, and the team does not have spare capacity to absorb the learning curve, the trade favours the simpler platform.

## Cost

Lower than self-managed Kubernetes at this scale, no cluster management overhead, and managed database/cache services, while not free, remove operational cost that would otherwise require engineering time to replicate safely.

## Security

Fewer moving parts means a smaller infrastructure attack surface, no Kubernetes RBAC to configure correctly on top of the application's own authorization model (`docs/08`), no ingress controller to secure separately. Managed database services bring vendor-managed patching and encryption at rest as a baseline rather than something we configure ourselves.

## Scalability

Sufficient for modelled load with room to grow via the explicit staged plan in `docs/13` §8, CDN cache-hit ratio first, then replicas, then Redis tuning, then a read replica, then worker replicas, then partitioning, each step measured against a real metric before being taken, not applied speculatively.

## Migration Path

The application's statelessness (`docs/04` §7) is the actual migration path, containers that run correctly on the current platform run correctly on Kubernetes without application-level changes, only deployment configuration changes, if the revisit trigger is ever hit.

## Revisit Trigger

Replica count exceeding roughly 8, or multiple teams needing independent deploy cadence for different parts of the system, both already recorded as the Kubernetes revisit trigger in `docs/03` §3 and restated here in the actual infrastructure decision.

## Reassessment, 3 Sep 2026 - scale target raised to 5,000 concurrent and up

The scale target was raised from the original modest estimate to a baseline of five thousand concurrent learners, built to scale beyond, alongside integrated live and recorded video. This naturally reopened the Kubernetes question, and after review the decision stands. The reasoning is worth recording because it is the reasoning, not the original numbers, that matters.

Large scale is hard to operate when it involves sprawling stateful infrastructure. The revised design in doc 13 deliberately pushes nearly all of that difficulty onto managed services and a content delivery network. Video, the heaviest load by far, is served from the edge and barely touches the application. The database, cache, and storage are managed services whose hard operational parts are the provider's responsibility. What remains of the application is stateless copies behind a load balancer, which a managed container platform scales automatically without Kubernetes and without turning two engineers into cluster operators.

Kubernetes earns its complexity with many independently scaled services, multiple teams needing independent deploys, or scheduling needs a simpler platform cannot meet. The platform has one application, one worker pool, and two engineers, and meets none of those conditions. Adopting Kubernetes would be a large operational tax for unused flexibility and a large new surface of failure modes learned under production pressure.

The decision therefore holds at the higher scale target, for a reason scale did not change: the application scales by running more stateless copies, and that does not require Kubernetes. The revisit trigger is unchanged. If the platform grows into many independently scaled services, or multiple teams deploying independently, or a genuine scheduling need, Kubernetes returns to the table. Until then it is complexity without payoff.
