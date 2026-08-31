# NeuViTech Labs

Technology education and career platform. Learn → Build → Prove → Certify → Connect → Work.

**Production:** [neuvitechlabs.com](https://neuvitechlabs.com) · **Status:** Sprint 1 — foundation

---

## Getting started

You need **Docker Desktop** and **VS Code**. Nothing else — no Python, no Node, no Postgres on your machine. That is deliberate: the development environment lives in this repository, so every machine runs an identical one.

**Windows only, first:** install WSL2 (`wsl --install` in an Administrator PowerShell, then reboot). Clone into the WSL2 filesystem, never `/mnt/c/` — cross-boundary file access is roughly ten times slower.

```bash
mkdir -p ~/code && cd ~/code
git clone git@github.com:ianisharya/neuvitech-labs.git
cd neuvitech-labs
code .
```

VS Code will offer **"Reopen in Container"** — accept it. The first build takes 15–25 minutes; afterwards it is seconds.

```bash
cp .env.example .env      # defaults work locally, no real secrets needed
make doctor               # verify the toolchain
make help                 # see every command
```

Full walkthrough with failure modes: [`docs/23-environment-setup-runbook.md`](docs/23-environment-setup-runbook.md).

## Commands

Everything is a `make` target, so there is one command set regardless of operating system.

```
make doctor      verify the toolchain
make up          start all services          make down     stop them
make api         run the API                 make web      run the web app
make migrate     apply migrations            make seed     seed dev data
make test        run all tests               make check    lint + types + tests
make guardrails  check the architectural rules
```

`make check` runs the same gates as CI. Green locally means green in the pipeline.

## Architecture at a glance

A **modular monolith**: one FastAPI application of strictly bounded modules, one Next.js presentation app holding zero business logic, one worker sharing the same image. PostgreSQL is the single system of record.

```
Browser → Next.js (SSR, SEO, BFF) → FastAPI (all domain logic) → PostgreSQL
                                          ├→ Redis (cache, queue, limits)
                                          ├→ Object storage (private media)
                                          └→ ARQ worker
```

Four things to understand before writing code:

1. **Nothing is hard-coded.** Nine environment variables exist; everything else — branding, navigation, feature flags, pricing rules, even provider API keys — lives in the database. See [`docs/05`](docs/05-configuration-architecture.md).
2. **The catalog is data, not code.** Programs, Tracks, Specializations and Masterclasses differ by rows in `catalog_item_type`, not by `if` statements. Adding a product type is an INSERT. See [`docs/06`](docs/06-product-catalog-architecture.md).
3. **Payment never equals access.** An `Entitlement` is a separate, audited grant. See [`docs/09`](docs/09-commerce-and-entitlements.md).
4. **Default deny.** Every endpoint declares a permission or is explicitly public; one that declares neither fails at startup. See [`docs/08`](docs/08-security-architecture.md).

## Documentation

`docs/` is the source of truth — 38 numbered documents plus ADRs. Start at [`docs/00-START-HERE.md`](docs/00-START-HERE.md).

**New to the project?** [`docs/37-onboarding-guide.md`](docs/37-onboarding-guide.md) takes you from nothing to your first change in about six hours.

**Something broken locally?** [`docs/36-troubleshooting-guide.md`](docs/36-troubleshooting-guide.md).

## Contributing

Read [`CONTRIBUTING.md`](CONTRIBUTING.md). In short: branch `feature/NVL-123-slug`, commit `feat(scope): NVL-123 description`, run `make check`, open a PR, get a review from the other track.

## Security

Never commit a secret. If one is ever committed, **rotate the credential immediately** — removing the file does not help, it is still in history. See [`SECURITY.md`](SECURITY.md).
