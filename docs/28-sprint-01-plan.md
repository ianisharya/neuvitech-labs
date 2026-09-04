# 28: Sprint 1 Detailed Plan

**Environment & Repository Foundation · Mon 31 Aug → Sun 13 Sep 2026**
**49 h capacity · 32 pts committed · 17 pts buffer (35%)**

## Sprint goal
> Both machines run a byte-identical Dev Container, the repository is governed with enforced quality gates, the first CI run is green, and Jira reflects the plan.

**Roughly 60% of this sprint is installation.** That is honest, not padding, you cannot review code on a machine that cannot run it. This is the only sprint shaped this way.

## Objectives
- Docker Desktop, VS Code, Git, SSH working on macOS and Windows
- WSL2 configured with the repository **inside** the WSL2 filesystem
- Monorepo skeleton with governance files, PR/issue templates, `docs/` committed
- `.devcontainer/` producing identical Python 3.12, Node 22, uv on both machines
- **Cross-platform validation passed**: the proof that the approach works
- Baseline CI green, branch protection on `main` (or explicitly BLOCKED)
- Jira project created, Sprint 1 imported
- **`NVL-EXT-01` Razorpay KYC research started**: longest lead time in the programme

## Stories

| Key | Story | Owner | Pts |
|---|---|---|---|
| NVL-101 | Host prerequisites on both machines | BOTH | 11 |
| NVL-102 | Repository structure and governance | AI+BOTH | 4 |
| NVL-103 | Dev Container definition and first build | AI+BOTH | 9 |
| NVL-104 | Cross-platform validation | BOTH | 4 |
| NVL-105 | Jira project configuration | ME | 3 |
| NVL-106 | Baseline CI pipeline | AI+TM | 4 |
| **Total** | | | **35** → committed **32**, three deferred to buffer |

Full subtask breakdown with acceptance criteria: `27-jira-backlog.md`.
Session-by-session schedule: `29-day-by-day-schedule.md`.

## What I produce (zero human hours)
`.devcontainer/devcontainer.json` + `Dockerfile` · `.gitignore` `.gitattributes` `.editorconfig` `LICENSE` `README.md` `CODEOWNERS` `CONTRIBUTING.md` `SECURITY.md` · `.github/` templates and `ci.yml` · monorepo tree with per-directory READMEs · `Makefile` · `.env.example` · this documentation pack · `jira-import-*.csv`

## What you physically do
Install WSL2, Docker, VS Code, extensions, Git · generate SSH keys · clone · review every file · reopen in container · verify toolchain versions · run cross-platform validation · create the Jira project and import · enable GitHub Actions · configure branch protection · start the Razorpay KYC process

## Dependencies
- **Confirm Day 1:** who holds GitHub repository admin
- **Confirm Day 1:** Jira via MCP connector or CSV
- **No third-party accounts needed**: deliberately sequenced so procurement cannot stall the start

## Risks

| Risk | Mitigation |
|---|---|
| Dev Container first build fails | **45-minute explicit buffer** (NVL-103.5); I fix the definition centrally |
| WSL2 needs BIOS virtualisation | Flagged Day 1; teammate may need a reboot into BIOS |
| Corporate proxy blocks registries | **Tell me on Day 1**: it also affects `uv sync`, `npm ci`, `docker pull` |
| No GitHub admin | NVL-106.5 reported **BLOCKED** with manual instructions, not silently closed |
| Windows runs longer than macOS | Expected; the 30-minute troubleshooting buffer absorbs it |

## Definition of Done
- [ ] Both machines: `docker run --rm hello-world`, `code --version`, `ssh -T git@github.com` all succeed
- [ ] Repository has all governance files; `.env` verified ignored
- [ ] `.devcontainer/` builds on both; `python`, `node`, `uv` versions **byte-identical**
- [ ] **Cross-platform validation passed with no local workarounds**
- [ ] Baseline CI green on a PR; a failure blocks merge
- [ ] Branch protection active, **or** explicitly BLOCKED with instructions
- [ ] Jira project created, Sprint 1 imported, board usable
- [ ] ADR-0001 … ADR-0007 ratified
- [ ] `NVL-EXT-01` Razorpay KYC started
- [ ] Velocity reported to me for Sprint 2 re-baselining

## Sprint review (Day 14)
**Demonstrate, do not describe:** open both machines side by side, run the same commands, show identical output. Walk the repository. Show the CI run. Show the Jira board.

## Retrospective questions
1. Did we finish the committed points? If not, by how much?
2. Where did time actually go, installation, waiting, reading, troubleshooting?
3. Which estimate was most wrong, and in which direction?
4. What should Sprint 2 commit?
