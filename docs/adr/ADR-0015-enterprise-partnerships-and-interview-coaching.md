# ADR-0015: Add Enterprise Sponsorship, Employer Talent Pipeline, and AI Interview Coaching

**Status:** Accepted · **Date:** 3 Sep 2026

## Context

A competitive gap analysis against Scaler Academy and FDE Academy (Futurense), conducted 3 Sep 2026, found three capabilities present in one or both competitors and absent from the original 20-sprint plan:

1. **Corporate cohort sponsorship and an employer hiring pipeline**: FDE Academy's core differentiator: employers sponsor training and browse a curated pool of pre-vetted graduates to hire.
2. **Academic-brand credential partnerships**: both competitors carry IIT partnerships on their certificates; we carry none.
3. **Mock interviews / interview coaching**: a named, marketed feature on both competitor platforms; present in our plan only as a single unbuilt line in `docs/12`'s AI capability table.

## Decision

Add all three, specified in `docs/39-enterprise-partnerships-and-interview-coaching.md`, using three placement rules:

- **Reuse existing patterns, never build a parallel system.** Corporate sponsorship extends commerce and entitlements; the talent pipeline extends careers and portfolio; co-branded credentials extend the existing signed-certificate system; interview coaching extends the AI gateway and the existing evaluation model.
- **Capability flags on one `Organisation` entity**, not three separate tables for employer/sponsor/partner, the same discipline already applied to the catalog type registry (`docs/06`) and to feature flags (`docs/05`).
- **Schedule impact stated, not absorbed.** Two of the three additions fit inside existing sprints because they are small extensions of an already-scheduled bounded context. The third, Organisation, sponsorship commerce, and the employer-facing surfaces, is a genuinely new bounded context and gets a new sprint, extending the full-scope completion date.

## Alternatives Considered

**Do nothing; treat these as future backlog with no committed placement.** Rejected. Two of the three gaps (corporate sponsorship, interview coaching) already had unused scaffolding sitting in the design, the `CORPORATE_AGREEMENT` entitlement source with no domain model, the interview-prep line with no build. Leaving known, partially-designed gaps unscheduled is worse than either building them or explicitly deferring them with a reason.

**Separate `Employer`, `CorporateClient`, and `Partner` tables.** Rejected for the same reason type-branching the catalog was rejected in `docs/06`: three parallel systems for what is structurally one relationship (an external organisation) triples the admin surface, the permission model, and the places a bug can hide, for a distinction that capability flags express in one column.

**Partner-issued credentials with an independent signing key per partner.** Rejected. Doubles key-management and revocation surface for a marginal credibility gain over attesting the partnership as signed metadata inside our own payload, the same verification authority, same revocation path, same public verification page either way.

**A dedicated corporate CRM/sales system, separate from the core platform.** Rejected for now. Corporate sponsorship at this scale is a commerce extension, not a sales-operations problem yet. Revisit if enterprise deal volume or contract complexity outgrows what `corporate_sponsorship` + `sponsorship_invite` can express.

**Fold all three into existing sprints with no schedule change.** Rejected. This project's own stated rule (`docs/24`, `docs/29`) is to extend the schedule when work doesn't fit, not compress it silently. Organisation, corporate commerce, and employer-facing surfaces are a real new bounded context comparable in scope to Careers or Community, each of which got a dedicated sprint. Pretending it fits for free would be the exact kind of overclaim this whole pack has been built to avoid.

**Add a fourth pillar for enterprise/B2B.** Rejected. `docs/02`'s Pillar 2 ("Community, Innovation & Careers") already named *"employer and recruiter ecosystem"* as part of its own scope from the original vision document, before any of this work started. The gap was never in positioning; it was that this line had never been built out into architecture. Adding a fourth pillar would have restructured a document that was already correct, to solve a problem that was actually an execution gap.

**Give `Organisation` genuine multi-tenant data isolation**: separate schemas or row-level security scoping every table by organisation. Rejected for this scope. Corporate sponsorship and the employer talent pipeline are a *business relationship* between an organisation and the platform, not a requirement that an organisation's data be walled off from every other organisation's. Building isolation now would answer a question nobody asked and duplicate the revisit trigger already recorded in `ADR-0008` for genuine multi-tenancy, that trigger stays exactly where it was: revisit if a real requirement for tenant-isolated data emerges, not preemptively.

## Consequences

**Positive:** closes a real, evidenced competitive gap · every addition strengthens rather than dilutes the platform's existing architectural discipline, since each one is a worked example of the capability-flag pattern applied to a new domain · the `CORPORATE_AGREEMENT` entitlement source finally has a domain model behind it, three years, sorry, one sprint plan, after being anticipated.

**Negative:** full-scope completion date moves from 6 Jun 2027 to **20 Jun 2027** (+14 days, one sprint) · a new bounded context means new authorization permissions, new admin surfaces, and new test coverage that didn't exist in the original estimate · enterprise sales has a materially different motion (longer cycles, procurement, contracts, invoicing terms) than B2C, which this ADR does not solve, see the new risk entry in `docs/31`.

## Trade-offs

Fourteen days added to the full-scope timeline in exchange for closing three named, evidenced competitive gaps rather than leaving them as an untracked risk. Given the gaps were found through direct comparison against two live, funded competitors, not speculation, the trade favors building over deferring.

## Cost

No new infrastructure. All three additions live inside the existing PostgreSQL system of record, the existing AI gateway, and the existing commerce and credential systems. The only new operational cost is whatever the corporate sales motion itself requires (invoicing terms, contract review), not a technology cost.

## Security

Talent pipeline is opt-in only, enforced at the schema level (`talent_pool_entry` requires an explicit row; no default visibility). Employer messages are logged and auditable (`employer_interest`). Co-branded credentials never grant a partner write access to the credential system, the relationship is data on our side, attested in our signature, not delegated authority. Corporate sponsorship redemption uses the same row-lock discipline as coupon redemption (`docs/09` §2) to prevent seat overselling under concurrency.

## Scalability

No different from the systems being extended, corporate sponsorship rides on the existing commerce write path; talent pipeline reads are cacheable the same way catalog reads are; interview coaching is bounded by the same AI budget and rate-limiting controls as every other agentic capability.

## Migration Path

Every table added here is additive, no existing table is altered except three new nullable columns on `certificate_policy`. Nothing in this ADR requires touching data already in production by the time it ships (Sprints 10, 19, and 21 are all ahead of the current execution point).

## Revisit Trigger

Enterprise deal volume or contract complexity that outgrows a lightweight `Organisation` + `corporate_sponsorship` model → revisit the "no dedicated CRM" decision. Genuine need for data-isolated multi-tenancy, as opposed to a business relationship, → revisit alongside the existing multi-tenancy revisit trigger in ADR-0008.
