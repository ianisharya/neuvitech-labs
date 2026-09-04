# macOS Setup: Day 1–2 (Required Commands Only)

Clean, linear path from a clean machine to a verified Dev Container. Not a replay of what was debugged to get here, the two build fixes found during setup (a broken apt source, a Postgres client version mismatch) are already committed in `.devcontainer/Dockerfile`, so a fresh clone builds correctly the first time. For the full investigation, see `docs/38-day-01-02-command-log.md`; for the prescriptive original, `docs/23-environment-setup-runbook.md`.

**Scope: through a working, verified container.** Nothing here touches application code, that starts Sprint 2.

---

## 1. Docker Desktop

Download from docker.com, install, launch, skip sign-in (not required).

**Settings → Resources:** set **6 GB RAM, 4 CPUs**. The default on some installs is 2 GB, which is not enough for the service set arriving in Sprint 2 and causes containers to die without a clear error.

**Settings → General:** confirm **VirtioFS** is selected (default on current versions).

Verify the daemon is actually running, `docker --version` succeeds even when it isn't:
```bash
docker run --rm hello-world
```

## 2. VS Code

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

## 3. Git and SSH

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

## 4. Clone

```bash
mkdir -p ~/code && cd ~/code
git clone git@github.com:ianisharya/neuvitech-labs.git
cd neuvitech-labs
```

```bash
git log --oneline # sanity check, should show real commits, not an empty repo
```

## 5. Open and build the container

```bash
code .
```
VS Code offers **"Reopen in Container"**: accept it. First build: 15–25 minutes, mostly waiting. Watch the log; it's the only way to see a failure rather than a silent hang.

If the prompt doesn't appear:
```
Cmd+Shift+P → Dev Containers: Reopen in Container
```

## 6. Verify

Inside the container terminal:
```bash
make doctor
```

Expect every line present, `python`, `node`, `npm`, `uv`, `psql` (16.x), `redis-cli`, `git`, `make`, `jq`, `docker`. `make doctor` exits non-zero and names anything missing; if it does, that's the report, not a failure to work around locally.

```bash
make help # confirm the command surface renders
```

---

**Setup is complete when `make doctor` reports every tool present.** Two things remain for Day 2 that aren't commands: reading `CONTRIBUTING.md` and `SECURITY.md` (NVL-102.4), and comparing this output line-by-line against the Windows machine once it reaches the same point (NVL-104).
