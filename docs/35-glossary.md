# 35 — Glossary

## Architecture
**Modular monolith** — one deployable application split into strictly bounded modules communicating through published interfaces. Microservice-style boundaries, monolith-style simplicity.
**Bounded context** — a region with its own vocabulary and rules. "Product" means something different in catalog than in commerce.
**Aggregate root** — a cluster of objects treated as one unit for changes. `Order` is the root; `OrderLine` belongs to it.
**BFF** — Backend for Frontend. Our Next.js server: renders, forwards a session cookie, holds zero business rules.
**System of record** — the authoritative source of truth. PostgreSQL. Caches and read models are derived and disposable.
**Read model** — a pre-computed denormalised copy shaped for fast reading, rebuilt at publish time.
**Transactional outbox** — writing domain events in the same transaction as the state change, relayed afterwards by a worker. Solves both "event lost after commit" and "event published for a rolled-back transaction".
**Twelve-factor** — config in environment, stateless processes, logs to stdout, dev/prod parity.

## Data
**UUIDv7** — time-sortable UUID. Index locality without guessability. v4 fragments B-trees; serial leaks volume.
**JSONB** — PostgreSQL binary JSON, queryable and indexable. Gives schema flexibility without EAV.
**GIN index** — the index type for containment and full-text queries.
**tsvector** — Postgres full-text search with stemming and ranking.
**pgvector** — embedding vectors with similarity search, inside our existing ACL and backup boundary.
**Recursive CTE** — `WITH RECURSIVE`; how we traverse the catalog graph without a graph database.
**Expand/contract** — add the new column and dual-write, remove the old one later. Enables zero-downtime deploys and safe rollback.
**Optimistic vs pessimistic locking** — detect conflict at write via a version column, vs `SELECT … FOR UPDATE`. We use pessimistic for coupon redemption where correctness is critical.
**Partial unique index** — uniqueness applying only to matching rows, e.g. `UNIQUE (slug) WHERE deleted_at IS NULL`.

## Security
**AuthN vs AuthZ** — who you are, vs what you may do. Different systems, never conflated.
**RBAC** — users hold roles, roles hold permissions, code checks permissions. Checking roles directly scatters logic.
**PDP** — Policy Decision Point. The single place authorization is decided: `security/authz.py`.
**Default deny** — anything not explicitly permitted is refused; an endpoint declaring neither fails at startup.
**Entitlement** — a grant of access to a *product*, separate from permissions. "May perform refunds" is a permission; "has been granted the AI Engineering Program" is an entitlement.
**Argon2id** — memory-hard password hashing; the correct default for new systems.
**Opaque token vs JWT** — a random string requiring server lookup, vs signed claims. We use opaque because instant revocation is a requirement.
**Step-up authentication** — re-authenticating for a sensitive action within a valid session.
**IDOR** — Insecure Direct Object Reference: accessing another user's resource by changing an id. Prevented by filtering ownership *inside* the query.
**SSRF** — tricking the server into fetching an attacker-chosen URL, often to reach internal services.
**Signed URL** — temporary cryptographically signed link to a private file.
**Ed25519** — fast modern signature algorithm; signs our certificates for offline verification.

## Commerce
**Minor units** — the smallest currency unit. `₹1,299.50` stored as `129950` with currency `INR`. Never floats: `0.1 + 0.2 != 0.3`.
**Idempotency key** — a client-supplied key so retrying a request does not repeat its effect. Without it, a double-clicked checkout charges twice.
**Webhook** — the provider calling *our* server. **Signature verification** proves origin; **idempotent processing** makes duplicate delivery harmless. Providers retry, so duplicates are normal.
**Reconciliation** — comparing our records against the provider's API to catch lost webhooks. Webhooks get dropped; money must not.
**Proration** — the fair partial charge when a subscriber changes plan mid-period.
**Grace period** — continued access after a failed renewal, so a transient card failure does not lock out a paying learner.
**Saga / compensation** — a multi-step process where each step has an undo: refund → revoke entitlement → revoke certificate.

## Learning
**First-class capability** — something with its own domain model, lifecycle, relationships, APIs, permissions and analytics, rather than a boolean on something else.
**Type registry** — `catalog_item_type`; describes each product kind. New kinds are rows, not migrations.
**Catalog item version** — an immutable snapshot. Enrolments pin to a version so curriculum cannot change under a learner after purchase.
**Cohort** — a batch of learners moving through on a schedule.
**Credential lifecycle** — `ELIGIBLE → GENERATED → ISSUED → VERIFIED… → REVOKED/EXPIRED`. A certificate is a state machine, not a PDF.

## AI
**RAG** — retrieval-augmented generation: fetch relevant documents, generate an answer grounded in them.
**Hybrid retrieval** — keyword plus vector search. Pure vector search underperforms on exact technical terms.
**Prompt injection** — untrusted content containing instructions that hijack the model. Defended by delimiting untrusted content, authorising tools against the *user's* permissions, and ACL-filtering retrieval in the query.
**Structured output** — forcing schema-conforming responses so downstream code parses reliably.
**Agent identity** — an agent as a first-class principal with its own least-privilege role.
**Human-in-the-loop** — the agent proposes, a human approves, **the system executes under the human's authority**. The agent never holds the credential.

## Delivery & operations
**Walking skeleton** — a thin end-to-end slice through every layer that runs and deploys, before any feature exists.
**Story point** — here, 1 point = 1 hour of one person's time including review, testing and rework.
**Trunk-based development** — short-lived branches merged frequently into a protected `main`.
**Conventional Commits** — `type(scope): NVL-123 description`. Machine-parseable, so changelogs and traceability are automatic.
**Artefact promotion** — build one image, promote *that image* through environments. Rebuilding means you never tested what you shipped.
**Canary** — release to a slice of traffic, watch, then continue or roll back.
**RED / USE** — Rate, Errors, Duration for services; Utilisation, Saturation, Errors for resources.
**OpenTelemetry** — vendor-neutral instrumentation; changing backends is a config change.
**Trace / span** — one request's journey; one operation within it.
**SBOM** — software bill of materials; answers "are we affected by this CVE" in minutes.
**SAST / DAST** — static analysis of source; dynamic testing against a running app.
**PITR** — point-in-time recovery; restore to any moment, not just the last nightly backup.
**Circuit breaker** — after repeated failures, stop calling a failing dependency instead of piling on requests.
**Graceful degradation** — losing a capability without losing the system.
**RPO / RTO** — maximum acceptable data loss (5 min) and maximum acceptable downtime (1 h).
