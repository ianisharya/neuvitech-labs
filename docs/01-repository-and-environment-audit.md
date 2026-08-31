# 01 — Repository & Environment Audit

**Method:** direct inspection. No assumption substituted for evidence.

## 1. Headline finding

> **`ianisharya/neuvitech-labs` exists, is publicly clonable, and contains ZERO commits, ZERO branches, ZERO tags and ZERO files.**

This is a **greenfield build**, not a modernisation.

### Evidence

| Check | Command | Result |
|---|---|---|
| Clone | `git clone --depth 50 …` | Exit 0 — `warning: You appear to have cloned an empty repository.` |
| All remote refs | `git ls-remote …` | Exit 0, **empty output** = reachable, zero refs |
| Working tree | `ls -la repo/` | `.git` only |
| History | `git log` | `fatal: your current branch 'main' does not have any commits yet` |

`git ls-remote` exiting 0 with no output is authoritative: the remote resolved and authenticated anonymously (so the repository is public and the URL is correct) and advertises no refs at all. A 404 or permission problem would have produced an error, not an empty list.

The GitHub REST API returned **HTTP 403 (rate limit)** from this container's egress IP and produced no usable evidence. It is recorded only for completeness; the git-protocol evidence is independent and sufficient.

### Consequences

| Brief instruction | Status |
|---|---|
| Inspect the existing repository | **Done — it is empty** |
| Assess technical debt | **N/A — no code, no debt** |
| Determine what to reuse | **Nothing** |
| Determine what to refactor | **Nothing** |
| Determine what to rewrite | **Everything is net-new** |

**Inherited technical debt: zero.** That is an asset. The main risk of a zero-debt greenfield is over-engineering on day one, which this plan guards against by starting as a modular monolith and deferring Kubernetes, graph databases, NoSQL, message brokers and microservices — each with a written revisit trigger.

## 2. Jira — BLOCKED

**Target:** `https://neuvitech-labs.atlassian.net`

| Check | Result |
|---|---|
| Direct fetch | **BLOCKED** — `ROBOTS_DISALLOWED` |
| Authenticated API | **Not available** — no credentials, no OAuth grant |
| Atlassian MCP connector | Present in the connector directory, `installState: not_installed`, `connected: false` |

Therefore, as of now:
- **Jira project: NOT INSPECTED.** I do not know whether one exists, its key, issue types, screens, fields or workflow scheme.
- **Jira: NOT CONFIGURED by me.** I have configured nothing.
- **Jira issues: NOT CREATED.** The tickets in `27-jira-backlog.md` are authored specifications, ready to create.

**Unblocking:** (a) connect the Atlassian MCP connector and I create issues and report exactly what was created; (b) import the supplied CSVs via Jira → System → External System Import → CSV; (c) create them manually.

**Missing input:** the earlier brief referenced Jira screenshots for workflow semantics. **None were provided.** The workflow in `26-jira-structure.md` is designed from the explicit state list and is marked provisional pending screenshot review. I have not invented screenshot contents.

## 3. Domain

`neuvitechlabs.com` is the stated production domain. **I have not verified registration** — I cannot check registrar status from this environment. Ticket `NVL-EXT-03` covers registration and DNS, needed by Sprint 5 for canonical URLs and SEO, and by Sprint 12 for production TLS.

## 4. Build environment (my authoring container)

| Tool | Status | Version |
|---|---|---|
| uv | Present | 0.11.7 |
| Python | Present | 3.12.3 |
| Node.js | Present | 22.22.2 |
| git | Present | 2.43.0 |
| **Docker** | **ABSENT** | — |
| PostgreSQL client | Absent | — |
| Redis client | Absent | — |
| Resources | 1 vCPU, 3.9 GiB, Ubuntu 24.04 | — |

### What this constrains — read carefully

1. **Docker is not available to me.** I cannot run `docker compose up`, cannot verify the Dev Container builds, cannot observe a container healthy. All container work is reported **`IMPLEMENTED`**, never `VERIFIED`, until your machine or CI proves it. This is stated once here and honoured throughout.
2. **No live Postgres or Redis.** Tests requiring real Postgres semantics (JSONB operators, `tsvector`, `pgvector`, advisory locks, `SERIALIZABLE`) are authored to run in your Dev Container and in CI, and are marked as such — never falsely reported as passing locally.
3. **Egress is allow-listed.** Reachable: PyPI, npm, GitHub, crates.io, Ubuntu archives. **Not reachable:** `*.atlassian.net`, payment providers, Zoom, cloud APIs, DNS registrars. Any task needing those is **BLOCKED in my environment** and must be executed by you.
4. **`uv` is present**, so the mandated project manager works immediately, and Python is confirmed as the backend language.

## 5. What I could not verify

Not assumed, and tracked as open questions in `31-risk-register.md`:

- Whether `neuvitechlabs.com` is registered
- Whether a payment merchant account exists, in which country, with which capabilities
- Whether a Zoom account exists and at which tier
- Whether any cloud account, hosting, email sending domain or object storage exists
- Intended primary currency and tax jurisdiction
- Who holds GitHub repository admin
- Existing brand assets, typography or visual direction

## 6. Conclusion

**Greenfield.** Reuse: none. Refactor: nothing. Rewrite: everything net-new. Inherited debt: zero. Day 1 must therefore establish environment and repository foundation — not features.
