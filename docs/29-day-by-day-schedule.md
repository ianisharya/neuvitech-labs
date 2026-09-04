# 29: Day-by-Day Execution Schedule

**Every session, with available hours, owner, tasks and buffer.** Sprint 1 is given in full detail. Sprints 2–20 follow the same session pattern and are detailed at each sprint planning session.

**Session pattern (fixed for all 280 days):**

| Day of sprint | Weekday? | Hours each | Purpose |
|---|---|---|---|
| 1–5 | Mon–Fri | 1.0–1.5 | One focused increment per person |
| **6, 7** | **Sat, Sun** | **3.0** | Major slice; integration checkpoint |
| 8–12 | Mon–Fri | 1.0–1.5 | One focused increment per person |
| **13** | **Sat** | **3.0** | Major slice; experimentation block |
| **14** | **Sun** | **3.0** | **Sprint review, retrospective, buffer** |

---

## SPRINT 1: Environment & Repository Foundation
**Mon 31 Aug → Sun 13 Sep 2026 · 49 h capacity · 32 pts committed · 17 pts buffer (35%)**

### Day 1: Mon 31 Aug · 1.25 h each · 2.5 h team
| Time | You (macOS) | Teammate (Windows) |
|---|---|---|
| 0:00–0:10 | **Both:** confirm licence, package name, track owners, Jira approach | ← |
| 0:10–0:55 | NVL-101.2/3/4 Docker Desktop: download, install, configure 6 GB, verify | **NVL-101.1 WSL2 install + reboot** (45 m) |
| 0:55–1:15 | NVL-101.5 VS Code install | Continue WSL2 setup, UNIX user |
| 1:15–1:25 | NVL-101.9 Confirm GitHub admin holder | Buffer |

**AI:** authors `.devcontainer/`, governance files, `Makefile` in parallel, zero human time.
**Scheduled 2.5 h / available 2.5 h. Windows runs longer; the 30 m troubleshooting buffer in NVL-101.10 absorbs it.**

### Day 2: Tue 1 Sep · 1.25 h each
| You | Teammate |
|---|---|
| NVL-101.6 VS Code extensions (20 m) | NVL-101.2/3/4 Docker Desktop + WSL2 backend (50 m) |
| NVL-101.7 Git config (20 m) | NVL-101.5 VS Code (20 m) |
| NVL-101.8 SSH key → GitHub (25 m) | Buffer |

### Day 3: Wed 2 Sep · 1.25 h each
| You | Teammate |
|---|---|
| NVL-102.3 Clone repo (15 m) | NVL-101.6 Extensions (20 m) · NVL-101.7 Git config in WSL (20 m) |
| NVL-102.4 Review governance files (40 m) | NVL-101.8 SSH key inside WSL (25 m) |
| NVL-102.5 Verify `.env` ignored (10 m) | Buffer |

### Day 4: Thu 3 Sep · 1.25 h each
| You | Teammate |
|---|---|
| NVL-105.1 Create Jira project (30 m) | NVL-102.3 Clone **inside WSL2** (15 m) |
| NVL-105.4 Decide MCP vs CSV (15 m) | NVL-102.4 Review governance files (40 m) |
| Buffer (30 m) | Buffer (20 m) |

### Day 5: Fri 4 Sep · 1.25 h each
| Both |
|---|
| NVL-102.6 First commit, push, PR, joint review, merge (25 m each) |
| NVL-103.2 Review the Dev Container definition; challenge pinned versions (30 m each) |
| Buffer (20 m) |

### Day 6: **Sat 5 Sep · 3 h each · 6 h team**
| Time | Both |
|---|---|
| 0:00–0:15 | Plan; agree what "identical" must mean |
| 0:15–0:50 | **NVL-103.3 Reopen in Container, first build** (mostly waiting; read the log) |
| 0:50–1:05 | NVL-103.4 Verify toolchain versions |
| 1:05–1:50 | **NVL-103.5 Buffer: first-build failures** |
| 1:50–2:20 | NVL-105.2 Import Jira CSVs, create Sprint 1 |
| 2:20–2:50 | NVL-105.3 Add issues, set components, verify board |
| 2:50–3:00 | Day report; approve Day 7 |

### Day 7: **Sun 6 Sep · 3 h each · 6 h team**
| Time | Both |
|---|---|
| 0:00–0:30 | **NVL-104.1 Cross-platform validation**: run identical commands side by side |
| 0:30–0:50 | NVL-104.2 One commits, the other pulls and runs |
| 0:50–1:05 | NVL-104.3 Line-ending check |
| 1:05–1:30 | NVL-104.4 Record divergences; I fix `devcontainer.json` centrally |
| 1:30–2:15 | **Experimentation block:** deliberately break the container, learn the recovery path |
| 2:15–2:45 | NVL-103.6 Document gotchas in the troubleshooting guide |
| 2:45–3:00 | Report; approve Day 8 |

### Days 8–12: Mon 7 – Fri 11 Sep · 1.25 h each
| Day | You | Teammate |
|---|---|---|
| 8 | Review `Makefile` targets; run each (45 m) | NVL-106.2 Enable Actions; review workflow (30 m) |
| 9 | Review `.env.example` contract (30 m) | NVL-106.3 Open PR; watch first CI run (30 m) |
| 10 | Review `docs/` completeness (40 m) | **NVL-106.4 CI failure buffer** (45 m) |
| 11 | NVL-106.5 Branch protection (or **BLOCKED**) (30 m) | Continue CI buffer |
| 12 | NVL-EXT-01 **Begin Razorpay KYC research** (40 m) | Verify branch protection blocks a direct push (20 m) |

### Day 13: **Sat 12 Sep · 3 h each**
| Time | Both |
|---|---|
| 0:00–0:45 | Full clean-clone rehearsal: delete local repo, re-clone, rebuild container, verify |
| 0:45–1:30 | **Experiment:** measure first-build vs cached-build time; document real numbers |
| 1:30–2:15 | Review the entire Sprint 2 plan; challenge the data-layer design **before** it is built |
| 2:15–2:45 | Update `36-troubleshooting-guide.md` with everything hit this sprint |
| 2:45–3:00 | Report |

### Day 14: **Sun 13 Sep · 3 h each, Sprint Review, Retrospective & Buffer**
| Time | Both |
|---|---|
| 0:00–0:45 | **Sprint review:** demonstrate both machines identical; walk the repository |
| 0:45–1:30 | **Retrospective:** what took longer than estimated? Where did time actually go? |
| 1:30–2:00 | Ratify ADR-0001 … ADR-0007 |
| 2:00–2:30 | **Report velocity to me; I re-baseline Sprint 2** |
| 2:30–3:00 | Approve Sprint 2 |

**Sprint 1 totals:** 32 pts committed · 49 h capacity · **17 h buffer**, deliberately large because installation is the least predictable work in the programme.

---

## Sprints 2–20: session pattern

Each sprint follows the same shape. Detailed day plans are produced at sprint planning, when they reflect reality rather than a guess.

| Session | Content |
|---|---|
| Days 1–5 | One increment per person per day. Track A backend, Track B frontend/infra |
| **Day 6** | Major implementation slice + integration checkpoint |
| **Day 7** | Major slice + **experimentation block** (POC, assumption test, failure injection) |
| Days 8–12 | One increment per person per day |
| **Day 13** | Major slice + **exploratory testing block** |
| **Day 14** | Review, retrospective, ADR ratification, **buffer** |

### Sprints with a modified shape

| Sprint | Modification | Why |
|---|---|---|
| **7, Payments** | 36 pts not 42; Days 6, 7 and 13 all on payment integration | External integration, ×2.0 rework multiplier, money at stake |
| **10, Certificates** | **Track swap on Day 1** | Bus factor; both must have touched both halves before launch |
| **11, Infrastructure** | Days 1–5 on cloud provisioning by humans | Account-specific; you write the IaC |
| **13, Hardening** | Days 6, 7, 13 are **failure-injection and load-testing sessions**, human-led | Observability is not done until proven by breaking things |
| **14, Launch** | Day 6 = production deploy; Days 7–13 = **72-hour observation window** with scheduled check-ins | Production is not "done" at deploy |

---

## Capacity rules: enforced

1. **Never schedule more than available hours.** Every day above totals ≤ 2.5 h (weekday) or 6 h (weekend) team time.
2. **Weekdays carry one increment per person.** Context switching costs 5–10 minutes; two tasks in an hour means neither finishes.
3. **Never double a weekday to catch up.** Overflow rolls to the next weekend block or Day 14.
4. **Day 14 is buffer, not capacity.** If it is fully consumed by delivery, the sprint was over-committed and I lower the next one.
5. **Review never precedes implementation. Testing never precedes a ready environment. Integration never precedes configured dependencies.**
6. **No task requires both people's simultaneous attention** except explicitly paired sessions (Day 1, Day 14, integration checkpoints, failure injection).
