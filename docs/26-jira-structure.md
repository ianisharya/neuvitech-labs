# 26: Jira Structure & Workflow

**Status: workflow spec confirmed from source screenshots (31 Aug 2026).** Supersedes the earlier provisional version.

## Project

| | |
|---|---|
| Site | `neuvitech-labs.atlassian.net` |
| Name | NeuViTech Labs |
| Key | **`SCRUM`**: should be changed to `NVL` (see §6) |
| Type | Team-managed software (`simplified: true`) |
| Project ID | 10000 |

---

## 1. The workflow: WM Unified User / Technical Story

Sixteen states. Modelled on the reference workflow supplied 31 Aug 2026.

### States and categories

| # | Status | Category | Meaning |
|---|---|---|---|
| 1 | **OPEN** | To Do | Created, not yet triaged |
| 2 | **ANALYSIS** | In Progress | Requirement being understood; unknowns identified |
| 3 | **REFINEMENT** | In Progress | Design reviewed and challenged; acceptance criteria written |
| 4 | **READY FOR DEV** | To Do | Meets Definition of Ready |
| 5 | **IN DEVELOPMENT** | In Progress | AI implementing |
| 6 | **IN CODE REVIEW** | In Progress | Human review by the other track |
| 7 | **DEV-TEST COMPLETE** | In Progress | Tests pass; developer-verified |
| 8 | **READY FOR QA** | To Do | Handed to functional testing |
| 9 | **QA FUNCTIONAL TESTING** | In Progress | Manual and exploratory testing |
| 10 | **READY FOR UAT** | To Do | QA passed |
| 11 | **UAT FUNCTIONAL TESTING** | In Progress | Acceptance testing |
| 12 | **RELEASE VALIDATION** | In Progress | Pre-release verification |
| 13 | **READY FOR PRD** | To Do | Approved for production |
| 14 | **CLOSED** | **Done** | Deployed and accepted |
| 15 | **ON HOLD** | To Do | Paused. Reachable from **any** status |
| 16 | **CANCELLED** | **Done** | Abandoned. Reachable from **any** status |

**Only CLOSED and CANCELLED are `Done`.** Everything else is To Do or In Progress. Getting this wrong corrupts every burndown chart and velocity number, an issue in a `Done`-category status counts as completed work whether or not it is finished.

### Transitions

**Forward path**
```
START → OPEN → ANALYSIS → REFINEMENT → READY FOR DEV → IN DEVELOPMENT
 → IN CODE REVIEW → DEV-TEST COMPLETE → READY FOR QA
 → QA FUNCTIONAL TESTING → READY FOR UAT → UAT FUNCTIONAL TESTING
 → RELEASE VALIDATION → READY FOR PRD → CLOSED
```

**Rework loops**: the transitions that make the workflow honest rather than decorative:

| From | To | When |
|---|---|---|
| IN CODE REVIEW | IN DEVELOPMENT | Review findings need fixing |
| QA FUNCTIONAL TESTING | IN DEVELOPMENT | Functional defect found |
| UAT FUNCTIONAL TESTING | IN DEVELOPMENT | Acceptance defect found |
| RELEASE VALIDATION | IN DEVELOPMENT | Validation failure |
| DEV-TEST COMPLETE | RELEASE VALIDATION | Fast path, skips QA/UAT for low-risk change |
| ANALYSIS | OPEN | Requirement not ready |
| REFINEMENT | ANALYSIS | Needs more analysis |

**Global transitions**: available from **any** status:
- **→ ON HOLD** (and back to the originating status)
- **→ CANCELLED**

---

## 2. Which states we actually use, by sprint

The full sixteen-state path assumes separate QA, UAT and release teams. We are two engineers who are also the QA team, the UAT team and the release team.

| Sprint | Path used | Why |
|---|---|---|
| **1–11** | OPEN → ANALYSIS → REFINEMENT → READY FOR DEV → IN DEVELOPMENT → IN CODE REVIEW → DEV-TEST COMPLETE → CLOSED | No deployed environment exists to test against |
| **12–14** | Full path including READY FOR QA, QA FUNCTIONAL TESTING, READY FOR UAT, UAT FUNCTIONAL TESTING, RELEASE VALIDATION, READY FOR PRD | Real environments, real UAT, real production |
| **15–20** | Full path | Steady state |

**The states exist from day one; we grow into them.** Configuring the full workflow now and using a subset is correct, it means no workflow migration at Sprint 12, which is exactly when you least want to be reconfiguring Jira.

What is *not* correct is moving an issue through six states in one sitting to satisfy the diagram. If DEV-TEST COMPLETE and READY FOR QA happen in the same five minutes with no environment between them, the second transition carries no information. Skip it and say so.

---

## 3. Mapping to the engineering workflow

| Engineering stage (`docs/17`) | Jira status |
|---|---|
| Understand | ANALYSIS |
| Design + human analysis | REFINEMENT |
|, Definition of Ready met, | READY FOR DEV |
| Implement | IN DEVELOPMENT |
| Analyse, review | IN CODE REVIEW |
| Test | DEV-TEST COMPLETE |
| Experiment, manual testing | QA FUNCTIONAL TESTING |
| Validate | UAT FUNCTIONAL TESTING |
| Deploy, observe | RELEASE VALIDATION |
| Harden, release | READY FOR PRD → CLOSED |

---

## 4. Automation rules to configure

| Trigger | Action |
|---|---|
| Branch created matching the issue key | → IN DEVELOPMENT |
| Pull request opened | → IN CODE REVIEW |
| Pull request merged and CI green | → DEV-TEST COMPLETE |
| Deployed to QA environment | → READY FOR QA |
| Deployed to production | → CLOSED |

Automation is what stops the workflow becoming manual bookkeeping that nobody keeps current.

---

## 5. Issue types and hierarchy

```
Epic NVL-E01 … NVL-E23
└── Story user-facing or engineering outcome
 └── Task a unit of work within a story
 └── Subtask a single executable action
```

Also: `Bug`, `Spike` (time-boxed investigation, Sprint 6 payment provider, Sprint 15 EMI).

**Smallest useful decomposition.** A subtask is something one person does in one sitting. Not every shell command earns a ticket; equally, "set up environment" as a single ticket hides real work.

---

## 6. Outstanding configuration

| # | Item | Why it matters |
|---|---|---|
| 1 | **Change project key `SCRUM` → `NVL`** | Every document, both CSVs, the guardrail script and the commit convention reference `NVL-`. Team-managed projects rename all issue keys automatically and keep redirects |
| ~~2~~ | ~~Fix `BLOCKED` status category~~ | **Resolved, confirmed 3 Sep 2026.** No status literally named `BLOCKED` remains in the live workflow, checked directly via API on two separate tickets. `ON HOLD` (To Do category) now covers pause semantics; `Cancelled` (Done category) covers abandonment. Both correctly categorised |
| 3 | Delete `SCRUM-4`, `SCRUM-5` | Jira onboarding samples |
| 4 | Create Sprint 1: 31 Aug – 13 Sep 2026 | |
| 5 | Custom fields | `Owner Type` · `AI Effort (h)` · `Human Effort (h)` · `Waiting Time (h)` · `Security Impact` · `Requires Migration` · `Sprint Day` |

### Note on plan IDs versus Jira keys

Jira numbers issues sequentially, so `NVL-101` in the plan is `SCRUM-8` in Jira, and will be `NVL-8` after the key change. **The plan ID is carried in each summary** (`NVL-101 · …`), so traceability works both ways: search `summary ~ "NVL-101"`.

---

## 7. Traceability

```
Plan ID NVL-101 → Jira SCRUM-8 → branch feature/NVL-101-slug
 → commits "chore: NVL-101 …" → PR → CI → DEV → QA → PROD → release tag
```

Enforced by a commit-msg hook and a CI check.
