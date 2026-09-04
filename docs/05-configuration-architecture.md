# 05: Configuration Architecture: Nothing Is Static

**Requirement:** *"Make sure while coding, nothing is static, it must come from the database, including the configurations."*

This document defines exactly how that is achieved, where the boundary sits, and why the boundary exists.

---

## 1. The principle

> **If a non-engineer might ever want it different, it lives in the database. If changing it requires a deploy, that is a design failure.**

Hard-coding is not only string literals in components. It includes: navigation menus, footer links, social URLs, brand colours, email copy, page titles, feature toggles, pricing rules, currency lists, tax rates, validation limits, rate-limit thresholds, cache TTLs, notification templates, homepage sections, SEO metadata, and product definitions.

All of it is data.

## 2. The one honest exception: bootstrap configuration

There is a chicken-and-egg problem: **you cannot read configuration from the database until you can connect to the database.** Pretending otherwise would produce a system that cannot start.

So configuration is layered:

```
Layer 0, BOOTSTRAP (environment variables, ~12 values)
 The minimum needed to reach the database and decrypt secrets
 ↓
Layer 1, RUNTIME SETTINGS (database, hot-reloadable)
 Everything else
 ↓
Layer 2, SCOPED OVERRIDES (database)
 Per-environment, per-locale, per-tenant-in-future overrides
```

### Layer 0: the complete list of environment variables

This list is closed. Adding to it requires an ADR.

| Variable | Why it cannot be in the database |
|---|---|
| `ENVIRONMENT` | Determines *which* settings scope to read |
| `DATABASE_URL` | Needed to reach the database |
| `REDIS_URL` | Needed before settings cache exists |
| `SECRET_KEY` | Signs sessions; must exist before any request |
| `ENCRYPTION_KEY` | Decrypts secret-typed settings *stored in* the database |
| `SUPERUSER_EMAIL` | Bootstraps the first principal |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Telemetry must work before the app is healthy |
| `LOG_LEVEL` | Needed before settings load, to debug settings failing to load |
| `APP_VERSION` | Injected by CI from the commit SHA |

**Nine variables. That is the entire static surface of the system.**

Everything else, including third-party API keys, is stored **encrypted in the database** and decrypted with `ENCRYPTION_KEY`. So rotating a payment provider key is an admin action, not a deployment.

## 3. The settings schema

```sql
setting_definition -- the CATALOG of what settings exist
 key TEXT PK -- 'brand.primary_color', 'commerce.default_currency'
 group_key TEXT -- 'brand', 'commerce', 'seo', 'features', 'email'
 label, description TEXT -- shown in the admin UI
 value_type TEXT -- string|int|bool|json|color|url|email|markdown|secret|enum
 json_schema JSONB -- validates the value
 default_value JSONB -- used when no override exists
 is_secret BOOLEAN -- encrypted at rest, redacted in logs and API
 is_public BOOLEAN -- may be sent to the browser?
 requires_restart BOOLEAN -- almost always false
 display_order INT
 permission TEXT -- who may change it

setting_value -- the actual VALUES, scoped
 id, definition_key FK
 scope_type TEXT -- GLOBAL | ENVIRONMENT | LOCALE | ORGANISATION
 scope_id TEXT -- 'production', 'en-IN', org uuid
 value JSONB -- encrypted when is_secret
 updated_by, updated_at
 UNIQUE (definition_key, scope_type, scope_id)

setting_audit -- append-only history
 definition_key, old_value_digest, new_value_digest,
 changed_by, changed_at, reason, request_id
```

**Resolution order (most specific wins):**
`ORGANISATION → LOCALE → ENVIRONMENT → GLOBAL → default_value`

**Why `setting_definition` is separate from `setting_value`:** the definition is the contract, type, validation schema, permission, whether it is a secret, whether it may reach the browser. The admin UI is *generated* from it. Adding a new setting is an INSERT plus a seed migration, and the admin screen for it appears automatically. No form is ever hand-written.

## 4. What lives in settings: the full inventory

| Group | Examples |
|---|---|
| `brand` | Name, legal name, logo asset ids, favicon, primary/accent colours, typography scale name, tagline |
| `contact` | Support email, sales email, phone, WhatsApp number, registered address |
| `social` | LinkedIn, X, YouTube, GitHub, Instagram URLs |
| `seo` | Default title template, default description, OG image, robots policy per environment, canonical host (`neuvitechlabs.com`) |
| `commerce` | Default currency, supported currencies, tax behaviour, invoice number format, order number prefix, checkout session TTL |
| `payments` | Active provider, provider keys (**secret**), webhook tolerance window, retry schedule, reconciliation interval |
| `features` | Every feature flag, see §6 |
| `email` | From name, from address, reply-to, provider credentials (**secret**), footer text |
| `notifications` | Which events notify, via which channel, with which template |
| `security` | Session TTL, absolute session cap, password policy, MFA-required roles, lockout thresholds, rate-limit tiers |
| `learning` | Default pass mark, max assessment attempts, progress-event batch size, certificate eligibility defaults |
| `media` | Storage provider, bucket, CDN host, signed-URL TTL, max upload size per type, allowed MIME types |
| `ai` | Provider, model per capability, token budgets, cost caps, prompt version pins, guardrail thresholds |
| `observability` | Sample rates, log level per module, alert thresholds |
| `ui` | Homepage section order, hero variant, cards per row, whether to show trust badges |

## 4a. Worked example: payment credentials, and why going live is never a deploy

This is the concrete case the abstract "provider keys (secret)" row above is standing in for. Written up explicitly because it is the first place a real business consequence, sandbox development now, a live merchant account later, depends on this architecture actually working as designed, not just being described as working.

```
payments.active_provider → "razorpay" (string, not secret)
payments.razorpay_key_id → "rzp_test_XXXXXXXXXXXX" (secret)
payments.razorpay_key_secret → "••••••••••••••••" (secret)
payments.razorpay_webhook_secret → "••••••••••••••••" (secret)
```

The `PaymentProvider` protocol implementation for Razorpay (`docs/09` §6) reads these four keys and nothing else. It has no branch, flag, or code path that distinguishes a Razorpay test key from a Razorpay live key, Razorpay's own key prefix (`rzp_test_…` vs `rzp_live_…`) is the only thing that differs, and that difference lives entirely inside the value, never in code that inspects it.

**Consequence:** the path from "developing against sandbox because KYC hasn't cleared yet" to "processing real payments" is four settings values changed through the admin UI. No code change, no pull request, no deploy, no restart. `is_secret = true` means the change is encrypted at rest and never appears in a diff, a log, or an API response, which is also exactly why it can't be reviewed by reading a PR, and why `docs/09` §9's test matrix includes an explicit test asserting this rather than leaving it as an assumption nobody checks.

## 5. Content and navigation are data too

Settings cover scalars. Structured content gets its own tables.

```sql
navigation_menu(id, key, label, locale, is_active) -- 'primary','footer','mobile'
navigation_item(id, menu_id, parent_id, label, href, icon,
 target, ordinal, visibility_rule JSONB, -- e.g. authenticated only
 badge_text, is_active)

page(id, slug, locale, title, status, seo JSONB, published_at)
page_section(id, page_id, section_type, ordinal, content JSONB, visibility_rule JSONB)

content_block(id, key, locale, format, body, updated_by) -- reusable copy
email_template(id, key, locale, subject, mjml_body, text_body, version, is_active)
notification_template(id, key, channel, locale, title, body, is_active)
faq(id, scope_type, scope_id, question, answer, ordinal)
testimonial(id, author, role, organisation, quote, media_id, is_published, ordinal)
```

**Consequence:** adding a footer link, reordering homepage sections, changing the hero headline, or fixing a typo in the welcome email is an **admin action taking seconds**, not a pull request and a deploy.

**The homepage is not a hard-coded React tree.** It is `page` + ordered `page_section` rows, each with a `section_type` mapped to a registered React component and a JSONB payload validated against that component's schema. Reordering sections is a drag in the admin UI.

## 6. Feature flags

```sql
feature_flag(key PK, label, description, flag_type, -- BOOLEAN|PERCENTAGE|VARIANT
 default_state, is_active, created_by)
feature_flag_rule(id, flag_key, ordinal, condition JSONB, outcome JSONB)
 -- condition: role, user id, cohort, environment, percentage bucket, date window
```

Every non-trivial feature ships behind a flag. This is what makes trunk-based development safe: incomplete work merges to `main` disabled, and is enabled when ready. Rollback becomes a toggle rather than a deploy.

Evaluation is a pure function, cached in Redis, invalidated on write. Flag state is included in analytics events so we can measure the effect of a flag.

## 7. Delivery and caching

**Backend:**
```python
settings = await get_settings() # request-scoped, cache-aside
brand_color = settings["brand.primary_color"]
if await flags.enabled("checkout.upi_enabled", user=user): ...
```
Cached in Redis under `settings:v{version}:{scope}`; a settings write bumps the version key, so invalidation is atomic and race-free. In-process memory cache with a 30-second TTL absorbs the hot path. **p99 settings lookup: under 1 ms.**

**Frontend:** the Next.js server fetches `GET /api/v1/settings/public` (only `is_public = true`) at render time and injects it into the root layout. Brand colours become CSS custom properties. **No public setting is ever bundled at build time**, because that would make it static again.

**Secrets never leave the server.** `is_secret` values are decrypted only in the API process, redacted in logs, and never included in any response.

## 8. Guardrails that keep this honest

Enforced in CI, not by discipline:

1. **`os.getenv` outside `core/config.py` fails the build.** Grep check.
2. **The Layer-0 variable list is asserted in a test.** Adding a tenth environment variable fails until the test and an ADR are updated.
3. **Hard-coded hex colours outside the token file fail ESLint.** Custom rule.
4. **Hard-coded user-facing strings in components fail lint.** Copy comes from `content_block` or i18n keys.
5. **A settings key read in code but absent from `setting_definition` fails a contract test.** No orphan settings.
6. **Settings requiring restart are asserted to be zero** outside the Layer-0 list.

## 9. Bootstrap and seeding

Settings definitions and their defaults are **seeded by Alembic migrations**, so they are versioned, reviewable and reproducible. A fresh database produces a fully working system with sane defaults, the definitions are code-managed, the values are data.

Sequence at startup:
```
Read 9 env vars → connect to Postgres → verify schema head → load setting_definitions
→ resolve values for ENVIRONMENT scope → warm Redis cache → bootstrap superuser if absent
→ start serving
```
Failure at any step exits non-zero with a message naming the step. **The application never starts partially configured.**

## 10. Why this matters beyond convenience

| Benefit | Consequence |
|---|---|
| Zero-deploy changes | Marketing edits copy, pricing, navigation and flags without engineering |
| Safer releases | Feature flags decouple deploy from release; rollback is a toggle |
| Real audit trail | Every configuration change records who, what, when and why |
| Environment parity | The same code runs everywhere; only scoped values differ |
| Genuine extensibility | New product types, page sections and settings arrive as data |
| Future multi-tenancy | `scope_type = ORGANISATION` already exists; enabling it is not a rewrite |

**Cost, stated honestly:** more indirection than reading a constant, an admin UI to build (Sprints 4 and 12), and a discipline to maintain. It is worth it, this is the difference between a platform and a website.
