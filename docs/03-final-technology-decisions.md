# 03 — Final Technology Decisions

**These are decisions, not options.** Evaluated against reliability, cross-platform compatibility, simplicity, maintainability, development speed, ease of installation, ease of debugging, long-term practicality and lowest unnecessary complexity. Full reasoning with rejected alternatives is in `adr/`.

---

## 1. THE cross-platform decision: VS Code Dev Containers

**Both machines develop inside an identical Linux container defined by `.devcontainer/devcontainer.json` in the repository.**

The single most important decision in this plan. It removes an entire category of problems.

You install Docker Desktop and VS Code. You open the repository. VS Code offers *"Reopen in Container"*. Minutes later you have Python 3.12, Node 22, uv, PostgreSQL client tools and every dependency — **byte-identical on macOS and Windows**.

| Problem without it | What actually happens | With Dev Containers |
|---|---|---|
| Python version drift | Mac 3.12.4, Windows 3.12.1, subtle behaviour differs, evening lost | Same interpreter, pinned in the image |
| Windows native Python | `pip install` compiles a C extension, needs MSVC Build Tools, fails unreadably | Linux wheels, no compilation |
| PATH configuration | "command not found"; different shells, different rc files | PATH defined in the image |
| Line endings | CRLF checkout, `bad interpreter: \r` | Linux container; `.gitattributes` enforces LF |
| File paths | `C:\Users\…` vs `/Users/…` leaks into config and tests | One path scheme |
| Shell differences | PowerShell vs zsh; every instruction needs two forms | One shell: bash, in the container |
| "Works on my machine" | Environment archaeology | **The environment IS the repository** |

**Cost:** Docker Desktop running (~2 GB idle) and a 15–25 minute first build. A one-off price on Day 2 that removes OS-difference debugging from all 280 days.

**Windows:** Docker Desktop with **WSL2 backend**; repository cloned **inside** the WSL2 filesystem (`~/code/…`), never `/mnt/c/`. Cross-boundary file access is ~10× slower. Not optional.
**macOS:** Docker Desktop with **VirtioFS**. Apple Silicon runs `arm64` natively; all images are multi-arch.

---

## 2. The stack

| Layer | Decision | Version | ADR |
|---|---|---|---|
| Dev environment | VS Code + Dev Containers | latest | ADR-0007 |
| Container runtime | Docker Desktop + Compose v2 | latest | ADR-0007 |
| Backend language | Python | 3.12 | ADR-0002 |
| Python project manager | **uv** | ≥ 0.5 | ADR-0005 |
| API framework | FastAPI + Pydantic v2 | latest | ADR-0002 |
| ORM / migrations | SQLAlchemy 2.0 (async) + Alembic | latest | ADR-0002 |
| Database | **PostgreSQL + pgvector** | 16 | ADR-0003 |
| Cache / queue / rate limit | Redis | 7 | ADR-0003 |
| Background jobs | ARQ | latest | ADR-0009 |
| Frontend | Next.js App Router + TypeScript strict | 15 | ADR-0004 |
| UI foundation | shadcn/ui (Radix + Tailwind), vendored | latest | ADR-0011 |
| Animation | Motion (Framer Motion successor) | latest | ADR-0011 |
| Object storage | MinIO local / S3-compatible prod | latest | ADR-0003 |
| Mail (local) | Mailpit | latest | — |
| API tests | pytest, pytest-asyncio, Schemathesis | latest | ADR-0010 |
| Web tests | Vitest, Testing Library, Playwright | latest | ADR-0010 |
| Load tests | k6 | latest | ADR-0010 |
| Lint / format / types | Ruff, mypy strict, ESLint, Prettier | latest | — |
| CI/CD | GitHub Actions | — | ADR-0012 |
| IaC | OpenTofu | latest | ADR-0013 |
| Hosting | Container platform + managed PostgreSQL | — | ADR-0013 |
| Observability | OpenTelemetry → Prometheus, Loki, Tempo, Grafana | latest | ADR-0014 |
| Error tracking | GlitchTip (Sentry-compatible, self-hostable) | latest | ADR-0014 |

### Why each, in one line

- **Python + FastAPI** — `uv` is mandated and is a Python tool; the AI, webhook and provider workloads are I/O-bound; Pydantic models serve HTTP validation, OpenAPI *and* LLM structured outputs. Django was the serious contender (ADR-0002).
- **PostgreSQL alone** — one engine covering relational, JSONB, full-text and vectors. It is also what makes "everything database-driven" practical: JSONB gives schema flexibility without EAV.
- **Redis** — cache-aside, rate limiting, idempotency keys, distributed locks, ARQ queue. One dependency, five jobs.
- **ARQ over Celery** — async-native, so workers reuse the same async session and repository layer as the API instead of maintaining a parallel sync data-access stack (ADR-0009).
- **Next.js as presentation only**, zero business logic — SEO is a hard requirement on every catalog surface.
- **shadcn/ui vendored** — accessible Radix primitives with source copied *into* the repository, so we own and restyle every line. Not a dependency we are trapped by (ADR-0011).
- **Async SQLAlchemy retained** — its failure mode is better: async errors fail loudly in dev and CI; sync-with-threadpool fails by silent pool exhaustion in production under load.

---

## 3. Deferred, with revisit triggers

Recorded so nobody wonders later whether they were forgotten.

| Deferred | Revisit when |
|---|---|
| Kubernetes | >8 replicas needed, or multiple teams deploying independently |
| Neo4j / graph DB | Traversals routinely exceed 4–5 hops, or path queries exceed p95 300 ms |
| MongoDB / NoSQL | A single event stream exceeds ~50M rows/month |
| Elasticsearch | >50k searchable documents, or p95 search >200 ms |
| Kafka / RabbitMQ | Genuine multi-consumer fan-out or replay requirements |
| Standalone vector DB | pgvector recall or latency becomes the measured bottleneck |
| Microservices | Multiple teams needing independent deploy cadence |
| Multi-tenancy | **Assumed out of scope. Say now if wrong** — expensive to retrofit |
| GraphQL | REST + generated TS types is sufficient; revisit if clients proliferate |

---

## 4. Repository layout

```
neuvitech-labs/
├── .devcontainer/{devcontainer.json,Dockerfile}   # THE cross-platform contract
├── .github/{workflows,ISSUE_TEMPLATE,pull_request_template.md}
├── apps/
│   ├── api/                        # FastAPI — system of record
│   │   ├── src/neuvitech/
│   │   │   ├── main.py
│   │   │   ├── core/               # config, logging, errors, ids, clock, pagination
│   │   │   ├── db/                 # engine, session, base, mixins
│   │   │   ├── security/           # authn, authz (single PDP), hashing, mfa, ratelimit
│   │   │   ├── settings/           # ← RUNTIME CONFIG from DB (see doc 05)
│   │   │   ├── modules/            # bounded contexts
│   │   │   │   ├── identity/ catalog/ learning/ live/ assessment/
│   │   │   │   ├── credential/ document/ commerce/ payments/ entitlement/
│   │   │   │   └── careers/ community/ ai/ analytics/ admin/
│   │   │   ├── integrations/       # provider protocols + adapters
│   │   │   ├── workers/            # ARQ tasks
│   │   │   └── observability/
│   │   ├── migrations/             # Alembic
│   │   ├── tests/{unit,integration,api,security,contract}/
│   │   └── pyproject.toml
│   └── web/                        # Next.js
│       ├── app/{(marketing),(catalog),(learn),(admin),verify}/
│       ├── components/{ui,patterns}/
│       ├── lib/{api-client,session,seo,settings}/
│       └── tests/e2e/
├── packages/contracts/             # OpenAPI → generated TypeScript
├── infrastructure/{compose,docker,tofu,grafana,k6}/
├── docs/                           # this pack, committed
├── scripts/
├── Makefile                        # ONE command interface, both OSes
└── README.md
```

---

## 5. One command interface

Every routine action is a `make` target — one command regardless of OS or shell, available in the Dev Container on both machines.

```
make help        make up          make down        make logs        make ps
make api         make web         make worker      make shell
make migrate     make migration m="…"              make seed        make reset-db
make test        make test-api    make test-web    make e2e         make load
make lint        make fmt         make typecheck   make check
make contracts   make scan        make clean
```

**`make check`** runs lint + typecheck + tests — the same gates as CI. Green locally means green in the pipeline. You will type it more than anything else.

---

## 6. Remaining OS differences — the complete list

| Action | 🍎 macOS | 🪟 Windows |
|---|---|---|
| Enable virtualisation | Already on | May need BIOS/UEFI |
| Install WSL2 | n/a | `wsl --install` (Admin PowerShell), reboot |
| Docker Desktop | `.dmg` → Applications | `.exe`, **enable WSL2 backend** |
| Repository location | `~/code/neuvitech-labs` | Inside WSL2 `~/code/…`, **never** `/mnt/c/` |
| Terminal | Terminal / iTerm | **Ubuntu (WSL)** — not PowerShell |
| Install Git | `brew install git` or Xcode CLT | In WSL: `sudo apt install git` |
| SSH key | `ssh-keygen -t ed25519` | Identical, **inside WSL** |
| Open project | `code ~/code/neuvitech-labs` | From WSL: `code .` |
| **After "Reopen in Container"** | **Identical** | **Identical** |

That table is the complete remainder. Past that point there is no divergence.
