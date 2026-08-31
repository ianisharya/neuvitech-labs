# 06 — Product Catalog Architecture

**The load-bearing design of the platform.** Masterclasses, Programs, Tracks, Specializations, Free Certification Courses, Certificates and Brochures are **first-class product capabilities** — not metadata on a Course, not one-off exceptions. New offerings must be introducible without an architectural rewrite.

---

## 1. The failure mode we design against

The default LMS design:
```
Course ──has many──> Module ──has many──> Lesson
   ^
   └── type: "masterclass" | "program" | "free_cert"   ← the mistake
```

Everything else becomes a boolean or an `if type == 'masterclass'` branch. It works for three months. Then a Masterclass needs live sessions and a Program does not; a Track needs sequencing across Programs; a Free Certification Course needs an exam but no payment; a Certificate needs revocation. Type-branching metastasises into every service, template and query, and the ninth product type means touching forty files.

**That is the "architectural rewrite" we are forbidden from needing.**

## 2. The core insight — three orthogonal concerns

| Concern | Question | Aggregate root |
|---|---|---|
| **Catalog** | What exists and is discoverable? | `CatalogItem` |
| **Commerce** | What is sold, at what price, to whom? | `Product` |
| **Learning** | What is delivered and completed? | `Enrolment` → `LearningComponent` |

A Free Certification Course is a `CatalogItem` with a `Product` priced at zero and full learning delivery. A Brochure is a document artefact *of* a `CatalogItem` with no commerce and no learning. A Certificate is an *outcome* of learning with its own credential lifecycle. Because the three are separate, each capability composes only what it needs — no nulls, no unused columns, no type-branching.

## 3. The type registry — how "no rewrite" is achieved

`catalog_item_type` is configuration, not code:

| Column | Purpose |
|---|---|
| `kind` (PK) | `PROGRAM`, `TRACK`, `SPECIALIZATION`, `MASTERCLASS`, `COURSE`, `FREE_CERTIFICATION_COURSE`, `BOOTCAMP`, `WORKSHOP`, `CORPORATE_PROGRAM`, … |
| `attribute_schema` JSONB | **JSON Schema** validating this kind's `attributes` |
| `lifecycle_states` JSONB | Allowed states and transitions for this kind |
| `allowed_child_kinds` JSONB | Which kinds may sit beneath it |
| `allowed_relations` JSONB | Which relation types are legal from this kind |
| `commerce_policy` | `NOT_SELLABLE` / `FREE` / `ONE_TIME` / `SUBSCRIPTION` / `EITHER` |
| `certificate_policy_id` | Eligibility rule set, nullable |
| `brochure_template_id` | Which template renders it, nullable |
| `route_pattern` | `/programs/{slug}`, `/masterclasses/{slug}` |
| `seo_template` JSONB | Title, description and JSON-LD templates |
| `capabilities` JSONB | `live_sessions`, `cohorts`, `assessments`, `projects`, `attendance`, `recordings`, `waitlist`, `lead_capture` |
| `search_config` JSONB | FTS weights and facets |

**Introducing "Executive Fellowship" as a tenth type is an INSERT plus a brochure template plus (optionally) a route segment. Not a migration. Not a service change.** That is the concrete, testable meaning of a scalable catalog — and it is the same "everything is data" principle as `05-configuration-architecture.md`.

### Where configuration stops

Configuration cannot express genuinely different *relational* structure. A live Masterclass needs scheduled sessions with instructors, capacity, attendance and recordings — real relational data with its own lifecycle. Cramming it into JSONB forfeits constraints, joins and indexes.

So we use a **hybrid**: JSONB `attributes` for descriptive per-kind fields (validated by the registry's JSON Schema), and **extension tables** for capabilities with genuine relational structure.

**Extension tables attach by capability, not by kind.** `live_session` attaches to anything whose registry entry declares `capabilities.live_sessions = true` — Masterclass today, Bootcamp tomorrow, Workshop next month, zero code change. **This is the key move: capability-oriented, not type-oriented.**

## 4. Core schema

### `catalog_item`
```
id UUIDv7 PK · kind FK → catalog_item_type · slug (unique per kind, partial index)
title · subtitle · summary · description_rich
status: DRAFT|IN_REVIEW|SCHEDULED|PUBLISHED|DEPRECATED|ARCHIVED
visibility: PUBLIC|UNLISTED|PRIVATE|INTERNAL
attributes JSONB              -- validated against the registry schema
difficulty · duration_minutes · effort_hours_per_week · language · locale
hero_media_id · thumbnail_media_id · seo JSONB
search_vector TSVECTOR GENERATED (GIN)
published_at · published_version_id · deprecated_at
created_by · updated_by · created_at · updated_at · deleted_at
```
Indexes: `(kind,status,visibility)`, `(slug)`, GIN on `search_vector`, GIN on `attributes`, `(published_at DESC)`.

### `catalog_item_version` — immutable published snapshots
```
id · catalog_item_id · version_number · content_snapshot JSONB
relationship_snapshot JSONB · published_at · published_by · checksum · is_current
```

**Why this table is non-negotiable:** a learner enrolled in AI Engineering v3 must keep the curriculum, outcomes and certificate criteria they were sold. Without versioning, an admin editing the live Program silently changes the contract of every active learner, invalidates every generated brochure, and retroactively breaks certificate eligibility.

- Enrolments pin to a `catalog_item_version_id`, never to `catalog_item_id`.
- Brochures generate **from a version**, so a downloaded PDF always matches what was promised.
- Certificate eligibility resolves against the enrolled version.
- Publishing = create version → validate → flip `is_current` → emit `catalog.item.published` via the outbox → invalidate caches → enqueue brochure regeneration.

### `catalog_relationship` — the hierarchy, as data
```
id · from_item_id · to_item_id · relation_type · ordinal
requirement: REQUIRED|ELECTIVE|RECOMMENDED · constraints JSONB
valid_from · valid_until
UNIQUE (from_item_id, to_item_id, relation_type)
```
Relations: `CONTAINS` · `SPECIALIZATION_OF` · `PART_OF_TRACK` · `PREREQUISITE_OF` · `ENTRY_POINT_TO` · `RELATED_TO` · `BUNDLES` · `LEADS_TO_CAREER`.

The canonical chain `Career → Program → Track → Specialization → Course → Module → Lesson` is **data, not code**. The frontend renders whatever the graph returns. A Track spanning two Programs, or a Masterclass that is an entry point into three Specializations, needs rows — not a code change. Cycle prevention and depth limits are enforced on write with a recursive CTE.

### Capability extension tables
| Table | Attaches when | Owns |
|---|---|---|
| `cohort` | `capabilities.cohorts` | Batch, dates, capacity, enrolment window, state |
| `live_session` | `capabilities.live_sessions` | Schedule, instructor, meeting ref, capacity |
| `session_attendance` | ↑ | Join/leave, duration, attendance %, verification |
| `session_recording` | ↑ | Storage key, duration, processing state, access policy |
| `assessment` | `capabilities.assessments` | Type, weight, pass mark, attempt limits |
| `learning_component` | LMS delivery | Module/Lesson tree, content refs, ordering |
| `credential` | `certificate_policy_id` set | Certificates (§6) |
| `brochure` / `brochure_version` | `brochure_template_id` set | Brochures (§7) |

## 5. The seven capabilities, concretely

**Programs** — `kind=PROGRAM`, commerce `ONE_TIME` or `SUBSCRIPTION`, contains Specializations, sits within Tracks, maps to Careers. Capabilities: cohorts, live sessions, assessments, projects, brochures, certificates. Versioned. Route `/programs/{slug}`, JSON-LD `Course`.

**Tracks — not a label on a course.** A sequenced, outcome-bearing path that may span multiple Programs. Own landing page and SEO, own objectives and career outcomes, ordered required/elective components via `ordinal` + `requirement`, own progress computation across constituent items, own completion definition and optional Track certificate, own analytics. Usually `NOT_SELLABLE`, but `BUNDLES` allows selling one later without redesign.

**Specializations** — `SPECIALIZATION_OF` a Program. Own curriculum (required + elective), prerequisites, skill map, projects, assessments, certification requirements, career mapping. Independently purchasable where the registry's commerce policy permits, so "buy the Program" and "buy just Agentic AI" are the same code path with different rows.

**Masterclasses — the stress test.** Simultaneously independently discoverable, independently purchasable or free, live *and* recorded, cohort-based, attendance-tracked, assessable, certificate-eligible, bundleable into Programs, and an entry point into Specializations. It needs **no special-case code**: capabilities `{live_sessions, cohorts, attendance, recordings, assessments}` all true, commerce policy `EITHER`, relations `ENTRY_POINT_TO` and `BUNDLES`. Everything else is the generic path.

**Free Certification Courses** — `commerce_policy = FREE`. **Critical: free ≠ no commerce path.** Enrolment still runs `Product(price=0) → Order(total=0) → Entitlement(source=FREE_ENROLMENT) → Enrolment`. The order is created and audited exactly like a paid one; only the payment step is skipped by server-side policy. One entitlement model, one enrolment model, one analytics funnel — and **a paid product can never leak through the free path**, because price resolves server-side from the product, never from the request.

**Certificates** — a credential aggregate, not a PDF:
```
ELIGIBLE → GENERATED → ISSUED → (VERIFIED events, unbounded) → REVOKED
                                                             ↘ EXPIRED
```
Public verification at `/verify/{credential_code}` — cacheable, rate-limited, **indexable** (organic proof of credibility). Ed25519 detached signature over a canonical payload allows offline verification against our published public key; revocation still requires the online check, and both are offered. Revocation is a state transition with audit, never a deletion. Issuance is idempotent with `UNIQUE (user_id, catalog_item_version_id, credential_type)` preventing duplicates under retry. Open Badges 3.0 / W3C VC alignment is an **evaluation** (ADR-0008), not a claim.

**Brochures** — versioned document artefacts generated **from `catalog_item_version`**, never hand-authored, so "do not duplicate brochure information" is structurally enforced: there is nowhere to type duplicate content. Regeneration is event-driven on `catalog.item.published`, so brochures cannot drift. Immutable versions mean a brochure downloaded in March remains retrievable. Access is via an authorised endpoint issuing a short-lived signed URL — **never a public object-storage URL** — so access policy and analytics are enforced server-side. A `brochure_safe` field whitelist in the registry means internal costs, margins and admin notes are structurally unable to reach a PDF. Rendered HTML→PDF in a worker, never in the request path.

## 6. Skills, careers and recommendations — relational, not Neo4j

```
skill · skill_edge(from,to,relation,weight) · catalog_item_skill(level,is_outcome)
career · career_skill(importance) · user_skill(level,evidence_type,evidence_id,verified_at)
job_skill(importance)
```

Skill-gap analysis is `career_skill` minus `user_skill`, then remaining skills mapped to catalog items. A join and a recursive CTE — not a graph database. `user_skill.evidence_id` pointing at a graded submission or credential is what makes the skill graph *trustworthy* rather than self-declared. Neo4j revisit trigger in ADR-0003.

## 7. API surface

```
GET  /api/v1/catalog/items?kind=&track=&skill=&difficulty=&q=&page=
GET  /api/v1/catalog/items/{kind}/{slug}
GET  /api/v1/catalog/items/{id}/curriculum
GET  /api/v1/catalog/items/{id}/related
GET  /api/v1/catalog/{programs|tracks|masterclasses}/{slug}   # pretty projections, one implementation
GET  /api/v1/catalog/search?q=
POST /api/v1/brochures/{item_id}/request
GET  /api/v1/brochures/{version_id}/download
GET  /api/v1/credentials/verify/{code}                        # public, rate-limited
POST /api/v1/admin/catalog/types                              # register a new product kind
POST /api/v1/admin/catalog/items/{id}/publish
```

## 8. How the non-negotiables are met

| Requirement | Mechanism |
|---|---|
| Own domain models | `catalog_item` + per-capability extension tables |
| Own lifecycle states | Per-kind `lifecycle_states` in the registry |
| Own relationships | `catalog_relationship` with typed relations |
| Own discovery surfaces | `route_pattern` + `seo_template` per kind |
| Own permissions | `catalog.{kind}.{action}`, generated from the registry |
| Own APIs | Uniform resource API + per-kind projections |
| Own administration | Admin renders forms from `attribute_schema` |
| Own analytics | `{kind}_viewed` emitted generically with `kind` as a dimension |
| Own SEO | Per-kind JSON-LD, sitemap partitioned by kind |
| Commerce where applicable | `commerce_policy` per kind; commerce never references `kind` |
| No rewrite for new offerings | New kind = registry row |
| No scattered product rules | **`grep -r "kind ==" ` in service code fails CI** |
| No duplicated product data | One `catalog_item`; pages, brochures and PDFs all render from the same version |
