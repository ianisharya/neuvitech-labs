# 37 — Onboarding Guide (New Engineer)

**Read this first.** By the end you will understand what NeuViTech Labs is, how it is built, why the decisions were made, and how to make your first change — without anyone explaining it to you.

Budget: **3 hours reading, 2 hours setup, 1 hour first change.**

---

## Hour 1 — What we are building

**Read:** `02-product-vision-and-strategy.md` (15 min) · `06-product-catalog-architecture.md` (30 min) · `05-configuration-architecture.md` (15 min)

**The five things that matter most:**

1. **EdTech first.** This is a technology education company that happens to have a solutions division — never the reverse. It is enforced structurally: EdTech owns the root URL namespace, ITES lives under `/solutions` and never appears above EdTech in navigation.

2. **The catalog is data, not code.** Programs, Tracks, Specializations, Masterclasses, Free Certification Courses, Certificates and Brochures are first-class capabilities defined by rows in `catalog_item_type`. **Adding a new product type is an INSERT, not a migration and a rewrite.** If you find yourself writing `if kind == "masterclass"`, stop — CI will fail your build, and correctly.

3. **Nothing is hard-coded.** Nine environment variables exist. Everything else — branding, navigation, feature flags, pricing rules, email templates, page sections, SEO defaults, even third-party API keys — lives in the database. If a non-engineer might want it different, it is data.

4. **Payment never equals access.** An `Entitlement` is a separate, audited grant. Purchases, scholarships, admin grants and corporate seats all converge on one access path, which is what makes revocation uniform.

5. **Default deny.** Every endpoint declares a permission or is explicitly `@public`. An endpoint declaring neither **fails at startup**. You cannot ship an accidentally open route.

---

## Hour 2 — How it is built

**Read:** `03-final-technology-decisions.md` (20 min) · `04-system-architecture.md` (20 min) · `08-security-architecture.md` (20 min)

**The stack:** Python 3.12 · FastAPI · SQLAlchemy 2.0 async · Alembic · PostgreSQL 16 + pgvector · Redis 7 · ARQ · Next.js 15 · TypeScript · Tailwind · shadcn/ui · Docker · GitHub Actions · OpenTelemetry → Grafana.

**The one boundary:** Next.js renders and holds **zero business logic**. FastAPI is the system of record. If a rule can be enforced in the browser it must *also* be enforced in the API, and the API is authoritative.

**Module boundaries are enforced by CI.** Each module under `modules/` owns its tables and exposes a service layer. Importing another module's ORM models or querying its tables directly fails the build. This is what makes the monolith modular rather than merely co-located.

**Why a monolith:** the core aggregates (`catalog → product → order → entitlement → enrolment`) are transactionally coupled. Splitting them would replace local ACID transactions with distributed sagas for no benefit. Microservices solve an organisational problem we do not have. See ADR-0001.

---

## Hour 3 — How we work

**Read:** `16-collaboration-model.md` (15 min) · `17-engineering-workflow.md` (15 min) · `18-engineering-standards.md` (20 min) · `36-troubleshooting-guide.md` (10 min, skim)

**The workflow:** Understand → Design → Implement → Analyse → Experiment → Test → Review → Modify → Integrate → Validate → Deploy → Observe → Harden → Release.

**Key conventions:**
- Branch `feature/NVL-123-short-slug` · commit `feat(catalog): NVL-123 description`
- One branch per ticket per person
- Every PR reviewed by someone from the other track
- Tables singular, `snake_case` · UUIDv7 keys · money as `amount_minor` + `currency`, never float · time as `TIMESTAMPTZ` UTC via the injectable clock
- Never return an ORM model from an endpoint — always a response schema
- Every relationship declares its loading strategy; the base model sets `lazy="raise"` so a forgotten `selectinload` fails in tests rather than production

---

## Hours 4–5 — Set up your machine

**Follow:** `23-environment-setup-runbook.md`

The short version:
1. Install Docker Desktop and VS Code. (Windows: install WSL2 first; clone **inside** WSL2, never `/mnt/c/`.)
2. Clone the repository.
3. Open in VS Code → **Reopen in Container**. First build 15–25 minutes.
4. `cp .env.example .env`
5. `make up` → `make migrate` → `make seed`
6. Verify: `localhost:3000` (app), `localhost:8000/api/v1/docs` (API), `localhost:8025` (mail), `localhost:3001` (Grafana)
7. `make check` — lint, typecheck, tests. Green means you match CI.

**If anything fails, `36-troubleshooting-guide.md` covers the failures we have actually hit.**

---

## Hour 6 — Your first change

A deliberately small, safe task that touches the whole stack:

**Add a new FAQ to the Program detail page.**

1. Find where FAQs come from — `faq` table, not a component. (This is the "nothing is hard-coded" principle in practice.)
2. Add a row through the admin console at `/admin/content/faq`.
3. Reload a program page. It appears. **No deploy, no code change.**
4. Now find the API endpoint that serves it: `modules/catalog/router.py`.
5. Read the service and repository beneath it. Notice ownership filtering happens *inside* the query, never after.
6. Run `make test-api -k faq` and read the tests.

**What you should have learned:** content is data · the layers are router → service → repository → database · authorization is a dependency, not an `if` statement · tests exist for everything.

---

## Where to look for things

| Question | Document |
|---|---|
| Why is it built this way? | `adr/` — every decision with alternatives rejected |
| How does the catalog work? | `06-product-catalog-architecture.md` |
| Where do settings live? | `05-configuration-architecture.md` |
| How does money become access? | `09-commerce-and-entitlements.md` |
| What are the coding conventions? | `18-engineering-standards.md` |
| Something is broken locally | `36-troubleshooting-guide.md` |
| Production is broken | `33-runbooks-and-operations.md` |
| What does this term mean? | `35-glossary.md` |
| What are we building next? | `25-master-roadmap.md` · `27-jira-backlog.md` |
| How do I deploy? | `13-infrastructure-and-deployment.md` · `21-cicd-pipeline.md` |

---

## The rules that will trip you up

1. **Never `if kind == "..."` in service code.** CI fails it. Use the type registry.
2. **Never `os.getenv` outside `core/config.py`.** CI fails it. Use settings.
3. **Never a raw hex colour in a component.** ESLint fails it. Use tokens.
4. **Never return an ORM model from an endpoint.** It leaks columns you did not mean to expose.
5. **Never trust a client-supplied price, user id or entitlement source.** All three are resolved server-side; a request containing a price is rejected and logged as a security event.
6. **Never mark a ticket done because the code exists.** `IMPLEMENTED` is not `VERIFIED`.
7. **Every bug fix ships with a regression test that failed before the fix.** No exceptions — it is how you know the fix addressed the real cause.

---

## Culture

- **Challenge decisions.** ADRs exist to be argued with. Bring evidence and we change them.
- **Say when you do not understand.** The failure mode on a small team is everyone nodding at code nobody can maintain.
- **Report reality.** If an estimate was wrong, say so. A plan nobody believes is worse than no plan.
- **Blameless post-incidents.** The target is the system, never the person.
- **Verify, do not assume.** "It should work" is not a status.
