# ADR-0006: Single-Repository Monorepo with Enforced Module Boundaries

**Status:** Accepted · **Date:** 2026-08-30

## Context
Two applications (FastAPI API, Next.js web), shared API contracts, infrastructure code and documentation. Two engineers on two parallel tracks that must stay in sync.

## Decision
One repository: `apps/api`, `apps/web`, `packages/contracts`, `infrastructure/`, `docs/`, `scripts/`. Backend module boundaries enforced by `import-linter`; the API contract enforced by generated types with a CI drift check.

## Alternatives Considered
**Separate repositories per app**: rejected. A cross-cutting change (add an API field, consume it in the UI) becomes two PRs in two repos with a coordination problem between them. With two people on two tracks that friction is paid several times a week.
**Monorepo tooling (Nx, Turborepo)**: rejected as premature. Two apps do not need a build orchestrator; `make` and path-filtered CI jobs suffice and are one less thing to learn.

## Consequences
**Positive:** atomic cross-stack changes in one PR · one source of truth for the API contract · shared CI, docs and tooling · **documentation changes in the same PR as the code it describes, so it does not drift** · a new contributor clones one thing.
**Negative:** CI runs more than strictly necessary (mitigated with path filters) · access control is all-or-nothing.

## Cost
Free.

## Security
One place to scan for secrets; Gitleaks covers everything. CODEOWNERS protects `migrations/`, `security/`, `payments/`, `.github/`, `infrastructure/`. Risk: anyone with access sees everything, acceptable at two people; revisit if contractors are added.

## Scalability
Fine to tens of thousands of files. Path-filtered CI keeps runtimes low.

## Migration Path
Splitting later is straightforward with `git filter-repo`, preserving history.

## Revisit Trigger
More than ~6 developers with divergent release cadence · a need for different access levels per application · CI runtimes above 15 minutes despite path filtering.
