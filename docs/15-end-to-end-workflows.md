# 15: End-to-End Workflows

Each workflow: trigger → steps → authorization → data written → failure handling → audit.

## Registration
`Visitor → Signup → Email verification → Profile → Explore`
**AuthZ:** public. **Writes:** `user`, hashed single-use `verification_token` with TTL. **Failures:** duplicate email returns a generic success (no enumeration); expired token offers a rate-limited resend. **Audit:** `user.created`, `user.verified`.

## Program discovery
`Homepage → Career → Track → Program → Specialization → Curriculum → Course`
Served from the materialised read model behind CDN + ISR + Redis. **All hierarchy resolved from `catalog_relationship`**: no hardcoded structure anywhere in the frontend. Emits `{kind}_viewed`.

## Purchase
`Product → server-side price resolution → coupon validation → checkout session → order → payment → webhook verification → entitlement → enrolment → receipt`
Idempotency key on checkout. **Amounts never accepted from the client.** Entitlement granted only after verified webhook. Hourly reconciliation catches lost webhooks. **Failure:** order stays `PENDING_PAYMENT`, learner sees a retry path, **no partial access is ever granted.**

## Free certification
`Free Certification Course → enrolment (zero-value order) → learning → assessment → completion → certificate → verification`
Same code path as paid, payment skipped by server-side policy. Assessment thresholds are real.

## Subscription
`Plan → checkout → payment → subscription → entitlement (valid_until = period_end + grace) → renewal`
Renewal failure → retry with backoff → `PAST_DUE` → `GRACE` → suspension. **Progress and submissions retained through suspension**: learner data outlives billing state.

## Learning
`Enrolment → Program → Specialization → Course → Module → Lesson → progress → assignment → project → assessment → completion → certificate`
Progress events batched client-side, flushed every 15 s, written asynchronously. **Completion criteria come from the enrolled `catalog_item_version`**, so rules cannot change under an active learner.

## Masterclass
`Discovery → detail → registration → payment if required → entitlement → enrolment → session → attendance → recording → assessment → certificate if eligible`
Capacity enforced with a row lock; overflow to waitlist. **Per-user meeting links, never a shared hardcoded URL.**

## Live learning
`Cohort → session → MeetingProvider (Zoom) → attendance → recording → resources → LMS`
Credentials in encrypted settings. Attendance from provider webhooks, reconciled by a scheduled job. Recordings ingested asynchronously into private storage, served via signed URLs.

## Project
`Assignment → submission → evaluation → feedback → resubmission → completion → portfolio`
Submissions private by default; publishing is an explicit learner action. Files scanned and stored privately.

## Certificate
`Completion → eligibility → generation (worker) → issuance → public verification → download → portfolio`
Idempotent issuance; unique constraint prevents duplicates under retry. Verification public, cacheable, rate-limited, **indexable**. Revocation is a state transition with audit, never a deletion.

## Brochure
`Product → request → lead capture if policy → generate or retrieve current version → signed URL → download → analytics`
Generation asynchronous and idempotent. Regeneration triggered by `catalog.item.published`, so the PDF cannot drift from the catalog.

## Superuser grant
`Authentication → MFA → authorization (admin.enrolment.grant) → grant → entitlement(SUPERUSER_GRANT) → enrolment → audit`
Records grant type, granted_by, waiver reason, payment status. **Entitlement source is server-assigned, never accepted from a request body.**

## Career
`Job → application → resume → screening → interview → status`
Resumes private, scanned, access-controlled. Employers see only what the candidate consented to share.

## AI
`User → AI gateway → authN → authZ → budget → guardrails → ACL-filtered retrieval → agent → tool permission → tool → audit → output validation → response`
High-risk actions insert a human approval gate before execution.

## Configuration change
`Admin → settings UI → validate against JSON Schema → permission check → write value → audit → bump cache version → propagate`
**No deploy.** Effective within seconds.

## Deployment
`Feature → Jira → branch → commit → PR → CI → DEV → QA → UAT → approval → PROD → canary → smoke → observe → release recorded`

## Incident
`Alert → runbook → investigate → mitigate (rollback / flag off / setting change) → fix → verify → post-incident review`
**Two of the three mitigation paths require no deployment.**
