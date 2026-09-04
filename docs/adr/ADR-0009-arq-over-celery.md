# ADR-0009: ARQ over Celery for Background Jobs

**Status:** Accepted · **Date:** Sprint 2

## Context

Several capabilities need background execution outside the request/response cycle: PDF generation, video transcoding, email delivery, the webhook relay from the transactional outbox (`docs/04` §4), brochure regeneration on catalog publish, and later scheduled jobs (reconciliation, backups). The stack is async-native throughout, FastAPI, SQLAlchemy 2.0 async, the entire repository and service layer (`docs/03`, ADR-0002).

## Decision

ARQ, an async-native Redis-backed job queue, for all background work.

## Alternatives Considered

**Celery**: the default choice for most Python teams, and seriously considered given its maturity, ecosystem, and the fact that most engineers have used it before. Rejected because Celery's worker model is fundamentally synchronous: workers run in threads or separate processes calling blocking code, which means every service function written against our async session and repository layer would need a second, parallel synchronous version to run inside a Celery task, or the worker would need to bridge sync-to-async on every call, adding complexity and a performance penalty for no benefit. We already accepted async's learning curve as a deliberate trade in ADR-0002; Celery would have meant paying that cost twice, once for the API and once for a separate sync data-access path in workers.

**RQ (Redis Queue)**: simpler than Celery, but synchronous in the same way, with the same duplication problem.

**Dramatiq**: a credible async-capable alternative, but a smaller community and less battle-tested at the traffic patterns we expect (background PDF and video jobs, not high-frequency micro-tasks) than ARQ, which was purpose-built for exactly this profile by the same author as `pydantic`'s async ecosystem tooling.

**A message broker (RabbitMQ, Kafka) instead of Redis-backed queuing.** Rejected as premature, Redis is already a dependency for caching, rate limiting and sessions (`docs/04`), and our job volume does not need a dedicated broker's durability or fan-out guarantees. Revisit trigger below.

## Consequences

**Positive:** workers import and call the exact same service functions the API calls, no parallel sync data-access stack, no duplicated business logic, no drift between what the API does and what a background job does · one fewer infrastructure dependency, since Redis is already present · async throughout means a worker awaiting an external API call (video transcoding provider, email provider) does not block other jobs the way a synchronous Celery worker thread would.

**Negative:** smaller community than Celery, so fewer Stack Overflow answers when something goes wrong · fewer built-in features (Celery has mature primitives for complex workflows, chords, and multi-broker support that ARQ does not) · Redis-backed means job durability is bounded by Redis's own persistence configuration, not a purpose-built message broker's guarantees.

## Trade-offs

A smaller ecosystem and fewer built-in workflow primitives, in exchange for a background-job system that shares code with the API instead of duplicating it. Given the service layer is intentionally HTTP-agnostic (`docs/18`, services never raise `HTTPException`, precisely so workers can call them), ARQ is the choice that actually lets that design pay off; Celery would have made that design decision pointless.

## Cost

Free and open source. No new infrastructure, Redis is already required.

## Security

Jobs execute with the same authorization context established when they were enqueued (the enqueuing service call, not the worker, decides what a job may do), a worker is not a privilege escalation path. Job payloads never carry secrets; anything sensitive is re-resolved from encrypted settings (`docs/05`) inside the job, not passed through the queue.

## Scalability

Worker replicas scale independently of the API (`docs/13`). Redis-backed queuing handles our expected job volume comfortably; queue depth and job failure rate are tracked metrics from Sprint 4 (`docs/14`).

## Migration Path

Because every job body is a thin wrapper around an existing service function, migrating to a different queue technology later would mean rewriting the wrapper layer, not the business logic underneath it.

## Revisit Trigger

Job volume or workflow complexity (multi-stage pipelines, fan-out/fan-in, cross-job dependencies) that genuinely outgrows what ARQ expresses cleanly → revisit Celery or a dedicated broker. Durability requirements that exceed what Redis persistence provides → revisit a message broker, consistent with the Kafka/RabbitMQ deferral already recorded in `docs/03` §3.
