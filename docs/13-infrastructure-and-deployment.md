# 13: Infrastructure and Deployment

This document specifies the deployment substrate, environment topology, release process, and scaling model. The governing decision is ADR-0019, which supersedes ADR-0013.

## 1. Separation of architectural target from deployment size

The architecture is designed for a target of 100,000 concurrent users. The deployment is sized for observed demand.

These are distinct decisions and are treated distinctly throughout this document. Designing for the target means the structure, workload separation, scaling mechanism, and data partitioning strategy accommodate that load without a rewrite. It does not mean the initial deployment provisions capacity for it. Provisioning for unrealised demand converts a design property into a recurring cost with no corresponding benefit.

The scaling triggers in section 8 define the transition between the two.

## 2. Deployment substrate

Kubernetes, using a lightweight CNCF-conformant distribution, is the substrate for all non-local environments. The rationale is recorded in ADR-0019 and is summarised here: at the target concurrency, workload classes with materially different resource profiles and scaling signals must scale independently, which requires scheduling and resource isolation that simpler platforms do not expose.

Only standard Kubernetes primitives are used in the core deployment path: Deployment, StatefulSet, Service, Ingress, HorizontalPodAutoscaler, ConfigMap, Secret, Job, CronJob, PodDisruptionBudget, NetworkPolicy, and ResourceQuota. Vendor-specific custom resources are excluded from the core path so that manifests remain portable across conformant installations.

## 3. Workload classes

Each class is a separate Deployment with its own replica count, resource allocation, and scaling signal.

```
   CLASS         WORKLOAD              SCALING SIGNAL      PROFILE
   ------------- --------------------- ------------------- ---------
   web           SSR presentation      request rate,       I/O-bound
                                       latency

   api           HTTP API              request rate,       I/O-bound
                                       latency

   mcp-server    MCP inbound           request rate        I/O-bound

   worker-       email, certificates,  queue depth         I/O-bound
   general       documents, outbox
                 relay

   worker-media  transcoding,          queue depth         CPU-bound
                 segmentation                              separate
                                                           processes

   worker-       scheduled jobs:       schedule            mixed
   scheduled     reconciliation,       (CronJob)
                 aggregation, billing

   inference     model serving         request rate,       memory-
                                       queue depth         bound

   analytics-    event ingestion       ingestion lag       I/O-bound
   ingest
```

The separation exists because a single undifferentiated pool must be provisioned for the sum of peak demands and permits one class to exhaust resources needed by another. Transcoding saturating CPU must not degrade request latency.

## 4. Stateful dependencies

```
   PostgreSQL       primary for writes, replicas for reads
                    streaming replication
                    point-in-time recovery
                    partitioning on high-volume event tables

   Redis            cache, session store, rate limiting,
                    idempotency keys, job queue
                    clustered at scale

   Object storage    S3-compatible, private by default
                    source media, processed media, documents
                    served through CDN with signed URLs

   Observability     metrics, logs, traces, error tracking
                    self-hosted per ADR-0014
```

Initial deployment self-hosts these on the cluster, consistent with the cost constraint. Managed alternatives satisfy the same interfaces and remain available. The migration is a connection configuration change, not an application change.

**Trade-off recorded explicitly:** self-hosting PostgreSQL places responsibility for replication, failover, backup verification, and version upgrades on the operating team. This is a real operational burden accepted in exchange for cost. The alternative, a managed database, removes that burden at a recurring cost. The selection between them depends on operating capacity, which is the open question in section 12.

## 5. Environments

```
   Local          Docker Compose, profile-based (ADR-0022)
                  Not Kubernetes by default

   Development    cluster namespace, deploys on merge
                  isolated data

   Staging        cluster namespace, manual promotion
                  production-equivalent configuration
                  anonymised data

   Production     cluster, manual promotion with approval
                  live configuration
```

Constraints applying across environments: no environment holds another's credentials; staging never connects to production data stores; production data reaching a lower environment is irreversibly anonymised first; non-production environments exclude themselves from search indexing.

## 6. Build and promotion

One artefact is built per commit and promoted unchanged.

```
   commit
      |
      v
   pipeline: static analysis, tests, security scan
      |
      v
   ONE image, tagged by commit digest
      |
      +--> development
      |
      +--> staging          same digest
      |
      +--> production       same digest
```

Rebuilding per environment invalidates prior testing, because the artefact tested is not the artefact deployed. The image digest and the schema migration revision are recorded together per release so that a rollback target is unambiguous.

Images: multi-stage builds, minimal base images, non-root execution, pinned base digests, vulnerability scanning before promotion, no embedded secrets.

## 7. Release process

```
   preconditions verified: pipeline green, staging accepted,
   migration reviewed, rollback target identified
      |
      v
   schema migration, expand phase only
      |     the prior image must remain functional against
      |     the new schema, which is what makes rollback
      |     possible during rollout
      v
   rolling update, health-gated
      |
      v
   canary: limited replica proportion
      |
      v
   observation: error rate, latency, saturation
      |
   +--+-------------------+
   |                      |
   within bounds      outside bounds
   |                      |
   v                      v
   complete rollout    halt and roll back
   |
   v
   smoke verification, observation period
```

Rollback paths, in ascending recovery time:

```
   feature flag disabled       configuration change, no deploy
   configuration reverted      configuration change, no deploy
   image reverted              redeploy prior digest
   schema reverted             down migration, where reversible
   data restored               point-in-time recovery
```

Two of the five require no deployment. This is a direct consequence of the database-driven configuration decision.

## 8. Scaling model

Capacity is added in a defined order, each step triggered by a measured signal.

```
   1  CDN cache effectiveness         hit ratio below target
   2  Request-serving replicas        sustained utilisation or
                                      latency at threshold
   3  Application cache coverage      database read volume
                                      attributable to cacheable
                                      queries
   4  Read replicas                   primary read utilisation
   5  Worker replicas per queue       queue depth or age
   6  Table partitioning              row count or query plan
                                      degradation on event tables
   7  Regional deployment             latency for a geographic
                                      user population
   8  Context extraction              a bounded context with a
                                      scaling profile the shared
                                      deployment cannot accommodate
```

Horizontal autoscaling operates continuously within configured bounds for steps two and five. The remaining steps are deliberate changes made in response to observed metrics.

**Not specified:** replica counts, node sizing, and threshold values. These require measurement against the implemented system and are not asserted here. Establishing them is a load testing deliverable.

## 9. Network and edge

CDN in front of static assets, media, and cacheable public pages. Ingress controller terminating TLS and routing to services. TLS certificates issued and renewed automatically, with expiry alerting as a backstop against silent renewal failure. Network policies denying inter-workload traffic by default with explicit allowances.

## 10. Cost model

Cost drivers, in expected order of magnitude at scale:

```
   CDN egress          scales with media consumption. Mitigated by
                       cache hit ratio, adaptive bitrate reducing
                       bytes to constrained connections, and
                       cold-tier archival storage.

   Cluster compute     scales with replica counts, which scale with
                       demand. Bounded by autoscaler maxima.

   Object storage      scales with retained media. Tiered by
                       access pattern.

   Inference compute   scales with AI usage. Bounded by per-
                       principal and per-capability budgets.

   Database storage    scales with retained data. Bounded by
                       retention policy on event tables.
```

Every driver is either usage-proportional with an enforced bound, or subject to a retention policy. No driver is an unbounded fixed liability.

**Not stated:** currency amounts. No pricing figures are asserted because they depend on a provider selection that has not been made and on volumes that have not been measured.

## 11. Business continuity

Continuous archiving with point-in-time recovery for the database. Restore procedures rehearsed on a defined interval, because an unexercised restore procedure is unverified. Object storage versioned against accidental overwrite. Recovery point and recovery time objectives are established and validated by exercise rather than assumed.

**Not yet established:** the specific recovery objectives. These are business decisions requiring confirmation, not technical defaults.

## 12. Open question: operating capacity

The operational surface established by this document, cluster lifecycle, self-hosted stateful services, multi-region deployment, and observability at the target scale, exceeds what the previously documented team size can be assumed to sustain.

This is recorded as an unresolved constraint. It is resolved by increasing operating capacity, adopting managed services to remove specific operational burdens at a recurring cost, or deferring components until capacity exists. The selection depends on budget and staffing information not available to this document, and is therefore not made here.

Deferring this question does not block implementation. It blocks operating the full topology at the target scale, which is a later milestone.
