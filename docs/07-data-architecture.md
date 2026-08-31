# 07 — Data Architecture

## 1. PostgreSQL 16 as the single system of record

Access patterns decide this, not popularity:

1. **Commerce demands ACID.** `order → payment → entitlement → enrolment` commits atomically or not at all. Eventual consistency here means learners who paid and cannot access, or accessed and did not pay.
2. **The catalog is genuinely relational** — joins and recursive traversals, which Postgres CTEs handle well.
3. **JSONB gives configuration-driven flexibility without EAV.** This is what makes both the settings system and the catalog type registry practical.
4. **One engine, four needs:** relational core, JSONB documents, full-text search (`tsvector`), vectors (`pgvector`). Each avoided dependency is one less thing to secure, back up, monitor and pay for.
5. **Operational maturity:** PITR, logical replication, partitioning, mature managed offerings.

## 2. Cross-cutting conventions

| Convention | Rule | Why |
|---|---|---|
| Primary keys | **UUIDv7** | Time-sortable → index locality (unlike v4, which fragments B-trees); non-enumerable (unlike serial, which leaks volume) |
| Public identifiers | `slug`, never the PK | URLs stay readable and stable |
| Money | `amount_minor BIGINT` + `currency CHAR(3)` | `0.1 + 0.2 != 0.3` in binary float, and the error compounds through discounts and tax |
| Time | `TIMESTAMPTZ`, UTC, injectable clock | Naive local timestamps make time-dependent tests flaky |
| Table names | `snake_case`, **singular** | Matches the ORM class name — one name in your head, not two |
| Booleans | `is_` / `has_` prefix | Self-documenting |
| Timestamps | `_at` suffix | `created_at`, `revoked_at` |
| Soft delete | `deleted_at` only where audit requires | With partial unique indexes so slugs can be reused |
| Foreign keys | Always declared, explicit `ON DELETE`, usually `RESTRICT` | Cascading deletes silently destroy audit trails |
| Constraints | In the database, not only the application | The database is the last line of defence and outlives the code |
| Naming conventions | Set on `MetaData` **before the first migration** | Retrofitting constraint names is miserable |

## 3. Domain schema overview

```
IDENTITY        user · user_profile · session · mfa_secret · recovery_code
                role · permission · role_permission · user_role · audit_log

SETTINGS        setting_definition · setting_value · setting_audit
                feature_flag · feature_flag_rule
                navigation_menu · navigation_item · page · page_section
                content_block · email_template · notification_template · faq · testimonial

CATALOG         catalog_item_type · catalog_item · catalog_item_version
                catalog_relationship · catalog_page_view (materialised)
                skill · skill_edge · catalog_item_skill · career · career_skill

LEARNING        learning_component · enrolment · progress_event · lesson_progress
                resource · announcement · media_asset

LIVE            cohort · live_session · session_attendance · session_recording

ASSESSMENT      assessment · question · answer_option · attempt · attempt_answer
                submission · evaluation · rubric · feedback

CREDENTIAL      credential · credential_verification_event · credential_audit
                certificate_policy · issuer_key

DOCUMENT        brochure · brochure_version · brochure_generation_job
                brochure_download_event · lead

COMMERCE        product · product_bundle_item · price · offer
                coupon · coupon_redemption · checkout_session · order · order_line
                invoice · idempotency_key

PAYMENTS        payment · payment_attempt · payment_webhook_event · refund
                subscription · subscription_event

ENTITLEMENT     entitlement · entitlement_grant_audit

CAREERS         job · job_skill · application · application_event · resume

COMMUNITY       article · event · event_registration · project_showcase · profile

AI              ai_prompt_version · ai_invocation · ai_tool_invocation
                agent_identity · ai_action_approval · document_embedding

ANALYTICS       analytics_event (monthly partitions) · metric_rollup

PLATFORM        outbox_event · job_run · notification · media_asset
```

## 4. Patterns that appear repeatedly

**Transactional outbox** — `outbox_event(id, aggregate_type, aggregate_id, event_type, payload, occurred_at, dispatched_at, attempts)`. Written in the same transaction as the state change; relayed by a worker. The only correct way to publish events from a database transaction.

**Append-only audit** — `audit_log(actor_id, actor_type, action, resource_type, resource_id, before, after, request_id, ip, user_agent, occurred_at)`. `actor_type` includes `AGENT` so AI actions are attributable. The application role holds no UPDATE or DELETE grant on this table.

**Idempotency** — `idempotency_key(key PK, user_id, endpoint, request_digest, response_snapshot, state, expires_at)`. Applied to checkout and every webhook. Without it, a double-clicked checkout charges twice.

**Partitioning** — `analytics_event` and `progress_event` are partitioned monthly with automatic partition creation and a retention policy. This is the pressure valve that keeps a NoSQL store unnecessary.

**Materialised read models** — `catalog_page_view` per published version, rebuilt at publish time. A six-table join becomes one primary-key lookup.

## 5. Migration discipline

- **Expand/contract only.** Add the new column and dual-write, then remove the old one in a later migration. Deploys never require downtime.
- **Every migration tested `upgrade` AND `downgrade` in CI.** A migration you cannot reverse is a deploy you cannot roll back.
- **Autogenerate is a first draft, not an answer.** It misses renames (it drops and recreates, destroying data), server defaults, check constraints, enum changes.
- **Never edit a migration that has run anywhere.** Write a new one.
- **Data migrations in separate revisions from schema migrations**, so one can re-run without the other.
- **Destructive changes require a separate, explicitly reviewed migration** with a rollback runbook.

## 6. Indexing strategy

Index every foreign key, every column in a `WHERE` or `ORDER BY` on a hot path, GIN on `search_vector` and every queried JSONB column, partial indexes for soft-deleted uniqueness, and composite indexes ordered by selectivity. Index additions are reviewed against `EXPLAIN ANALYZE` output, not added speculatively — every index costs write throughput.

## 7. Backup and recovery

Daily full backup plus continuous WAL archiving for PITR. **Restore rehearsed quarterly** — an untested backup is not a backup, and the rehearsal is a scheduled ticket, not an intention. Object storage versioned with lifecycle rules. Recovery objectives: **RPO 5 minutes, RTO 1 hour**, both validated in the Sprint 14 disaster-recovery exercise.
