# 23: Environment Setup Runbook

**Full canonical path: clean machine → verified Dev Container → running services.** Structured so every macOS step completes before any Windows step begins, read and run top to bottom, not side by side.

**Three related documents, three different scopes:**
- **This document**: the complete journey, both OSes, through service verification. Read this once, fully, before Day 1.
- `setup-macos-day1-2.md` / `setup-windows-day1-2.md`, the trimmed version, one OS each, stopping at a verified container. Use these as a quick reference once you already know the territory.
- `docs/38-day-01-02-command-log.md`, the historical record of what was actually run, including two real bugs found and fixed along the way. Not a runbook, a replay.

**The two bugs that debugging once found are already fixed in `.devcontainer/Dockerfile`.** A fresh clone today builds clean on the first pass, nobody needs to rediscover a broken Yarn apt source or a Postgres client version mismatch. Full writeup if you're curious: `docs/36-troubleshooting-guide.md` §11.

**Phase gate, stated once here so it doesn't cause the confusion it caused for real on 31 Aug 2026:** Phases A and B, for both OSes, are Sprint 1 work, host setup and the Dev Container. **Phase C (services) does not work until `apps/api/` exists, which is Sprint 2.** Running `make up` or `curl localhost:8000/health` before then fails with a connection error, not because anything is broken, but because there is nothing there yet to connect to. If you're doing this on Day 1 or 2, stop after Phase B.

---

# PART ONE: macOS

## A1. Docker Desktop

Download from docker.com, install, launch, skip sign-in (not required).

**Settings → Resources:** set **6 GB RAM, 4 CPUs**. The default on some installs is 2 GB, which is not enough for the service set arriving in Sprint 2 and causes containers to die without a clear error.

**Settings → General:** confirm **VirtioFS** is selected (default on current versions).

Verify the daemon is actually running, `docker --version` succeeds even when it isn't:
```bash
docker run --rm hello-world
```

| Failure | Fix |
|---|---|
| "Docker Desktop is damaged" | Quarantine flag: `xattr -d com.apple.quarantine /Applications/Docker.app` |
| `Cannot connect to the Docker daemon` | Docker Desktop isn't running, launch it, wait for the whale icon to stop animating |
| Containers die immediately | RAM allocation too low, see above |

## A2. VS Code

Download from code.visualstudio.com, unzip to Applications.

```bash
```
Command Palette (`Cmd+Shift+P`) → **Shell Command: Install 'code' command in PATH**

```bash
code --version
```

**Install the Dev Containers extension**: required before VS Code will ever offer "Reopen in Container":
```
Cmd+Shift+X → search "Dev Containers" → install ms-vscode-remote.remote-containers
```

## A3. Git and SSH

```bash
git --version # accept the Xcode Command Line Tools prompt if offered
```

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com" # must match your GitHub account
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global core.autocrlf input
```
`core.autocrlf input` matters: without it every file looks modified to the other person.

```bash
ssh-keygen -t ed25519 -C "you@example.com"
```
Accept the default path. If prompted `already exists. Overwrite (y/n)?`, answer **n**: you have an existing key, use it instead.

Add the key to Keychain so the passphrase is never asked again:
```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
cat >> ~/.ssh/config << 'EOF'
Host github.com
 AddKeysToAgent yes
 UseKeychain yes
 IdentityFile ~/.ssh/id_ed25519
EOF
```

```bash
pbcopy < ~/.ssh/id_ed25519.pub
```
Paste into GitHub → **Settings → SSH and GPG keys → New SSH key**.

```bash
ssh -T git@github.com
# → Hi <username>! You've successfully authenticated, but GitHub does not provide shell access.
```

## A4. Clone

```bash
mkdir -p ~/code && cd ~/code
git clone git@github.com:ianisharya/neuvitech-labs.git
cd neuvitech-labs
```

```bash
git log --oneline # sanity check, real commits, not an empty repo
```

## B1. Open and build the container

```bash
code .
```
VS Code offers **"Reopen in Container"**: accept it. First build: 15–25 minutes, mostly waiting. Watch the log; it's the only way to see a failure rather than a silent hang.

If the prompt doesn't appear:
```
Cmd+Shift+P → Dev Containers: Reopen in Container
```

**Any Dockerfile change from here on uses Rebuild, not Reopen**: Reopen may reuse cached layers:
```
Cmd+Shift+P → Dev Containers: Rebuild Container
```

| Failure | Fix |
|---|---|
| Package downloads fail | Corporate proxy or VPN, check Docker Desktop's proxy settings before assuming the Dockerfile is broken |
| Terminal unusable after build | Command Palette → *Developer: Reload Window* |

## B2. Verify

Inside the container terminal:
```bash
make doctor
```
Expect every line present, `python`, `node`, `npm`, `uv`, `psql` (16.x), `redis-cli`, `git`, `make`, `jq`, `docker`. `make doctor` exits non-zero and names anything missing.

```bash
make help # confirm the command surface renders
```

**macOS is done here.** Do not continue into Phase C unless `apps/api/` genuinely exists in the repository, check `git log --oneline -- apps/api` if unsure.

---

## C1. Services *(Sprint 2 only: stop here on Day 1–2)*

```bash
cp .env.example .env
git status --short # .env must NOT appear
```

```bash
make up # first run pulls images: 5–10 min. Later: 30–60 s
make ps # every service Up and healthy
```

**Port conflicts are the most likely first-run failure.**
```bash
lsof -i :5432 # find what's using the port
```
| Port | Conflicts with |
|---|---|
| 5432 | A local PostgreSQL install |
| 6379 | A local Redis |
| 3000 | Another Node app |
| 8000 | Another dev server |

Report the conflicting port rather than editing `docker-compose.yml` yourself, the mapping needs to stay identical on both machines.

## C2. Verify the stack

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

## C3. Failure-path check

The step people skip. It proves health checks are real, not decorative.
```bash
docker compose stop postgres
curl http://localhost:8000/ready # expect 503 naming postgres
docker compose start postgres
curl http://localhost:8000/ready # expect 200
```

## C4. Test suite

```bash
make check # lint + typecheck + tests, the same gates CI runs
```

**macOS Phase C complete.**

---

# PART TWO: Windows

**Every command below runs in the Ubuntu (WSL) terminal, never PowerShell or CMD, except the two explicitly marked PowerShell.**

## A1. WSL2: do this first, everything else depends on it

**In PowerShell, as Administrator:**
```powershell
wsl --install
```
**Reboot.** Not optional.

Ubuntu opens automatically and asks for a UNIX username and password, **this is not your Windows password**, write it down, `sudo` needs it.

```powershell
wsl --list --verbose
```
Expect `Ubuntu Running 2`, the `2` is what matters.

If it shows `1`:
```powershell
wsl --set-version Ubuntu 2
wsl --set-default-version 2
```

| Failure | Fix |
|---|---|
| `0x80370102` | Virtualisation disabled, enable Intel VT-x / AMD-V in BIOS/UEFI, reboot |
| `wsl --install` not recognised | Windows too old, update to Windows 10 21H2+ or Windows 11 |

## A2. Docker Desktop: installed from Windows, configured for WSL2

Download from docker.com, run the `.exe`. **Tick "Use WSL 2 instead of Hyper-V."**

**Settings → Resources:** **6 GB RAM, 4 CPUs.**

**Settings → Resources → WSL Integration:** enable for **Ubuntu**.

Verify from the WSL terminal:
```bash
docker run --rm hello-world
```

| Failure | Fix |
|---|---|
| `docker` not found in WSL | WSL Integration not enabled, see above |
| Containers die immediately | RAM allocation too low |

## A3. VS Code: installed from Windows, connects into WSL

Download the **User Installer**, tick **"Add to PATH."**

Install two extensions from the Windows side (`Ctrl+Shift+X`):
- **WSL** (`ms-vscode-remote.remote-wsl`), required for VS Code to connect into the Ubuntu filesystem at all
- **Dev Containers** (`ms-vscode-remote.remote-containers`), required before VS Code will ever offer "Reopen in Container"

## A4. Git and SSH: inside WSL

```bash
sudo apt update && sudo apt install -y git
git --version
```

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com" # must match your GitHub account
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global core.autocrlf input
```

```bash
ssh-keygen -t ed25519 -C "you@example.com"
```
Accept the default path. If prompted `already exists. Overwrite (y/n)?`, answer **n**.

WSL has no Keychain daemon, the macOS-equivalent step is `ssh-agent` plus a startup hook so it persists across new terminal sessions:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat >> ~/.bashrc << 'EOF'
if [ -z "$SSH_AUTH_SOCK" ]; then
 eval "$(ssh-agent -s)" > /dev/null
 ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi
EOF
```
Skipping the passphrase entirely is also reasonable for a personal machine.

`clip.exe` is the WSL-to-Windows-clipboard equivalent of macOS's `pbcopy`, reachable directly from the Linux side:
```bash
clip.exe < ~/.ssh/id_ed25519.pub
```
Paste into GitHub → **Settings → SSH and GPG keys → New SSH key**.

```bash
ssh -T git@github.com
```

## A5. Clone: inside WSL2, never `/mnt/c/`

```bash
mkdir -p ~/code && cd ~/code
git clone git@github.com:ianisharya/neuvitech-labs.git
cd neuvitech-labs
```

> **Critical:** the repository must live inside the WSL2 filesystem. Cloning to `/mnt/c/Users/…` makes every file operation roughly ten times slower for the rest of the programme. To confirm you're in the right place: `df -T .` should report `ext4`, never `drvfs`. If you cloned to the wrong place, delete it and re-clone.

```bash
git log --oneline
```

## B1. Open and build the container

```bash
code .
```
Run **from the WSL terminal**. VS Code opens with a green **WSL: Ubuntu** badge bottom-left, if that badge is missing, close and reopen from WSL instead.

VS Code offers **"Reopen in Container"**: accept it. First build: 15–25 minutes.

If the prompt doesn't appear:
```
Ctrl+Shift+P → Dev Containers: Reopen in Container
```

**Any Dockerfile change from here on uses Rebuild, not Reopen:**
```
Ctrl+Shift+P → Dev Containers: Rebuild Container
```

## B2. Verify

```bash
make doctor
```
Expect every line present, same ten tools as macOS, and **the output must be byte-identical to the macOS `make doctor` output**, not merely similar. That comparison is the actual proof the Dev Container decision works; treat it as a real check, not a formality.

```bash
make help
```

**Windows is done here.** Do not continue into Phase C unless `apps/api/` exists.

---

## C1. Services *(Sprint 2 only)*

```bash
cp .env.example .env
git status --short
```

```bash
make up
make ps
```

Port conflicts and their fixes are identical to macOS, see Part One, C1.

## C2. Verify the stack

Identical URLs and commands to macOS, C2.

## C3. Failure-path check

Identical to macOS, C3.

## C4. Test suite

```bash
make check
```

**Windows Phase C complete.**

---

# PART THREE: Cross-platform validation *(both engineers, together)*

The step that proves the Dev Container decision actually worked, not just that it was written to work. This was performed for real on 2 Sep 2026, `NVL-104` is closed, `make doctor` output confirmed byte-identical across both machines on two separate runs. The procedure below is what to repeat for any future engineer joining the team.

1. **Both run `make doctor`.** Compare line by line, not approximately.
2. One commits a trivial change; the other pulls and runs it without modification.
3. Both confirm `git status` is clean, no file shows as modified purely from line endings.
4. `df -T .` inside the Windows container reports `ext4`, not `drvfs`.
5. Record any divergence. **Fix it in `.devcontainer/`, never locally**: a local workaround reintroduces exactly the drift the container exists to prevent.

**Any divergence found is a bug in the container definition**, not something to route around on one machine.

---

## Setup time summary

| Phase | macOS | Windows |
|---|---|---|
| A, Host prerequisites | 2 h 15 m | 3 h 00 m |
| B, Repository and container | 50 m | 50 m |
| C, Services (Sprint 2) | 1 h 10 m | 1 h 10 m |
| Cross-platform validation (shared) | 30 m | 30 m |
| **Total through Phase B** | **≈ 3 h 05 m** | **≈ 3 h 50 m** |

Windows pays a WSL2 tax macOS does not. Both totals include the standard troubleshooting buffer for real first-attempt friction, proxy issues, RAM allocation, image pulls, not just the optimistic path.

## Daily startup, once set up

```bash
cd ~/code/neuvitech-labs && code . # reopens in container automatically
make up # ~40 s, once Phase C applies
git pull
```
About two minutes at the start of each session, on either machine.
