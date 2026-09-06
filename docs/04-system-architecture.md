# 04: System Architecture, High-Level Design

This document defines the high-level structure of the system: its layers, its boundaries, its runtime topology, and the rules that govern how components relate. It is the reference for structural questions. Low-level design of individual components is documented in the component-specific documents referenced throughout.

## 1. Architectural style and its justification

The backend is a modular monolith deployed as a set of independently scalable workload classes on Kubernetes.

These two properties are frequently treated as contradictory and are not. The codebase is a single deployable artefact with strictly bounded internal modules. The runtime is multiple replicas of that artefact, each configured to serve a particular workload class. This yields the development and transactional advantages of a monolith with the operational scaling characteristics required at the target concurrency.

The justification for a modular monolith rather than microservices rests on a specific technical property of this domain: the core aggregates, catalogue item, product, order, entitlement, and enrolment, participate in transactions that must be atomic. Distributing them across services replaces local ACID transactions with distributed sagas and compensating actions. That is a substantial increase in failure modes and implementation complexity, incurred to solve an organisational problem, independent team deployment, that the current structure does not have.

The justification for deploying it as separate workload classes is that request handling, background processing, and model inference have materially different resource profiles and scaling signals. Request handling is I/O-bound and scales on request rate and latency. Video transcoding is CPU-bound and scales on queue depth. Model inference is memory-bound and scales differently again. Running them as one undifferentiated pool means provisioning for the sum of the peaks and allowing one class to starve another.

## 2. Layers and dependency direction

The backend is organised in layers with a strict dependency rule: dependencies point inward, toward the domain. The domain layer depends on nothing external. Infrastructure depends on interfaces the domain defines, not the reverse.

```
   HTTP clients        MCP clients         Scheduled triggers
        |                   |                      |
        v                   v                      v
   +---------------------------------------------------------+
   |  INTERFACE LAYER                                         |
   |  HTTP routers, MCP tool handlers, worker task entry      |
   |  Responsibilities: transport concerns only.              |
   |  Validate input, resolve identity, check authorization,  |
   |  delegate, serialise output. No business rules.          |
   +---------------------------------------------------------+
                            |
                            v
   +---------------------------------------------------------+
   |  APPLICATION / SERVICE LAYER                             |
   |  Use-case orchestration. Transaction boundaries.         |
   |  Calls domain logic and infrastructure through ports.    |
   |  Framework-agnostic. Raises domain exceptions, never     |
   |  transport-specific errors.                              |
   +---------------------------------------------------------+
                            |
                            v
   +---------------------------------------------------------+
   |  DOMAIN LAYER                                            |
   |  Entities, value objects, domain rules, state machines.  |
   |  Depends on nothing outside itself. No framework, no     |
   |  database, no network. Testable in isolation.            |
   +---------------------------------------------------------+
                            ^
                            | implements ports defined inward
   +---------------------------------------------------------+
   |  INFRASTRUCTURE LAYER                                    |
   |  Repositories, provider implementations, message         |
   |  publishing, cache, object storage, model inference.     |
   |  Concrete. Substitutable. Depends on domain interfaces.  |
   +---------------------------------------------------------+
```

The practical consequence is that business logic can be tested without a database, without a network, and without a model, because every external dependency is reached through an interface with an in-memory implementation available. This property is required by ADR-0022 for development on constrained hardware and is provided by ADR-0021.

## 3. Bounded contexts

The application layer is divided into bounded contexts. Each owns its persistent data, exposes a service interface, and does not reach into another context's tables or models.

```
identity      users, authentication, sessions, MFA, roles, permissions, audit
settings      runtime configuration, feature flags, content, navigation
catalog       item type registry, items, versions, relationships, publishing
learning      courses, modules, lessons, progress, resources
live          cohorts, sessions, meeting provision, attendance, recordings
assessment    quizzes, exams, projects, submissions, grading
credential    certificate eligibility, issuance, verification, revocation
document      brochure generation, versioning, access
commerce      products, prices, offers, coupons, checkout, orders
payments      provider adapters, webhooks, reconciliation, refunds
entitlement   access grants and enrolments
careers       jobs, applications, screening
community     articles, events, showcases, profiles
ai            gateway, agents, tools, memory, retrieval, evaluation
mcp           server role and client role, see document 43
analytics     event ingestion, aggregation, metrics, behavioural data
media         video pipeline, transcoding, storage layout, delivery
admin         administrative surfaces over the above
```

Cross-context communication occurs through a target context's service interface or through published domain events. Direct import of another context's models or repositories is prohibited and enforced by a static import check in continuous integration.

## 4. Runtime topology

```
                            Clients
                               |
                    +----------+----------+
                    |                     |
              CDN edge cache        API traffic
              video, static              |
              assets                     |
                    |                    v
                    |            Ingress controller
                    |            TLS termination, routing,
                    |            rate limiting at edge
                    |                    |
                    |     +--------------+--------------+
                    |     |              |              |
                    v     v              v              v
              +----------------+  +-------------+  +-------------+
              | web            |  | api         |  | mcp-server  |
              | Next.js SSR    |  | FastAPI     |  | MCP inbound |
              | HPA on RPS     |  | HPA on RPS  |  | HPA on RPS  |
              +----------------+  +-------------+  +-------------+
                                         |
              +--------------------------+--------------------------+
              |              |             |            |           |
              v              v             v            v           v
        +----------+  +-----------+  +---------+  +---------+  +---------+
        | worker   |  | worker    |  | worker  |  |inference|  | analytics|
        | general  |  | media     |  | schedule|  | Ollama  |  | ingest   |
        | HPA on   |  | HPA on    |  | CronJob |  | or      |  | HPA on   |
        | queue    |  | queue,    |  |         |  | remote  |  | lag      |
        | depth    |  | CPU-bound |  |         |  |         |  |          |
        +----------+  +-----------+  +---------+  +---------+  +---------+
              |              |             |            |           |
              +--------------+------+------+------------+-----------+
                                    |
        +---------------+-----------+-----------+---------------+
        |               |           |           |               |
        v               v           v           v               v
   PostgreSQL      PostgreSQL    Redis      Object          Observability
   primary         replicas      cluster    storage         stack
   writes          reads         cache,     media,          metrics, logs,
                                 queue,     documents       traces
                                 sessions
```

Each workload class scales on a signal appropriate to its work. Request-serving classes scale on request rate and latency. Queue-consuming workers scale on queue depth. This separation is the operational justification for Kubernetes recorded in ADR-0019.

## 5. Request path

The path a request takes is uniform, and the ordering is a security property rather than an implementation convenience.

```
   1  Ingress: TLS termination, coarse rate limit, routing
   2  Correlation identifier assigned or propagated from the client
   3  Trace span opened, structured log context established
   4  Security headers applied, origin policy enforced
   5  Fine-grained rate limit evaluated against identity and route class
   6  Session resolved: cookie to token hash to cache, database on miss
   7  Authorization: the route's declared permission is evaluated
   8  Request body validated against a declared schema
   9  Interface layer delegates to the service layer
  10  Service layer opens a transaction, applies rules
  11  Repository executes queries with ownership constraints in the
      query predicate, not applied after retrieval
  12  Response serialised from an explicit output schema
  13  Audit record written for state-changing operations
  14  Domain events written to the outbox in the same transaction
  15  Span closed, metrics recorded, log context closed
```

Two properties of this ordering are load-bearing. Authorization at step seven precedes any data access, so an unauthorized request never reaches a repository. Ownership constraints at step eleven are part of the query predicate, which makes another principal's data unreachable rather than retrieved and then rejected.

A route that declares neither a required permission nor an explicit public marker causes a startup assertion failure. This makes an unauthenticated route a deployment-time failure rather than a runtime vulnerability.

## 6. Write path and event propagation

State changes that other contexts must observe use a transactional outbox.

```
   Service begins transaction
        writes aggregate state
        writes audit record
        writes outbox event
   Transaction commits atomically
        |
        v
   Relay process polls the outbox
        publishes events
        marks them dispatched
        |
        v
   Subscribers: cache invalidation, analytics ingestion,
   notification dispatch, downstream projections
```

The justification is that the alternatives are incorrect. Publishing before commit emits events for transactions that may roll back. Publishing after commit loses events if the process fails between the two operations. Writing the event within the transaction and relaying it afterward is the only ordering that is atomic with the state change.

## 7. Read path

Read traffic substantially exceeds write traffic for catalogue and content surfaces. The read path is layered accordingly.

```
   CDN edge          public catalogue pages, static assets, video
        |            cache miss
        v
   Application cache  Redis, cache-aside, version-keyed invalidation
        |            cache miss
        v
   Read model         denormalised projection assembled at publish time
        |            not present
        v
   Read replica       PostgreSQL replica for non-transactional reads
        |
        v
   Primary            only for reads that must observe the latest write
```

Read models are assembled when a catalogue item is published, converting a multi-table traversal into a single-key retrieval. Cache keys incorporate the published version identifier, so publishing a new version changes the key and stale entries expire without an invalidation race.

Reads that must observe their own preceding write, such as a confirmation page immediately following a purchase, are routed to the primary. This is an explicit per-query decision, not a global default.

## 8. Concurrency model

The system uses different concurrency mechanisms for different workload classes, selected by the nature of the work rather than applied uniformly.

**Request handling and I/O-bound work** uses asynchronous execution. Database access, cache access, provider calls, and inter-service communication are I/O-bound, and asynchronous execution allows a single process to handle many concurrent requests without a thread per request.

**CPU-bound work** does not use asynchronous execution, because Python's global interpreter lock prevents parallel execution of Python bytecode within a process. CPU-bound work, including video transcoding and any numerical processing, runs in separate processes. Transcoding additionally delegates to a native encoder process rather than executing in Python at all.

**Scheduled and deferred work** runs in worker processes consuming from a queue, isolated from the request path so that a slow job cannot degrade request latency.

The following concerns are handled explicitly rather than left to defaults, because each has a documented failure mode when unhandled:

- Cancellation. Client disconnection propagates cancellation so that abandoned work does not continue consuming resources.
- Timeouts. Every external call has an explicit timeout. An unbounded call is an unbounded resource hold.
- Retries with exponential backoff and jitter. Uniform retry intervals produce synchronised retry storms.
- Backpressure. Queue depth is bounded. When a bound is reached, work is rejected with an explicit signal rather than accumulating until memory is exhausted.
- Idempotency. Operations that may be retried carry an idempotency key so that repetition does not repeat the effect.
- Graceful shutdown. On termination signal, a process stops accepting new work, completes in-flight work within a bounded period, and exits.
- Resource limits. Every workload declares CPU and memory requests and limits, so that one class cannot starve another.

## 9. Capacity model at the target concurrency

The concurrency target is 100,000 concurrent users. The following describes how the architecture accommodates that target. It does not assert measured performance, because no measurements exist for a system that is not yet built. These are design allocations to be validated by load testing, and the load testing requirement is recorded in the testing documentation.

The dominant load is video delivery, and it is served from CDN edge caches rather than from the application. The application's involvement in a video session is an entitlement check and the issuance of a short-lived signed URL. This is the design property that makes the target tractable: video bandwidth scales with the CDN, not with application capacity.

Catalogue reads are cacheable at the edge and in the application cache, so a large share of read traffic does not reach the database.

The remaining application load comprises authenticated interactions: progress recording, assessment submission, commerce operations, and AI interactions. Progress events are batched at the client and written asynchronously rather than synchronously per event.

Database write concentration is addressed by partitioning the highest-volume tables, specifically progress events and analytics events, by time. Read concentration is addressed by replicas.

**Unvalidated:** the replica count, node sizing, partition strategy thresholds, and cache hit ratios required to meet the target are not stated here because they have not been measured. They are determined by load testing against the implemented system.

## 10. Failure behaviour

Dependency failure degrades a capability rather than the system, with one documented exception.

```
   Cache unavailable        reads fall through to the database
                            rate limiting fails closed for
                            authentication, open for reads

   Object storage or CDN    media unavailable; catalogue browsing,
   unavailable              commerce, text content, and assessment
                            continue

   Payment provider         checkout disabled with an explicit status;
   unavailable              existing entitlements unaffected

   Inference unavailable    AI features report unavailable; all
                            non-AI functionality continues

   MCP server unreachable   affected tools unavailable; the agent
   (client role)            proceeds without them or reports the
                            limitation

   Read replica             reads fall back to the primary at
   unavailable              increased primary load

   Primary database         no graceful degradation. This is the
   unavailable              single dependency without a fallback,
                            which is why it is deployed with
                            replication and point-in-time recovery
```

The AI layer is an enhancement and never a dependency of a core path. No commerce, learning, or credential operation blocks on model availability.

## 11. Scaling progression

Capacity is added in a defined order, each step triggered by an observed metric rather than anticipation.

```
   1  Increase CDN cache effectiveness
   2  Increase request-serving replica count
   3  Extend application cache coverage
   4  Add read replicas
   5  Increase worker replica count per queue
   6  Partition high-volume tables
   7  Introduce regional deployment for latency
   8  Extract a bounded context to a separate service, only if
      it demonstrates a scaling profile the shared deployment
      cannot accommodate
```

Step eight is listed for completeness and is not anticipated. The modular structure makes it available without a rewrite, which is the purpose of maintaining strict context boundaries in a monolith.
