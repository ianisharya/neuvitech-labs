# Contributing to NeuViTech Labs

This document is how we build. It exists so that any engineer, on their first day or their four hundredth, can contribute in a way the rest of the team recognises without anyone having to explain it in person. Read it before your first change. It takes about fifteen minutes and it saves far more than that in review cycles.

The standards here are not bureaucracy. Each one exists because its absence causes a specific, real problem, and where that is not obvious the reason is stated. If a rule ever seems to be getting in the way of good work rather than protecting it, raise it, because a rule nobody understands is a rule that gets worked around.

## Before you write anything

Read three documents first. `docs/37-onboarding-guide.md` takes you from nothing to your first change. `docs/18-engineering-standards.md` is the code-level conventions. `docs/16-collaboration-model.md` explains who does what across the team. Together they are about an hour, and they are faster than learning the same things through rejected pull requests.

Then make sure you understand the ticket you are working on. If you cannot explain in a sentence what the change is meant to achieve and how you will know it worked, the ticket is not ready and you should say so rather than start coding.

## The engineering loop

Every change moves through the same loop, described in full in `docs/17-engineering-workflow.md`. In short: understand the requirement, design the approach, implement it, analyse it critically, test it, have it reviewed, integrate it, validate it against the running system, and only then consider it done. Expect at least one round of correction on most changes. That is normal and it is built into the estimates. A change that needs no correction is a pleasant surprise, not the baseline you are failing to meet.

## Branches

Create one branch per ticket, named for the ticket and a short description of the work:

```
feature/NVL-123-catalog-type-registry
fix/NVL-145-coupon-race-condition
chore/NVL-160-bump-dependencies
hotfix/NVL-201-webhook-signature-verification
```

The prefix matches the kind of work, using the same vocabulary as the commit types described below. One branch belongs to one person for one ticket. Two people never share a branch, because a shared branch is a merge conflict waiting to happen with a countdown timer attached. Pull from the main branch frequently, because a branch that lives alone for three days drifts far enough to make merging painful.

Work that is genuinely incomplete does not sit on a long-lived branch. It merges to the main branch disabled behind a feature flag, as described in `docs/05-configuration-architecture.md`. This is what lets the whole team integrate continuously without shipping half-finished features to learners, and it is why the branching model is trunk-based rather than a web of long branches.

## Commits

Every commit message follows this exact shape:

```
type(scope): NVL-123 imperative description
```

An example:

```
feat(commerce): NVL-214 verify webhook signatures on raw request bytes
```

The message is machine-parseable on purpose. It drives changelog generation, it links every line of code back to the ticket that justified it, and it makes the history readable months later when nobody remembers why a change was made. A commit that does not follow this shape is rejected by a commit-message hook before it is ever pushed.

The rules for the message body: write one logical change per commit, use the present-tense imperative in the description, as in "add" not "added" or "adds", and use the body of the commit to explain why the change was made rather than what it did, because the diff already shows what it did. A good body answers the question a reviewer or a future maintainer will actually ask, which is almost never "what changed" and almost always "why".

### The allowed commit types

Only these types are permitted. Each one has a precise meaning, and using the wrong one pollutes the changelog and the history, so choose deliberately.

- **feat** is a new capability visible to a user or to another part of the system. It adds behaviour that was not there before. A new endpoint, a new screen, a new field a learner can set. Anything that would belong in release notes as something the product can now do is a feat.

- **fix** is a correction to behaviour that was wrong. Something did not work as intended and now it does. A fix always implies there was a defect, so if the behaviour was never promised in the first place, it is probably a feat and not a fix.

- **refactor** is a change to the internal structure of the code that deliberately does not change its external behaviour. Renaming, reorganising, extracting a function, simplifying logic. If a refactor changes what the system does, it is not a refactor, it is a feat or a fix that was mislabelled.

- **perf** is a change made specifically to improve performance, such as latency, throughput, memory, or cost, without changing what the system does. It is a narrower cousin of refactor, called out separately because performance changes carry their own risk and deserve their own visibility.

- **test** is the addition or correction of tests, with no change to the code under test. If you fixed a bug and added a test for it, the fix and the test can travel together under fix, but a commit that only touches tests is a test commit.

- **docs** is a change to documentation only, whether that is the documents in the docs folder, code comments, or these governance files. No behaviour changes.

- **build** is a change to the build system, the dependency manifests, the Dockerfile, the lockfiles, or anything about how the software is compiled and packaged. It changes how the artefact is produced, not what the artefact does.

- **ci** is a change to the continuous integration and deployment configuration, the GitHub Actions workflows, the pipeline definitions. It changes how the software is tested and shipped, not the software itself.

- **chore** is routine maintenance that fits none of the above and touches nothing a user would notice: bumping a dependency version, updating a configuration default, tidying a directory. If you are unsure and the change is genuinely mundane and invisible, chore is the honest choice.

- **security** is a change made specifically to address a security concern, whether closing a vulnerability, hardening a control, or fixing a policy. It is called out separately from fix because security changes must be visible in the history at a glance, and because they often warrant faster review and different handling.

- **revert** undoes a previous commit. The description names what is being reverted and the body explains why, because a revert without a reason is just churn.

### The project scopes

The scope names the part of the system the change touches. It is one of the module or area names below, drawn directly from the system architecture in `docs/04-system-architecture.md`, so that the scope in a commit always corresponds to a real boundary in the code. If a change genuinely spans several scopes, choose the one that is most central to the change, and if it truly belongs to no single scope, the scope may be omitted, though this should be rare.

The bounded-context modules, each of which owns its own tables, its own service layer, and its own public interface:

- **identity** is users, authentication, sessions, multi-factor authentication, roles, permissions, and the audit log. Anything about who a person is and what they are allowed to do.

- **settings** is runtime configuration, feature flags, and the database-driven content and navigation. Anything about values that a non-engineer can change without a deploy.

- **catalog** is the product type registry, catalog items, their immutable versions, the relationships between them, and the publishing pipeline. The heart of what the platform offers.

- **learning** is courses, modules, lessons, learner progress, and learning resources. The delivery of learning content.

- **live** is cohorts, live sessions, the meeting provider integration, attendance, and recordings. Everything about learning that happens at a scheduled time.

- **assessment** is quizzes, exams, projects, submissions, and grading. Everything about proving that learning happened.

- **credential** is certificates: their eligibility rules, issuance, public verification, and revocation. The credibility layer.

- **document** is brochures: their generation from catalog data, versioning, access control, and analytics.

- **commerce** is products, prices, offers, coupons, checkout, and orders. The three-tier access model and everything about turning an intent to pay into an order.

- **payments** is the payment provider adapters, webhooks, reconciliation, and refunds. Everything that touches the money rail itself.

- **entitlement** is entitlements and enrolments: the grants that actually decide access, independent of how they were paid for.

- **careers** is jobs, applications, and screening. The employer-facing and career side.

- **community** is articles, events, showcases, and developer profiles. The social and content layer.

- **ai** is the AI gateway, guardrails, agents, tools, memory, and evaluations. Everything about the AI tutor and any other use of models.

- **analytics** is event ingestion, aggregation, and metrics. The measurement layer.

- **admin** is the administrative surfaces that sit over every other module.

Cross-cutting areas that are not bounded-context modules but are legitimate scopes:

- **karma** is the karma, streak, and goodies reward system, which spans learning events and commerce but is coherent enough to name on its own.

- **media** is the video and streaming pipeline: transcoding, adaptive bitrate, storage layout, and delivery.

- **web** is the Next.js presentation application: pages, components, and anything about how the platform looks and feels in the browser.

- **infra** is infrastructure and deployment: the container definitions, the infrastructure-as-code, the environment configuration.

- **db** is the database layer itself: the shared base models, the migration machinery, and cross-cutting schema concerns that do not belong to a single module.

- **deps** is dependency management across the project when a change is not specific to one module.

- **docs** is the documentation set, used as a scope when the type is not already docs, which is rare.

## Pull requests

Run the full local check before you open a pull request. The command is `make check`, and it runs the same lint, type-checking, and test gates that the pipeline runs, so a green result locally means a green pipeline. Opening a pull request that fails checks the author could have caught wastes a reviewer's attention, which is the scarcest resource on a small team.

Every pull request needs an approving review from the other track. The team works in two tracks, described in `docs/16-collaboration-model.md`, and each reviews the other, so that no code reaches the main branch without a second person having understood it. The pull request template will prompt you for what a reviewer needs; fill it in properly rather than deleting it.

### Reviewing a pull request

The reviewer's job is to understand the change, not merely to approve it. Approving something you do not understand is worse than not reviewing it, because it manufactures false confidence that a second person checked the work.

Review in this order of importance. Does the change do what its ticket says. Are the acceptance criteria actually met. Is authorization enforced wherever the change touches access. Is input validated at every boundary the change introduces. Are the failure paths handled, not just the happy path. Are the tests meaningful, actually asserting behaviour, or do they merely execute the code and pass. Will the next person to read this understand it without asking the author.

For changes that touch money, access, authorization, or credentials, both people read the code, not one author and one skimmer. These are the areas where a subtle mistake is expensive and hard to reverse, and they earn the extra care.

## What the automated checks enforce

Some standards are enforced by tooling rather than by review, so that they never depend on a reviewer remembering them. These will fail the build:

- Reading an environment variable outside the single configuration module. All configuration except a small set of bootstrap values comes from the database, as described in `docs/05-configuration-architecture.md`.
- Branching on a catalog item's kind in service code. Product kinds differ by configuration in the type registry, not by conditional code, as described in `docs/06-product-catalog-architecture.md`.
- Using a floating-point number for a monetary value. Money is always integer minor units with an explicit currency.
- Raising an HTTP-specific error from a service layer. Services must not know they were called over HTTP, so that a background worker can reuse them.
- Importing another module's internal models or repository directly. Cross-module access goes through the target's service layer or a published event.
- An endpoint that declares neither a required permission nor an explicit public marker. Access is default-deny, so an endpoint that forgets to declare its access requirement fails at startup rather than shipping open.
- A raw colour value in a component instead of a design token. A removed focus outline, which breaks keyboard navigation.

The guardrail script that catches most of these lives in the repository and can be run locally. Each finding it reports explains why the rule exists, so treat a failure as a short lesson rather than an obstacle.

## The definition of done

A change is not done because the code exists and compiles. It is done when the acceptance criteria are demonstrably met, the tests including the failure paths pass in the pipeline, authorization is enforced and ownership is filtered inside the query rather than checked afterward, any database migration is reversible and tested in both directions, the necessary logs and metrics are emitted, an alert and a runbook exist for anything that can fail in production, the documentation is updated, and a second person has reviewed it and run it. The full checklist is in `docs/34-definition-of-ready-and-done.md`.

## Honesty

The word implemented means the code exists. The word verified means someone watched it actually work. Use the weaker word when you have not seen it run. Never record that an external system was configured, or a deployment succeeded, or an integration works, unless it genuinely happened and you confirmed it. If something is blocked, say it is blocked and say why, rather than presenting partial work as complete. This is the single most important cultural rule in the project, because a plan built on inflated status is a plan that fails quietly and late.

Every bug fix ships with a regression test that failed before the fix and passes after it. This is not optional, because it is the only way to know the fix addressed the real cause rather than a symptom, and it is what stops the same bug returning six months later.
