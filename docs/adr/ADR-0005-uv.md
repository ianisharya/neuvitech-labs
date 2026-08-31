# ADR-0005 — uv as the Python Project Manager

**Status:** Accepted · **Date:** 2026-08-30

## Context
The brief mandates uv. Verified present in my environment at 0.11.7.

## Decision
uv for Python version management, dependency resolution, locking, virtual environments and task running. `uv.lock` committed. CI installs with `uv sync --frozen`.

## Alternatives Considered
**Poetry** — mature and widely used, but markedly slower resolution and a historically awkward relationship with PEP 621 metadata. **pip + pip-tools + pyenv** — three tools where one suffices. **PDM / Hatch** — capable, smaller ecosystems.

None was seriously contested: the brief mandates uv, and uv is independently the strongest current option.

## Consequences
**Positive:** one tool for Python versions, dependencies, venvs and scripts · 10–100× faster resolution, which compounds across every CI run · lockfile gives reproducible installs · manages the interpreter itself, eliminating system-Python drift.
**Negative:** younger than Poetry · some tooling still assumes `requirements.txt` (mitigated by `uv export`) · fast-moving, so pin the uv version in the container image.

## Cost
Free and open source.

## Security
Committed lockfile with hashes prevents dependency substitution. `uv sync --frozen` fails in CI if the lockfile and manifest disagree, so an unreviewed dependency cannot enter through a stale lock. Integrates with `pip-audit` and Dependabot.

## Scalability
Faster CI installs compound across hundreds of runs.

## Migration Path
`pyproject.toml` is standard PEP 621; `uv export` produces `requirements.txt` if a tool demands one.

## Revisit Trigger
Only if uv were abandoned upstream. Migration would be low-cost given standard metadata.
