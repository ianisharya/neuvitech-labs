# 23 — Environment Setup Runbook

**Clean machine → working environment.** Sprint 1, Days 1–7.
**Legend:** 🍎 macOS · 🪟 Windows · 🔵 both identical

Both of you work in parallel; you are not blocked by each other until Phase D.

---

## Phase A — Host prerequisites

### 🪟 A1. WSL2 — 45 min
1. **PowerShell as Administrator:** `wsl --install`
2. **Reboot.** Not optional.
3. Ubuntu opens; set a UNIX username and password. **This is not your Windows password** — write it down; `sudo` needs it.
4. Verify: `wsl --list --verbose` → `Ubuntu Running 2`. The `2` is what matters.

| Failure | Fix |
|---|---|
| `0x80370102` | Virtualisation disabled — enable Intel VT-x / AMD-V in BIOS |
| Shows version `1` | `wsl --set-version Ubuntu 2` then `wsl --set-default-version 2` |
| Command not recognised | Update to Windows 10 21H2+ or Windows 11 |

### 🔵 A2. Docker Desktop — 50 min
1. Download from docker.com (~600 MB; the download is most of the time)
2. 🍎 `.dmg` → drag to Applications → launch → approve the privileged helper
   🪟 Run the `.exe`; **tick "Use WSL 2 instead of Hyper-V"**; reboot if asked
3. Launch, accept the licence, skip sign-in
4. **Settings → Resources: 6 GB RAM, 4 CPUs.** *Some installs default to 2 GB, which is not enough and causes containers to die without a clear error*
5. 🪟 **Settings → Resources → WSL Integration:** enable for Ubuntu
6. 🍎 **Settings → General:** confirm VirtioFS
7. Verify (🍎 Terminal, 🪟 **Ubuntu WSL** terminal):
   ```bash
   docker --version && docker compose version && docker run --rm hello-world
   ```
   **The third command is the real test** — the first two succeed even when the daemon is not running.

### 🔵 A3. VS Code — 20 min
Download from code.visualstudio.com. 🍎 unzip → Applications → Command Palette → *Shell Command: Install 'code' command in PATH*. 🪟 **User Installer**, tick "Add to PATH". Verify `code --version`.
🪟 Install on **Windows**, not inside WSL — it connects into WSL automatically.

### 🔵 A4. Extensions — 20 min
**Required:** Dev Containers · Docker · 🪟 WSL
**Recommended:** GitLens · Error Lens · EditorConfig · GitHub Copilot · GitHub Pull Requests
Language extensions (Python, Pylance, Ruff, ESLint, Prettier, Tailwind) install **automatically inside the container** — do not install them on the host.

### 🔵 A5. Git — 20 min
🍎 `brew install git` or accept the Xcode CLT prompt · 🪟 in WSL: `sudo apt update && sudo apt install -y git`
```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global core.autocrlf input
```
`core.autocrlf input` matters: without it every file looks modified to the other person.

### 🔵 A6. SSH key — 25 min
```bash
ssh-keygen -t ed25519 -C "you@example.com"    # Enter three times
cat ~/.ssh/id_ed25519.pub                      # → GitHub → Settings → SSH keys
ssh -T git@github.com                          # expect: Hi <username>!
```
🪟 Generate **inside WSL**, not PowerShell.
**Also confirm now: who has repository admin?**

---

## Phase B — Repository and container

### 🔵 B1. Clone — 10 min
```bash
mkdir -p ~/code && cd ~/code
git clone git@github.com:ianisharya/neuvitech-labs.git
cd neuvitech-labs
```
> 🪟 **Critical:** inside the WSL2 filesystem (`~/code/…`). Cloning to `/mnt/c/Users/…` makes every file operation ~10× slower for nine months. If you clone to the wrong place, delete and re-clone.

First clone shows `warning: You appear to have cloned an empty repository.` — **correct.**

### 🔵 B2. Open — 5 min
`code .` 🪟 from the WSL terminal. A green **WSL: Ubuntu** badge appears bottom-left. If not, you opened from Windows — close and retry from WSL.

### 🔵 B3. Reopen in Container — 35 min *(first time)*
VS Code prompts *"Reopen in Container"* → click it. Or Command Palette → *Dev Containers: Reopen in Container*.

**15–25 minutes the first time.** Watch the log — it is the only way to see a failure. Subsequent opens: 10–20 seconds.

```bash
python --version   # 3.12.x
node --version     # v22.x
uv --version
make help
```

| Failure | Fix |
|---|---|
| Package downloads fail | Corporate proxy or VPN — **tell me**, it also affects `uv sync`, `npm ci`, `docker pull` |
| Cannot connect to daemon | Docker Desktop not running |
| Terminal unusable after build | Command Palette → *Developer: Reload Window* |
| Very slow on Windows | Repo is on `/mnt/c/` — re-clone into WSL |

---

## Phase C — Services

### 🔵 C1. Environment file — 10 min
```bash
cp .env.example .env
git status --short        # .env must NOT appear
```
Only the nine bootstrap variables; defaults work locally. **No secrets needed until Sprint 7.**

### 🔵 C2. Start — 15 min
```bash
make up        # first run pulls images: 5–10 min. Later: 30–60 s
make ps        # every service Up and healthy
```
**Port conflicts are the most likely first-run failure.** `lsof -i :5432` finds the culprit. 5432 (local Postgres), 6379 (local Redis), 3000 (another Node app), 8000 (another dev server). **Tell me which port and I remap it in Compose** — do not edit it yourself, it must stay identical on both machines.

### 🔵 C3. Verify — 20 min
```bash
make migrate && make seed
curl http://localhost:8000/health
curl http://localhost:8000/ready
```
| URL | Expect |
|---|---|
| `localhost:3000` | Server-rendered status page |
| `localhost:8000/api/v1/docs` | Swagger UI |
| `localhost:8025` | Mailpit inbox |
| `localhost:9001` | MinIO console |
| `localhost:3001` | Grafana (from Sprint 4) |

### 🔵 C4. Failure-path check — 10 min
The step people skip. It proves health checks are real.
```bash
docker compose stop postgres
curl http://localhost:8000/ready     # expect 503 naming postgres
docker compose start postgres
curl http://localhost:8000/ready     # expect 200
```

### 🔵 C5. Test suite — 15 min
```bash
make check      # lint + typecheck + tests — the same gates CI runs
```

---

## Phase D — Cross-platform validation *(Day 7, both together)*

The step that proves the Dev Container decision worked.

1. Both run `make check` — **identical results**
2. Both run `make up` and hit all URLs — **identical behaviour**
3. One commits a trivial change; the other pulls and runs — **works unchanged**
4. Compare `python`, `node`, `uv` versions — **byte-identical**
5. `git status` clean on both — no line-ending noise

**Any divergence is a bug in `devcontainer.json` and I fix it centrally. Do not work around it locally** — a local workaround reintroduces exactly the drift the container exists to prevent.

---

## Time summary

| Phase | 🍎 | 🪟 |
|---|---|---|
| A — Host | 2 h 15 m | 3 h 00 m |
| B — Repo and container | 50 m | 50 m |
| C — Services | 1 h 10 m | 1 h 10 m |
| D — Validation (shared) | 45 m | 45 m |
| **Total** | **≈ 5 h** | **≈ 5 h 45 m** |

Roughly 60% of Sprint 1. Real work — **you cannot review code on a machine that cannot run it.**

## Daily startup thereafter
```bash
cd ~/code/neuvitech-labs && code .    # reopens in container
make up                                # ~40 s
git pull
```
About two minutes, budgeted in every day plan.
