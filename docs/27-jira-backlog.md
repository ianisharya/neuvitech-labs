# 27: Jira Backlog: Epic → Story → Task → Subtask

> **STATUS: THIS FILE IS THE SYSTEM OF RECORD.** Earlier in this project, live tickets existed in Jira under project key NVL, created and updated through the Atlassian connector. Jira is no longer used for this project. No ticket sync happens, and no external system is checked against this file.
>
> Every `NVL-E0x` epic and `NVL-1xx` to `NVL-2xx` task below is an internal reference identifier, kept for continuity with prior work and with the rest of this documentation set, which cites these identifiers throughout. Update this file directly when scope, status, or sprint assignment changes. There is nothing else to reconcile it against.

**Point scale: 1 point = 1 hour of one person's time**, including review, running, testing and rework.

---

## Epic index

| Key | Epic | Sprints | Pts |
|---|---|---|---|
| NVL-E01 | Development Environment & Repository Foundation | 1 | 32 |
| NVL-E02 | Platform Skeleton & Data Layer | 2 | 40 |
| NVL-E03 | Identity, Authorization & Security | 3 | 38 |
| NVL-E04 | Runtime Configuration & Content System | 4 | 20 |
| NVL-E05 | Observability Foundation | 4 | 18 |
| NVL-E06 | Product Catalog Core | 5 | 24 |
| NVL-E07 | Design System & UI Foundation | 5 | 14 |
| NVL-E08 | Public Catalog, Discovery & SEO | 6 | 42 |
| NVL-E09 | Commerce, Payments & Entitlements | 7 | 36 |
| NVL-E10 | LMS Core & Video Delivery | 8 | 42 |
| NVL-E11 | Assessments, Projects & Free Certifications | 9 | 42 |
| NVL-E12 | Certificates, Brochures & Portfolio | 10 | 42 |
| NVL-E13 | Live Learning & Subscriptions | 11 | 26 |
| NVL-E14 | **Kubernetes Production Infrastructure** *(k3s, hardens the Sprint 2 dev cluster, ADR-0019, supersedes ADR-0013)* | 11–12 | 44 |
| NVL-E15 | Admin Console & Analytics | 12 | 22 |
| NVL-E16 | Hardening: Security, Performance & Observability Validation | 13 | 38 |
| NVL-E17 | Production Launch & Post-Deployment Observation | 14 | 38 |
| NVL-E18 | Financing, Billing & Tax | 15 | 40 |
| NVL-E19 | Careers & Job Board | 16 | 40 |
| NVL-E20 | Community & Content | 17 | 40 |
| NVL-E21 | AI Foundation & Guardrails | 18 | 40 |
| NVL-E22 | Agentic AI Capabilities | 19 | 40 |
| NVL-E23 | ITES, Scale & v2 Release | 20 | 40 |
| NVL-E24 | **Enterprise: Corporate Sponsorship & Employer Talent Pipeline** *(added ADR-0015)* | 21 | 40 |
| ~~NVL-E25~~ | reserved, retired during renumbering, not a missing epic | | |
| NVL-E26 | **Model Context Protocol: server and client roles** *(added ADR-0020)* | 18 | 6 |
| ~~NVL-E27~~ | reserved, retired; provider abstraction work is tracked under NVL-E02 instead (NVL-213), not a separate epic | | |
| ~~NVL-E28~~ | reserved, retired; constrained local development work is tracked under NVL-E02 instead (NVL-214), not a separate epic | | |
| NVL-E29 | **Video pipeline and near-live streaming at scale** *(docs 41, ADR-0017)* | 22 | 40 |
| NVL-E30 | **Problem-solving platform and AI tutor memory** *(docs 10, 12, ADR-0018)* | 23 | 40 |
| NVL-E31 | **Karma, streaks and goodies store** *(doc 40)* | 24 | 40 |
| NVL-EXT | External Dependencies & Accounts | 2–17 | 14 |

---

## Ownership legend

`AI`, I do all of it, your time zero · `ME`, macOS · `TM`, Windows teammate · `BOTH` · `AI+ME` · `AI+TM` · `AI+BOTH`

---

# EPIC NVL-E01: Development Environment & Repository Foundation

**Sprint 1 · 32 points · Goal:** both machines run an identical Dev Container, the repository is governed, and the first CI run is green.
**Blocks:** everything. **Blocked by:** nothing.

## Story NVL-101: Host prerequisites installed on both machines · 11 pts · BOTH

*Why:* nothing can be built, run or reviewed until Docker and VS Code work on both machines.
*Prerequisites:* laptops, admin rights, internet. *Unblocks:* NVL-102 onward. *Parallel:* yes, both work simultaneously.

| Subtask | Owner | Time | Verification |
|---|---|---|---|
| NVL-101.1 Install WSL2 + Ubuntu, reboot, set UNIX user | TM | 45 m | `wsl -l -v` shows `Ubuntu Running 2` |
| NVL-101.2 Install Docker Desktop; (Windows) enable WSL2 backend; (macOS) confirm VirtioFS | BOTH | 35 m | Whale icon steady |
| NVL-101.3 Configure Docker resources: 6 GB RAM, 4 CPU | BOTH | 10 m | Settings show the values |
| NVL-101.4 Verify Docker daemon | BOTH | 5 m | `docker run --rm hello-world` |
| NVL-101.5 Install VS Code, add `code` to PATH | BOTH | 20 m | `code --version` |
| NVL-101.6 Install extensions: Dev Containers, Docker, (Windows) WSL, GitLens, Copilot | BOTH | 20 m | Extensions listed |
| NVL-101.7 Install Git; configure name, email, `init.defaultBranch`, `pull.rebase`, `core.autocrlf input` | BOTH | 20 m | `git config --list` |
| NVL-101.8 Generate SSH key, add to GitHub, verify | BOTH | 25 m | `ssh -T git@github.com` authenticates |
| NVL-101.9 Confirm who holds GitHub repository admin | ME | 10 m | Documented answer |
| NVL-101.10 **Buffer: installation troubleshooting** | BOTH | **30 m** |, |

**AC:** *Given* two clean machines, *when* both complete this story, *then* `docker run --rm hello-world`, `code --version` and `ssh -T git@github.com` all succeed on both, and `git config core.autocrlf` returns `input`.

## Story NVL-102: Repository structure and governance · 4 pts · AI+BOTH

*Why:* contribution standards must exist before the first line of product code, or they are never adopted.
*Blocked by:* NVL-101.8. *Unblocks:* NVL-103.

| Subtask | Owner | Time |
|---|---|---|
| NVL-102.1 Author monorepo tree, `.gitignore`, `.gitattributes`, `.editorconfig`, `LICENSE`, `README`, `CODEOWNERS` | AI | 0 h |
| NVL-102.2 Author `CONTRIBUTING.md`, `SECURITY.md`, PR + issue templates, `docs/` skeleton with this pack, `Makefile` stub | AI | 0 h |
| NVL-102.3 Clone repository ((Windows) **inside WSL2**, never `/mnt/c/`) | BOTH | 15 m |
| NVL-102.4 Review all governance files, request changes | BOTH | 40 m |
| NVL-102.5 Verify `.env` is ignored: `touch .env && git status` | ME | 10 m |
| NVL-102.6 First commit, push, open PR, joint review, merge | BOTH | 25 m |
| NVL-102.7 Buffer | BOTH | 20 m |

**AC:** *Given* a clone, *when* I list the root, *then* all nine governance files are present and non-placeholder; *when* I create `.env`, *then* it does not appear in `git status`; *when* I run `git log --oneline`, *then* there is exactly one commit matching `^(feat|fix|chore|docs|ci|refactor|test|security)(\(.+\))?: NVL-\d+ .+`.

## Story NVL-103: Dev Container definition and first build · 9 pts · AI+BOTH

*Why:* **the cross-platform contract.** After this story, macOS and Windows are identical.
*Blocked by:* NVL-102. *Unblocks:* all development. **Critical path.**

| Subtask | Owner | Time |
|---|---|---|
| NVL-103.1 Author `.devcontainer/devcontainer.json` + `Dockerfile` (Python 3.12, Node 22, uv, psql, redis-cli, make, jq, extensions) | AI | 0 h |
| NVL-103.2 Review the container definition; challenge pinned versions | BOTH | 30 m |
| NVL-103.3 **Reopen in Container, first build** | BOTH | **35 m** (15–25 m waiting) |
| NVL-103.4 Verify toolchain: `python --version`, `node --version`, `uv --version`, `make help` | BOTH | 15 m |
| NVL-103.5 **Buffer: first-build failures** (proxy, RAM, image pull) | BOTH | **45 m** |
| NVL-103.6 Document any host-specific gotcha in `36-troubleshooting-guide.md` | BOTH | 20 m |

**AC:** *Given* both machines, *when* each opens the folder and reopens in container, *then* the build succeeds and `python --version`, `node --version`, `uv --version` return **byte-identical** strings on both.

## Story NVL-104: Cross-platform validation · 4 pts · BOTH

*Why:* proves the Dev Container decision worked. **Do not skip.**
*Blocked by:* NVL-103.

| Subtask | Owner | Time |
|---|---|---|
| NVL-104.1 Both run identical verification commands, compare output side by side | BOTH | 30 m |
| NVL-104.2 One commits a trivial change; the other pulls and runs it | BOTH | 20 m |
| NVL-104.3 Confirm no file shows modified purely from line endings | BOTH | 15 m |
| NVL-104.4 Record findings; I fix any divergence in `devcontainer.json` | BOTH | 25 m |

**AC:** *Given* both machines, *when* the same commands run, *then* output is identical, `git status` is clean on both, and **no local workaround was required**. Any divergence is a bug in the container definition, fixed centrally, never worked around locally.

## Story NVL-105: Jira project configuration · 3 pts · ME

| Subtask | Owner | Time |
|---|---|---|
| NVL-105.1 Create project `NVL`, Scrum, configure issue types | ME | 30 m |
| NVL-105.2 Import `jira-import-epics.csv` and `jira-import-sprint-01.csv` | ME | 30 m |
| NVL-105.3 Create Sprint 1 (31 Aug – 13 Sep 2026), add issues, set components | ME | 30 m |
| NVL-105.4 Decide MCP connector vs manual, and tell me | ME | 15 m |

## Story NVL-106: Baseline CI pipeline · 4 pts · AI+TM

| Subtask | Owner | Time |
|---|---|---|
| NVL-106.1 Author `.github/workflows/ci.yml` (lint, typecheck, build; pinned action versions) | AI | 0 h |
| NVL-106.2 Enable GitHub Actions; review the workflow | TM | 30 m |
| NVL-106.3 Open a PR, watch the first run, read the logs | TM | 30 m |
| NVL-106.4 **Buffer: first CI failures** | TM | **45 m** |
| NVL-106.5 Configure branch protection (or report **BLOCKED** with instructions if no admin) | ME | 30 m |

**AC:** *Given* a PR, *when* CI runs, *then* every job executes and a failure blocks merge; *when* a direct push to `main` is attempted, *then* it is rejected, **or** the ticket is explicitly `BLOCKED` with manual instructions, never silently closed.

---

# EPIC NVL-E02: Platform Skeleton & Data Layer · Sprint 2 · 40 pts

**Goal:** API and web boot, settings load **from the database**, migrations run, logging and tracing emit, health endpoints report truthfully, and the whole thing deploys to DEV.

| Story | Title | Owner | Pts | Key subtasks |
|---|---|---|---|---|
| NVL-201 | uv project + FastAPI skeleton + lifespan | AI+ME | 4 | app factory, versioned router, OpenAPI, docs disabled in prod |
| NVL-202 | Compose services: Postgres+pgvector, Redis, MinIO, Mailpit | AI+BOTH | 5 | healthchecks, named volumes, **port-conflict resolution (20 m buffer)**, `make up` verified |
| NVL-203 | Bootstrap configuration, the 9 env vars | AI+ME | 3 | Pydantic settings, fail-fast, `.env.example`, **CI check: no `os.getenv` outside `core/config.py`** |
| NVL-204 | SQLAlchemy async engine, base model, UUIDv7 + mixins, **`lazy="raise"`** | AI+ME | 4 | session-per-request, naming conventions, pooling |
| NVL-205 | Alembic init + first migration + **up/down tested in CI** | AI+ME | 4 | async config, pgvector extension, reversibility test |
| NVL-206 | **Runtime settings loaded from the database** | AI+ME | 4 | `setting_definition`/`setting_value` tables, resolution order, Redis cache, seed migration |
| NVL-207 | Structured logging, request-id, uniform error model | AI+ME | 3 | JSON logs, PII **allow-list** serialiser, error envelope with correlation id |
| NVL-208 | Health + readiness with dependency checks | AI+ME | 3 | `/health` touches nothing; `/ready` checks Postgres and Redis; **failure-path tested by stopping Postgres** |
| NVL-209 | Next.js skeleton + API client + SSR status page | AI+TM | 4 | TypeScript strict, error/loading boundaries, degraded state |
| NVL-210 | Test harness + full CI gate chain | AI+TM | 4 | pytest async fixtures, DB-per-test, coverage gates, service containers |
| NVL-211 | **DEV deployment: build once, tag by SHA, deploy, smoke test** | AI+TM | 4 | rollback procedure documented and **rehearsed once** |
| NVL-EXT-01 | **Start Razorpay merchant KYC** | ME | 2 | **Longest lead time in the programme, start now** |
| NVL-EXT-02 | Start email sending-domain verification | ME | 1 | SPF/DKIM records added |
| NVL-EXT-03 | Register `neuvitechlabs.com`, configure DNS + Cloudflare | ME | 2 | Nameservers changed |
| NVL-212 | Local Kubernetes cluster (k3d), DEV namespace, deploy the Sprint 2 skeleton onto it | AI+ME | 3 | replaces a plain Docker Compose DEV deploy; production hardening of the same cluster shape happens at Sprint 11, ADR-0019 |
| NVL-213 | Provider interfaces: `LanguageModel`, `EmbeddingModel`, `VectorStore` protocols, Ollama implementation, in-memory test doubles | AI+ME | 3 | interfaces modelled on domain need, not on Ollama's own API shape; test suite exercises the in-memory implementation, not the network, ADR-0021 |
| NVL-214 | Profile-based local development: minimal, web, full-local, AI, observability, Kubernetes profiles in Compose | AI+ME | 2 | routine tasks start few services; readiness endpoint reports which optional dependency is absent, ADR-0022 |

---

# EPIC NVL-E03: Identity, Authorization & Security · Sprint 3 · 38 pts

| Story | Title | Owner | Pts |
|---|---|---|---|
| NVL-301 | User model, registration, Argon2id, email verification | AI+ME | 5 |
| NVL-302 | Opaque server-side sessions, login, logout, revocation | AI+ME | 5 |
| NVL-303 | TOTP MFA, recovery codes, step-up re-authentication | AI+ME | 5 |
| NVL-304 | RBAC: roles, permissions, **single policy decision point**, default-deny startup assertion | AI+ME | 6 |
| NVL-305 | Superuser bootstrap (**CI check: no hard-coded email comparisons**) | AI+ME | 3 |
| NVL-306 | Append-only audit log | AI+ME | 3 |
| NVL-307 | Redis rate limiting, brute-force protection, security headers, CORS | AI+ME | 4 |
| NVL-308 | Auth UI: signup, login, verify, reset, MFA enrolment | AI+TM | 5 |
| NVL-309 | **Security scanning in CI**: Gitleaks, Semgrep, Trivy, Checkov, audits | AI+TM | 3 |
| NVL-310 | **Human experiment: attempt to break your own authorization** (IDOR, privilege escalation, session fixation) | BOTH | **3** |

**NVL-310 is not optional.** An authorization system nobody has attacked is an assumption, not a control.

---

## Sprints 1–24: epic summary

Full story-level breakdown is produced at each sprint planning session, when it reflects what was actually built rather than a guess made months earlier. Epics, goals, points and key risks are fixed now.

| Sprint | Epic(s) | Focus | Highest-risk item |
|---|---|---|---|
| 1 | E01 | Dev Container, repository governance, first CI pipeline green | Toolchain must be byte-identical across both development machines, or the cross-platform guarantee fails at the first sprint |
| 2 | E02 | API and web boot; settings from database; Postgres, Redis, migrations, logging, errors, health; DEV deploy on a Kubernetes cluster; provider interfaces with Ollama and in-memory test doubles; profile-based local development | Kubernetes, provider abstraction, and local development tooling are all established at once, on a repository with no application code yet, ADR-0019, ADR-0021, ADR-0022 |
| 3 | E03 | Argon2id, sessions, MFA, RBAC, audit, rate limiting, security scanning in CI | Default-deny must fail at startup for an endpoint declaring neither a permission nor an explicit public marker, not at runtime |
| 4 | E04, E05 | Settings admin UI, content/navigation tables, feature flags, OTel → Grafana, GlitchTip | First trace end to end |
| 5 | E06, E07 | Type registry, versioning, relationships, publish + outbox; design tokens; restyle components | Publish pipeline correctness |
| 6 | E08 | Public catalog, read model, caching, FTS, SEO, JSON-LD, sitemap, Core Web Vitals | Cache invalidation correctness |
| 7 | E09 | **Products, prices, coupons, checkout, Razorpay, webhooks, reconciliation, entitlements** | **Highest-risk sprint. 36 pts, not 42** |
| 8 | E10 | Learning components, progress, video pipeline, signed URLs, player | Video cost and CDN hit ratio |
| 9 | E11 | Assessment engine, submissions, grading, free certification path | Server-side grading integrity |
| 10 | E12 | Credential lifecycle, Ed25519 signing, verification page, brochure generation · **track swap** | Idempotent issuance under retry |
| 11 | E13, E14 | Cohorts, Zoom, attendance, subscriptions; **harden the Sprint 2 Kubernetes cluster for production**: workload classes, HPA, network policies, pod security, on-cluster stateful services, ingress, TLS, CDN | Zoom integration; first production-grade cluster, not first cloud provisioning, ADR-0019 |
| 12 | E14, E15 | Admin console, analytics, investor metrics; **pipeline proven to PROD** | First production deploy |
| 13 | E16 | Load testing (k6), DAST (ZAP), pen-testing, **failure-injection validation of all 10 alert scenarios** | Discovering an alert never worked |
| 14 | E17 | **UAT, production deployment, 72-hour observation, DR rehearsal** | Real users, real money |
| 15 | E18 | Subscription billing hardening, tax, invoicing, refunds (no EMI, removed per ADR-0016) | Renewal, proration and grace-period correctness |
| 16 | E19 | Jobs, applications, resumes, screening | File security |
| 17 | E20 | Articles, events, showcases, profiles, moderation | Content moderation policy |
| 18 | E21, E26 | AI gateway, guardrails, pgvector, hybrid retrieval, budgets, AI observability; **MCP server and client roles** | Prompt injection defence; MCP tool descriptions and results treated as untrusted data, ADR-0020 |
| 19 | E22 | Agent identities, tool authorization, human-approval gates, evals | Tool authorization correctness |
| 20 | E23 | ITES surfaces, scale tuning, DR re-rehearsal, v2 release | Scale tuning now validates against the Kubernetes autoscaling model from Sprint 11 rather than a from-scratch scale-up |
| 21 | E24 | Organisation entity, corporate sponsorship commerce, opt-in employer talent pipeline | Enterprise sales motion differs from B2C, see `docs/31` risk entry R28 |
| 22 | E29 | Video pipeline and near-live streaming at scale: adaptive bitrate, CDN delivery, live broadcast plus recording, processing pipeline | Video bandwidth is the dominant variable cost, see `docs/31` risk entry R29, ADR-0017 |
| 23 | E30 | Problem-solving platform and AI tutor memory: exercises with solutions, AI-tutor chat help, persistent tutor memory | No in-browser code execution by design; memory holds sensitive learner data, see `docs/31` risk entry R31, ADR-0018 |
| 24 | E31 | Karma, streaks and goodies store: verified-event karma, streak multiplier, karma-priced goodies through existing commerce | Karma awarded only on server-verified events, never client-claimed |

---

## Ticket field template

Every ticket carries: **Identity** (epic, story, title) · **Purpose** (description, why it exists) · **Ownership** (AI/ME/TM/BOTH/AI+…) · **Execution** (exact work, required tools and software, commands, expected result) · **Time** (AI effort, human effort, waiting, testing, review, debugging allowance, total) · **Dependencies** (prerequisites, blockers, upstream, downstream, parallelisation) · **Validation** (Given/When/Then acceptance criteria, test procedure, expected result, definition of complete).

The CSV imports carry these as columns.
