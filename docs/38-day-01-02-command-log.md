# 38: Day 1–2 Command Log

**What this is:** every command actually run (or given to run) while standing up the environment on 31 Aug – 1 Sep 2026. Part A is chronological, replay it end to end on a fresh machine. Part B is the same commands regrouped by category, look something up without hunting through the flow.

**Verification key:**
- [done] **Confirmed**: real output was seen and matched expectation
- [pending] **Given, not confirmed**: instructed but no output reported back (mainly Manuraj's track)
- (UI) **UI action**: not a typed command; a menu or command-palette action

Machine markers: macOS (Anish) · Windows/WSL2 (Manuraj)

---

## PART A: Chronological flow

### Phase 1: SSH key and GitHub access (macOS) [done]

```bash
ssh-keygen -t ed25519 -C "you@example.com"
```
Accepted the default path at the first prompt. Passphrase set, then added to Keychain so it's never asked again:
```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```
```bash
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
Pasted into GitHub → Settings → SSH and GPG keys → New SSH key. Verified:
```bash
ssh -T git@github.com
# → Hi ianisharya! You've successfully authenticated...
```

### Phase 2: Repository bootstrap on a fresh clone (macOS) [done]

```bash
mkdir -p ~/code && cd ~/code
git clone git@github.com:ianisharya/neuvitech-labs.git
cd neuvitech-labs
mkdir -p .devcontainer .github/ISSUE_TEMPLATE scripts docs
```

Governance files (produced earlier, downloaded to `~/Downloads`) moved into place:
```bash
D=~/Downloads
mv "$D/devcontainer.json" "$D/Dockerfile" "$D/post-create.sh" .devcontainer/
mv "$D/pull_request_template.md" .github/
mv "$D/bug_report.md" "$D/config.yml" .github/ISSUE_TEMPLATE/
mv "$D/doctor.sh" scripts/
mv "$D/.editorconfig" "$D/.gitattributes" "$D/.gitignore" \
 "$D/CODEOWNERS" "$D/CONTRIBUTING.md" "$D/Makefile" \
 "$D/README.md" "$D/SECURITY.md" .
```
`.env.example` needed a manual check, some browsers save it as `.env`:
```bash
ls -la ~/Downloads/.env*
mv ~/Downloads/.env.example .env.example # direction depends on how it downloaded
```

Verified the full set landed:
```bash
find . -path ./.git -prune -o -type f -print | sort
find . -path ./.git -prune -o -type f -print | wc -l # expect 16
```

### Phase 3: Permission fix on downloaded scripts (macOS) [done]

Browser-downloaded files came in at `600`; a bare `chmod +x` on top of that yields `711`, not `755`, the group/other read bits were never there to add to.

```bash
ls -l .devcontainer/post-create.sh scripts/doctor.sh
# → -rwx--x--x (wrong: need -rwxr-xr-x)
```
Fixed explicitly, not relatively:
```bash
chmod 755 .devcontainer/post-create.sh scripts/doctor.sh
```
Swept for any other file with the same problem:
```bash
find . -path ./.git -prune -o -type f -perm 600 -print
find . -path ./.git -prune -o -type f -perm 600 -exec chmod 644 {} +
```

### Phase 4: First push to an empty repository (macOS) [done]

No base branch exists on an empty repo, so no PR is possible, this bootstrap commit goes straight to `main` (the documented exception in `docs/19`).

```bash
git status --short # .env must NOT appear
git check-ignore -v .env 2>&1 || echo "no .env present, fine"
git config user.name && git config user.email
git remote -v # confirm origin already points at the right URL
git branch -M main
git add -A
git status --short # read every line before committing
```
```bash
git commit \
 -m "chore: NVL-102 bootstrap repository structure and documentation" \
 -m "Establishes the cross-platform contract (.devcontainer), governance
files, command interface (Makefile), and the nine-variable bootstrap
configuration surface. No application code, that begins Sprint 2. ..."
git push -u origin main
```
```bash
git log --oneline
git ls-files | wc -l
git ls-files | grep -c '^\.env$' # must be 0
```

### Phase 5: CODEOWNERS fix, once Manuraj's handle was known (macOS) [done]

```bash
cat > CODEOWNERS << 'EOF'
* @ianisharya @manu2raj
/apps/api/migrations/ @ianisharya @manu2raj
# ... (full pattern list)
EOF
grep -c 'teammate-github-handle' CODEOWNERS # must print 0
```

### Phase 6: VS Code not offering "Reopen in Container" (macOS) [done] (resolved)

```
(UI) Cmd+Shift+X → search "Dev Containers" → confirm ms-vscode-remote.remote-containers installed
```
```bash
pwd
ls -la .devcontainer/
git log --oneline -1
git ls-files .devcontainer/
```
```
(UI) Cmd+Shift+P → "Dev Containers: Reopen in Container"
(UI) Cmd+Shift+P → "Developer: Reload Window" (if the command didn't appear)
```
```bash
docker ps # confirms the daemon is actually reachable
```
Cause turned out to be the extension not yet installed, resolved after Check 1.

### Phase 7: First real build failure: opaque `exit code: 100` (macOS) [done]

```bash
cd ~/code/neuvitech-labs
docker build -f .devcontainer/Dockerfile -t nvl-debug .
```
Summary line only, re-ran with full, uncollapsed output:
```bash
docker build --no-cache --progress=plain -f .devcontainer/Dockerfile -t nvl-debug . 2>&1 | tee build-debug.log
```
Connectivity sanity check run in parallel:
```bash
docker run --rm alpine sh -c "apk add --no-cache curl && curl -sI https://deb.debian.org"
```
Corporate-network check (Zscaler suspected, given prior Jira screenshots showed a corporate instance):
```bash
ps aux | grep -i zscaler | grep -v grep
ls /Applications | grep -i zscaler
security find-certificate -a -c "Zscaler" /Library/Keychains/System.keychain 2>/dev/null | grep -i zscaler
scutil --nc list 2>/dev/null | grep -i zscaler
```
Ruled out, office laptop with Zscaler was shut down; this build ran on the personal laptop with no VPN. The `--progress=plain` log then showed the real cause: `NO_PUBKEY 62D54FD4003F6525` from a Yarn apt source shipped in the base image.

### Phase 8: Yarn fix applied and verified (macOS) [done]

```bash
grep -rn "yarnpkg" .devcontainer/ # confirmed: not ours, came from the base image
```
Added `RUN rm -f /etc/apt/sources.list.d/yarn.list 2>/dev/null || true` before the first `apt-get update` in the Dockerfile, then:
```bash
docker build --no-cache -f .devcontainer/Dockerfile -t nvl-debug . 2>&1 | tail -40
```
```
(UI) Cmd+Shift+P → "Dev Containers: Reopen in Container"
```
Inside the container:
```bash
make doctor
```
Confirmed: python 3.12.11, node 22.23.2, uv 0.5.11, git, make, jq, docker, all present. **`psql` reported 15.19 against a spec of 16**: flagged, not yet fixed at this point.

### Phase 9: psql version fix (macOS) [done]

Added the PGDG apt source (key import + `postgresql-client-16` in place of `postgresql-client`) to the Dockerfile. Forced a full rebuild rather than a reopen, since the image was already cached:
```
(UI) Cmd+Shift+P → "Dev Containers: Rebuild Container"
```
```bash
make doctor # re-checked, psql now 16.x
```

### Phase 10: Committing the Dockerfile fixes (macOS) [done]

```bash
git add .devcontainer/Dockerfile docs/36-troubleshooting-guide.md
git commit -m "fix: NVL-103 correct base image apt sources (Yarn key, psql version)

..."
git push
```

### Phase 11: devcontainer-lock.json (macOS) [done]

Appeared as untracked after the rebuild, the Dev Containers CLI generates it when `devcontainer.json` declares Features.
```bash
git status # (aliased locally as `git st`)
cat .devcontainer/devcontainer-lock.json # sanity check before committing
```
`.gitignore` updated with an explicit "intentionally tracked" comment block, then:
```bash
git add .gitignore .devcontainer/devcontainer-lock.json
git commit -m "chore: NVL-103 track devcontainer Feature lockfile, document intent

..."
git push
git status --short # nothing left untracked
```

### Phase 12: Manuraj's parallel track [pending] given, not confirmed

**PowerShell as Administrator:**
```powershell
wsl --install
# reboot
wsl --list --verbose # expect: Ubuntu Running 2
```
If it showed version 1:
```powershell
wsl --set-version Ubuntu 2
wsl --set-default-version 2
```
**Inside the Ubuntu (WSL2) terminal, never PowerShell, from here on:**
```bash
sudo apt update && sudo apt install -y git
git config --global user.name "Manuraj"
git config --global user.email "manu2raj@yahoo.co.in"
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global core.autocrlf input
ssh-keygen -t ed25519 -C "manu2raj@yahoo.co.in"
cat ~/.ssh/id_ed25519.pub # paste into GitHub manually, no WSL equivalent of pbcopy was given
ssh -T git@github.com
```
```bash
mkdir -p ~/code && cd ~/code # inside WSL2, NEVER /mnt/c/
git clone git@github.com:ianisharya/neuvitech-labs.git
cd neuvitech-labs
code .
```
Re-synced at least twice as fixes landed on `main`:
```bash
git pull
```
Then, matching Anish's Phase 8–9:
```
(UI) Cmd+Shift+P → "Dev Containers: Reopen in Container"
```
```bash
make doctor
```
**No output has come back from his side yet.** This entire phase is instructions given, not confirmed results, treat accordingly.

---

## PART B: By category

### SSH / GitHub authentication
```bash
ssh-keygen -t ed25519 -C "you@example.com"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519 # (macOS) only
cat ~/.ssh/id_ed25519.pub
pbcopy < ~/.ssh/id_ed25519.pub # (macOS) only
ssh -T git@github.com
```

### Git: remote and branch setup
```bash
git clone git@github.com:ianisharya/neuvitech-labs.git
git remote -v
git remote set-url origin <url> # only if wrong, never `add` over an existing remote
git remote add origin <url> # only if genuinely absent
git branch -M main
```

### Git: staging, committing, pushing
```bash
git status --short
git status # full form
git add -A
git add <specific files>
git commit -m "<subject>" -m "<body>"
git push -u origin main # -u only on the very first push
git push # subsequent pushes
git pull
git log --oneline
git check-ignore -v .env
git config user.name
git config user.email
```

### Git: verification
```bash
git ls-files | wc -l
git ls-files | grep -c '^\.env$'
git ls-files .devcontainer/
git log --oneline -1
```

### File system / permissions
```bash
mkdir -p <dirs>
mv <source> <dest>
ls -la
ls -l <file>
chmod 755 <file> # explicit, not chmod +x
find . -path ./.git -prune -o -type f -perm 600 -print
find . -path ./.git -prune -o -type f -perm 600 -exec chmod 644 {} +
find . -path ./.git -prune -o -type f -print | sort
find . -path ./.git -prune -o -type f -print | wc -l
pwd
```

### Docker: direct build and diagnostics
```bash
docker ps
docker build -f .devcontainer/Dockerfile -t nvl-debug .
docker build --no-cache -f .devcontainer/Dockerfile -t nvl-debug .
docker build --no-cache --progress=plain -f .devcontainer/Dockerfile -t nvl-debug . 2>&1 | tee build-debug.log
docker run --rm alpine sh -c "apk add --no-cache curl && curl -sI https://deb.debian.org"
```

### VS Code: Dev Containers (UI, not terminal)
```
Cmd+Shift+X → Extensions panel, search "Dev Containers"
Cmd+Shift+P → "Dev Containers: Reopen in Container"
Cmd+Shift+P → "Dev Containers: Rebuild Container" ← use after any Dockerfile change
Cmd+Shift+P → "Developer: Reload Window"
```
**Reopen vs Rebuild matters.** Reopen may reuse cached layers; Rebuild forces a fresh build. Any time the Dockerfile changes, use Rebuild, this was the actual mistake risk after the psql fix.

### Container-internal verification
```bash
make doctor # the whole point of this target, one command, compares cleanly across machines
make help
make clean
```

### Corporate network / proxy diagnosis (macOS)
```bash
ps aux | grep -i zscaler | grep -v grep
ls /Applications | grep -i zscaler
security find-certificate -a -c "Zscaler" /Library/Keychains/System.keychain 2>/dev/null | grep -i zscaler
scutil --nc list 2>/dev/null | grep -i zscaler
```

### Windows / WSL2 (given to Manuraj, not yet confirmed)
```powershell
wsl --install
wsl --list --verbose
wsl --set-version Ubuntu 2
wsl --set-default-version 2
```
```bash
sudo apt update && sudo apt install -y git
```

---

## Not yet used: Makefile surface arriving in later sprints

For completeness, referenced but never run because the code they operate on doesn't exist yet:

```
make up / down / logs / ps [Sprint 2, NVL-202]
make api / web / worker [Sprint 2, NVL-201, NVL-209]
make migrate / migration / seed [Sprint 2, NVL-205, NVL-206]
make test / test-api / check [Sprint 2, NVL-210]
make guardrails [available now, scripts/check_guardrails.py not yet copied in]
```
