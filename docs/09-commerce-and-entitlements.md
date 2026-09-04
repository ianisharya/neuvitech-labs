# 09 - Commerce, Subscriptions, Access Tiers and Entitlements

This document replaces the earlier commerce design. Two things changed the shape of it. First, the business model moved from one-time purchases with optional EMI to a three-tier model built around subscriptions. Second, EMI was removed entirely. What did not change is the principle everything here still rests on: paying for something and being allowed to use it are two separate facts, and the second one is the only one the rest of the platform ever checks.

## 1. The three tiers, in plain terms

Every piece of paid or free access on the platform falls into one of three tiers. A learner can hold entitlements from all three at once, and the systems that deliver learning never need to know which tier granted access. They ask one question: does this person hold a valid entitlement to this thing right now.

**Tier 1 is free, and free means free.** Free courses and free videos cost nothing, require no subscription, and once a learner earns a free certification it stays earned. There is no clock on a free credential. This tier is the top of the funnel and the thing neither of the obvious competitors offers, so it is treated as a real product and not a teaser. The one thing that keeps it honest is that free certifications still require passing a real, gated assessment. A certificate nobody can fail is worth nothing, so the free tier is generous with access and strict with assessment.

**Tier 2 is subscription, billed monthly or annually.** This is ongoing access to the library: most Programs, Tracks, Specializations, live cohorts, and recorded lectures. The learner pays on a recurring cycle and keeps access as long as the subscription is active. When a subscription lapses, access suspends. It does not delete anything. Progress, notes, submissions, earned free certificates, and karma all survive a lapse untouched, and resuming the subscription resumes access exactly where the learner left off. This rule is not a nicety. A learner whose card expired in March should not lose a year of work, and a platform that punishes a billing failure by destroying progress does not deserve the resubscribe.

**Tier 3 is a one-time purchase with a long but finite access window.** Some things are bought outright rather than rented: flagship programs, premium certifications, and eventually academically co-branded credentials. The access window is the published duration of the thing plus one year, calculated once at the moment of purchase and stored as a fixed end date. A six month program bought today grants access until eighteen months from today, and that date never moves. This is deliberately not "forever." A fixed end date is honest to store, cheaper to sustain because the platform is not serving video for a purchase made a decade ago, and still a strong offer because eighteen months of owned access comfortably survives any subscription lapse. The published duration is what counts, not how fast or slow the individual learner actually moves, so the end date is knowable and fixed on day one and cannot drift or become a support dispute two years later.

## 2. Why three tiers is not three systems

The temptation with a model like this is to build three access systems: one for free enrolment, one for subscription checks, one for purchases. That would be a mistake, and the platform was built from the start to avoid it.

Access has always been checked against an **entitlement**, never against a payment record and never against a subscription table. An entitlement is a single grant that says this user may access this thing, from this date, until this date, granted for this reason. The reason is recorded in a field called source, and the tiers are simply different sources:

```
FREE_ENROLMENT Tier 1, no end date, never expires
SUBSCRIPTION Tier 2, end date tracks the billing period plus a grace window
PAYMENT Tier 3, end date fixed at purchase as duration plus one year
SCHOLARSHIP a granted equivalent of Tier 2 or 3, no money involved
ADMIN_GRANT staff granting access for support or goodwill
CORPORATE_AGREEMENT an organisation sponsoring seats, covered in doc 39
```

Every downstream system, the LMS, the certificate engine, the portfolio, the video player, asks the entitlement service one question and gets one answer. It never learns or cares which source granted the entitlement. This is what makes three tiers cost roughly the same to maintain as one, and it is why adding a fourth tier later, if it ever happens, would be a new source value and not a new system.

## 3. The chain, from catalogue to access

```
CatalogItem
 -> Product what is sold, and how: subscription plan, one-time item, or free
 -> Price an amount and a currency, or a billing interval for subscriptions
 -> Offer a time-boxed discount
 -> Coupon a code the learner can apply
 -> Checkout
 -> Order or Subscription, for recurring
 -> Payment verified against the provider
 -> Entitlement the grant that actually matters
 -> Enrolment the learner is now in the thing
```

A Product is deliberately separate from a CatalogItem. One catalogue item can be sold several ways at once. The same Specialization might be included in a Tier 2 subscription, available as a Tier 3 one-time purchase for someone who wants to own it past their subscription, and partly visible through a free introductory course. Three products, one catalogue item, and the commerce layer never branches on what kind of catalogue item it is. It reads the product's policy and proceeds.

## 4. Subscriptions in detail

A subscription is the primary revenue model, so it gets the most careful treatment.

The lifecycle a subscription moves through:

```
TRIALING optional free trial period
ACTIVE paid and current
PAST_DUE a renewal payment failed, retries in progress
GRACE retries exhausted, a short window of continued access as a courtesy
CANCELED the learner or an admin ended it, access runs to period end
EXPIRED access has ended
PAUSED deliberately suspended, resumable
```

Billing is monthly or annual, chosen by the learner. Annual is offered at a discount to the monthly-times-twelve price, because a year of committed revenue is worth more than the discount costs, and because an annual learner is a more consistent learner, which is the kind the whole platform is built to reward.

Renewals are attempted automatically. When one fails, the subscription moves to PAST_DUE and the provider retries on a schedule with increasing gaps between attempts. If every retry fails, the subscription moves to GRACE, which grants a short additional window of access rather than cutting the learner off the instant a card expires. Only after grace ends does access actually suspend. Throughout all of this, nothing the learner has done is deleted. Suspension hides access. It never destroys progress.

An entitlement derived from a subscription carries an end date set to the current period end plus the grace window. Each successful renewal pushes that date forward. This means the entitlement check stays simple: is today before the entitlement's end date. The billing machinery updates the date, and the access check never has to understand billing.

Upgrades, downgrades, and switching between monthly and annual are handled with proration, so a learner who upgrades mid-cycle pays the fair difference rather than a full new charge, and nobody is billed twice for overlapping time.

## 5. One-time purchases in detail, Tier 3

A one-time purchase creates an Order, exactly like any other purchase, and on verified payment it creates an entitlement with source PAYMENT and a fixed end date.

The end date calculation is the whole point of this tier, so it is worth being exact. At the moment of purchase, the system reads the published duration of the catalogue item, adds one year, and writes the resulting date to the entitlement. A program published as six months yields eighteen months of access. A program published as three months yields fifteen. The learner's actual pace is irrelevant to this calculation. The date is written once and never recomputed, which means it can be shown honestly on the receipt, cannot drift, and cannot be gamed by a learner who deliberately never marks the course complete.

If the same catalogue item is later also offered on subscription, a learner might hold both a Tier 3 entitlement and a Tier 2 one at different times. The entitlement service simply honours whichever grant is currently valid. Owning something outright and also subscribing are not in conflict; the learner just has access, and the reason is recorded for audit but invisible to delivery.

## 6. Free access in detail, Tier 1

Free enrolment runs through the identical path as a paid one, and this is intentional. A free course still creates a Product priced at zero, still creates an Order with a total of zero, still creates an Entitlement, still creates an Enrolment. The only difference is that the payment step is skipped by a server-side policy that reads the product's price of zero. It is skipped, not faked. There is no fake payment record and no special free-only code path that could drift out of sync with the real one.

This matters for a concrete security reason. Because free and paid run the same path, a paid product can never be slipped through the free path, because the price is resolved on the server from the product itself and never accepted from the learner's browser. The free tier is generous, but it cannot be used as a side door into paid content.

Free certifications carry a real assessment with a real pass mark. Completion requires genuine progress plus a passing score, both defined in the certificate policy. The free tier's honesty is the entire reason it works as a funnel: a free credential from the platform means something because it could have been failed.

## 7. Karma as a second currency

The platform has a second kind of value beyond money: karma. Karma is earned by learning and can be spent on goodies. It is described in full in doc 40, but it touches commerce here in one clean way. A goodie is a Product priced in karma instead of currency. Redeeming karma for a goodie runs through the same Order and fulfilment path as any purchase, with karma as the payment method and a karma-balance check standing in for a payment authorisation. This means the goodies store is not a second commerce system. It is the commerce system already built, pointed at a different currency and a physical fulfilment step.

## 8. What was removed, and why it is stated plainly

EMI, instalment financing, is gone. The earlier plan carried it as an unverified possibility, always marked as something that could not be promised until a real merchant account confirmed it was available. The business decision is now to not offer it at all. Subscriptions serve the same underlying need, which is spreading cost over time, and they do it without depending on a financing product whose availability, fees, and refund behaviour were never confirmed. Removing EMI removes a whole category of unverified claims and a whole set of edge cases around part-paid financing and refunds, and it replaces them with a monthly subscription that any learner can start and stop cleanly.

## 9. The rules that do not bend

These held in the earlier design and still hold. They are the difference between a commerce system that can be trusted with money and one that cannot.

The frontend never sends a price or an amount. It sends a product identifier, a quantity, and optionally a coupon code. The server resolves the price, the discount, the tax, and the total. A request that arrives carrying an amount is rejected and logged as a security event, not quietly honoured.

Coupons are re-validated at the moment an order is placed, not only when they are displayed, because time passes between the two and coupons expire and run out. Redemption is atomic, using a row lock and per-user limits, so a coupon capped at a hundred uses is redeemed exactly a hundred times even under a rush.

Entitlement is granted only after payment is verified, and verification means the provider confirmed it, the confirmation signature checked out against the raw bytes we received, the provider's event identifier has not been seen before, and the amount and currency match the order. A success message in the learner's browser grants nothing. It only redirects. The grant happens server-side on verified confirmation.

Provider webhooks are idempotent. The same confirmation arriving twice, which providers do routinely, is detected by a unique constraint on the event identifier and treated as a no-op. Out-of-order arrival is handled by state checks rather than by assuming order.

Reconciliation runs on a schedule. Any order stuck waiting for payment past a reasonable window is checked directly against the provider, because webhooks are occasionally lost and money must never be. A learner who paid and never got access, because a webhook vanished, is found and fixed by reconciliation rather than by a support ticket.

Money is stored as integer minor units with an explicit currency, never as a floating point number, everywhere, including the frontend. Refunds revoke the matching entitlement through the domain, with an audit trail, and cascade to revoke any credential that was issued solely on the strength of that entitlement.

## 10. Payment provider

Razorpay is the provider, chosen for an India-first learner base with UPI, cards, netbanking, and subscription support with rupee settlement. It sits behind a provider protocol, so a second provider can be added later as another implementation of the same interface without touching checkout. The move from test credentials to live credentials is a change of encrypted settings in the database, not a code change and not a deploy, which is what lets development proceed on sandbox now and go live the moment the merchant account clears, covered in doc 05 and doc 27.

## 11. The subscription and access schema

```
product
 id, catalog_item_id, kind, is_active, tax_category
 kind is one of SUBSCRIPTION_PLAN, ONE_TIME, FREE, GOODIE

price
 id, product_id, currency, amount_minor
 interval null for one-time and free, MONTH or YEAR for subscriptions
 trial_days, is_default

subscription
 id, user_id, product_id, price_id, state, interval
 current_period_start, current_period_end
 cancel_at_period_end, grace_until
 provider_subscription_id

order
 id, order_number, user_id, state, currency
 subtotal_minor, discount_minor, tax_minor, total_minor
 payment_method CARD, UPI, NETBANKING, KARMA, FREE
 placed_at

entitlement
 id, user_id, catalog_item_id, product_id
 source FREE_ENROLMENT, SUBSCRIPTION, PAYMENT, SCHOLARSHIP, ADMIN_GRANT, CORPORATE_AGREEMENT
 granted_by, granted_at
 valid_from, valid_until valid_until null only for FREE_ENROLMENT
 revoked_at, revocation_reason

enrolment
 id, user_id, catalog_item_id, catalog_item_version_id
 entitlement_id, state, enrolled_at, completed_at
```

The valid_until field carries the whole tier model. It is null only for free enrolment, which never expires. For subscriptions it tracks the billing period plus grace and moves forward on renewal. For one-time purchases it is fixed at purchase as duration plus one year and never moves. One field, read the same way by every access check, is the entire mechanism.

## 12. The test matrix

Every one of these is an automated test, because this is the part of the system that touches money and access, and the failures here are the expensive ones.

Subscription creation, monthly and annual. Successful renewal moving the period forward. A failed renewal moving to past due, retrying, moving to grace, and finally suspending, with progress confirmed intact at every step. Resubscription after a lapse restoring access to exactly where the learner was. Upgrade and downgrade with correct proration. Switching monthly to annual and back. Cancellation running access to period end rather than cutting it immediately.

One-time purchase writing an end date of exactly published duration plus one year. That date confirmed not to move when the course is later edited, when the learner completes early, and when the learner never completes at all.

Free enrolment creating a zero total order and a non-expiring entitlement. A paid product rejected when someone attempts to acquire it through the free path. A request carrying a client-supplied price rejected and logged.

A duplicate payment webhook treated as a no-op. A webhook with a bad signature rejected and no entitlement granted. An order stranded by a lost webhook recovered by reconciliation. A refund revoking the entitlement and cascading to revoke a certificate issued under it.

Karma redemption for a goodie debiting the balance atomically, and a redemption attempted with insufficient karma refused cleanly.

Two people racing to redeem the last available seat of a capacity-limited cohort, where exactly one succeeds.
