# ADR-0016 - Three-Tier Access Model, Subscription-Primary, EMI Removed

**Status:** Accepted · **Date:** 3 Sep 2026

## Context

The original commerce design was built around one-time purchases with an optional EMI financing path, and treated subscriptions as a secondary capability. Two business decisions changed this. First, the primary model is now subscription, billed monthly or annually, because recurring revenue is more predictable and because a subscription rewards and depends on the consistent engagement the whole platform is designed to encourage. Second, EMI was removed entirely, because its availability, fees, and refund behaviour were never confirmable and subscriptions serve the same spread-the-cost need without that uncertainty.

At the same time, the platform needs to keep a genuinely free tier as its top of funnel, and needs a way to sell certain flagship items outright to learners who want to own them beyond a subscription.

## Decision

Adopt three access tiers, all expressed through the existing single entitlement model rather than through three separate systems.

Tier 1 is free, non-expiring, gated by real assessment. Tier 2 is subscription, monthly or annual, where a lapse suspends access without deleting progress. Tier 3 is a one-time purchase whose access window is the item's published duration plus one year, fixed at the moment of purchase.

Remove EMI from the plan entirely.

## Alternatives Considered

**Subscription only, with no one-time purchases at all.** Rejected because some learners genuinely want to own a flagship credential outright rather than rent access to it, and because the eventual academically co-branded credential is exactly the kind of serious, owned thing that fits a purchase rather than a subscription. A pure subscription model would have forced those learners into a rental they did not want.

**One-time purchases only, keeping the original model and just dropping EMI.** Rejected because it forgoes recurring revenue, which is the more predictable base to build a business on, and because it does not reward consistency the way a subscription does.

**One-time purchase granting perpetual access, owned forever.** Seriously considered and rejected in favour of duration plus one year. Perpetual access is more expensive to sustain, because the platform serves video and infrastructure for purchases made arbitrarily long ago, and it is dishonest to store, because forever is represented as a null end date, which is the special case the schema was specifically trying to avoid. A fixed date of duration plus one year is generous enough to be a strong offer, honest to store as a real date, and bounded in cost.

**Access window tied to the learner's actual completion date rather than the published duration.** Rejected because that date is not knowable at purchase, so it cannot be shown on the receipt, and because it creates an unanswerable edge case when a learner never completes. Using the published duration means the end date is fixed and knowable on day one.

**Keeping EMI as an unverified future possibility.** Rejected. Carrying a feature the plan could never actually promise, always hedged as unconfirmed, added edge cases around part-paid financing and refunds for no certain benefit. Removing it removes a whole category of unverified claims.

## Consequences

**Positive.** Recurring revenue becomes the base of the business. The free tier stays a real product and a genuine funnel. Learners who want ownership can buy it. The three tiers cost roughly the same to maintain as one, because they are three sources on one entitlement model, not three systems. Removing EMI removes real complexity and a set of claims that could not be substantiated.

**Negative.** Subscription billing is more complex than one-time payment, with renewals, retries, grace periods, proration, and state transitions that all have to be correct and tested. A lapsed subscription that suspends access is a worse moment for the learner than owning something outright, which puts real weight on the resubscribe experience and on never deleting progress. The business now depends on retention, not just acquisition, which is a harder discipline.

## Trade-offs

More billing complexity in exchange for predictable recurring revenue and a model that rewards consistency. The complexity is real and lands mostly in the subscription state machine, which is why doc 09 gives it the most careful treatment and the largest share of the test matrix.

## Cost

No new infrastructure. Subscriptions run through the same Razorpay provider and the same order path as one-time purchases. The cost is engineering time on the subscription state machine and its tests, not new systems to run.

## Security

Unchanged from the principles already in place. Price is resolved server-side, never accepted from the client. Entitlement is granted only on verified payment. The free tier cannot be used as a side door into paid content because price is resolved from the product on the server. Karma as a currency for goodies runs through the same verified, server-side order path.

## Scalability

The entitlement check is a single date comparison regardless of tier, so access checking does not get more expensive as the tier model grows. Subscription renewals are handled by scheduled background work that scales independently of the request path.

## Migration Path

Because access is checked against entitlements and not against payment or subscription records, a future change to the tier model is a new source value and new billing logic, not a change to how any delivery system checks access. The delivery side is insulated from commerce changes by design.

## Revisit Trigger

If retention data shows subscriptions are the wrong primary model for this market, revisit the balance between subscription and one-time. If a confirmed, well-priced financing product becomes available and learners genuinely need it, revisit the removal of EMI, but only against confirmed terms, never on assumption.
