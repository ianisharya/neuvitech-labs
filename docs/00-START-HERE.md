# 00: START HERE

**NeuViTech Labs, Engineering & Delivery Plan**
**Domain:** neuvitechlabs.com · **Repository:** github.com/ianisharya/neuvitech-labs
**Status:** Sprint 1, Day 3. **Milestone M1 achieved**: Dev Container verified byte-identical on both machines. Not planned-and-untouched, see below.
**Version:** 1.2, updated 2 Sep 2026 against real execution, not just the original plan.

---

## Where things actually stand

The rest of this document describes the plan as designed. This section is the honest delta between that plan and what has actually happened, so nobody mistakes "PLANNED" for the current state.

| Sprint 1 story | State |
|---|---|
| NVL-101 Host prerequisites | Anish: [done] confirmed. Manuraj: [done] confirmed, reached a working container 2 Sep |
| NVL-102 Repository governance | Bootstrapped and pushed to `main`. 102.4 (both engineers actually reading the governance files) not yet confirmed |
| NVL-103 Dev Container | [done] **VERIFIED on both machines, 2 Sep**: `make doctor` byte-identical across macOS and Windows/WSL2, all 10 tools including the Postgres client version fix |
| NVL-104 Cross-platform validation | [done] **Closed, 2 Sep.** Toolchain comparison independently confirmed byte-identical on both machines across two separate runs. The remaining sub-items in the ticket's own acceptance criteria, commit/pull round trip, clean `git status` on both, the experimentation block, findings in `docs/36`, are not separately evidenced here; closure is recorded on the strength of the Jira status alone for those |
| NVL-105 Jira configuration | Mostly done. Epic and stories created live via the Atlassian connector. **Project key rename `SCRUM`→`NVL` confirmed done**: API calls now return `NVL-` keys directly (e.g. `NVL-14`, `NVL-11`). **`BLOCKED`-status-miscategorized-as-`Done` bug confirmed resolved 3 Sep**: no status named `BLOCKED` remains; `ON HOLD`/`Cancelled` are both correctly categorised. Only sample-issue cleanup remains unconfirmed, `docs/26` §6 |
| NVL-106 CI pipeline | Not started |
| NVL-EXT-01 Razorpay KYC | **Deferred to Sprint 5, decision recorded 2 Sep.** Not a lapse, a deliberate trade-off: collapses the original ~8-week buffer against Sprint 7 to as little as zero margin in the worst case. In exchange, the codebase now has an enforced requirement (not just an assumption) that moving from sandbox to a live account is a configuration change only, `docs/05` §4a, `docs/09` §9, and `NVL-14`'s comment carry the full math |

**Two real bugs found and fixed, now confirmed resolved on both machines:** the base Dev Container image ships a Yarn apt source with no importable signing key, which aborted `apt-get update` entirely; and Debian's default `postgresql-client` resolves to 15.x against a Postgres 16 spec. Both fixed in `.devcontainer/Dockerfile`, both written up in `docs/36-troubleshooting-guide.md` §11 so nobody rediscovers them. Full session replay, command by command: `docs/38-day-01-02-command-log.md`.

**One item remains genuinely open from the original Day 1 list.** GitHub repository admin and the licence were both answered 1 Sep; domain registration was briefly reported resolved in error and has been corrected back to open, see "Still open" at the end of this document.

---

## What this pack is

The complete engineering plan for building NeuViTech Labs from an empty repository to a production platform. It is written so that **someone who joins the team on day 200 can read it and understand the system, the decisions, and the plan without anyone explaining it to them.**

It contains one architecture, one technology stack, one workflow. There are no alternatives to choose from. Decisions are recorded in `adr/` with the reasoning and the rejected options, so they can be challenged with evidence, but the default is that we execute what is written here.

---

## The project in one paragraph

We are building an EdTech-first technology education platform: a first-class product catalog (Programs, Tracks, Specializations, Masterclasses, Free Certification Courses, Certificates, Brochures), a real LMS delivering live, recorded and pre-recorded video through one player, a three-tier access model (free forever, subscription monthly or annual, and one-time purchase for a fixed window), a problem-solving platform, a memory-carrying agentic AI tutor built on open-source models, a karma and streak reward system with a goodies store, a community and careers layer, and an enterprise sponsorship and employer talent pipeline. **Everything is database-driven, including configuration, navigation, branding, feature flags and product definitions.** Nothing that a non-engineer might need to change is hard-coded. The stack is Python 3.12 with FastAPI, PostgreSQL 16, Redis and Next.js 15, developed inside a VS Code Dev Container so the MacBook and the Windows machine are byte-identical, and built to serve a baseline of five thousand concurrent learners and scale beyond. **24 sprints of 14 days**, starting Monday 31 August 2026, production launch 14 March 2027, full scope 1 August 2027. There is no EMI; subscriptions serve the spread-the-cost need instead.

---

## Document index

Numbered for reading order. Every document is self-contained enough to be read on its own.

### Part 1: Context and decisions
| # | Document | What it answers |
|---|---|---|
| 01 | `01-repository-and-environment-audit.md` | What existed at the start? (Nothing, here is the evidence) |
| 02 | `02-product-vision-and-strategy.md` | What are we building and for whom? |
| 03 | `03-final-technology-decisions.md` | **Exactly which technologies, and why. No alternatives.** |

### Part 2: Architecture
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

### Part 3: How we work
| # | Document | What it answers |
|---|---|---|
| 16 | `16-collaboration-model.md` | **Who does what, AI, me, teammate** |
| 17 | `17-engineering-workflow.md` | What is the lifecycle of a feature? |
| 18 | `18-engineering-standards.md` | How do we write code here? |
| 19 | `19-git-and-version-control.md` | Branching, commits, PRs, releases |
| 20 | `20-testing-strategy.md` | What do we test, at which level, and when? |
| 21 | `21-cicd-pipeline.md` | How does code reach production? |
| 22 | `22-software-installation-matrix.md` | **What to install, and at which point in the workflow** |
| 23 | `23-environment-setup-runbook.md` | Clean machine → working environment, both OSes |

### Part 4: The plan
| # | Document | What it answers |
|---|---|---|
| 24 | `24-capacity-and-estimation-model.md` | **How every estimate was derived** |
| 25 | `25-master-roadmap.md` | 24 sprints, 5 phases, milestones |
| 26 | `26-jira-structure.md` | Project config, issue types, workflow, fields, includes the confirmed 16-state workflow and outstanding config |
| 27 | `27-jira-backlog.md` | **Epic → Story → Task → Subtask, with all fields** |
| 28 | `28-sprint-01-plan.md` | Sprint 1, session by session |
| 29 | `29-day-by-day-schedule.md` | **Every session, hours, owner, tasks** |
| 30 | `30-critical-path.md` | What determines the launch date |
| 31 | `31-risk-register.md` | What can go wrong and what we do about it |

### Part 5: Operations and completion
| # | Document | What it answers |
|---|---|---|
| 32 | `32-production-readiness-checklist.md` | What must be true before we go live |
| 33 | `33-runbooks-and-operations.md` | What to do at 2am when something breaks |
| 34 | `34-definition-of-ready-and-done.md` | When is work actually finished? |
| 35 | `35-glossary.md` | Every term explained |
| 36 | `36-troubleshooting-guide.md` | The failures you will actually hit, now includes two real Dev Container findings |
| 37 | `37-onboarding-guide.md` | **New joiner: read this first** |
| 38 | `38-day-01-02-command-log.md` | Every command actually run to stand up the environment, by flow and by type |
| 39 | `39-enterprise-partnerships-and-interview-coaching.md` | **Corporate sponsorship, employer talent pipeline, co-branded credentials, AI interview coaching, added 3 Sep 2026 via competitive gap analysis** |
| 40 | `40-karma-streaks-and-goodies.md` | **Karma earned by verified learning, streak multiplier rewarding consistency, goodies store priced in karma** |
| 41 | `41-video-and-streaming-architecture.md` | **Live near-live broadcast, recorded and pre-recorded video, adaptive bitrate over CDN, structured recording storage, real latency budgets** |
| 42 | `42-end-to-end-master-flow.md` | **The single complete flow of the whole application, from stranger to graduate, naming the technology, logic and conditionals at every stage. Read this first.** |

### Decisions
`adr/`, ADR-0001 to ADR-0018, each recording context, decision, alternatives rejected, consequences, trade-offs, cost, security, scalability, migration path and revisit trigger.

### Data files
| File | Purpose |
|---|---|
| `neuvitech-labs-plan.xlsx` | 280-day schedule, capacity model, sprint summary, Sprint 1 detail, risk register |
| `jira-import-epics.csv` | All epics, superseded for Sprint 1 now that the real issues exist in Jira; still the reference for Sprints 2–20 |
| `jira-import-sprint-01.csv` | Sprint 1 stories, tasks and subtasks with full fields, same note |

---

## Reading paths

**Before Day 1 (both of you, ≈60 min):** 03 → 16 → 22 → 24 → 28

**New engineer joining later (about 3 hours):** 42 first, for the whole picture in one pass, then 37, 02, 03, 04, 05, 06, 16, 18, 23 for the depth behind it

**Picking this up mid-Sprint-1, right now:** 27 (what's ticketed) → 36 §11 (what's already broken and fixed) → 38 (exactly what was typed to get here)

**"I need to change something in the catalog":** 06 → 05 → 27

**"Production is broken":** 33 → 14 → 36

---

## Non-negotiable principles

These govern every decision in this pack. If a future change violates one, it needs an ADR.

1. **Nothing is hard-coded.** Configuration, navigation, branding, feature flags, pricing rules, email templates, product definitions and page metadata all come from the database. Only bootstrap secrets live in environment variables.
2. **One environment definition.** The Dev Container is the environment. Mac and Windows are identical after "Reopen in Container", **verified true on both machines, `make doctor` byte-identical, as of 2 Sep 2026.**
3. **The catalog is data, not code.** A new product type is a row, not a migration and a rewrite.
4. **Payment never equals access.** Entitlements are a separate, auditable grant.
5. **Default deny.** Every endpoint declares a permission or is explicitly public; one that declares neither fails at startup.
6. **Observability is part of the product**, not added at the end.
7. **Nothing is claimed without evidence.** `IMPLEMENTED` is not `VERIFIED`. This is why the table at the top of this document distinguishes the two.
8. **Humans are engineers here**, not a review queue. Analysis, experimentation, operations and production ownership are real work with real time allocated.

---

## Verified facts

- **Repository:** no longer empty. `NVL-102` (bootstrap: governance, Dev Container, docs) is on `main`, plus two follow-up commits fixing real Dev Container build failures. Full history in `docs/38`.
- **Jira:** the Atlassian MCP connector is connected and confirmed working, not the "unreachable" state this pack originally assumed. Site is `neuvitech-labs.atlassian.net`; the project's actual key is **`SCRUM`**, not the `NVL` this pack assumes throughout. Every ticket summary carries the plan ID (`NVL-101 · …`) specifically so the two stay traceable regardless, see `docs/26` §6. Rename recommended, not yet applied.
- **31 August 2026 is a Monday.** Sprints run Mon→Sun, giving identical capacity every sprint. Permanent fact, unaffected by anything above.
- **The Dev Container has been built and verified on both real machines** (macOS/arm64 and Windows/WSL2), not merely authored. Docker was never available in the AI's own authoring environment, which is why every container-related claim in this pack was written as `IMPLEMENTED, not VERIFIED` until proven otherwise. It has now been proven on both: `make doctor` output is byte-identical across all 10 tools, confirmed across two independent runs on 2 Sep 2026. `NVL-104` (cross-platform validation) is closed. The toolchain match is directly evidenced here; the ticket's remaining sub-items (commit/pull round trip, clean `git status` on both, the experimentation block, `docs/36` write-up) are not, closure on those rests on the Jira status alone.

## Still open

| Question | Asked | Status |
|---|---|---|
| Who holds **GitHub repository admin**? | Day 1 | **Resolved 1 Sep**: Anish Arya. Unblocked NVL-106.5 (branch protection), now configured |
| Licence: proprietary or open source? | Day 1 | **Resolved 1 Sep**: proprietary. `LICENSE` committed |
| Is `neuvitechlabs.com` registered? | Day 1 | **Not registered as of 1 Sep**: confirmed not yet done, corrected after an earlier false report |
| Jira: connector or CSV? | Day 1 | **Resolved**: connector, confirmed working |
| Manuraj's GitHub handle | Later | **Resolved**: `manu2raj`, applied in `CODEOWNERS` |

One genuinely open item remains: domain registration. Two notes on what's already closed, the `LICENSE` file names Anish Arya personally as copyright holder, since no incorporated entity has been established for NeuViTech Labs yet; and branch protection is live on `main`, so every change from here on goes through a PR, not a direct push.
