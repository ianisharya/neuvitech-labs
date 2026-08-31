# 09 — Commerce, Payments, Subscriptions & Entitlements

## 1. The chain

```
CatalogItem → Product → Price → Offer → Coupon → Checkout → Order → Payment
                                                                     ↓
                                          Entitlement → Enrolment → Access
```

**`Product` is deliberately separate from `CatalogItem`.** One catalog item may be sold several ways (full Program, one Specialization, an early-bird cohort seat, a bundle) and one product may bundle several catalog items. Merging them forces price, currency and coupon fields into the catalog and makes bundles impossible without a rewrite.

**Commerce never branches on `kind`.** It resolves `commerce_policy` from the type registry. Adding a sellable product type requires zero commerce changes.

## 2. Non-negotiable rules

1. **The frontend never sends a price.** It sends `product_id`, `quantity`, `coupon_code`. The server resolves price, eligibility, discount, tax and total. A request containing an amount is **rejected and logged as a security event** — not ignored.
2. **Coupons are re-validated at order placement**, not only at cart display. Time passes between the two, and coupons expire and exhaust.
3. **Redemption is atomic.** `SELECT … FOR UPDATE` on the coupon row plus partial unique indexes for per-user caps. A coupon capped at 100 uses must be redeemable exactly 100 times under concurrency — this gets an explicit concurrent test.
4. **Entitlement is granted only after verified payment.** Verification means: webhook received **and** signature verified against raw bytes **and** provider event id not previously processed **and** amount and currency match the order. A client-side "success" callback grants nothing; it only redirects.
5. **Webhooks are idempotent.** `provider_event_id` carries a UNIQUE constraint. Duplicate delivery is a no-op returning 200. Out-of-order delivery is handled by state-machine guards, never by assuming ordering.
6. **Reconciliation runs hourly.** Any order `PENDING_PAYMENT` older than N minutes is checked directly against the provider API. **Webhooks get lost; money must not.**
7. **Money is integer minor units with explicit currency.** No floats anywhere, including the frontend.
8. **Refund ⇒ entitlement revocation** through the domain, with audit, cascading to any credential issued solely under that entitlement.

## 3. Schema

```
product(id, sku, catalog_item_id?, bundle_id?, is_active, tax_category)
price(id, product_id, currency, amount_minor, interval NULL|MONTH|QUARTER|YEAR,
      trial_days, tax_behavior, active_from, active_until, is_default)
offer(id, name, product_scope JSONB, discount_type, discount_value, starts_at, ends_at, priority)
coupon(id, code UNIQUE CITEXT, discount_type, discount_value, currency?,
       max_discount_minor?, min_purchase_minor?, starts_at, ends_at,
       max_redemptions, max_per_user, first_purchase_only, scope JSONB, user_scope JSONB)
coupon_redemption(id, coupon_id, user_id, order_id, discount_applied_minor, redeemed_at)
       UNIQUE(coupon_id, order_id)
checkout_session(id, user_id, state, currency, items JSONB, coupon_id?,
       computed_totals JSONB, expires_at, idempotency_key)
order(id, order_number, user_id, state, currency, subtotal_minor, discount_minor,
      tax_minor, total_minor, billing_address JSONB, placed_at)
order_line(id, order_id, product_id, catalog_item_id, catalog_item_version_id,
      quantity, unit_amount_minor, discount_minor, tax_minor, total_minor)
payment(id, order_id, provider, provider_payment_id, state, amount_minor, currency,
      method, captured_at, failure_code)
payment_webhook_event(id, provider, provider_event_id UNIQUE, event_type,
      payload_digest, signature_verified, processed_at, processing_state)
refund(id, payment_id, amount_minor, reason, state, provider_refund_id, requested_by)
subscription(id, user_id, product_id, price_id, state, current_period_start,
      current_period_end, cancel_at_period_end, grace_until, provider_subscription_id)
entitlement(id, user_id, catalog_item_id?, product_id?, source, source_ref_id,
      granted_by, granted_at, valid_from, valid_until?, revoked_at?, revocation_reason?)
enrolment(id, user_id, catalog_item_id, catalog_item_version_id, cohort_id?,
      entitlement_id, state, enrolled_at, completed_at?, source)
invoice(id, order_id, number, issued_at, pdf_media_id, tax_breakdown JSONB)
idempotency_key(key PK, user_id, endpoint, request_digest, response_snapshot, state, expires_at)
```

## 4. Entitlements — payment ≠ access

`source ∈ { PAYMENT, SUBSCRIPTION, FREE_ENROLMENT, SCHOLARSHIP, PROMOTION, ADMIN_GRANT, SUPERUSER_GRANT, CORPORATE_AGREEMENT, CAMPAIGN }`

Access checks ask the entitlement service, **never the order table**. This is what lets a purchase, a scholarship, an admin grant and a corporate seat converge on one access path, and what makes revocation uniform. Every grant records `granted_by` and writes an audit row. Superuser grants additionally record grant type, waiver reason and payment status.

**Superuser free enrolment flow:**
```
Authentication → MFA → Authorization (admin.enrolment.grant) → Grant
  → Entitlement(source=SUPERUSER_GRANT) → Enrolment → Audit
```
Normal users cannot reach this path: it is a distinct admin endpoint requiring a permission no learner role holds, and **entitlement source is server-assigned, never accepted from a request body**.

## 5. Subscriptions

States: `TRIALING → ACTIVE → PAST_DUE → GRACE → CANCELED | EXPIRED`, plus `PAUSED`.

Renewal, retry with backoff, grace period, upgrade/downgrade with proration, cancel-at-period-end. Entitlements derived from a subscription carry `valid_until = current_period_end + grace`; the renewal webhook extends it.

**A failed renewal suspends access but does not delete progress.** Learner data outlives billing state.

## 6. Payment provider — decided

**Razorpay is the primary provider. Stripe is the second adapter for international learners.** Both sit behind a `PaymentProvider` protocol.

Reasoning: the learner base is India-first (Gurugram signal, INR pricing, `neuvitechlabs.com`). Razorpay covers UPI, cards, netbanking, wallets, EMI and subscriptions with INR settlement — UPI alone is decisive for the Indian market. Stripe covers international cards and is added when international volume justifies it.

**This decision is final. It does not require your input** — but it does require you to open the merchant account (`NVL-EXT-01`, started Sprint 2, because **KYC takes two to four weeks and is the longest lead time in the programme**).

## 7. EMI and financing — verified, never assumed

The brief is explicit: do not fake EMI.

- **Status: UNVERIFIED.** I cannot confirm what is enabled on a merchant account that does not yet exist.
- A **spike in Sprint 15** verifies, against the real merchant dashboard and API docs: eligibility rules, supported issuers and tenures, geography, merchant-vs-customer fee bearing, settlement timing, refund behaviour on part-paid EMI, and interaction with coupons and subscriptions.
- **Until verified, no EMI UI renders.** No "EMI from ₹X/month" copy ships on assumption.
- The protocol exposes `supports_financing()` and `get_financing_options(amount, currency)` so a second financing provider can be added without touching checkout.

## 8. Tax, billing and invoicing

Billing address capture, tax category per product, tax computed server-side and stored per order line, **sequential gap-free invoice numbering generated inside the order transaction**, PDF invoice via worker, credit notes for refunds, multi-currency with a price row per currency (never runtime FX conversion for display prices).

**Open question for you:** is GST invoicing with GSTIN capture required at launch? It changes the invoice schema and is far cheaper to build in than to retrofit. Needed by Sprint 15.

## 9. Test matrix — every one of these is an automated test

Success · failure · cancellation · duplicate webhook · **forged webhook signature** · expired coupon · coupon over global limit · coupon over per-user limit · below minimum purchase · coupon on ineligible product · **concurrent redemption of the last available use** · subscription creation · renewal · renewal failure → grace → expiry · refund → entitlement revocation → credential revocation · order/line total consistency (property test: `sum(lines) == order.total`) · **free-product checkout bypass attempt on a paid product (must fail)** · paid masterclass purchase · program purchase · specialization purchase · idempotent double-submit of checkout.
