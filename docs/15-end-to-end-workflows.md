# 15: End-to-End Workflows

Each workflow: trigger → steps → authorization → data written → failure handling → audit.

## Registration
`Visitor → Signup → Email verification → Profile → Explore`
**AuthZ:** public. **Writes:** `user`, hashed single-use `verification_token` with TTL. **Failures:** duplicate email returns a generic success (no enumeration); expired token offers a rate-limited resend. **Audit:** `user.created`, `user.verified`.

## Program discovery
`Homepage → Career → Track → Program → Specialization → Curriculum → Course`
Served from the materialised read model behind CDN + ISR + Redis. **All hierarchy resolved from `catalog_relationship`**: no hardcoded structure anywhere in the frontend. Emits `{kind}_viewed`.

## Purchase

```
   MONEY BECOMES ACCESS: the flow that must never break

   learner picks a product
            |
   checkout: server resolves price, coupon, tax, total
            |            (client NEVER sends an amount)
            v
   Order created, state PENDING_PAYMENT
            |
            v
   payment provider redirect
            |
     +------+------+
     |             |
  succeeds      fails / abandoned
     |             |
     |             +--> order stays PENDING_PAYMENT
     |                  learner sees a retry path
     |                  NO partial access granted
     v
  provider webhook arrives
     |
     +--> signature verified on RAW BYTES
     +--> event id not seen before (unique constraint)
     +--> amount and currency match the order
     |
     v  only if ALL of the above pass
   ENTITLEMENT granted   <-- the fact that actually
     |                       decides access
     v
   Enrolment created, learner is in

   Meanwhile, on a schedule:
   reconciliation checks orders stuck PENDING_PAYMENT
   against the provider, because webhooks get lost
   and money must not.
```

`Product → server-side price resolution → coupon validation → checkout session → order → payment → webhook verification → entitlement → enrolment → receipt`
Idempotency key on checkout. **Amounts never accepted from the client.** Entitlement granted only after verified webhook. Hourly reconciliation catches lost webhooks. **Failure:** order stays `PENDING_PAYMENT`, learner sees a retry path, **no partial access is ever granted.**

## The three access tiers converging

```
   THREE WAYS IN, ONE WAY TO CHECK

   FREE                SUBSCRIPTION         ONE-TIME
   zero-value order    monthly/annual       purchase
        |                   |                   |
        v                   v                   v
   entitlement         entitlement         entitlement
   source=FREE         source=SUBSCRIPTION source=PAYMENT
   valid_until=null    valid_until=period  valid_until=
   (never expires)     end + grace         duration+1yr
        |                   |               (fixed at
        |                   |                purchase)
        +---------+---------+-------------------+
                  |
                  v
        "is today before valid_until?"
                  |
                  v
        LMS, certificates, portfolio, video player

   Every delivery system asks ONE question and never
   learns which tier answered it. That is why three
   tiers cost about the same to maintain as one.
```

## Free certification
`Free Certification Course → enrolment (zero-value order) → learning → assessment → completion → certificate → verification`
Same code path as paid, payment skipped by server-side policy. Assessment thresholds are real.

## Subscription

```
   SUBSCRIPTION LIFECYCLE: lapse suspends, never deletes

   TRIALING --> ACTIVE <----------------+
                  |                     |
          renewal fails                 | payment
                  |                     | succeeds
                  v                     |
              PAST_DUE  (retries, widening gaps)
                  |                     |
          retries exhausted             |
                  |                     |
                  v                     |
               GRACE  (short courtesy window) 
                  |                     |
           grace ends                   |
                  |                     |
                  v                     |
             SUSPENDED ------ resubscribe
                  |
   PROGRESS, notes, submissions, earned certificates,
   and karma ALL SURVIVE untouched. Access is hidden,
   never destroyed. A learner whose card expired in
   March does not lose a year of work.
```

`Plan → checkout → payment → subscription → entitlement (valid_until = period_end + grace) → renewal`
Renewal failure → retry with backoff → `PAST_DUE` → `GRACE` → suspension. **Progress and submissions retained through suspension**: learner data outlives billing state.

## Video playback authorisation

```
   EVERY PLAY IS AUTHORISED, EVERY TIME

   learner presses play
            |
            v
   entitlement check   <-- does a valid grant exist
            |               right now for this item
     +------+------+
     |             |
    yes            no
     |             |
     |             +--> refused, no URL issued
     v
   short-lived SIGNED URL issued
   (minutes, session-bound)
            |
            v
   CDN honours the signature, serves segments
            |
            v
   player streams adaptively, emits progress events

   No permanent public link to paid video exists.
   A copied link stops working almost immediately
   and was tied to that session in the first place.
```

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
