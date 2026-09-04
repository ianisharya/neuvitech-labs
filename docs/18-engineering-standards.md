# 18: Engineering Standards & Conventions

Where a rule is unobvious, the reason is given. A rule you do not understand is a rule you will break.

## 1. Universal
- **Explicit over implicit.** No magic, no clever metaprogramming, no dynamic attribute access.
- **Fail loudly and early.** Invalid config crashes at startup, not at the first request.
- **No dead code.** Delete it; git remembers.
- **Line length 100.** Enforced by Ruff and Prettier.
- **Comments explain *why*.** `# lock the row because two concurrent redemptions of the last use would both succeed` is useful; `# get the coupon` is noise.
- **Nothing hard-coded that belongs in settings** (doc 05).

## 2. Naming

| Thing | Convention | Example |
|---|---|---|
| Python module | `snake_case` | `catalog_item.py` |
| Python class | `PascalCase` | `CatalogItemService` |
| Database table | `snake_case`, **singular** | `catalog_item` |
| Foreign key | `<table>_id` | `catalog_item_id` |
| Boolean column | `is_` / `has_` | `is_active` |
| Timestamp column | `_at` | `created_at`, `revoked_at` |
| Money column | `_minor` + a currency column | `total_minor`, `currency` |
| Permission | `<module>.<resource>.<action>` | `catalog.program.publish` |
| Setting key | `<group>.<name>` | `brand.primary_color` |
| API route | plural, kebab-case | `/api/v1/catalog/items` |
| React component | `PascalCase` file and export | `ProgramCard.tsx` |
| Git branch | `<type>/NVL-<n>-<slug>` | `feature/NVL-123-type-registry` |

**Singular table names** because the ORM class is singular, one name in your head, not two.

## 3. Python module structure

```
modules/<context>/
├── models.py # SQLAlchemy ORM, no business logic
├── schemas.py # Pydantic, no ORM imports
├── repository.py # the ONLY place queries live
├── service.py # the ONLY place business rules live
├── router.py # validate, authorize, delegate, return
├── events.py # domain events emitted
└── exceptions.py
```

**A router does four things:** validate input, check authorization, call a service, return a response schema. **A router containing an `if` about business rules is a bug.**

**Cross-module access goes through the target's `service.py`.** Never import another module's `models.py`. `import-linter` enforces this in CI.

## 4. Python specifics
- `mypy --strict`. No `Any` except at genuine boundaries, with a comment.
- `from __future__ import annotations` at the top of every module.
- All I/O is `async`. **No blocking calls in `async def`**: no `requests`, no `time.sleep`, no sync file I/O.
- **Every relationship declares its loading strategy.** Base model sets `lazy="raise"`.
- One session per request, injected as a dependency.
- **Never raise `HTTPException` from a service.** Services must not know they are called over HTTP, or a worker cannot reuse them.
- Money is always `int` minor units plus an explicit currency. Never `float`.
- Time via the injectable clock, never `datetime.now()`.

## 5. TypeScript / React
- `strict: true`. No `any`; use `unknown` and narrow.
- **Server Components by default.** `"use client"` only for state, effects, handlers or browser APIs, pushed as far down the tree as possible.
- API types are **generated** from OpenAPI. Never hand-written.
- No inline styles. Tailwind utilities only. No raw hex colours.
- Every list `key` is a stable id, never an array index.
- Every interactive element has a visible `focus-visible` state. **Never `outline: none`.**
- Every component ships all eight states, including **empty and error**.

## 6. API design
- Versioned `/api/v1/…`. Plural nouns; verbs only for genuine actions.
- **401 vs 403:** 401 = we do not know who you are; 403 = we know, and you may not.
- **404 over 403** for resources whose existence must not be revealed.
- Every list endpoint paginated. **No unbounded queries, ever.**
- Uniform error envelope: machine-readable `code`, human `message`, `correlation_id`. **Never a stack trace.**
- **Never return an ORM model.** Always a response schema, returning ORM objects leaks columns you did not mean to expose.

## 7. Testing
- Test **behaviour**, not implementation.
- Test names describe the scenario: `test_coupon_redemption_fails_when_per_user_limit_reached`.
- Arrange / Act / Assert, visually separated.
- Factories, not fixtures with hard-coded ids. Each test independent.
- **Mock only at the system boundary.** Never mock your own database.
- **Every bug fix ships with a regression test that failed before the fix.** No exceptions, it is how you know the fix addressed the real cause.

## 8. Logging
```python
logger.info("order.placed", order_id=str(order.id), total_minor=order.total_minor,
 currency=order.currency, user_id=str(user.id))
```
Structured key/values, never f-strings. Event names `noun.verb` and **stable**: they are queried. **Never log** passwords, tokens, card data, full bodies on sensitive routes, or PII.

## 9. Git
`type(scope): NVL-123 imperative description`, types `feat` `fix` `refactor` `test` `docs` `chore` `ci` `security` `perf` `build`.
One logical change per commit. Present-tense imperative. Body explains *why*.
**Never commit:** secrets, `.env`, generated files (except lockfiles and generated types, which **are** committed so CI can detect drift).

## 10. Code review
**The reviewer's job is to understand the change, not to approve it.**
Check in order: does it do what the ticket says · are acceptance criteria met · is authorization enforced · is input validated · are failure paths handled · are the tests meaningful or do they merely execute the code · will the other person understand this in three months.

**"LGTM" without reading is worse than no review**: it manufactures false confidence. For payments, authorization, entitlements and certificates: **both people read the code.**
