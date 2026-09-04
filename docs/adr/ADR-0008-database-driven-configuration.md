# ADR-0008: Database-Driven Runtime Configuration

**Status:** Accepted · **Date:** 2026-08-30

## Context
Explicit requirement: *"nothing is static, it must come from the database, including the configurations."* Beyond compliance, the operational case is strong, a platform where marketing must file a pull request to fix a typo in the footer is a platform that moves at engineering speed for non-engineering work.

## Decision
A three-layer model. **Layer 0:** exactly nine environment variables, the minimum to reach the database and decrypt secrets. **Layer 1:** everything else in `setting_definition` + `setting_value`, hot-reloadable, scoped, audited. **Layer 2:** scoped overrides by environment, locale and (future) organisation.

Structured content, navigation, pages, page sections, email templates, FAQs, gets dedicated tables. Feature flags get their own tables with rule-based evaluation.

## Alternatives Considered

**Everything in environment variables**: the conventional twelve-factor reading. Rejected: every change requires a deploy; there is no audit trail, no type validation, no admin UI, and no per-scope resolution. It also does not satisfy the requirement.

**Config files in the repository**: same deploy problem, plus merge conflicts on operational changes.

**A dedicated config service (Consul, etcd)**: another stateful system to run, secure and back up, for data that fits comfortably in a table we already have.

**Literally everything in the database, zero env vars**: impossible. You cannot read the database connection string from the database. Pretending otherwise produces a system that cannot start. **The nine-variable boundary is the honest minimum**, and it is closed: adding a tenth requires an ADR.

## Consequences
**Positive:** zero-deploy configuration changes · full audit trail of who changed what and why · feature flags decouple deploy from release, making rollback a toggle · environment parity (same code, different scoped values) · **multi-tenancy is already structurally possible** via `scope_type = ORGANISATION` · type validation via JSON Schema · the admin UI is *generated* from `setting_definition`, so new settings need no hand-written form.

**Negative:** more indirection than reading a constant · a settings cache to invalidate correctly · an admin UI to build (Sprints 4 and 12) · a discipline to maintain, enforced by CI rather than good intentions.

## Trade-offs
We accept indirection and a cache-invalidation concern in exchange for operational independence from deploys. Given a two-person team where every deploy costs review and verification time, removing deploys from the change path for content and configuration is a large win.

## Cost
No additional infrastructure, it is tables in the existing database and keys in the existing Redis.

## Security
Secret-typed settings are encrypted at rest with `ENCRYPTION_KEY`, redacted in logs, and **never included in any API response**. `is_public` gates what may reach the browser. Every change is audited. **Rotating a provider key becomes an admin action rather than a deployment**, which materially improves incident response.
Risk: an admin misconfiguring a critical setting. Mitigated by JSON Schema validation, permission gating per setting, and the audit trail.

## Scalability
Settings are cached in Redis under a version key bumped on write, so invalidation is atomic and race-free, with an in-process 30-second cache absorbing the hot path. **p99 lookup under 1 ms.**

## Migration Path
Definitions and defaults are seeded by Alembic migrations, so they are versioned and reproducible. A fresh database produces a working system.

## Revisit Trigger
Settings lookup appears in a latency profile · the number of definitions exceeds a few thousand · a genuine need arises for configuration shared across separate services.
