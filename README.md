# NeuViTech Labs

A technology education and career platform. Learners discover a career direction, learn through live and recorded courses, prove their ability through real assessment, earn verifiable credentials, and connect with employers. The platform is EdTech first, with a community and careers layer alongside it and a technology solutions division behind it.

Production runs at neuvitechlabs.com. The project is under active development; see the documentation set for exactly where it stands.

## What the platform is

At its core is an extensible catalog of learning: Programs, Tracks, Specializations, Masterclasses, free certification courses, and more, all defined as data rather than hard-coded, so new kinds of offering are a configuration change rather than a rewrite. On top of that sits a learning system that delivers live sessions, recordings of those sessions, and pre-recorded lectures through one video player, tracks progress honestly, and runs real assessments that mean something.

Access comes in three tiers. Free courses and videos cost nothing and free certifications, once earned, are kept forever. A subscription, billed monthly or annually, opens the library for as long as it is active, and a lapse suspends access without ever deleting a learner's progress. A one-time purchase buys a flagship program outright for its published duration plus one year. There is no instalment financing; a subscription serves the same need to spread cost.

Around this are a problem-solving platform with worked solutions and an AI tutor to explain them, mock interviews and resume review, a karma and streak system that rewards consistent learning with points redeemable for goods, verifiable certificates, a community layer, and an employer-facing careers side. The AI tutor is agentic, built on open-source models, carries memory of each learner across sessions stored in the platform's own database, and runs through a single guarded gateway.

## Getting started

You need Docker Desktop and Visual Studio Code. You do not need Python, Node, PostgreSQL, or anything else installed on your machine, because the entire development environment lives inside a container defined in this repository, which means every engineer's environment is identical regardless of their operating system.

On Windows, install WSL2 first, then clone the repository inside the WSL2 filesystem rather than on the Windows drive, because a repository on the Windows drive is roughly ten times slower for the kind of file access development needs. On macOS there is no such step.

```
mkdir -p ~/code && cd ~/code
git clone git@github.com:ianisharya/neuvitech-labs.git
cd neuvitech-labs
code .
```

Visual Studio Code will offer to reopen the folder in the container. Accept it. The first build takes fifteen to twenty-five minutes as it assembles the environment; every subsequent open takes seconds. When it is ready, verify the toolchain and see the available commands:

```
make doctor
make help
```

The full walkthrough, including every failure anyone has actually hit and how it was resolved, is in `docs/23-environment-setup-runbook.md`, with a shorter per-operating-system quick start in `setup-macos-day1-2.md` and `setup-windows-day1-2.md`.

## The command interface

Everything routine is a make target, so there is one set of commands regardless of operating system or shell. The ones you will use most:

```
make doctor       verify the toolchain matches across machines
make up           start all services
make down         stop all services
make migrate      apply database migrations
make seed         load development data
make test         run the test suite
make check        lint, type-check, and test, the same gates the pipeline runs
make guardrails   check the architectural rules
```

Run `make check` before every push. A green result locally means a green pipeline.

## How the system is shaped

The backend is a modular monolith: one deployable application composed of strictly bounded modules, each owning its own data and exposing a service layer that other modules call rather than reaching into each other's tables. The presentation layer is a separate application that renders the interface and holds no business logic of its own. PostgreSQL is the single source of truth. Redis handles caching, sessions, rate limiting, and the background job queue. Video is served from a content delivery network so that it stays fast and affordable at scale, with the application only checking permission and never serving the video bytes itself.

Four principles govern almost every decision, and understanding them explains most of the codebase:

Nothing that a non-engineer might need to change is hard-coded. Configuration, branding, navigation, pricing rules, feature flags, and product definitions all live in the database. Only a small set of bootstrap values live in the environment. This is covered in `docs/05-configuration-architecture.md`.

The catalog is data, not code. A new kind of product is a row in a registry, not a new table and a rewrite. This is covered in `docs/06-product-catalog-architecture.md`.

Paying for something and being allowed to use it are separate facts. Access is always checked against an entitlement, never against a payment record, which is what lets free enrolment, subscription, one-time purchase, scholarship, and corporate sponsorship all grant access through one path. This is covered in `docs/09-commerce-and-entitlements.md`.

Access is default-deny. Every endpoint declares the permission it requires or explicitly marks itself public, and one that declares neither fails at startup rather than shipping open. This is covered in `docs/08-security-architecture.md`.

## Documentation

The `docs` folder is the source of truth for this project, written so that a new engineer can understand the system and the plan without anyone explaining it to them. Start at `docs/00-START-HERE.md`, which indexes everything and lays out reading paths for different needs. New engineers should begin with `docs/37-onboarding-guide.md`. Architectural decisions, with their alternatives and trade-offs, are recorded in `docs/adr`.

## Contributing

Read `CONTRIBUTING.md` before your first change. In short: branch as `feature/NVL-123-short-description`, commit as `type(scope): NVL-123 imperative description`, run `make check`, open a pull request, and get a review from the other track. The contributing guide details the allowed commit types and the project scopes.

## Security

Never commit a secret. If a secret is ever committed, rotate the credential immediately, because removing the file does not remove it from history. Report vulnerabilities privately rather than in a public issue. The full policy is in `SECURITY.md`.

## Licence

This repository is proprietary. See `LICENSE`.
