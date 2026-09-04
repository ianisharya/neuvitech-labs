# ADR-0010: Catalog Type Registry: Hybrid JSONB + Capability Extension Tables

**Status:** Accepted · **Date:** Sprint 5

## Context

The catalog must express Programs, Tracks, Specializations, Masterclasses, Free Certification Courses and future product kinds without a rewrite each time a new kind is introduced, the entire premise of `docs/06`. Every kind shares some structure (title, description, SEO metadata) and diverges on other structure (a Masterclass has live sessions and attendance; a Free Certification Course does not).

## Decision

A hybrid: **JSONB `attributes`** on `catalog_item`, validated against a per-kind JSON Schema stored in `catalog_item_type.attribute_schema`, for descriptive fields that vary by kind but have no independent relational structure, and **capability-flagged extension tables** (`live_session`, `cohort`, `assessment`, etc.) for capabilities that are genuinely relational, attached by declared capability rather than by kind.

## Alternatives Considered

**Pure JSONB, everything in `attributes`, no extension tables.** Rejected. A live session has its own lifecycle, scheduling, instructor assignment, capacity, attendance records, recordings, genuine relational data with its own constraints, indexes and query patterns. Forcing that into a JSONB blob forfeits foreign keys, forfeits `SELECT ... FOR UPDATE` for capacity enforcement, and forfeits the query planner's ability to use an index on session start time. JSONB is right for "a field that varies by kind"; it is wrong for "a table's worth of data with its own identity."

**Pure relational, a table per kind (a `masterclass` table, a `program` table, a `free_certification_course` table).** Rejected outright, this is the exact type-branching failure mode `docs/06` §1 exists to document. Nine product kinds means nine tables, nine sets of queries, nine places a bug can hide, and a tenth kind means a migration and a service rewrite rather than a configuration row.

**Single-table inheritance with a `kind` discriminator column and every possible field as a nullable column.** Rejected. Sparse tables with dozens of nullable columns are a well-known anti-pattern, most rows have most columns null, indexes bloat with rarely-used columns, and adding a field for one kind means a schema migration touching every row regardless of kind.

**Entity-Attribute-Value (EAV) modelling for everything, including relational capabilities.** Rejected. EAV solves the "flexible attributes" problem JSONB already solves more simply, with actual query operators, GIN indexing, and JSON Schema validation, while EAV forfeits type safety and turns every query into a self-join. JSONB is a better EAV than EAV.

## Consequences

**Positive:** a new descriptive field for one kind is a `attribute_schema` update, not a migration · a new kind with only descriptive differences is a single `catalog_item_type` row · genuinely relational capabilities (live sessions, cohorts, assessments) keep real foreign keys, real constraints, real indexes · capability flags mean the ninth product type reuses existing extension tables automatically if it shares capabilities with an eighth, rather than needing new ones.

**Negative:** two mental models to hold at once, "is this a JSONB attribute or an extension table?", and getting that call wrong in either direction costs real rework · JSONB fields are not enforced by the database schema itself, only by the JSON Schema validation in the service layer, so a bypass of that validation layer (a direct SQL write, a bug in the validator) can produce malformed attributes that only surface at read time.

## Trade-offs

Genuine judgment is required on every new capability: does this belong in `attributes`, or does it need its own table? The rule of thumb recorded in `docs/06` §3, JSONB for descriptive fields validated by schema, extension tables for anything with its own relational lifecycle, resolves most cases, but not all, and that boundary call is a real design decision each time, not a mechanical one.

## Cost

No additional infrastructure, PostgreSQL's native JSONB and GIN indexing, already in use.

## Security

JSON Schema validation on write prevents malformed or unexpected attribute shapes from entering the catalog. Extension table access goes through the same authorization and ownership-filtering discipline as every other table (`docs/08`), capability flags gate which UI surfaces render, not which rows a query can see.

## Scalability

GIN indexes on `attributes` keep JSONB queries performant at catalog scale (hundreds of items, not millions). Extension tables scale independently, `live_session` volume is bounded by cohort count, not catalog size.

## Migration Path

A capability outgrowing JSONB, needing its own indexes, its own foreign keys, its own lifecycle, migrates to an extension table by adding the table and backfilling from the JSONB field, then removing the field from the schema in a later release (the same expand/contract discipline as any other schema change, `docs/07` §5).

## Revisit Trigger

A descriptive JSONB field routinely needs relational queries (joins, foreign keys, its own indexes) that JSONB cannot express efficiently → promote it to an extension table. The two-model boundary itself proving consistently hard to call correctly across multiple product kinds → revisit whether a different split is needed.
