# Windows Setup: Day 1–2 (Required Commands Only)

Clean, linear path from a clean machine to a verified Dev Container. The two build fixes found during setup on macOS (a broken apt source, a Postgres client version mismatch) are already committed in `.devcontainer/Dockerfile`, a fresh clone builds correctly the first time, no debugging required. Full investigation: `docs/38-day-01-02-command-log.md`; prescriptive original: `docs/23-environment-setup-runbook.md`.

**Two corrections against what was said elsewhere in this project:** the command palette shortcut is **`Ctrl+Shift+P`**, not `Cmd+Shift+P`, that's Mac-only and was given to you in error earlier. And there's a real Windows equivalent for the macOS Keychain/`pbcopy` steps, given properly below rather than left as a gap.

**Scope: through a working, verified container.** Nothing here touches application code, that starts Sprint 2.

---

## 1. WSL2: do this first, everything else depends on it

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

If `wsl --install` fails with `0x80370102`: virtualisation is disabled. Reboot into BIOS/UEFI and enable Intel VT-x or AMD-V.

**From here on, every command runs in the Ubuntu (WSL) terminal, never PowerShell or CMD**, unless marked otherwise.

## 2. Docker Desktop: installed from Windows, configured for WSL2

Download from docker.com, run the `.exe`. **Tick "Use WSL 2 instead of Hyper-V."**

**Settings → Resources:** **6 GB RAM, 4 CPUs.** The default on some installs is 2 GB, which is not enough and causes containers to die without a clear error.

**Settings → Resources → WSL Integration:** enable for **Ubuntu**.

Verify from the WSL terminal, `docker --version` succeeds even when the daemon isn't running, so the real test is:
```bash
docker run --rm hello-world
```

## 3. VS Code: installed from Windows, connects into WSL

Download the **User Installer** from code.visualstudio.com. **Tick "Add to PATH."**

Install two extensions from the Windows side (Extensions panel, `Ctrl+Shift+X`):
- **WSL** (`ms-vscode-remote.remote-wsl`), required for VS Code to connect into the Ubuntu filesystem at all
- **Dev Containers** (`ms-vscode-remote.remote-containers`), required before VS Code will ever offer "Reopen in Container"

## 4. Git and SSH: inside WSL

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
Accept the default path. If prompted `already exists. Overwrite (y/n)?`, answer **n**: use the existing key instead.

WSL has no Keychain daemon, so the macOS-equivalent step is `ssh-agent` plus a startup hook so it persists across new terminal sessions:
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
Skipping the passphrase entirely is also a reasonable choice for a personal machine, either is defensible, just be consistent.

`clip.exe` is the WSL-to-Windows-clipboard equivalent of `pbcopy`, reachable directly from the Linux side:
```bash
clip.exe < ~/.ssh/id_ed25519.pub
```
Paste into GitHub → **Settings → SSH and GPG keys → New SSH key**.

```bash
ssh -T git@github.com
# → Hi <username>! You've successfully authenticated, but GitHub does not provide shell access.
```

## 5. Clone: inside WSL2, never `/mnt/c/`

```bash
mkdir -p ~/code && cd ~/code
git clone git@github.com:ianisharya/neuvitech-labs.git
cd neuvitech-labs
```

> **Critical:** the repository must live inside the WSL2 filesystem (`~/code/…`). Cloning to `/mnt/c/Users/…` makes every file operation roughly ten times slower and will make file-watching and tests painful for the rest of the programme. If you cloned to the wrong place, delete it and re-clone.

```bash
git log --oneline # sanity check, should show real commits, not an empty repo
```

## 6. Open and build the container

```bash
code .
```
Run **from the WSL terminal**, not from a Windows shell, VS Code opens with a green **WSL: Ubuntu** badge bottom-left. If that badge is missing, you opened it from Windows; close and retry from WSL.

VS Code offers **"Reopen in Container"**: accept it. First build: 15–25 minutes, mostly waiting. Watch the log.

If the prompt doesn't appear:
```
Ctrl+Shift+P → Dev Containers: Reopen in Container
```

## 7. Verify

Inside the container terminal:
```bash
make doctor
```

Expect every line present, `python`, `node`, `npm`, `uv`, `psql` (16.x), `redis-cli`, `git`, `make`, `jq`, `docker`. `make doctor` exits non-zero and names anything missing; if it does, that's the report, not a failure to work around locally.

```bash
make help # confirm the command surface renders
```

---

**Setup is complete when `make doctor` reports every tool present.** The moment it does, compare the output **line by line against the macOS output**: that comparison is NVL-104, and it's the actual proof the Dev Container decision works, not a formality.
