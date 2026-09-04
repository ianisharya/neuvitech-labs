# 17: Engineering Workflow

The lifecycle of every feature, from idea to production.

## 1. The workflow

```
UNDERSTAND → DESIGN → IMPLEMENT → ANALYSE → EXPERIMENT → TEST
 → REVIEW → MODIFY → INTEGRATE → VALIDATE → DEPLOY → OBSERVE → HARDEN → RELEASE
```

Not every feature needs every stage at full depth. A copy change skips experimentation; a payment integration gets all of it twice.

## 2. Stage by stage

| Stage | Who | What happens | Output |
|---|---|---|---|
| **Understand** | AI + Human | Restate the requirement, identify affected modules, list unknowns | Ticket description with acceptance criteria |
| **Design** | AI lead | Data model, API contract, authorization, failure modes, migration plan | Design note in the ticket; ADR if architectural |
| **Analyse** (pre-build) | **Human** | Challenge the design. What was assumed? What breaks at scale? | Approval or redirection |
| **Implement** | **AI** | Code, tests, migrations, config, docs | Branch + PR |
| **Analyse** (post-build) | **Human** | Read the code. Correctness, security, performance, edge cases | Review comments |
| **Experiment** | **Human** | POC, assumption test, failure injection, alternative approach | Findings, sometimes a design change |
| **Test** | Both | Automated suite; manual and exploratory testing | Test results, bug list |
| **Modify** | AI or Human | Fix findings. Human-written code is welcome here | Updated PR |
| **Integrate** | Both | Merge, resolve conflicts, regenerate contracts, run full suite | Green `main` |
| **Validate** | **Human** | Verify acceptance criteria against the running system | Acceptance |
| **Deploy** | **Human** | Merge → DEV → QA → PROD | Deployed artefact |
| **Observe** | **Human** | Dashboards, logs, traces, error rate after deploy | Confirmation or incident |
| **Harden** | Both | Fix what observation revealed; add missing tests and alerts | Improvements |
| **Release** | **Human** | Tag, changelog, feature flag on | Release notes |

## 3. Variations by work type

**Database schema change:** Design → **human reviews the migration before it runs anywhere** → implement → test upgrade AND downgrade → apply locally → verify → PR → CI runs both directions → merge → DEV → verify → QA → PROD (expand phase) → later release (contract phase).

**External integration (payments, Zoom, LLM):** **Spike first**: human tests the real API and documents actual behaviour, which routinely differs from the docs → design against observed behaviour → implement with the provider protocol → test against sandbox → **failure-mode testing (timeouts, malformed responses, outages)** → integrate → validate → deploy → observe closely. Rework multiplier **×2.0** applies here.

**Frontend feature:** Design (states first, including empty and error) → implement → **human checks keyboard navigation, screen reader, mobile at 320px, dark mode** → axe → visual regression → Lighthouse → review → merge.

**Infrastructure change:** Design → **human writes or heavily modifies the IaC** (account-specific) → plan → review the plan output → apply to DEV → verify → apply to QA → verify → apply to PROD → observe.

## 4. Definition of Ready (before work starts)

- Requirement restated in the ticket, with the "why"
- Acceptance criteria in Given/When/Then, and testable
- Dependencies identified and resolved or explicitly accepted
- Design reviewed by at least one human
- Test approach agreed
- Estimated in points (1 point = 1 hour of one person's time)
- Owner and track assigned
- Security impact assessed
- **Both of you can explain what is being built.** If either cannot, it is not Ready

## 5. Definition of Done (before a ticket closes)

**Implementation**: acceptance criteria demonstrated, not asserted · standards followed · no TODO without a ticket · errors handled.
**Tests**: unit, integration where data is involved, failure paths, coverage gate met, **passing in CI**.
**Security**: authorization enforced, input validated, ownership filtered in the query, no secrets, Gitleaks clean.
**Data**: migration reversible and tested both directions, indexes considered.
**Human validation**: code reviewed by the other track, **run and manually verified**, exploratory testing where user-facing.
**Observability**: logs emitted, metrics exposed, alert added if it can fail in production, runbook written.
**Documentation**: API, schema, `.env.example`, ADR if architectural.
**Tracking**: Jira transitioned, commits carry the key, PR links the issue.

## 6. Higher bar for high-consequence work

Payments, entitlements, authorization and certificates additionally require: concurrency tested where races are possible · idempotency tested · forged and replayed input tested · rollback path tested · audit entry verified · **both of you read the code**, not one author and one skimmer · the relevant scenario from `09-commerce-and-entitlements.md` §9 covered by an automated test.

## 7. The honesty check

Before writing "done": Did I **see** it work, or do I believe it works? · Would it survive a hostile user? · If this breaks at 2am, is there a runbook? · Can the other person maintain this without asking me? · Have I claimed anything I did not verify?

If any answer is uncomfortable, it is not done.
