# 19 — Git & Version Control

## 1. Branching model

**Protected `main` + short-lived branches + environment promotion.**

```
main (protected, always deployable, auto-deploys to DEV)
 ├── feature/NVL-123-catalog-type-registry
 ├── fix/NVL-145-coupon-race-condition
 ├── chore/NVL-160-bump-deps
 └── hotfix/NVL-201-webhook-signature   → main + immediate PROD promotion
```

**Why not GitFlow:** a long-lived `develop` pays off only with parallel release trains, which we do not have. It would buy merge conflicts, duplicated CI and drift, in exchange for nothing. Environment promotion via GitHub Environments gives us the DEV/QA/PROD gates people usually reach for `develop` to get.

**Feature flags, not long branches.** Incomplete work merges to `main` disabled behind a flag (doc 05 §6). This is what makes trunk-based development safe.

## 2. Branch protection on `main`
No direct pushes · PR required · ≥1 approval from the other track · required status checks · conversation resolution required · linear history · signed commits · force-push and deletion blocked · CODEOWNERS review on `migrations/`, `security/`, `payments/`, `.github/`, `infrastructure/`.

## 3. Daily workflow

```bash
# start of session
cd ~/code/neuvitech-labs && code .        # reopens in container
git checkout main && git pull
make up                                    # ~40 s

# work
git checkout -b feature/NVL-123-short-slug
# ... I implement, you review ...
make check                                 # same gates as CI
git add -p                                 # review each hunk
git commit -m "feat(catalog): NVL-123 add catalog item type registry"
git push -u origin feature/NVL-123-short-slug
gh pr create --fill

# after approval and green CI: Squash and merge via the UI
git checkout main && git pull
git branch -d feature/NVL-123-short-slug
```

`git add -p` rather than `git add .` is the last checkpoint before a stray `console.log` or hardcoded token enters history.

## 4. Two-engineer rules
1. **One branch per ticket per person.** Never both on one branch (Sprint 1 Day 1 is the single documented exception — the repo does not exist yet).
2. **Track A merges schema-affecting changes first**, then Track B regenerates types.
3. **Each reviews the other's PR.** Satisfies the approval requirement and means no code reaches `main` unseen.
4. **Pull frequently.** A branch alive three days across two people is a merge conflict with a countdown timer.

## 5. Common situations

| Situation | Command |
|---|---|
| Wrong branch | `git stash && git checkout -b correct && git stash pop` |
| Amend last commit (unpushed) | `git commit --amend` |
| Undo last commit, keep changes | `git reset --soft HEAD~1` |
| Branch behind main | `git rebase main` then `git push --force-with-lease` |
| Two Alembic heads | `alembic merge -m "merge heads" <rev1> <rev2>` — avoid by keeping to rule 2 |
| **Committed a secret** | **Rotate the credential immediately.** Removing the file is not the fix — it is still in history |

## 6. Releases
Semantic version tags on `main` (`v0.3.0`), changelog auto-generated from Conventional Commits, GitHub Release recording the **image digest and Alembic head** so rollback is deterministic. Every release lists the `NVL-` keys it contains.

## 7. Traceability
```
Jira NVL-123 → branch feature/NVL-123-slug → commits "…: NVL-123 …"
   → PR titled "NVL-123 …" → CI run → DEV → QA → PROD → release tag
```
Enforced by a commit-msg hook and a CI check. **I will not claim a Jira↔GitHub integration is live unless it has been configured and verified.**
