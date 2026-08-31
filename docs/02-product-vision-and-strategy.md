# 02 — Product Vision & Strategy

## 1. Vision

> A futuristic technology education and career platform where students learn the technologies of tomorrow, build real systems, prove their capability, connect with industry, and move into careers.

**Domain:** neuvitechlabs.com

## 2. Positioning — the decision that governs everything

The platform must read as **"a serious technology education company that happens to have a technology solutions division,"** never "an IT services company that also sells courses."

This is enforced structurally, not with copy:

| Enforcement point | Rule |
|---|---|
| Information architecture | EdTech owns the root namespace (`/programs`, `/tracks`, `/masterclasses`, `/certifications`). ITES is confined to `/solutions` |
| Homepage | Above the fold is career and program discovery. ITES appears no higher than the fourth section |
| Sitemap and SEO | Catalog pages carry canonical priority; ITES pages `priority ≤ 0.5` |
| Domain model | Catalog, LMS, Credentials and Careers are core bounded contexts. ITES is **content-only**, with no LMS or commerce coupling |
| Roadmap | ITES lands in Sprint 20, after every EdTech capability. Deliberate |

## 3. The three pillars

**Pillar 1 — EdTech (dominant).** Career paths, Programs, Tracks, Specializations, Courses, Masterclasses, Bootcamps, Workshops, Certifications, Free Certification Courses, memberships, cohorts, LMS, projects, assessments, portfolio, mentorship, live learning, career preparation.

**Pillar 2 — Community, Innovation & Careers.** Community, technical articles, blog, events, hackathons, open source, research, student projects, showcases, developer profiles, job listings, employer and recruiter ecosystem.

**Pillar 3 — ITES / AI Solutions (secondary).** AI, GenAI, Agentic AI, automation, cloud, DevOps, platform engineering, data engineering, software engineering, AI infrastructure, consulting, digital transformation.

**Coupling rule:** Pillar 3 may *reference* Pillar 1 but must not *depend on* it in code. No shared tables beyond identity and CMS primitives.

## 4. Core product loop

```
DISCOVER → CHOOSE CAREER → UNDERSTAND SKILLS → EXPLORE PROGRAM → CHOOSE SPECIALIZATION
  → LEARN → ATTEND LIVE → WATCH RECORDINGS → PRACTISE → BUILD PROJECTS → SUBMIT
  → GET EVALUATED → IMPROVE → BUILD PORTFOLIO → GET CERTIFIED → JOIN COMMUNITY
  → CONNECT WITH INDUSTRY → FIND OPPORTUNITIES → BUILD CAREER
```

Compressed: **LEARN → BUILD → PROVE → CERTIFY → CONNECT → WORK**

Every feature must be justifiable as advancing a learner along this loop. Features that do not are backlog, not roadmap.

## 5. Multiple entry points — an architectural requirement

A visitor must be able to enter from **any** first-class surface, not only a Course:

```
Career ──┐
Track ───┤
Program ─┼→ Curriculum → Outcomes → Instructor → Brochure → Pricing → Coupon
Spec ────┤                                                → Checkout → Payment
Masterclass ┤                                             → Entitlement → Enrolment
Free Cert ──┘                                             → Learning
```

Consequence: discovery, SEO, pricing, checkout, entitlement and enrolment are all written against a **generic catalog item**, never against "Course". This is the reason for the architecture in `06-product-catalog-architecture.md`.

## 6. Credibility constraints — non-negotiable

- Free certificates reflect **real completion and assessment criteria**. A certificate anyone can click through is worthless and damages the brand.
- **No claims of accreditation, university affiliation or government recognition** render anywhere unless evidence of actual recognition is supplied.
- **No fabricated outcome statistics.** Placement rates, salary figures, hiring-partner counts and learner counts render only from recorded data. Until real data exists, those UI slots render *nothing* — not a placeholder number.
- Investor metrics are computed from event data, never hand-entered.

## 7. Initial catalog hypothesis

Working set for schema and SEO design. **Not final** — the actual catalog is a product decision, and because the catalog is data-driven it can change without engineering work.

| Program | Specializations |
|---|---|
| AI Engineering | Generative AI · Agentic AI · LLM Engineering · AI Infrastructure · MLOps · AI Security |
| Cloud & DevOps | Cloud Engineering · Kubernetes · DevOps · Platform Engineering · SRE · DevSecOps · IaC |
| Full-Stack Engineering | Modern Web · Backend Engineering · Distributed Systems · API Engineering · Performance |
| Data Engineering | Data Engineering · Data Platforms · Streaming · Data Infrastructure |

**Free Certification Courses:** Git, Docker, Kubernetes, Terraform, PostgreSQL, Redis, Linux, API Security, GitHub Actions, AI, Agentic AI — all "Fundamentals".

These exist in the plan only to prove the schema can express them. **The schema must not encode them.**

## 8. Learner cost principle

Students complete as much curriculum as possible **without paid cloud accounts**. Labs default to Docker Compose, kind/k3d/minikube and local Postgres/Redis/Mongo/Neo4j. Any unavoidable third-party cost is disclosed on the product page *before* purchase.
