# ADR-0002: Python 3.12 + FastAPI, with Async SQLAlchemy

**Status:** Accepted · **Date:** 2026-08-30

## Context
The brief mandates `uv`, a Python project manager, so the backend is Python. Remaining questions: which framework, and, given a non-expert team, async or sync data access.

## Decision
FastAPI + Pydantic v2 + SQLAlchemy 2.0 (async) + Alembic.

## Alternatives Considered
**Django + DRF**: genuinely tempting: ORM, migrations, auth and admin included. Rejected because (a) its async story is weaker and our AI gateway, webhook handling and provider calls are I/O-bound; (b) Django Admin is a data-editing tool, not the workflow-driven, settings-generated admin console this product requires, we would build our own regardless, paying Django's async cost for a benefit we then discard; (c) DRF serializers duplicate what Pydantic already does, and our Pydantic models double as LLM structured-output schemas.

**Flask**: too little structure for a system this size. **Litestar**: excellent, but a far smaller community, which matters when two non-expert engineers are searching for answers at 10pm.

**Sync SQLAlchemy**: seriously considered *because* the team is non-expert; async SQLAlchemy has real footguns (`MissingGreenlet`, lazy-loading traps). **Rejected on failure-mode grounds:** async errors are loud and immediate, they fail in development and CI, never silently in production. Sync-with-threadpool fails by *silent thread-pool exhaustion under load*, which surfaces late, in production, under traffic. For a team that will make mistakes, prefer the mistakes that fail fast and visibly. Mitigations: `lazy="raise"` on every relationship, and `36-troubleshooting-guide.md` §1.

## Consequences
**Positive:** async-native for I/O-bound work · OpenAPI generated automatically, giving us both the API spec and the contract between our two tracks for free · one Pydantic schema serving HTTP validation, OpenAPI and LLM structured outputs · excellent typing · very large community.
**Negative:** more assembly than Django · async requires discipline · we build the admin ourselves.

## Cost
Free and open source.

## Security
No built-in auth means we implement it, also an opportunity to implement it correctly (Argon2id, opaque sessions, MFA, single PDP). Pydantic validation at every boundary is a strong default. `response_model` prevents accidental field leakage, provided we never return ORM objects directly.

## Scalability
ASGI with async I/O handles high concurrency on modest hardware; workers scale independently.

## Migration Path
Domain logic lives in `service.py` modules with no HTTP dependency, services never raise `HTTPException` precisely to preserve this, so a framework change would touch routers only.

## Revisit Trigger
If async proves a persistent source of defects for this team by Sprint 5, reconsider sync SQLAlchemy with `def` endpoints. The repository layer isolates data access, so the change is contained.
