# ADR-0007: VS Code Dev Containers as the Cross-Platform Contract

**Status:** Accepted · **Date:** 2026-08-30

## Context
One engineer on macOS, one on Windows. The brief requires **one unified engineering workflow**, not two development tracks. Neither engineer is expert-level, so time lost to environment differences is time not spent on the product. The project spans 280 days, so any recurring friction compounds.

## Decision
Both engineers develop inside an identical Linux container defined by `.devcontainer/devcontainer.json` in the repository. Windows uses Docker Desktop with the WSL2 backend and the repository cloned **inside** the WSL2 filesystem. macOS uses Docker Desktop with VirtioFS.

## Alternatives Considered

**Native installs on both OSes with Docker only for services**: the common approach. Rejected: it leaves Python and Node version drift, PATH configuration, shell differences, line endings, and Windows C-extension compilation. Each is individually small and collectively a recurring tax over 280 days, and every one of them produces confusing errors for non-expert engineers.

**WSL2 on Windows + native on macOS, no container**: closer, but still two different Linux/macOS userlands with different package managers and library versions. Solves the shell problem, not the version-drift problem.

**Cloud development environments (Codespaces, Gitpod)**: excellent parity, but a recurring cost, dependent on connectivity, and slower for interactive work. Revisit if a third engineer joins and setup time becomes a bottleneck.

**Nix / devbox**: genuinely reproducible, but a steep learning curve for two non-expert engineers and a smaller community to search when stuck.

## Consequences
**Positive:** byte-identical toolchains · one set of commands after "Reopen in Container" · the environment is versioned with the code, so a dependency change is a reviewed PR · a new engineer is productive in under an hour · **eliminates an entire category of bug reports**.

**Negative:** Docker Desktop must run (~2 GB idle) · 15–25 minute first build · slightly slower file I/O than native (mitigated by WSL2-internal clone and VirtioFS) · one more concept to learn on day one.

## Trade-offs
We pay a one-off 25-minute build and a persistent ~2 GB of RAM to remove OS-difference debugging from 280 days of work. Given that neither engineer is expert-level and every hour is scarce, this trade is strongly favourable.

## Cost
Free. Docker Desktop is free for our use; VS Code and the extension are free.

## Security
The container runs as a non-root user. Secrets stay in `.env` on the host, mounted, and git-ignored. The container has no production credentials. Minor risk: a compromised base image, mitigated by pinning the digest and Trivy-scanning it in CI.

## Scalability
Scales to more engineers at zero marginal cost, the definition is already in the repository.

## Migration Path
If we ever abandon Dev Containers, the Dockerfile documents exactly what a native install must provide. Nothing is locked in.

## Revisit Trigger
File I/O performance becomes a measured bottleneck on Windows despite an in-WSL clone · a team member cannot run Docker for policy reasons · we move to cloud development environments.
