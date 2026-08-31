# 00 — START HERE

**NeuViTech Labs — Engineering & Delivery Plan**
**Domain:** neuvitechlabs.com · **Repository:** github.com/ianisharya/neuvitech-labs
**Status:** PLANNED. No production code written. No external system modified.
**Version:** 1.0 — Final. This is the single source of truth.

---

## What this pack is

The complete engineering plan for building NeuViTech Labs from an empty repository to a production platform. It is written so that **someone who joins the team on day 200 can read it and understand the system, the decisions, and the plan without anyone explaining it to them.**

It contains one architecture, one technology stack, one workflow. There are no alternatives to choose from. Decisions are recorded in `adr/` with the reasoning and the rejected options, so they can be challenged with evidence — but the default is that we execute what is written here.

---

## The project in one paragraph

The repository is **empty** (verified — zero commits). We are building an EdTech-first technology education platform: a first-class product catalog (Programs, Tracks, Specializations, Masterclasses, Free Certification Courses, Certificates, Brochures), a real LMS, real commerce with payments and entitlements, a community and careers layer, and a guardrailed agentic-AI layer. **Everything is database-driven — including configuration, navigation, branding, feature flags and product definitions.** Nothing that a non-engineer might need to change is hard-coded. The stack is Python 3.12 + FastAPI + PostgreSQL 16 + Redis + Next.js 15, developed inside a **VS Code Dev Container** so the MacBook and the Windows machine are byte-identical. **20 sprints of 14 days**, starting **Monday 31 August 2026**, production launch **14 March 2027**, full scope **6 June 2027**.

---

## Document index

Numbered for reading order. Every document is self-contained enough to be read on its own.

### Part 1 — Context and decisions
| # | Document | What it answers |
|---|---|---|
| 01 | `01-repository-and-environment-audit.md` | What exists today? (Nothing — here is the evidence) |
| 02 | `02-product-vision-and-strategy.md` | What are we building and for whom? |
| 03 | `03-final-technology-decisions.md` | **Exactly which technologies, and why. No alternatives.** |

### Part 2 — Architecture
| # | Document | What it answers |
|---|---|---|
| 04 | `04-system-architecture.md` | How do the pieces fit together? |
| 05 | `05-configuration-architecture.md` | **How is *everything* database-driven?** |
| 06 | `06-product-catalog-architecture.md` | **The load-bearing design.** How do we add product types without a rewrite? |
| 07 | `07-data-architecture.md` | What is the schema and why? |
| 08 | `08-security-architecture.md` | How is it secured, end to end? |
| 09 | `09-commerce-and-entitlements.md` | How does money become access? |
| 10 | `10-lms-architecture.md` | How does learning actually work? |
| 11 | `11-design-system-and-uiux.md` | **How do we become best-in-class on UI/UX?** |
| 12 | `12-agentic-ai-architecture.md` | How is AI added safely? |
| 13 | `13-infrastructure-and-deployment.md` | How does it run in production? |
| 14 | `14-observability-architecture.md` | How do we know it is healthy? |
| 15 | `15-end-to-end-workflows.md` | What happens, step by step, in every major flow? |

### Part 3 — How we work
| # | Document | What it answers |
|---|---|---|
| 16 | `16-collaboration-model.md` | **Who does what — AI, me, teammate** |
| 17 | `17-engineering-workflow.md` | What is the lifecycle of a feature? |
| 18 | `18-engineering-standards.md` | How do we write code here? |
| 19 | `19-git-and-version-control.md` | Branching, commits, PRs, releases |
| 20 | `20-testing-strategy.md` | What do we test, at which level, and when? |
| 21 | `21-cicd-pipeline.md` | How does code reach production? |
| 22 | `22-software-installation-matrix.md` | **What to install, and at which point in the workflow** |
| 23 | `23-environment-setup-runbook.md` | Clean machine → working environment, both OSes |

### Part 4 — The plan
| # | Document | What it answers |
|---|---|---|
| 24 | `24-capacity-and-estimation-model.md` | **How every estimate was derived** |
| 25 | `25-master-roadmap.md` | 20 sprints, 5 phases, milestones |
| 26 | `26-jira-structure.md` | Project config, issue types, workflow, fields |
| 27 | `27-jira-backlog.md` | **Epic → Story → Task → Subtask, with all fields** |
| 28 | `28-sprint-01-plan.md` | Sprint 1, session by session |
| 29 | `29-day-by-day-schedule.md` | **Every session, hours, owner, tasks** |
| 30 | `30-critical-path.md` | What determines the launch date |
| 31 | `31-risk-register.md` | What can go wrong and what we do about it |

### Part 5 — Operations and completion
| # | Document | What it answers |
|---|---|---|
| 32 | `32-production-readiness-checklist.md` | What must be true before we go live |
| 33 | `33-runbooks-and-operations.md` | What to do at 2am when something breaks |
| 34 | `34-definition-of-ready-and-done.md` | When is work actually finished? |
| 35 | `35-glossary.md` | Every term explained |
| 36 | `36-troubleshooting-guide.md` | The failures you will actually hit |
| 37 | `37-onboarding-guide.md` | **New joiner: read this first** |

### Decisions
`adr/` — ADR-0001 to ADR-0014, each recording context, decision, alternatives rejected, consequences, trade-offs, cost, security, scalability, migration path and revisit trigger.

### Data files
| File | Purpose |
|---|---|
| `neuvitech-labs-plan.xlsx` | 280-day schedule, capacity model, sprint summary, Sprint 1 detail, risk register |
| `jira-import-epics.csv` | All epics |
| `jira-import-sprint-01.csv` | Sprint 1 stories, tasks and subtasks with full fields |

---

## Reading paths

**Before Day 1 (both of you, ≈60 min):** 03 → 16 → 22 → 24 → 28

**New engineer joining later (≈3 hours):** 37 → 02 → 03 → 04 → 05 → 06 → 16 → 18 → 23

**"I need to change something in the catalog":** 06 → 05 → 27

**"Production is broken":** 33 → 14 → 36

---

## Non-negotiable principles

These govern every decision in this pack. If a future change violates one, it needs an ADR.

1. **Nothing is hard-coded.** Configuration, navigation, branding, feature flags, pricing rules, email templates, product definitions and page metadata all come from the database. Only bootstrap secrets live in environment variables.
2. **One environment definition.** The Dev Container is the environment. Mac and Windows are identical after "Reopen in Container".
3. **The catalog is data, not code.** A new product type is a row, not a migration and a rewrite.
4. **Payment never equals access.** Entitlements are a separate, auditable grant.
5. **Default deny.** Every endpoint declares a permission or is explicitly public; one that declares neither fails at startup.
6. **Observability is part of the product**, not added at the end.
7. **Nothing is claimed without evidence.** `IMPLEMENTED` is not `VERIFIED`.
8. **Humans are engineers here**, not a review queue. Analysis, experimentation, operations and production ownership are real work with real time allocated.

---

## Verified facts

- Repository `ianisharya/neuvitech-labs`: **exists, public, zero commits, zero branches.** `git ls-remote` returned no refs.
- Jira `neuvitech-labs.atlassian.net`: **not reachable from my environment.** Nothing configured, nothing created. CSV imports provided.
- **31 August 2026 is a Monday.** Sprints run Mon→Sun, giving identical capacity every sprint.
- **Docker is absent from my authoring environment.** Container work is `IMPLEMENTED` until your machine or CI proves it.

## What I need at the start of Day 1

| Question | Needed for |
|---|---|
| Who holds **GitHub repository admin**? | Branch protection, Sprint 1 |
| Jira: Atlassian MCP connector, or CSV import? | Whether I can create issues |
| Licence: proprietary or open source? | First commit |
| Confirm `neuvitechlabs.com` is registered, or shall it be? | Sprint 5 SEO, Sprint 12 deploy |

Everything else I have decided.
