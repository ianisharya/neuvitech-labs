# ADR-0012: Trunk-Based Git with Environment Promotion, over GitFlow

**Status:** Accepted · **Date:** Sprint 2

## Context

Two engineers, one repository, needing a branching and release model that supports continuous integration into a protected `main`, safe rollback, and environment promotion (DEV → QA → PROD, `docs/13`) without introducing coordination overhead disproportionate to team size.

## Decision

Trunk-based development: a protected `main`, short-lived feature branches, no long-lived `develop` branch, incomplete work merged behind feature flags rather than kept on long branches (`docs/05` §6, `docs/19`).

## Alternatives Considered

**GitFlow** (`develop`, `release/*`, `hotfix/*`, `feature/*` branches with a formal release-branch cutover). Rejected. GitFlow's value proposition is coordinating multiple parallel release trains and staged release candidates, genuinely useful when several versions are in flight or a release needs a stabilisation window independent of ongoing development. We have neither: one deployable artefact, promoted unchanged through environments (`docs/13` §2), with no parallel release trains to coordinate. Adopting GitFlow's structure would mean merge conflicts between `develop` and `main` diverging, and CI running twice against near-duplicate branches, in exchange for coordination machinery that solves a problem we do not have.

**GitHub Flow (branch, PR, merge to `main`, deploy) without feature flags.** A closer contender, and largely what we do, but rejected as insufficient on its own, because without feature flags, incomplete work either sits on a long-lived branch (reintroducing merge-conflict risk) or gets merged half-finished. Feature flags are the piece that makes true trunk-based development safe: incomplete work merges to `main` disabled, decoupling "merged" from "released."

**A long-lived branch per environment (`main`, `qa`, `production`), each promoted by merge.** Rejected. This conflates "which commit is where" with "which branch represents an environment," and makes it easy for environment branches to drift from each other in ways a single promoted-image model (`docs/13` §2, one image, tagged by commit SHA, promoted unchanged) does not allow.

## Consequences

**Positive:** `main` is always close to what is actually running or about to run, since nothing sits unreleased on a long branch · environment promotion (`docs/13`) maps cleanly onto "this commit SHA, this image, promoted through DEV → QA → PROD" without a parallel branch structure to keep in sync · rollback is a redeploy of the previous image tag or a feature flag toggle, not a branch-management exercise (`docs/21` §5).

**Negative:** requires discipline around feature flags for anything genuinely incomplete, the safety trunk-based development provides depends on that discipline being followed, not on the branching model alone · no built-in concept of a "release candidate" branch for a formal stabilisation window, which would need to be added deliberately if a future release ever needs one.

## Trade-offs

We give up GitFlow's built-in support for coordinating multiple release trains, in exchange for a model that matches our actual deployment reality, one artefact, promoted through environments, and removes an entire category of branch-synchronisation problems that would exist for no benefit at our current scale and team size.

## Cost

No additional tooling, GitHub's native branch protection and Environments features (`docs/21` §3) provide everything this model needs.

## Security

Branch protection on `main` (`docs/19` §2), required PR, required approval from the other track, required status checks, no direct pushes, is the actual security control here, independent of which branching model sits underneath it. CODEOWNERS gates review on the highest-consequence paths (migrations, security, payments, infrastructure).

## Scalability

Scales to more engineers without structural change, more branches, more PRs, same model. Would need revisiting only if genuine parallel release trains became necessary.

## Migration Path

Moving to GitFlow later, if a future need for parallel release trains genuinely emerges, means introducing a `develop` branch and release-branch discipline on top of the existing history, an additive change, not a rewrite of what exists.

## Revisit Trigger

A genuine need for multiple release trains in flight simultaneously (e.g., supporting an old major version while developing a new one) → revisit GitFlow or a release-branch model. Feature-flag discipline consistently breaking down in practice → revisit whether longer-lived branches are actually safer for this team than the theory suggests.
