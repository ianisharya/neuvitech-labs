# 16: Collaboration Model: Who Does What

**Read before Day 1.** This is a collaborative AI + human engineering team. **You are engineers, not a review queue.**

---

## 1. Responsibility matrix

| Area | AI (me) | You (macOS) | Teammate (Windows) |
|---|---|---|---|
| Architecture | **Lead**: propose, document, justify | **Challenge**, approve, own final call | **Challenge**, approve |
| Technical design | **Lead** | Analyse, critique | Analyse, critique |
| Backend implementation | **Lead**: majority of code | Analyse, modify, extend | Analyse, modify, extend |
| Frontend implementation | **Lead**: majority of code | Analyse, modify | Analyse, modify |
| Database schema & migrations | **Lead** | **Review every migration** | Review |
| Infrastructure as code | Draft | **Lead**: account-specific | Support |
| CI/CD pipeline | Draft | Configure secrets, runners | **Lead**: validate end to end |
| Deployment | Draft config, runbooks | **Execute** | **Execute** |
| Secrets & credentials | Never touch | **Own** | **Own** |
| Experimentation / POCs | Suggest, prepare harness | **Own** | **Own** |
| Human-written code | Integrate and review it | **Write where it's faster** | **Write where it's faster** |
| Unit / integration tests | **Lead** | Review, extend | Review, extend |
| Manual & exploratory testing | Cannot | **Own** | **Own** |
| Performance testing | Write k6 scripts | Run, analyse | Run, analyse |
| Security validation | Implement, scan config | Validate, pen-test flows | Validate |
| Observability config | **Lead** | Validate by breaking things | **Lead** on failure injection |
| Production operations | Runbooks | **Own** | **Own** |
| Incident response | Analyse from logs you paste | **Own** | **Own** |
| Rollback / recovery | Document, rehearse plan | **Execute** | **Execute** |
| Documentation | **Lead** | Correct from real experience | Correct |
| Jira administration | Write specs | **Own** | Support |
| Final acceptance | Cannot | **Own** | **Own** |

**Read the matrix honestly: I lead implementation; you lead everything that touches a real machine, a real account, or a real user.**

## 2. Track split for parallel work

| | **Track A, Platform & Data** (macOS) | **Track B, Experience & Delivery** (Windows) |
|---|---|---|
| Domain | Backend modules, database, commerce, payments, security | Frontend, design system, admin console, CI/CD, deployment |
| Analysis focus | Correctness, data integrity, authorization | UX, accessibility, performance, pipeline reliability |
| Owns in production | Database, API, workers | Web tier, CDN, pipeline |
| Reviews | Track B's PRs | Track A's PRs |

**Contract between tracks:** the OpenAPI schema. Track A publishes it; Track B generates TypeScript from it; **CI fails on drift.** This converts "the backend renamed a field" from a production surprise into a compile error on the PR.

**Track swap at Sprint 10** so both of you have touched both halves before launch. Bus factor is a real risk with two people.

## 3. What I cannot do: stated plainly

I have **no access** to your machines, GitHub account, Jira, cloud, payment providers, or DNS. Concretely:

- I cannot run `docker compose up` and see the result. You run it; you paste the output.
- I cannot click a button in a browser.
- I cannot create a Jira issue unless the Atlassian MCP connector is connected.
- I cannot configure GitHub branch protection or environment secrets.
- **Docker is not installed in my authoring environment.** Anything container-related is `IMPLEMENTED`, never `VERIFIED`, until you prove it.

When something needs your access I say `BLOCKED`, explain why, and give exact instructions. **I will not claim it is done.**

## 4. Human engineering work: first-class, with time allocated

These are not "review tasks". They have their own tickets and estimates.

| Activity | Examples | Typical allocation |
|---|---|---|
| **Architecture analysis** | Challenge a design before it is built; find the case I missed | 1–2 h per major design |
| **Proof of concept** | Test whether Razorpay webhooks behave as documented; measure pgvector recall | 2–3 h per spike |
| **Assumption testing** | Is p95 really under 200 ms with 10k catalog rows? Measure it | 1–2 h |
| **Failure-mode exploration** | Kill the database mid-checkout. What actually happens? | 2 h per major flow |
| **Human-written code** | IaC, deploy scripts, operational tooling, test cases, quick fixes | Throughout |
| **Exploratory testing** | Use the product like a hostile user | 2 h per sprint |
| **Performance analysis** | Read flame graphs, find the slow query, propose the index | 2–3 h in Sprints 13 and 19 |
| **Security validation** | Try to break your own authorization; attempt IDOR | 3 h in Sprint 13 |
| **Observability validation** | Break things deliberately; confirm alerts fire | 4 h in Sprint 13 |
| **Production operations** | Deploy, monitor, respond, roll back | Sprints 12–14 and ongoing |

**Roughly 30% of your total hours are allocated to analysis, experimentation and operations rather than code review.** That is deliberate. A team that only reviews generated code does not understand its own system.

## 5. When you should write the code yourself

Do not route everything through me. Write it directly when:

- It is faster to type than to describe (a one-line fix, a config tweak)
- It is account-specific, IaC with your resource names, CI secrets
- It is exploratory, a throwaway script to test an assumption
- It is operational, a debugging or maintenance script
- You are learning something and want the reps

**Tell me what you wrote** so I keep it consistent and do not overwrite it. Human-written code goes through the same standards, tests and review as mine.

## 6. Analysis expectations: do not trust me blindly

For every significant output, the expected posture is:

1. **Reasoning review**: does the argument hold? What was assumed?
2. **Architecture review**: does it fit the system? What does it make harder later?
3. **Code review**: correctness, edge cases, error paths
4. **Security analysis**: what would an attacker try?
5. **Performance analysis**: what does this do at 10,000 rows? At 1,000 concurrent users?
6. **Maintainability**: will you understand this in March?

**Copilot** is useful as a second opinion here, ask it to review the diff for bugs, edge cases and security issues. It catches different things than you do. It is a supplement, never a substitute, and no ticket depends on it.

**"That looks wrong because…" is the most valuable sentence you can write.** I would rather be corrected in review than have a subtle bug reach production.

## 7. The cycle

```
I design → you analyse and challenge → I implement → you review
 → you run and test → you experiment → issues found
 → I fix (or you fix) → you re-run → you validate → you approve → done
```

**Expect at least one correction round on most tickets.** That is normal and it is in the estimates. A ticket needing no correction is a pleasant surprise, not the baseline.

## 8. Approval protocol

**Nothing advances automatically.** Not the next day, not the next sprint.

**Approvals that count:** "Proceed with Day 5" · "Approved" · "Go ahead".
**Not approvals:** "Looks good" · "Interesting" · "What do you think?". If ambiguous, I ask.

## 9. Status vocabulary: used precisely

`PLANNED` → `IN PROGRESS` → `READY FOR REVIEW` → `IMPLEMENTED` (code exists, **not proven**) → `TESTED` (automated tests pass) → `VERIFIED` (**you observed it working**) → `DEPLOYED` → `BLOCKED`.

**`IMPLEMENTED` is not `VERIFIED`.** I use the weaker word whenever I have not seen it work, which for anything involving Docker is always.

I will never write "Jira configured", "GitHub environment configured" or "payment integrated" unless it actually happened and you verified it.

## 10. How to report a problem

```
Ticket: NVL-112
Command: make up
Machine: Windows / WSL2
Expected: all services healthy
Actual: api container exits immediately
Output: <paste the FULL error, not a summary>
Tried: make down && make up, same result
```

**Paste full output, not a description.** "It says something about a port" costs a round trip; the actual error usually contains the answer.

## 11. Session shape

**Weekday (1–1.5 h):** 5 min approve → 25 min review → 20 min run and test → 15 min fix cycle → 10 min commit, PR, Jira.

**Weekend (3 h):** as above with a longer build phase, a mid-session integration checkpoint, and a dedicated experimentation or exploratory-testing block.

**Day 14 (3 h, both):** sprint review, retrospective, ADR ratification, **buffer**. Deliberately under-committed.

## 12. What I will not do

Claim external work I could not perform · mark a ticket done with unmet acceptance criteria · invent metrics or outcomes · fake a payment success path or an always-passing test · add a security bypass "just for now" · commit a secret · skip tests to hit a day boundary · advance without your approval.

**If a day's scope will not fit, I say so at the start and propose a cut.**

## 13. The one thing that matters most

**Tell me the truth about your capacity, your understanding and your velocity.**

Everything here, the full multi-sprint plan, rests on estimates. Estimates survive contact with reality only if reality is reported back. I would rather re-plan four times honestly than hold one plan that stopped being true in October.
