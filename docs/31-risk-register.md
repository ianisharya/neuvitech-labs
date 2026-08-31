# 31 — Risk Register

Probability × Impact. Every risk has a detection method, a mitigation, a contingency and an allocated buffer.

## Critical risks

| ID | Risk | P | I | Detection | Mitigation | Contingency | Buffer |
|---|---|---|---|---|---|---|---|
| **R01** | **Razorpay merchant KYC delayed beyond Sprint 7** | High | High | Weekly status check from Sprint 2 | Started **Sprint 2 — five sprints early**, ~8 weeks slack | Build against sandbox; swap live keys when approved (they are a setting, not a deploy) | 8 weeks slack |
| **R02** | **Scope vs capacity.** 980 team-hours for a platform this broad | High | High | Velocity at every Day 14 | Ruthless sequencing; Phase E is all post-launch; explicit out-of-scope list | Cut from the float list in `30-critical-path.md` §2 — never from identity, catalog, commerce, hardening or launch | 14–35% per sprint |
| **R03** | **Sprint 7 payments integration** — highest complexity, external dependency, money at stake | Med | **Very High** | Spike in Sprint 6 reveals doc-vs-reality gaps | 36 pts not 42; ×2.0 rework multiplier; three weekend sessions; extra DoD bar; **both engineers read the code** | Extend into Sprint 8; delay LMS by one sprint | ×2.0 |
| **R04** | **Content, not code, becomes the bottleneck.** A platform with no curriculum is a demo | High | High | Sprint 6 review — are there real programs to publish? | Catalog is data-driven, so authoring can start Sprint 5 in parallel with engineering | Launch with fewer, better programs | — |
| **R05** | **Observability found broken during Sprint 13 failure injection** | Med | High | The injection exercise itself | Full sprint allocated; ten scenarios, each a subtask | Fix in Sprint 13, re-test; delay launch by one sprint if alerts are fundamentally wrong | Full sprint |

## High risks

| ID | Risk | P | I | Detection | Mitigation |
|---|---|---|---|---|---|
| R06 | Dev Container first build fails (proxy, RAM, image pull) | Med | High | Sprint 1 Day 6 | 45-minute explicit buffer; troubleshooting guide; I fix the definition centrally — **never a local workaround** |
| R07 | Windows/WSL2 performance or path problems | Med | Med | Sprint 1 Day 7 cross-platform validation | Repo **inside** WSL2 mandated; validated on Day 7, not discovered in month three |
| R08 | Async SQLAlchemy footguns | Med | Med | Test failures | `lazy="raise"` on every relationship; `36-troubleshooting-guide.md` §1; failure mode is loud and immediate |
| R09 | First cloud provisioning takes far longer than estimated | Med | High | Sprint 11 | Three sprints before launch; you write the IaC; ×1.8 multiplier |
| R10 | First production deploy fails | Med | High | Sprint 12 | Pipeline validated with ten explicit tests; rollback rehearsed; Day 13 held as buffer |
| R11 | Video CDN cost scales faster than revenue | Med | High | Cost dashboard from Sprint 8 | Cache-hit ratio tracked; adaptive bitrate; signed short-lived URLs |
| R12 | **Bus factor** — one person owns half the system | Med | High | Obvious in retrospect, too late | **Track swap at Sprint 10**; documentation-first; ADRs |
| R13 | Sustained cadence — 7 days/week for 9 months | High | Med | Missed sessions | Day 14 buffer; roll to weekends, **never double a weekday**; one weekday off per week costs 9% and is absorbed |
| R14 | Two-track API drift | Med | Med | CI | Generated TypeScript from OpenAPI; CI fails on drift; Track A merges schema first |
| R15 | Catalog over-abstraction — the registry becomes an unusable meta-system | Med | High | Sprint 6 | Constrained: JSONB for descriptive fields, extension tables for relational capability. Validated against three real kinds before extending |
| R16 | Free certificates devalue the brand | Med | High | Market feedback | Real completion + assessment thresholds; verifiable; revocable |
| R17 | Security incident in a payment-bearing system | Low | **Very High** | Scanning, audit, alerts | Security-by-architecture; blocking scanners; authorization test matrix; human adversarial testing in Sprints 3 and 13 |

## Medium risks

| ID | Risk | P | I | Mitigation |
|---|---|---|---|---|
| R18 | Port conflicts on first `make up` | High | Low | 20-minute buffer; I remap centrally, never locally |
| R19 | Dependency or version conflicts | Med | Med | Pinned lockfiles; Dependabot; Trivy |
| R20 | CI runtime creeps past 10 minutes | Med | Med | Caching; path filters; measured each sprint |
| R21 | Email deliverability (SPF/DKIM/DMARC) | Med | Med | Domain verification started Sprint 2; Mailpit until then |
| R22 | Zoom API differs from documentation | Med | Med | Spike before build; provider protocol isolates it |
| R23 | EMI capability does not exist on the account | Med | Med | **Spike verifies before any UI is built.** No EMI copy ships on assumption |
| R24 | AI cost or latency creep | Med | Med | Hard budgets per user and capability; deterministic-first; small models for classification |
| R25 | GST/tax requirements discovered late | Med | Med | **Open question raised now**; cheaper to build in than retrofit |
| R26 | Neither engineer has frontend experience | Med | Med | shadcn/ui vendored; Server Components by default; no client-state library; design tokens mechanical |
| R27 | Estimates systematically wrong | Med | Med | Re-baselined at every Day 14 from real velocity, not defended |

## Open questions — answers change the plan

| # | Question | Needed by | If wrong |
|---|---|---|---|
| Q1 | Is `neuvitechlabs.com` registered? | Sprint 2 | Blocks SEO and production TLS |
| Q2 | Who holds GitHub repository admin? | **Sprint 1 Day 1** | Branch protection reported BLOCKED |
| Q3 | Single-tenant confirmed? | **Sprint 3** | **Expensive to retrofit multi-tenancy** |
| Q4 | Is GST invoicing required at launch? | Sprint 15 | Invoice schema change |
| Q5 | Which cloud provider and region? | Sprint 8 | IaC, cost model, latency |
| Q6 | Any existing accreditation to display? | Sprint 6 | We will not claim what is unevidenced |
| Q7 | Brand assets — logo, typography, colour direction? | Sprint 5 | I choose defaults you may dislike |
| Q8 | Zoom tier and API access? | Sprint 9 | Live learning slips |

## Buffer allocation

| Level | Buffer |
|---|---|
| Per task | Rework multipliers ×1.3 to ×2.5 by work type |
| Per sprint | 14–35%, largest in Sprints 1–2 and 7 |
| Per phase | Day 14 of each sprint is buffer, not capacity |
| Programme | Phase E is entirely post-launch and can absorb slippage |

**If Day 14 is routinely consumed by delivery, the sprint was over-committed and I lower the next one.** That is the signal, and it only works if you report it.
