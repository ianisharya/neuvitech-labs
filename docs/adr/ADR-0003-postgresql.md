# ADR-0003: PostgreSQL 16 as the Single System of Record

**Status:** Accepted · **Date:** 2026-08-30

## Context
The platform needs transactional commerce, a richly relational catalog, flexible per-type attributes, database-driven configuration, full-text search, and vector similarity for RAG. The brief invites consideration of graph and NoSQL databases.

## Decision
PostgreSQL 16 as the single system of record, with `pgvector`. No second database in v1.

## Alternatives Considered
**+ Neo4j**: deferred. Skill graphs, prerequisites and career mapping are served by a `skill_edge` table and recursive CTEs at our data volume. Neo4j adds a second stateful system to secure, back up, monitor and learn.
**+ MongoDB**: deferred. JSONB covers flexible documents with SQL query power *and* transactional integrity.
**+ Elasticsearch**: deferred. Postgres FTS is sufficient for a catalog of hundreds of items.
**+ dedicated vector DB**: deferred. `pgvector` keeps embeddings inside the existing access-control and backup boundary, which is **how we enforce retrieval ACLs**, not an incidental convenience.
**MySQL**: rejected. Weaker JSONB, no native vector extension, weaker full-text.

## Consequences
**Positive:** one engine to learn, secure, back up and monitor, significant for a two-person team · ACID across the commerce chain · JSONB enables both the settings system and the catalog type registry without EAV · one backup covers everything.
**Negative:** deep graph traversal is less expressive than Cypher · very high-volume event ingestion will eventually need partitioning or extraction · one system means one blast radius.

## Cost
Free engine. Managed hosting is the expense; self-managing would trade money for operational risk we should not accept at this team size.

## Security
Row-level scoping in the repository layer · encryption at rest · append-only audit log with no UPDATE/DELETE grant to the application role · least-privilege database roles.

## Scalability
Vertical first, then a read replica for catalog reads, then partitioning for event tables. Modelled load (~400 uncached DB RPS) sits comfortably within a single well-indexed primary.

## Migration Path
A specific workload (AI traces, activity streams) can be extracted per-table without touching the core.

## Revisit Trigger
Traversals routinely exceeding 4–5 hops or path queries above p95 300 ms (→ Neo4j as a **derived read model**, never a second source of truth) · a single event stream above ~50M rows/month · search relevance requirements Postgres FTS cannot express.
