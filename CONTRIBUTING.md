# Contributing

## Before your first change

Read [`docs/37-onboarding-guide.md`](docs/37-onboarding-guide.md), then [`docs/18-engineering-standards.md`](docs/18-engineering-standards.md). Roughly three hours. It is faster than learning these rules through failed reviews.

## The loop

```
Understand → Design → Implement → Analyse → Experiment → Test
  → Review → Modify → Integrate → Validate → Deploy → Observe → Harden → Release
```

Expect at least one correction round on most changes. That is normal and it is budgeted. A change needing no correction is a pleasant surprise, not the baseline.

## Branches

```
feature/NVL-123-catalog-type-registry
fix/NVL-145-coupon-race-condition
chore/NVL-160-bump-dependencies
hotfix/NVL-201-webhook-signature
```

One branch per ticket per person. Never two people on one branch. Pull frequently — a branch alive three days across two people is a merge conflict with a countdown timer.

Incomplete work merges to `main` **disabled behind a feature flag** rather than living on a long branch. That is what makes trunk-based development safe here.

## Commits

```
type(scope): NVL-123 imperative description
```

Types: `feat` `fix` `refactor` `test` `docs` `chore` `ci` `security` `perf` `build`

One logical change per commit. Present-tense imperative. The body explains **why**, not what — the diff already shows what.

```
feat(commerce): NVL-214 verify webhook signatures on raw request bytes

The framework re-serialises JSON before handing it to the handler, which
changes byte order and invalidates the provider's signature. Read the raw
body before parsing.
```

Use `git add -p`, not `git add .`. It is the last checkpoint before a stray `console.log` or a hardcoded token enters history permanently.

## Pull requests

Run `make check` first — it runs the same gates as CI, so a green run means a green pipeline.

Every PR needs an approval from **the other track**. Track A reviews Track B and vice versa, so nothing reaches `main` unseen.

### Reviewing

**The reviewer's job is to understand the change, not to approve it.**

In order: does it do what the ticket says · are the acceptance criteria met · is authorization enforced · is input validated · are failure paths handled · are the tests meaningful or do they merely execute the code · will the other person understand this in three months.

**"LGTM" without reading is worse than no review** — it manufactures false confidence. For payments, authorization, entitlements and certificates, both people read the code.

Ask Copilot to review the diff too. It catches different things than you do. It is a supplement, never a substitute.

## Rules that fail the build

| Rule | Why |
|---|---|
| No `os.getenv` outside `core/config.py` | Nine bootstrap variables; everything else is database-driven |
| No `if item.kind == "..."` | The ninth product type must not mean touching forty files |
| No `float` for money | `0.1 + 0.2 != 0.3`, and the error compounds through discount and tax |
| No `HTTPException` outside a router | Services must not know they were called over HTTP |
| No cross-module `models`/`repository` imports | Defeats the boundary, blocks future extraction |
| Every route declares a permission or `@public` | Default deny — you cannot ship an accidentally open route |
| No raw hex colours in components | Colours are database-backed tokens |
| No `outline: none` | Removes the keyboard focus indicator |

Run `make guardrails` to check locally. Each finding explains why the rule exists.

## Definition of Done

A ticket is not done because code exists.

Acceptance criteria **demonstrated**, not asserted · tests including failure paths, passing in CI · authorization enforced and ownership filtered inside the query · migration reversible and tested both directions · logs and metrics emitted · alert plus runbook if it can fail in production · reviewed by the other track · **run and manually verified**.

Full checklist: [`docs/34-definition-of-ready-and-done.md`](docs/34-definition-of-ready-and-done.md).

## Honesty

`IMPLEMENTED` means code exists. `VERIFIED` means someone watched it work. Use the weaker word when you have not seen it run.

Never claim a Jira issue, GitHub setting, cloud resource or third-party integration was configured unless it actually happened. Say `BLOCKED` and state what is needed.

Every bug fix ships with a regression test that failed before the fix. No exceptions — it is how you know the fix addressed the real cause rather than a symptom.
