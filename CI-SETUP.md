# Continuous Integration Setup

This document covers the pipeline's design and the configuration steps that must be performed in the repository settings.

## What the pipeline enforces

The repository currently contains documentation, configuration, and scripts. Application code, Kubernetes manifests, and container definitions arrive in later sprints.

Rather than defer the pipeline until code exists, or write jobs that pass without verifying anything, each job detects whether its subject is present. If present, it runs. If absent, it reports what it is waiting for and passes. The workflow file does not change when application code lands; the jobs activate on their own.

The following run against the repository as it currently stands.

**Documentation standards.** Prose is checked for emojis and em-dashes, which the documentation standard excludes. Markdown structure is checked for balanced code fences and exactly one top-level heading per document. An unbalanced fence renders the remainder of a document as a code block, which is a silent failure that review frequently misses.

**Architecture decision record consistency.** Every decision record must declare a status, must be listed in the index, and if marked superseded must name its successor. A decision record whose status is unclear, or which is missing from the index, is a record a reader cannot rely on.

**Secret detection.** The full commit history is scanned, not only the most recent commit, because a secret introduced earlier and not yet detected remains exposed regardless of when it entered.

**Repository hygiene.** Tracked files are limited to two megabytes, because large files in git history are retained permanently and downloaded by every clone. Environment files holding real values must not be tracked.

The following activate when their subject exists.

**Architectural guardrails.** Enforces the constraints recorded in the architecture documents. If application code exists but the guardrail script is absent, the job fails rather than skipping, because that combination means enforcement was removed rather than not yet added.

**Python quality.** Lint, format, type checking, and module boundary enforcement. The boundary check verifies that bounded contexts do not import each other's internals, which is the property that makes the modular monolith modular rather than merely co-located.

**Web quality.** Lint, format, and type checking for the presentation application.

**Tests.** Runs against real PostgreSQL and Redis service containers rather than substitutes, because the data layer depends on behaviour those engines provide. Provider interfaces use their in-memory implementations, so tests require no network and no model inference. Migrations are exercised in both directions, because a migration that cannot be reversed is a deployment that cannot be rolled back.

**Kubernetes manifests.** Schema validation against published API schemas, and enforcement of the pod security requirements recorded in ADR-0019: containers do not run as root, privilege escalation is not permitted, images are pinned by digest rather than by mutable tag, and resource requests and limits are declared so that one workload cannot starve another.

**Container image.** Built and scanned for known vulnerabilities on every run. An image that has not been scanned is not promotable.

## The aggregate gate

A single job named "CI passed" depends on every other job. Branch protection requires only that job.

The list of jobs feeding the gate is maintained in the workflow file rather than in repository settings. Adding a job therefore requires no settings change, and a renamed job cannot silently drop out of the required set, which is a common way enforcement degrades over time without anyone noticing.

## Configuration steps

### Enable Actions

In the repository settings, under Actions, then General:

Confirm actions are permitted. Under workflow permissions, select read repository contents. The pipeline requires nothing beyond read access, and least privilege is the appropriate default.

### Observe the first run

The first run occurs on the pull request that introduces the workflow, which means the pipeline is tested against its own introduction.

Open the pull request checks and read each job's log completely, including jobs that pass. This is the one opportunity to observe what the pipeline does before it becomes routine output that is no longer read.

Expected on the current repository: documentation, secrets, and hygiene run and pass. Guardrails, Python, web, tests, manifests, and image report their subject as absent and pass. The aggregate gate confirms all jobs succeeded.

### Handle first-run failures

First runs frequently fail for environmental reasons rather than code defects. Read the complete log of the failing job. A pinned action that cannot be fetched generally indicates a network or permissions condition rather than a workflow error. A secret detection failure means something matching a credential pattern was found, and must be investigated rather than bypassed.

### Configure branch protection

This requires repository administrator access.

Under settings, then branches, add or edit a rule for the main branch. Enable requiring a pull request before merging, with at least one approving review. Enable requiring status checks to pass, and add the check named "CI passed". Enable requiring conversation resolution. Enable requiring linear history. Enable the setting that prevents administrators bypassing these rules, because a protection that administrators can bypass provides no guarantee at the moment it matters.

### Verify the protection is effective

```
git checkout main
git pull
echo "protection test" >> README.md
git commit -am "test: verify branch protection"
git push
```

The push must be rejected. Then discard the test commit:

```
git reset --hard HEAD~1
```

A rejected push confirms the protection is active. A successful push means the rule did not save correctly and must be reconfigured.

## Acceptance criteria

Given a pull request, every job executes and a failing job prevents the merge. Given an attempted direct push to the main branch, the push is rejected. Both conditions must hold.
