# 24: Capacity & Estimation Model

**How every number in this plan was derived.** If a premise here is wrong, tell me and I re-derive rather than defend.

## 1. Your capacity

| | Per person | Team of 2 |
|---|---|---|
| Weekday (Mon–Fri) | 1.0–1.5 h · **plan at 1.25 h** | 2.5 h |
| Weekend day (Sat, Sun) | 3.0 h | 6 h |
| Per week | 12.25 h | **24.5 h** |
| **Per 14-day sprint** (10 weekdays + 4 weekend days) | 24.5 h | **49 h** |

A 14-day sprint is exactly two calendar weeks, so capacity is identical in every sprint. Starting Monday 31 August 2026 means every sprint runs **Mon → Sun**, putting the 3-hour blocks on Days 6, 7, 13 and 14.

**Plan at 1.25 h, commit at 1.0 h.** The gap is deliberate buffer.

## 2. What your hours are spent on

Not "review AI code". The realistic distribution across the programme:

| Activity | Share | Notes |
|---|---|---|
| Code review and analysis | 30% | Reading, understanding, challenging |
| Running, testing, verifying | 25% | Executing, manual testing, acceptance |
| Debugging and rework cycles | 15% | Things fail; this is the honest allocation |
| **Experimentation and POCs** | 10% | Assumption testing, failure injection |
| **Human-written code** | 8% | IaC, scripts, fixes, tests |
| Environment, setup, tooling | 7% | Front-loaded in Sprints 1–2, recurring later |
| **Deployment and operations** | 5% | Sprints 11–14 and ongoing |

**Roughly 23% of your time is experimentation, human-written code and operations**: not review. That is what makes you engineers on this project rather than a review queue.

## 3. Human throughput rates: the basis of every estimate

Conservative on purpose.

| Activity | Rate |
|---|---|
| Reading and understanding generated code | 150–250 lines/hour · **security and payments: 100 lines/hour** |
| Reviewing a PR | 20 min per 300 lines, including comments |
| Running a command and reading output | 2–5 min (longer when it fails) |
| First Dev Container build | 15–25 min, mostly waiting |
| `make up` cold (images cached) / warm | 2–4 min / 30–60 s |
| Next.js dev server first start / subsequent | 30–60 s / 10–15 s |
| Full test suite (grows over time) | 2–5 min |
| Manual test of one user flow | 10–20 min including notes |
| Writing a bug report I can act on | 5–10 min |
| Commit → push → PR → review → merge → Jira | 10 min per ticket |
| **Context switch between tasks** | 5–10 min, why weekdays carry one thing |
| Deploy to an environment + verify | 20–30 min |
| Investigating a production alert | 30–90 min |

## 4. The rework multiplier: nothing works first time

| Work type | Multiplier |
|---|---|
| Configuration and setup | **× 1.5** |
| Straightforward application code | **× 1.3** |
| **External integration** (payments, Zoom, LLM) | **× 2.0** |
| Anything touching both OSes | × 1.6 |
| First use of a new tool or library | × 1.8 |
| **Deployment and infrastructure** | **× 1.8** |
| Production incident work | × 2.5 |

**These are already inside every estimate in this pack.** When you see "45 min", that is the expected time *including* the likely correction round, not the optimistic path.

## 5. Worked example

**NVL-214, Payment webhook handler with signature verification** (Sprint 7)

| Step | Who | Time |
|---|---|---|
| I write handler, signature verification, idempotency, tests | AI | 0 human |
| Read design, challenge the approach | Human | 15 m |
| Review ~400 lines of security-critical code at 100 lines/hour | Human | **40 m** |
| Run tests, read results | Human | 10 m |
| **Experiment: send a forged signature, confirm rejection** | Human | 20 m |
| **Experiment: send a duplicate event, confirm no double grant** | Human | 20 m |
| Test against the provider sandbox with a real webhook | Human | 30 m |
| Debug the inevitable mismatch between docs and reality | Human | 30 m |
| Fix cycle with me | Shared | 20 m |
| Re-test, verify audit rows written | Human | 20 m |
| Commit, PR, second review, merge, Jira | Human | 15 m |
| **Subtotal** | | **220 m** |
| × 2.0 external-integration multiplier applied to the integration portion | | **~300 m = 5 h** |

Which is why this ticket spans **two weekend sessions**, not one weekday hour. Sprint 7 is the highest-risk sprint in the programme and is estimated accordingly.

## 6. Story points

**1 point = 1 hour of one person's time**, including review, running, testing and rework. A direct hours mapping, because with 1-hour sessions a point that does not map to a session is useless for scheduling.

| Sprints | Committed | Buffer | Reason |
|---|---|---|---|
| 1–2 | **32** | 35% | Environment setup, first exposure, highest uncertainty |
| 3–5 | **38** | 22% | Finding rhythm |
| 6–10 | **42** | 14% | Steady state |
| **7** | **36** | 27% | **Payments, highest-risk sprint** |
| 11–14 | **38** | 22% | Deployment, production, incident risk |
| 15–20 | **40** | 18% | Integration-heavy |

**If you consistently finish early, tell me and I raise it. If you overrun, tell me and I lower it. Do not silently absorb overruns.**

## 7. Programme totals

| Phase | Sprints | Days | Team hours | Ends |
|---|---|---|---|---|
| **A, Foundation and Environment** | 1-2 | 28 | 98 | 27 Sep 2026 |
| **B, Core Platform** | 3-7 | 70 | 245 | 6 Dec 2026 |
| **C, Learning, Commerce and Credentials** | 8-11 | 56 | 196 | 31 Jan 2027 |
| **D, Launch: Hardening, Production, Observation** | 12-14 | 42 | 147 | **14 Mar 2027** |
| **E, Extended Scope and Scale** | 15-24 | 140 | 490 | **1 Aug 2027** |
| **Total** | **24** | **336** | **1,176** |, |

At the committed floor (1.0 h weekdays) the programme is about 1,056 h; at sustained stretch (1.5 h) it is about 1,296 h.

**Sprint 1 is unlike any other:** roughly 60% is machine setup rather than code work. That is honest, not padding. You cannot review code on a machine that cannot run it.

## 8. What is NOT in these estimates

- **My generation time**: effectively zero from your side.
- **Reading this documentation**: ~60 min of pre-reading before Day 1.
- **External wait time**: merchant KYC, DNS propagation, cloud provisioning. Tracked as `NVL-EXT-*` tickets started early, because they consume calendar, not effort.
- **Meetings**: there are none. Review and retrospective sit inside the Day-14 session.
- **Sick days and holidays**: absorbed by Day-14 buffer. Lose more than two sessions in a sprint and tell me on Day 14 so I can re-baseline.

## 9. How to tell me the plan is wrong

At each Day 14, answer three questions:

1. Did we finish the committed points? If not, by how much?
2. Where did the time actually go, review, running, debugging, experimenting, or setup?
3. Which single estimate was most wrong, and in which direction?

**Three sprints of honest velocity data is worth more than any amount of up-front estimating.**
