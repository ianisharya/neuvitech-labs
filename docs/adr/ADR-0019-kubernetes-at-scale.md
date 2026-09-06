# ADR-0019: Kubernetes as the Deployment Substrate, Superseding ADR-0013

**Status:** Accepted. Supersedes ADR-0013.
**Date:** 2026-09-06

## Context

ADR-0013 deferred Kubernetes. Its reasoning was specific and, at the scale target then in force, sound: a single stateless application, a single worker pool, a small operating team, and heavy state pushed onto managed services. That reasoning was re-examined when the concurrency target moved to 5,000 and was found to still hold.

The concurrency target is now 100,000 concurrent users. This is a twenty-fold increase and it invalidates the premises ADR-0013 relied upon.

At 100,000 concurrent the deployment characteristics change in kind, not only in degree:

- Application replica count moves from single digits to a range where manual or platform-level scaling is insufficient, requiring horizontal autoscaling driven by observed metrics.
- Worker capacity for video transcoding, embedding generation, and analytics aggregation requires scheduling across a pool rather than a fixed allocation.
- Traffic distribution across geographic regions becomes a latency requirement rather than an optimization.
- Rolling deployment, health-gated rollout, and automated rollback must operate across many replicas without manual coordination.
- Resource isolation between workload classes, request-serving, background processing, and model inference, becomes necessary to prevent one class from starving another.

These are the conditions under which a container orchestrator provides capability that a simpler platform does not.

## Decision

Kubernetes is adopted as the deployment substrate for all non-local environments.

The specific distribution and configuration are chosen to satisfy the cost and open-source constraints:

- **k3s** or an equivalent lightweight CNCF-conformant distribution for self-hosted clusters. k3s is open source, has substantially lower control-plane resource requirements than a full distribution, and is CNCF-certified, meaning workload manifests remain portable to any conformant Kubernetes.
- **k3d** for local Kubernetes when a developer needs to work on Kubernetes-specific concerns. This is not the default local development mode. See ADR-0022.
- Standard Kubernetes primitives only: Deployment, StatefulSet, Service, Ingress, HorizontalPodAutoscaler, ConfigMap, Secret, Job, CronJob, PodDisruptionBudget, NetworkPolicy, ResourceQuota. No vendor-specific custom resources in the core deployment path.

Portability is a first-order requirement of this decision. Manifests target conformant Kubernetes so that the cluster can move between a self-hosted installation and any managed offering without changing workload definitions.

## Alternatives Considered

**Retain the container platform from ADR-0013.** Rejected on capability grounds. Managed container platforms provide horizontal scaling, but the scheduling control, resource isolation between workload classes, and multi-region coordination required at 100,000 concurrent exceed what they expose. This is a change in requirement, not a change in preference.

**Managed Kubernetes from a cloud provider.** Not rejected, but not selected as the initial deployment. A managed control plane removes real operational burden. It also introduces a recurring cost and a degree of provider coupling that the cost constraints direct against while the deployment remains small. Because the decision targets conformant Kubernetes with standard primitives, migration to a managed offering is a cluster change, not an application change, and can be made when the operational burden justifies the cost.

**Nomad.** Technically viable, lower operational complexity than Kubernetes, open source. Rejected on ecosystem grounds: the observability, autoscaling, ingress, and operator ecosystem the architecture depends on is substantially more mature on Kubernetes, and the portability guarantee of CNCF conformance has no direct Nomad equivalent.

**Docker Compose on multiple hosts with external load balancing.** Rejected. It provides no scheduling, no automated rescheduling on node failure, no metric-driven autoscaling, and no resource isolation between workload classes. It is adequate for local development and is retained for that purpose only.

## Consequences

**Enabled by this decision:**

- Metric-driven horizontal autoscaling per workload class, so request-serving capacity and background-processing capacity scale independently against their own signals.
- Resource requests and limits per workload class, preventing transcoding or inference from starving request handling.
- Rolling deployment with health gating and automated rollback across many replicas without manual coordination.
- Node-failure tolerance through automatic rescheduling.
- A single deployment model that is unchanged from a three-node cluster to a large one, which is what removes the rewrite the scale increase would otherwise require.

**Costs introduced by this decision:**

- Kubernetes has a substantial operational surface: cluster upgrades, node lifecycle, networking, ingress, storage classes, and role-based access control are all now operational responsibilities.
- The failure modes are more numerous and less obvious than those of a simpler platform. Diagnosing a scheduling or networking failure requires Kubernetes-specific knowledge.
- The team-size assumption that ran through prior planning documents does not hold at this operational surface. This is stated as a known constraint requiring resolution rather than assumed away. See the open question below.

## Cost Position

k3s, k3d, and every Kubernetes primitive used are open source with no licence cost. Cluster compute is the cost, and it scales with the number and size of nodes, which is under direct control.

The architecture is designed for 100,000 concurrent. The initial deployment is sized for observed demand, which is currently zero. These are separate decisions and the documentation treats them separately throughout. Running a small cluster costs approximately what running the equivalent workload on a simpler platform costs, because the cost is the compute, not the orchestrator.

## Security Position

Kubernetes introduces its own authorization surface that must be configured rather than assumed. The following are requirements of this decision, not optional hardening:

- Role-based access control configured with least privilege. No workload runs with cluster-admin.
- NetworkPolicy denying traffic by default, with explicit allowances between workloads that must communicate.
- Pod security standards enforced: containers run as non-root, with read-only root filesystems where the workload permits, and without privilege escalation.
- Secrets sourced from the cluster secret mechanism, with the encrypted-at-rest configuration verified rather than assumed.
- Images pinned by digest and scanned before deployment.

## Migration Path

The application is stateless and twelve-factor. This property, established before this decision and preserved by it, is what makes the migration a packaging change. Application code does not change to run on Kubernetes.

Migration away from Kubernetes, or between Kubernetes installations, is likewise bounded: standard primitives and CNCF conformance mean manifests are portable.

## Open Question Requiring Confirmation

The operational surface introduced by this decision, combined with the multi-region and observability requirements at 100,000 concurrent, exceeds what the previously documented team size can be assumed to carry. This is identified as an unresolved constraint. It is resolved by one of: increasing the operating team, adopting a managed control plane to remove cluster-lifecycle work, or deferring the multi-region requirement until the team can carry it. No option is selected here because the choice depends on budget and hiring information not available to this document.

## Revisit Trigger

Revisit this decision if the concurrency requirement is revised downward by an order of magnitude, in which case the ADR-0013 reasoning would apply again. Revisit the self-hosted versus managed control-plane choice when cluster-lifecycle operations are measured to consume a material share of engineering capacity.
