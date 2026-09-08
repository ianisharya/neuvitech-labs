# CI Pipeline Implementation Log

This document records what the continuous integration pipeline consists of, file by file, and the exact sequence of failures and fixes encountered while bringing the first pull request through it. It is a companion to CI-SETUP.md, which covers configuration steps to be performed in repository settings. This document covers what was built and why each part exists.

## Repository layout

```
.github/
  workflows/
    ci.yml                       the pipeline definition
  pull_request_template.md       pull request description template
  ISSUE_TEMPLATE/
    bug_report.md                bug report template
    config.yml                   issue template configuration

scripts/
  ci/
    check_prose.sh               documentation prose standard
    check_markdown.sh            markdown structural validity
    check_adrs.sh                architecture decision record consistency
    check_file_sizes.sh          repository file size limits
    check_env_handling.sh        environment file tracking rules
    check_manifests.sh           kubernetes manifest schema validation
    check_pod_security.sh        kubernetes pod security requirements

CI-SETUP.md                      configuration steps and acceptance criteria
```

## Design principle: detection before execution

The repository at the time this pipeline was written contains documentation, configuration, and scripts. Application code, Kubernetes manifests, and a container image definition do not yet exist.

A pipeline written to assume those things exist would fail immediately for a reason unrelated to any actual defect. A pipeline that omits jobs for them until they exist would need to be rewritten later, at the point when a rewrite is least convenient.

The approach taken instead: every job whose subject may not yet exist begins with a detection step. If the subject is present, the job runs its checks. If the subject is absent, the job states what it is waiting for and exits successfully. The workflow file does not change when application code, manifests, or a Dockerfile are added. The corresponding job activates on its own.

Jobs whose subject already exists, documentation, secrets, and repository hygiene, run without a detection step, because their subject is the repository itself.

## The workflow file: .github/workflows/ci.yml

Ten jobs. Each is described below with its purpose, its trigger condition if it is guarded, and what it checks.

### documentation

Runs unconditionally. Executes check_prose.sh, check_markdown.sh, and check_adrs.sh in sequence. Any failure blocks the job.

### secrets

Runs unconditionally. Checks out the full commit history, not only the latest commit, because a secret introduced earlier and not yet detected remains exposed regardless of when it entered. Runs gitleaks-action, pinned to commit 83373cf2f8c4db6e24b41c1a9b086bb9619e9cd3, corresponding to v2.3.9.

This job carries a job-level permissions override, described in the implementation history section below, granting contents: read and pull-requests: read. Every other job in the workflow uses the workflow-level default of contents: read only.

### hygiene

Runs unconditionally. Executes check_file_sizes.sh and check_env_handling.sh.

### guardrails

Detects the presence of an apps/ directory. If absent, the job passes and states that guardrail enforcement begins when application code is created. If apps/ is present but scripts/check_guardrails.py is not, the job fails, because that combination indicates enforcement was removed rather than not yet added. If both are present, the guardrail script is run against apps/.

### python

Detects apps/api/pyproject.toml. If present, installs dependencies with uv, then runs ruff check, ruff format --check, mypy, and an import boundary check confirming that bounded contexts do not import each other's internals. The boundary check looks for an import-linter configuration and fails if application code exists without one, on the same reasoning as the guardrails job: the constraint must be enforced, not merely intended.

### web

Detects apps/web/package.json. If present, installs dependencies with npm, then runs eslint, a prettier format check, and a TypeScript type check.

### tests

Runs PostgreSQL and Redis as service containers, both pinned by image digest rather than by tag. Detects apps/api/tests. If present, applies database migrations, reverses them, and reapplies them, confirming that every migration is reversible before running the test suite with coverage reporting. Provider interfaces for external systems such as model inference use their in-memory implementations in this job, so the test suite requires no network access and no running model.

### manifests

Detects a Kubernetes manifest directory at infrastructure/kubernetes or deploy. If present, runs check_manifests.sh.

### image

Detects a Dockerfile at infrastructure/docker/api.Dockerfile or at the repository root. If present, builds an image tagged with the commit SHA, then scans it with trivy-action for HIGH and CRITICAL severity vulnerabilities. A vulnerability at either severity fails the job.

### ci-passed

Depends on all nine jobs above. Runs regardless of their outcome, evaluates whether any failed or were cancelled, and fails if so. This is the single check configured as required in branch protection. The list of jobs it depends on is maintained in this file rather than in repository settings, so that adding a job requires no settings change and a renamed job cannot silently leave the required set.

## The check scripts

### check_prose.sh

Scans every tracked Markdown file for the Unicode em-dash character and for characters in several emoji code point ranges. Unicode matching is performed in Python rather than shell pattern matching, because shell handling of multibyte characters is inconsistent across platforms. Reports every file containing either and fails if any are found.

### check_markdown.sh

Scans every tracked Markdown file for two structural properties: that the number of triple-backtick code fence lines is even, meaning every opened code block is closed, and that at least one line beginning with a single hash and a space is present, meaning the document has a top-level heading.

The check originally required exactly one such heading per file. This was found to be incorrect for documents that use the hash heading style for section markers throughout rather than reserving it for the title alone, and was corrected to require presence rather than uniqueness. This correction is described in the implementation history section below.

### check_adrs.sh

Reads every file matching ADR-*.md in docs/adr. For each, confirms a line matching the pattern Status: followed by text is present. If that status text contains the word superseded, confirms an ADR number is also named in the same line, on the basis that a superseded record with no stated successor is not useful to a reader. Confirms every ADR number found is also referenced in docs/adr/README.md.

### check_file_sizes.sh

Lists every file tracked by git and fails if any exceeds two megabytes. The limit exists because large files committed to git history are retained permanently and downloaded by every future clone.

### check_env_handling.sh

Lists every file tracked by git and fails if any matches a pattern for an environment file holding real values, such as .env or .env.production, while explicitly permitting .env.example. Notes, without failing, if .env.example is absent.

### check_manifests.sh

Detects a Kubernetes manifest directory at infrastructure/kubernetes or deploy. If found, downloads kubeconform and validates every YAML file in that directory against published Kubernetes API schemas, using strict mode, which rejects fields not defined in the schema. This catches structural errors, such as a misspelled field name, before a manifest reaches a cluster.

### check_pod_security.sh

Detects a Kubernetes manifest directory. If found, parses every YAML document, identifies workload kinds (Deployment, StatefulSet, DaemonSet, Job, CronJob), and for each checks four conditions on the pod template: that the pod security context sets runAsNonRoot to true, that every container's security context sets allowPrivilegeEscalation to false, that every container image reference includes a sha256 digest rather than only a tag, and that every container declares both resource requests and resource limits. A failure on any condition names the file, the workload, and the container.

## CI-SETUP.md

Covers configuration steps performed outside the workflow file: enabling GitHub Actions in repository settings, observing the first pipeline run, handling first-run failures, configuring branch protection to require the ci-passed check with pull requests and administrator bypass prevention both enabled, and verifying that protection is effective by attempting and observing the rejection of a direct push to the main branch.

## Implementation history

This section records the failures encountered when the pipeline was first run against a real pull request, in the order they occurred, with the cause and the fix applied for each.

### First pipeline run

Three jobs failed.

**secrets.** gitleaks-action reported that GITHUB_TOKEN is required to scan pull requests, describing this as a recent change in the action's own behavior. The workflow did not supply this variable to the step.

**documentation.** check_markdown.sh reported eight files as having more than one top-level heading, and two files as having none. The eight were documents that use the hash heading style for section markers by design, which the check's original rule, requiring exactly one such heading, did not account for. The two were .github/pull_request_template.md and .github/ISSUE_TEMPLATE/bug_report.md, which had no top-level heading of any kind.

**image.** The job referenced aquasecurity/setup-trivy@v0.2.2. This action and version do not exist. GitHub Actions reported it as unable to resolve.

### First fix

Applied to address all three failures from the first run.

In the secrets job, added GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }} to the step's environment.

In check_markdown.sh, removed the rule rejecting more than one top-level heading, retaining only the rule requiring at least one.

In .github/pull_request_template.md, added a top-level heading as the first line of the file.

In .github/ISSUE_TEMPLATE/bug_report.md, added a top-level heading immediately after the closing line of the YAML frontmatter block. The heading was placed after the frontmatter rather than before it, because inserting content before the opening frontmatter delimiter would have prevented GitHub from parsing the file's issue template metadata.

In the image job, replaced the nonexistent action reference with aquasecurity/trivy-action, using the version tag 0.28.0 as an interim value pending verification of a specific commit.

### Second pipeline run

One job failed, with a different and more specific error than before.

**secrets.** The step now received the token, and gitleaks-action proceeded to call the GitHub API to list commits on the pull request, which it uses to determine the boundary of an incremental scan. This call returned an HTTP 403 response with the message Resource not accessible by integration. The response headers included x-accepted-github-permissions: pull_requests=read, identifying the specific scope the supplied token lacked.

The cause was the workflow-level permissions block, which grants only contents: read to every job by default. This is sufficient for checking out and reading repository content but not for the pull request metadata endpoint gitleaks-action calls in this mode.

### Second fix

Two changes were made.

The interim trivy-action version tag was replaced with a specific commit digest. The commit was identified by retrieving the GitHub release page for aquasecurity/trivy-action version v0.35.0 directly, where GitHub displays the commit associated with the release along with a verification indicator. The identified commit is 57a97c7e7821a5776cebc9bb87c984fa69cba8f1. The same release's notes stated that an earlier tag naming convention for this action had been affected by a supply chain incident and that tags using a v prefix, including this one, were confirmed unaffected. This was the basis for pinning to a specific verified commit rather than continuing to reference a version tag.

A job-level permissions override was added to the secrets job specifically, granting contents: read and pull-requests: read. This override applies only to that job. The workflow-level default of contents: read remains unchanged for the other nine jobs, none of which call an API endpoint requiring a broader scope.

### Outcome of the second fix

Not yet confirmed by a subsequent pipeline run at the time this document was written. The next run against the same pull request is expected to indicate whether both changes resolved the remaining failure.

### Third round: Node.js 20 removal and action pin currency

This round began from an external claim rather than a pipeline failure. The claim stated that GitHub was removing Node.js 20 from Actions runners on September 23, and that several actions pinned in this workflow, being old commits, could stop functioning on that date with no code change made in this repository.

The claim was verified rather than accepted or dismissed. GitHub's own workflow log text, retrieved directly, states that actions have been forced to run under Node.js 24 by default since June 2, and that Node.js 20 is removed from the runner entirely on September 16. The date in the original claim was incorrect by one week.

The reasoning that every old pin was therefore an equal risk was found to be too broad. Two of the six actions pinned in this workflow, actions/checkout and gitleaks/gitleaks-action, had already been observed executing successfully under the forced Node 24 default, directly, in this repository's own first and second pipeline runs. The Node 20 deprecation warning appeared in both logs immediately before each of those steps completed and reached an unrelated, later error. This is evidence that those two pins already function correctly under Node 24, not an inference about them.

The remaining four pinned actions were checked individually against each project's own release history, rather than assumed safe or unsafe based on the age of the commit alone.

aquasecurity/trivy-action had already been corrected in the second round of this log, to v0.35.0, and required no further change.

actions/setup-python was pinned to v5.3.0. Retrieving the project's releases page directly showed that native Node 24 support was introduced in v6.0.0, one major version after the pinned release, and that v6.2.0 was the current latest release at the time of the check, marked as such on the page and carrying a GitHub-verified commit signature.

actions/setup-node was pinned to v4.1.0. Retrieving the project's releases page directly showed that native Node 24 support was introduced in v5.0.0, three major versions after the pinned release, and that v7.0.0 was the current latest release at the time of the check, marked as such on the page and carrying a GitHub-verified commit signature.

astral-sh/setup-uv was pinned to v5.1.0. The project's release notes showed that native Node 24 support was introduced in v7.0.0, two major versions after the pinned release. The corrected pin, v10.0.1, was sourced from the maintainer's current marketplace listing, which displays this exact commit as the maintainer's own usage example, rather than from an independent fetch of the releases page as was done for the two actions above. This distinction in evidence is recorded because it is a different, though still first-party, standard of confirmation. The same maintainer's release notes state that the project moved from tag-based to commit-based pinning specifically in response to a supply chain incident affecting a different, widely used action, the same category of incident already noted in the second round regarding aquasecurity/trivy-action.

Three pins were corrected: actions/setup-python to v6.2.0, actions/setup-node to v7.0.0, and astral-sh/setup-uv to v10.0.1. Each was corrected at every occurrence in the workflow file rather than only the first. actions/setup-python appeared in three job definitions, astral-sh/setup-uv appeared in two, and actions/setup-node appeared in one.

Following these corrections, every file previously produced over the course of this project was searched for the three superseded commit references. None were found outside the workflow file, and no other document was found to embed a literal action pin. No file beyond the workflow required correction as a result of this round.

### Outcome of the third round

Not yet confirmed by a subsequent pipeline run at the time this document was written.

## A recurring log message, explained once

Both pipeline runs described in the first two rounds included a warning from GitHub Actions stating that Node.js 20 is deprecated and that the workflow is running with Node.js 24 by default. This originates from within gitleaks-action's own bundled runtime declaration at the pinned commit, not from any configuration in this repository, and did not cause either run to fail. The underlying deadline this warning refers to is real and is addressed in the third round above. The warning itself, on its own, was never a failure.
