# 34: Definition of Ready & Definition of Done

## Definition of Ready: before work starts

- [ ] Requirement restated in the ticket, with the "why"
- [ ] Acceptance criteria in **Given/When/Then**, and testable
- [ ] Dependencies identified, resolved or explicitly accepted
- [ ] **Design reviewed and challenged by at least one human**
- [ ] Test approach agreed
- [ ] Estimated in points (1 point = 1 hour of one person's time)
- [ ] Owner and track assigned
- [ ] Security impact assessed (None/Low/Medium/High)
- [ ] "Requires migration" answered
- [ ] Required software installed and verified (`22-software-installation-matrix.md`)
- [ ] **Both engineers can explain what is being built**: if either cannot, it is not Ready

## Definition of Done: before a ticket closes

### Implementation
- [ ] All acceptance criteria **demonstrated, not asserted**
- [ ] Follows `18-engineering-standards.md`
- [ ] No `TODO`/`FIXME` without a linked ticket · no commented-out code · no debug output
- [ ] Errors handled; nothing fails silently
- [ ] **Nothing hard-coded** that belongs in settings

### Tests
- [ ] Unit tests for logic and branches
- [ ] Integration tests where a database or Redis is involved
- [ ] **Failure paths tested, not only the happy path**
- [ ] Coverage gate met (85% commerce/payments/entitlement/credential/security, 70% elsewhere)
- [ ] **All tests pass in CI**, not merely locally

### Human validation
- [ ] Code reviewed by the other track, **substantively**: a reviewer who cannot explain the change has not reviewed it
- [ ] **Run and manually verified** on at least one machine
- [ ] Exploratory testing done where user-facing
- [ ] Cross-platform verified at milestones

### Security
- [ ] Authorization enforced (permission declared or explicitly `@public`)
- [ ] Input validated at the boundary
- [ ] **Ownership filtered inside the query**, not after fetching
- [ ] No secret in code, config or logs; Gitleaks clean

### Data
- [ ] Migration reversible, or documented as irreversible with a rollback runbook
- [ ] **Tested `upgrade` AND `downgrade` in CI**
- [ ] Indexes considered for new query paths

### Observability
- [ ] Structured logs emitted for business events
- [ ] Metrics exposed where measurable
- [ ] **Alert added if this can fail in production, with a runbook**
- [ ] Traces cover the new path

### Documentation
- [ ] API changes in `docs/api/` · schema changes in `docs/database/`
- [ ] New settings documented in `setting_definition`
- [ ] ADR written if the decision is architectural

### Tracking
- [ ] Jira transitioned (or **BLOCKED** reported with the reason)
- [ ] Commits carry the `NVL-` key · PR links the issue

## Higher bar: payments, entitlements, authorization, certificates

- [ ] **Concurrency tested** where races are possible
- [ ] **Idempotency tested**: the same request twice produces one effect
- [ ] **Forged and replayed input tested**
- [ ] Failure and rollback paths tested
- [ ] Audit entry written and verified
- [ ] **Both engineers have read the code**: not one author and one skimmer
- [ ] The relevant scenario from `09-commerce-and-entitlements.md` §9 is an automated test

## Definition of Done: sprint

- [ ] Sprint goal met, or the gap explicitly stated
- [ ] Every committed ticket Done, or moved with a reason
- [ ] **Working software demonstrated, run it, do not describe it**
- [ ] Full suite green in CI · deployed to DEV and smoke-tested
- [ ] No known security issue open
- [ ] Technical debt recorded as tickets, not memory
- [ ] ADRs ratified · retrospective held · **velocity reported to me**
- [ ] Next sprint's tickets meet Definition of Ready

## Definition of Done: project

The project is complete only when **all** of these are true:

- [ ] Implementation complete across Phases A–D
- [ ] **Human-written contributions integrated**
- [ ] Code analysed, not merely accepted
- [ ] **Experiments completed**: assumptions tested, not assumed
- [ ] All automated tests pass
- [ ] Integration works end to end
- [ ] **Both environments validated**: macOS and Windows
- [ ] CI/CD proven end to end, including a **successful rollback**
- [ ] Production deployment complete
- [ ] **Observability works and every alert was proven by deliberate failure injection**
- [ ] Security requirements satisfied; adversarial testing done
- [ ] **Backup restore and disaster recovery rehearsed**, RPO/RTO measured
- [ ] Documentation complete and validated by someone following it
- [ ] Production validation complete
- [ ] **72-hour post-deployment observation window closed clean**
- [ ] All critical and high issues resolved
- [ ] Production readiness checklist fully ticked
- [ ] Both engineers give final acceptance

## The honesty check

Before writing "done": Did I **see** it work, or do I believe it works? · Would it survive a hostile user? · If this breaks at 2am, is there a runbook? · Can the other person maintain this without asking me? · **Have I claimed anything I did not verify?**

If any answer is uncomfortable, it is not done.
