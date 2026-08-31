# 30 — Critical Path & Dependencies

## 1. The critical path

These determine the launch date. A day lost here is a day lost overall.

```
NVL-101 Host prerequisites (S1)
   └→ NVL-103 Dev Container (S1)        ← EVERYTHING depends on this
        └→ NVL-202 Compose services (S2)
             └→ NVL-204/205 Data layer + migrations (S2)
                  └→ NVL-206 Settings from database (S2)
                       └→ NVL-E03 Identity & authorization (S3)
                            └→ NVL-E06 Catalog core (S5)
                                 └→ NVL-E08 Public catalog (S6)
                                      └→ NVL-E09 Commerce & payments (S7)
                                           └→ NVL-E10 LMS (S8)
                                                └→ NVL-E11 Assessments (S9)
                                                     └→ NVL-E12 Certificates (S10)
                                                          └→ NVL-E14 Cloud infra (S11)
                                                               └→ NVL-E14 Pipeline to PROD (S12)
                                                                    └→ NVL-E16 Hardening (S13)
                                                                         └→ NVL-E17 LAUNCH (S14)
```

### Why each is on the path

| Task | Why it blocks the date |
|---|---|
| **NVL-103 Dev Container** | Nothing can be built, run, tested or reviewed until both machines have a working environment. **The single highest-leverage task in the programme** |
| **NVL-202 Compose services** | No database means no persistence, no tests against real Postgres semantics |
| **NVL-204/205 Data layer** | Every module's schema depends on the base model, ID strategy and migration conventions. Building tables before these exist guarantees a rewrite |
| **NVL-206 Settings from DB** | The "nothing is static" principle. Retrofitting it later means ripping hard-coded values out of every module |
| **NVL-E03 Identity** | No authorization without principals. Every subsequent module needs `require_permission` |
| **NVL-E06 Catalog core** | The type registry is the load-bearing design. Commerce, LMS, certificates and brochures all reference catalog items |
| **NVL-E09 Commerce** | Revenue capability. Also the highest-risk external integration |
| **NVL-E14 Cloud infra** | Cannot deploy to what does not exist. Provisioned three sprints before launch so failures surface with time to fix |
| **NVL-E16 Hardening** | Launching without validated alerts means discovering in production that monitoring never worked |

## 2. Off the critical path — genuine float

| Work | Float | Can slip to |
|---|---|---|
| Design system refinement (S5) | 2 sprints | S12 polish |
| Community (S17) | Post-launch | Any Phase E sprint |
| Careers (S16) | Post-launch | Any Phase E sprint |
| AI (S18–19) | Post-launch | Any Phase E sprint |
| ITES surfaces (S20) | Post-launch | Anytime |
| Brochures (S10) | 1 sprint | S12 |
| Masterclasses/Zoom (S11) | 1 sprint | S12 |
| Subscriptions (S11) | 2 sprints | S15 |

**If the schedule slips, cut from this list — never from identity, catalog, commerce, hardening or launch.**

## 3. Genuinely parallel work

| Parallel | Why it works |
|---|---|
| Host installs on both machines (S1 D1–4) | Independent machines |
| Track A backend / Track B frontend (all sprints) | Different directories; OpenAPI is the contract |
| **`NVL-EXT-*` account setup / all development** | Calendar time, not effort |
| Documentation / implementation | I write docs while you review code |
| Observability config / feature work (S4) | Different modules |
| IaC authoring / application work (S11) | Different repositories areas |

## 4. Must be sequential

| Sequence | Why |
|---|---|
| Environment → any development | Cannot run what has no runtime |
| Base model → any table | Conventions must exist first |
| Migration → code depending on the schema | Column must exist before it is queried |
| Identity → any authorized endpoint | `require_permission` must exist |
| Catalog → commerce → entitlement → LMS | Each references the previous |
| Implementation → review → test → deploy | Cannot review what does not exist |
| Alerts configured → failure injection | Cannot validate what is not configured |
| Deploy → observation window | Cannot observe what is not running |

## 5. External dependencies — calendar, not effort

**These are the most dangerous items in the plan** because no amount of effort accelerates them.

| Ticket | Dependency | Lead time | Needed by | **Start** | Slack |
|---|---|---|---|---|---|
| NVL-EXT-01 | **Razorpay merchant KYC** | **2–4 weeks** | S7 (23 Nov) | **S2 (14 Sep)** | ~8 weeks |
| NVL-EXT-02 | Email domain verification | 2–5 days | S5 | S2 | ~6 weeks |
| NVL-EXT-03 | `neuvitechlabs.com` + Cloudflare | Hours–2 days | S6 | S2 | ~8 weeks |
| NVL-EXT-04 | Cloud hosting + managed Postgres | 1–3 days | S11 | S8 | ~6 weeks |
| NVL-EXT-05 | Object storage + CDN | Hours | S8 | S7 | ~2 weeks |
| NVL-EXT-06 | Zoom account + API app | 1–3 days | S11 | S9 | ~4 weeks |
| NVL-EXT-07 | LLM provider key | Immediate | S18 | S17 | ~2 weeks |

**NVL-EXT-01 is the highest-risk item in the entire programme.** Merchant KYC is outside your control and routinely takes four weeks. It is started in Sprint 2 — five sprints early — precisely so a delay consumes slack rather than the launch date.

## 6. Bottlenecks

| Bottleneck | Mitigation |
|---|---|
| **Human review capacity** — the fundamental constraint | Two parallel tracks; each reviews the other; estimates built on measured review rates |
| **Sprint 7 payments** — highest complexity, external dependency, money | 36 pts not 42; spike first; three weekend sessions on it; ×2.0 multiplier |
| **Sprint 11 first cloud provisioning** — new tooling, account-specific | You write the IaC; three sprints before launch |
| **Sprint 13 failure injection** — may reveal alerts never worked | Full sprint allocated; findings feed Sprint 14 |
| **Single-track knowledge** — bus factor with two people | **Track swap at Sprint 10** |
| **Video CDN cost** — scales with success | Cost dashboard from Sprint 8; cache-hit ratio tracked |

## 7. Highest-risk tasks — extra buffer allocated

| Task | Sprint | Risk | Buffer |
|---|---|---|---|
| Dev Container first build | 1 | Proxy, RAM, image pull failures | **45 m explicit** |
| Razorpay webhook integration | 7 | Docs differ from reality | **×2.0 multiplier** |
| First production deploy | 12 | Everything is new at once | **Full day 13 as buffer** |
| Failure-injection validation | 13 | May find alerts never worked | **Full sprint** |
| Production launch | 14 | Real users, real money | **72-hour observation** |
| EMI verification | 15 | Capability may not exist | **Spike before build** |
