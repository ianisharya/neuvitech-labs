# 39: Enterprise, Partnerships & Interview Coaching

**Added 3 Sep 2026**, in response to a competitive gap analysis against Scaler Academy and FDE Academy (Futurense). Three capabilities were missing from the original 20-sprint plan: a corporate/enterprise commerce and sponsorship model, an employer-facing talent pipeline, and a formalized interview-coaching capability. This document specifies all three.

**Design discipline held throughout:** every addition here reuses an existing pattern rather than inventing a parallel one. If you find yourself building a second way to grant access, a second way to sign a credential, or a second commerce flow, stop, that's the exact mistake this document exists to prevent.

---

## 1. Organisation: one entity, capability-flagged, not three separate systems

The naive approach adds three unrelated things: an "Employer" table for the talent pipeline, a "Corporate Client" table for sponsorship, and a "Partner" table for co-branded credentials. Three tables, three admin screens, three sets of permissions, for what is structurally the same thing three times: an external entity with a relationship to the platform.

**This is the exact mistake `docs/06`'s catalog type registry was built to prevent, applied to a different domain.** One entity, capability flags.

```sql
organisation(
 id UUID PK,
 name, legal_name, slug,
 capabilities JSONB, -- {"employer": true, "corporate_sponsor": true, "credentialing_partner": false}
 billing_contact_email, billing_address JSONB,
 status: PENDING | ACTIVE | SUSPENDED,
 created_by, created_at
)

organisation_member(
 organisation_id FK, user_id FK,
 role: ADMIN | BILLING | VIEWER,
 invited_by, joined_at,
 UNIQUE (organisation_id, user_id)
)
```

An organisation can be an employer, a corporate sponsor, a credentialing partner, or any combination, a university that also wants to hire graduates sets both flags on one row. New relationship types in future are new capability flags, not new tables. **This is the same non-negotiable as the catalog: capability-driven, never type-branched.** `grep -r "capabilities\[.employer.\] ==" ` style branching in service code fails the same guardrail check as `kind ==` does for the catalog.

---

## 2. Corporate cohort sponsorship: a commerce extension, not a new commerce system

FDE Academy's model: an employer sponsors an engineer's training, or buys a dedicated cohort. This is real revenue and a real distribution channel neither competitor's absence from our original plan should have left unaddressed.

### The mistake to avoid

Building a second checkout flow for corporate purchases. **There is one commerce system.** A corporate sponsorship is a bulk purchase of seats against an existing product, by an organisation instead of an individual, same `Product`, same `Price`, same `Order`, same invoice numbering discipline from `docs/09`.

```sql
corporate_sponsorship(
 id UUID PK,
 organisation_id FK,
 catalog_item_id FK, -- which program/specialization/masterclass
 order_id FK, -- the actual purchase, same commerce.order table
 seats_purchased INT,
 seats_redeemed INT DEFAULT 0,
 price_per_seat_minor, currency,
 starts_at, expires_at,
 status: ACTIVE | EXHAUSTED | EXPIRED,
 CHECK (seats_redeemed <= seats_purchased)
)

sponsorship_invite(
 id UUID PK,
 sponsorship_id FK,
 code TEXT UNIQUE, -- redemption code, or targeted to an email
 invited_email TEXT,
 redeemed_by_user_id FK NULL,
 redeemed_at NULL,
 expires_at
)
```

### The entitlement source already existed and was never used

`docs/09` §4 already lists `entitlement.source ∈ { ..., CORPORATE_AGREEMENT, ... }`. That value has been sitting in the enum since Sprint 1 planning with no domain model underneath it. This document is that domain model, not a new decision.

**Redemption flow:**
```
Organisation admin buys N seats (normal checkout, organisation as billing party)
 → corporate_sponsorship created, seats_purchased = N
 → N sponsorship_invite rows generated (codes or targeted emails)
 → candidate redeems a code
 → SELECT ... FOR UPDATE on corporate_sponsorship (same race-condition discipline as coupon redemption, docs/09 §2)
 → entitlement created: source = CORPORATE_AGREEMENT, source_ref_id = sponsorship_invite.id
 → enrolment proceeds through the IDENTICAL path as any other entitlement source
```

**Non-negotiable, restated from `docs/09` §4:** access checks ask the entitlement service, never a sponsorship table directly. A corporate-sponsored learner and a self-paying learner are indistinguishable to every downstream system, LMS, certificates, portfolio. This is the entire reason entitlement sources exist as an enum rather than a table join.

---

## 3. Employer talent pipeline: opt-in, or it doesn't ship

FDE Academy's "curated pool of pre-vetted engineers for employers to hire" is real product-market signal. It is also a privacy decision with real consequences if built wrong.

### The non-negotiable

**A learner must explicitly opt in. Employers never get a default view of anyone's profile, ever.** This is not a UX preference, it is consistent with `docs/08` §9's existing data-minimisation stance, and it is the difference between a feature learners trust and a feature that gets the platform accused of selling their data.

```sql
talent_pool_entry(
 id UUID PK,
 user_id FK UNIQUE,
 visibility: PUBLIC | ORGANISATION_ALLOWLIST,
 allowlisted_organisation_ids UUID[] NULL, -- only when visibility = ORGANISATION_ALLOWLIST
 headline, skills_summary,
 featured_credential_ids UUID[], -- references credential.id, existing table, no duplication
 featured_project_ids UUID[], -- references submission.id where is_public = true
 opted_in_at, updated_at
)

employer_interest(
 id UUID PK,
 organisation_id FK,
 user_id FK,
 talent_pool_entry_id FK,
 message,
 status: SENT | VIEWED | RESPONDED | DECLINED,
 created_at
)
```

`featured_credential_ids` and `featured_project_ids` are references, never copies, a revoked certificate (`docs/06` §5, credential lifecycle) disappears from a talent pool entry automatically, because there is exactly one source of truth for whether a credential is currently valid. Duplicating credential state into this table would create the same class of bug the catalog versioning system exists to prevent.

**Opting out is one action, immediate, and removes the entry from every employer's future search**: it does not retroactively un-send messages already sent, which is disclosed at opt-in time.

---

## 4. Co-branded credentials: one signature, not two

Both competitors lean on academic-brand partnerships (IIT-Roorkee, IIT Delhi) for credibility. If NeuViTech pursues a credentialing partnership, the certificate system needs to represent it, without undermining the single-verification-authority design in `docs/06` §5.

### The decision, and the alternative rejected

**Rejected: letting a partner co-sign with their own key.** This would mean trusting an external party's private key security, doubling key-rotation and revocation complexity, and splitting verification authority across two systems for a marginal credibility gain over the alternative below.

**Decision: the partner relationship is attested metadata inside our own signed payload, not a second signature.**

```sql
-- extends certificate_policy, docs/06 §5
ALTER TABLE certificate_policy ADD COLUMN co_issuer_organisation_id UUID REFERENCES organisation(id) NULL;
ALTER TABLE certificate_policy ADD COLUMN co_issuer_display_name TEXT NULL;
ALTER TABLE certificate_policy ADD COLUMN co_issuer_logo_media_id UUID NULL;
```

The Ed25519-signed payload (`docs/06` §5) includes the co-issuer's identity when set, so the partnership itself is cryptographically attested, a forged co-branding claim fails verification exactly like a forged grade would. The public verification page renders both logos. **One key, one verification authority, one place a revocation actually revokes.**

Requires `organisation.capabilities.credentialing_partner = true` and a signed agreement recorded outside this system (legal, not technical) before the flag is set, this document covers the architecture, not the partnership negotiation.

---

## 5. AI Interview Coach: formalizing a line that already existed

`docs/12-agentic-ai-architecture.md`'s capability table already listed *"Interview preparation | Agentic | Stateful multi-turn dialogue with retrieval"*, one line, no data model, no epic, no sprint. Both named competitors ship this as a real, marketed feature. This section is that line, actually built out.

```sql
mock_interview_session(
 id UUID PK,
 user_id FK,
 catalog_item_id FK NULL, -- optionally scoped to a program/specialization
 interview_type: BEHAVIORAL | TECHNICAL_CODING | SYSTEM_DESIGN | DOMAIN_SPECIFIC,
 mode: AI_AGENT | HUMAN_MENTOR,
 status: SCHEDULED | IN_PROGRESS | COMPLETED | CANCELLED | ABANDONED,
 started_at, ended_at,
 transcript_media_id UUID NULL, -- private, access-controlled same as any submission
 ai_feedback JSONB NULL, -- structured: clarity, correctness, communication, per-question notes
 human_evaluation_id UUID NULL REFERENCES evaluation(id) -- reuses the existing evaluation table, docs/10 §4
)
```

**`AI_AGENT` mode is a gateway consumer, not a new AI system.** It goes through the exact chokepoint in `docs/12` §2, same authorization, same budget check, same guardrails, same audit trail. The interview prompt is one more entry in `ai_prompt_version`, reviewed like any other. **Same failure posture as every other AI capability (`docs/12` §8): if the provider is down, mock interview scheduling degrades to `HUMAN_MENTOR` mode or a clear "unavailable" state, nothing in a core learning or commerce path waits on this.**

`HUMAN_MENTOR` mode reuses the existing `evaluation`/`rubric`/`feedback` tables from `docs/10` §4 rather than inventing a parallel review system, a mentor-reviewed mock interview is graded exactly like a project submission.

A completed, well-scored session can optionally be surfaced in the learner's portfolio (`docs/06`), same opt-in publishing action as any other project.

---

## 6. What did not change

**No fourth pillar.** `docs/02`'s three-pillar model (EdTech dominant, Community/Careers secondary, ITES tertiary) holds. Corporate sponsorship is a distribution channel *for* Pillar 1's existing catalog, not a new business line. The employer talent pipeline extends Pillar 2's existing Careers epic. Neither required, or received, a positioning rewrite.

**No new commerce system, no new credential system, no new AI system.** Every table above either extends an existing one or references it by ID. That was the design constraint going in, and it held.

**No multi-tenancy.** `organisation` is a business entity with members and capability flags, not a data-isolation boundary. The `scope_type = ORGANISATION` hook already present in `docs/05`'s settings architecture remains unused by this document, genuine multi-tenant isolation is a separate, larger decision, still out of scope, still with the same revisit trigger as before.

Reference: ADR-0015, `docs/25-master-roadmap.md` (Sprint 21), `docs/27-jira-backlog.md` (NVL-E24).
