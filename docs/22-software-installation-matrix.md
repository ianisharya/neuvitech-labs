# 22 — Software Installation Matrix

**Installed at the point of need, not all at once.** Nothing is assumed present. Every row is real Jira work with real time.

**Legend:** 🍎 macOS · 🪟 Windows · 🔵 both identical

---

## Wave 1 — Sprint 1, Days 1–4: develop anything at all

| Software | Why | 🍎 macOS | 🪟 Windows | When | Verification | Owner | Time |
|---|---|---|---|---|---|---|---|
| **WSL2 + Ubuntu** | Linux kernel for Docker; where the repo lives | n/a | `wsl --install` (Admin PowerShell), reboot | S1 D1 | `wsl -l -v` shows `Ubuntu Running 2` | Teammate | **45 m** |
| **Docker Desktop** | Runs Dev Container + all services | `.dmg` → Applications | `.exe`, **enable WSL2 backend** | S1 D1 | `docker run --rm hello-world` | Both | **50 m** |
| **VS Code** | Editor; hosts the Dev Container | `.zip` or `brew --cask` | `.exe` User Installer, add to PATH | S1 D1 | `code --version` | Both | 20 m |
| **VS Code extensions** | Dev Containers, Docker, 🪟 WSL, GitLens, Copilot | Identical | Identical | S1 D2 | Extensions listed | Both | 20 m |
| **Git** | Version control | `brew install git` / Xcode CLT | In WSL: `sudo apt install git` | S1 D2 | `git --version` | Both | 20 m |
| **GitHub SSH key** | Push access | `ssh-keygen -t ed25519` | Identical, **inside WSL** | S1 D2 | `ssh -T git@github.com` | Both | 25 m |
| **Jira access** | Ticket tracking | Browser | Browser | S1 D2 | Can create an issue | Both | 15 m |

**Wave 1 total: 🍎 ≈ 2 h 30 m · 🪟 ≈ 3 h 15 m**

Note there is **no** host install of Python, Node, uv, PostgreSQL or Redis. That is the point of the Dev Container decision — those are precisely the installs that break differently on each OS.

## Wave 2 — Sprint 1, Days 5–7: the container itself

| Software | Why | Setup | When | Verification | Owner | Time |
|---|---|---|---|---|---|---|
| **Dev Container image** | Python 3.12, Node 22, uv, psql, redis-cli, make, jq, curl | I author `.devcontainer/`; you click *Reopen in Container* | S1 D5 | `python --version`, `node --version`, `uv --version`, `make help` | 🔵 Both | **35 m** (first build 15–25 m) |
| Container extensions | Python, Pylance, Ruff, ESLint, Prettier, Tailwind | Automatic, listed in `devcontainer.json` | S1 D5 | Present in the container | 🔵 Both | 5 m |
| **Cross-platform validation** | Prove both machines are identical | Both run the same commands, compare | S1 D7 | Byte-identical versions; both `make check` green | 🔵 Both | **45 m** |

## Wave 3 — Sprint 2: services and the persistence layer

| Software | Why | Setup | When | Verification | Owner | Time |
|---|---|---|---|---|---|---|
| **PostgreSQL 16 + pgvector** | Primary database | Compose service, `make up` | S2 D2 | `psql -c "SELECT version()"`, `CREATE EXTENSION vector` | 🔵 Both | 25 m |
| **Redis 7** | Cache, queue, rate limiting | Compose service | S2 D2 | `redis-cli ping` → PONG | 🔵 Both | 15 m |
| **MinIO** | S3-compatible object storage | Compose service | S2 D3 | Console at `:9001`, bucket created | 🔵 Both | 20 m |
| **Mailpit** | Captures local mail | Compose service | S2 D3 | Inbox at `:8025` | 🔵 Both | 10 m |
| **Alembic** | Migrations | Python dependency | S2 D5 | `make migrate` reaches head | 🔵 Both | 20 m |
| **DB GUI** (TablePlus or DBeaver) | Inspect data visually | App install, connect to `localhost:5432` | S2 D5 | Tables visible | 🔵 Both | 25 m |
| **Port-conflict resolution** | 5432 / 6379 / 3000 / 8000 collisions | `lsof -i :PORT`; I remap in Compose | S2 D2 | `make ps` all healthy | 🔵 Both | **20 m buffer** |

## Wave 4 — Sprint 2–3: CI, testing, quality

| Software | Why | Setup | When | Verification | Owner | Time |
|---|---|---|---|---|---|---|
| **GitHub Actions** | CI/CD | I author workflows; you enable Actions | S2 D11 | First green PR run | Teammate | 30 m |
| **pytest + asyncio + coverage** | Backend tests | Dependency | S2 D9 | `make test-api` green | AI + Both | 15 m |
| **Vitest + Testing Library** | Component tests | Dependency | S3 D6 | `make test-web` green | AI + Teammate | 15 m |
| **Playwright + browsers** | E2E | `npx playwright install` in container | S3 D8 | `make e2e` green | Teammate | 30 m |
| **Schemathesis** | API contract fuzzing | Dependency | S3 D10 | Runs against OpenAPI | AI | 15 m |
| **Ruff, mypy, ESLint, Prettier** | Lint, format, types | Dependency + pre-commit | S2 D6 | `make check` green | 🔵 Both | 25 m |
| **Gitleaks, Semgrep, Trivy, Checkov** | Security scanning | CI + pre-commit | S3 D12 | Scans run and block | Teammate | 40 m |
| **GitHub Copilot** | Review aid | VS Code extension, sign in | S2 D4 | Suggestions appear | 🔵 Both | 15 m |

## Wave 5 — Sprint 4–5: observability

| Software | Why | Setup | When | Verification | Owner | Time |
|---|---|---|---|---|---|---|
| **OpenTelemetry SDK + Collector** | Instrumentation | Dependency + Compose service | S4 D6 | Spans reaching the collector | AI + You | 40 m |
| **Prometheus** | Metrics | Compose service | S4 D7 | Targets up, `/metrics` scraped | You | 25 m |
| **Loki** | Logs | Compose service | S4 D7 | Logs queryable in Grafana | You | 25 m |
| **Tempo** | Traces | Compose service | S4 D8 | Trace visible end to end | You | 25 m |
| **Grafana** | Dashboards, alerts | Compose service | S4 D8 | First dashboard renders | You | 40 m |
| **GlitchTip** | Error tracking | Compose service + DSN in settings | S5 D6 | Test exception appears | You | 30 m |

## Wave 6 — Sprint 11–12: deployment

| Software | Why | Setup | When | Verification | Owner | Time |
|---|---|---|---|---|---|---|
| **Cloud provider account + CLI** | Hosting | Account signup, CLI install, `auth login` | S11 D2 | `whoami` returns identity | You | **60 m** |
| **OpenTofu** | Infrastructure as code | Container tool | S11 D3 | `tofu version`, `tofu init` | You | 30 m |
| **Cloudflare account** | DNS, CDN, WAF, TLS | Signup, add `neuvitechlabs.com`, change nameservers | S11 D4 | DNS resolving | You | **45 m** + DNS propagation |
| **Managed PostgreSQL** | Production database | Provision via OpenTofu | S11 D6 | Connect from a container | You | 45 m |
| **Object storage + CDN** | Media | Provision via OpenTofu | S11 D7 | Signed URL works | Teammate | 40 m |
| **Container registry** | Image storage | Provision, CI push credentials | S11 D8 | Image pushed and pulled | Teammate | 30 m |
| **GitHub Environments** | DEV/QA/PROD secrets and gates | Repo settings, reviewer on production | S11 D9 | Deploy blocked pending approval | You | 30 m |

## Wave 7 — Sprint 15–17: integrations

| Software | Why | When | Owner | Time |
|---|---|---|---|---|
| **Razorpay dashboard + test keys** | Payments (account started S2, keys used S7) | S7 D2 | You | 40 m |
| **Transactional email provider** | Real mail (domain verification S2) | S5 D3 | You | 40 m |
| **k6** | Load testing | S13 D6 | Teammate | 30 m |
| **OWASP ZAP** | DAST | S13 D8 | Teammate | 40 m |
| **Zoom account + API app** | Live sessions | S11 D2 | You | 45 m |
| **LLM provider key** | AI features | S16 D2 | You | 20 m |

---

## Accounts with lead time — start these early

| Account | Needed by | Lead time | **Start in** |
|---|---|---|---|
| **Razorpay merchant (KYC)** | Sprint 7 | **2–4 weeks** | **Sprint 2 — longest lead time in the programme** |
| Email sending domain (DNS verification) | Sprint 5 | 2–5 days | Sprint 2 |
| `neuvitechlabs.com` registration | Sprint 5 | Hours | Sprint 2 |
| Cloud hosting | Sprint 11 | Days | Sprint 8 |
| Zoom paid tier | Sprint 11 | Days | Sprint 9 |

**Razorpay KYC is the single most likely cause of a slipped sprint**, because approval is outside your control. `NVL-EXT-01` starts it five sprints early.

## Per-tool lifecycle — why "install Docker" costs 50 minutes

Every install accounts for: download · installation · first launch · login · licence prompts · PATH/environment configuration · extensions · dependencies · version verification · compatibility verification · project integration · first real use · troubleshooting.

**Twelve steps, not one.** The Jira subtasks follow exactly this structure.

## Version pinning

`.devcontainer/Dockerfile` (base digest, Python, Node, uv) · `uv.lock` (hashed Python deps) · `package-lock.json` (Node deps) · `docker-compose.yml` (service image tags) · `.github/workflows/*.yml` (action versions) · `infrastructure/tofu/versions.tf` (provider versions).

**Nothing floats.** A dependency changing without a reviewed PR is a supply-chain risk and a reproducibility bug at once.

## Machine requirements

| | Minimum | Recommended |
|---|---|---|
| Free disk | 30 GB | 50 GB |
| RAM | 8 GB | 16 GB |
| Docker allocation | 4 GB / 2 CPU | **6 GB / 4 CPU** |

Docker's default on some installs is 2 GB, which is not enough for our service set. The symptom is containers dying without a clear error — raising it is an explicit Day-1 subtask.
