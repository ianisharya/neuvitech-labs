# 36 — Troubleshooting Guide

The failures you will actually hit. **Most practically useful document in the pack after the runbooks.**

## 1. Async SQLAlchemy

### `MissingGreenlet` — lazy loading in async
```python
order = await session.get(Order, order_id)
for line in order.lines:      # MissingGreenlet
```
```python
stmt = select(Order).where(Order.id == oid).options(selectinload(Order.lines))
order = (await session.execute(stmt)).scalar_one()
```
**Our base model sets `lazy="raise"`** so a forgotten `selectinload` fails in tests, not production. **Silver lining:** this error is loud and immediate — that failure mode is precisely why we kept async (ADR-0002).

### Other async traps
- **Missing `await`** returns a coroutine. Symptom appears much later as `AttributeError: 'coroutine' object has no attribute…`. **If an error mentions a coroutine, look for a missing `await` first.**
- **One session per request.** Never a module-level global session.
- **Objects expire after commit** — set `expire_on_commit=False`, and read values before committing.
- **Never mix drivers** — `asyncpg` for the app, `psycopg` only inside Alembic if needed.

## 2. Alembic
- **Always read the generated migration.** Autogenerate misses renames (it drops and recreates, **destroying data**), server defaults, check constraints, enum changes.
- **Test `downgrade` in CI.** A migration you cannot reverse is a deploy you cannot roll back.
- **Never edit a migration that has run anywhere.** Write a new one.
- **Two branches, two heads** → `alembic merge`. Avoid it: Track A merges schema first.
- **Naming conventions on `MetaData` before the first migration.** Retrofitting is miserable.

## 3. FastAPI / Pydantic
- **Never return ORM models.** Use `response_model` — it filters as well as documents. Returning ORM objects leaks `password_hash` and internal flags.
- **A blocking call in `async def` blocks the whole event loop.** No `requests`, no `time.sleep`, no sync file I/O.
- **`BackgroundTasks` is not a job queue** — it dies with the process. Use ARQ for anything that must survive a restart.
- **Pydantic v2:** `model_validate` not `parse_obj`, `model_dump` not `dict`, `field_validator` not `validator`.

## 4. Security traps that cause real incidents
- **Never trust a client-supplied price, user id or entitlement source.** All resolved server-side.
- **Verify webhook signatures on raw bytes** — some frameworks re-serialise JSON and invalidate the signature.
- **Compare secrets with `hmac.compare_digest`**, never `==` (timing leak).
- **Filter ownership inside the query.** Fetch-then-check is one forgotten check from IDOR.
- **Same response whether or not an account exists** on login and reset.
- **`.env` in `.gitignore` before any `.env` exists.** Order matters; history is forever.

## 5. Next.js / React
- **`"use client"` is contagious downward.** One at the top of a layout ships your whole app to the browser.
- **Never put secrets in `NEXT_PUBLIC_*`** — that prefix means "embed in the browser bundle".
- **Hydration mismatch** — `Date.now()`, `Math.random()`, `localStorage` during render.
- **`fetch` caching is aggressive.** For anything user-specific pass `{ cache: "no-store" }`. **Caching an authenticated response is a cross-user data leak — a security issue, not a performance one.**
- **`key` must be a stable id**, never an array index.

## 6. Docker & Compose
- **Layer order:** copy `pyproject.toml`/`package.json` and install *before* copying source, or every code change reinstalls everything.
- **`depends_on` waits for the container, not the service.** Use `condition: service_healthy` and retry at app startup anyway.
- **`localhost` inside a container is that container.** Use the service name: `postgres`, `redis`.
- **Anonymous volumes shadow directories** — the classic `node_modules` / `.venv` time sink.
- **Run as non-root**, or bind-mounted files become root-owned on your host.

## 7. Dev Container
| Symptom | Fix |
|---|---|
| Build fails on package download | Proxy/VPN — tell me |
| Extensions missing | They install on first build; reload the window |
| Very slow on Windows | Repo on `/mnt/c/` — re-clone into WSL |
| Container won't start after a Dockerfile change | *Dev Containers: Rebuild Container* |
| Ports not forwarded | Check `forwardPorts` in `devcontainer.json` |

## 8. CI
- **Pin action versions.** `@v4` is a moving target and so is a supply-chain compromise.
- **Green locally, red in CI** → almost always a service-container difference or a missing environment variable. Run `make check`, which uses the same configs.
- **Flaky E2E** → a missing wait condition, not a reason to retry blindly.

## 9. Two-engineer friction
- **Do not both edit the same file in one session.** The track split is designed to prevent it.
- **Merge and pull frequently.** A three-day branch across two people is a countdown timer.
- **Review properly.** "Looks good" on a payment webhook handler is worse than no review — it manufactures false confidence.
- **Say when you do not understand.** The failure mode on a two-person team is both nodding at code neither can maintain in March.

## 10. When you are stuck
1. Read the **full** error, not the last line
2. Check the runbook (`33`) and this guide
3. `make down && make up` — genuinely fixes state problems
4. Ask Copilot to explain the error
5. **Paste the full output to me** with what you tried
6. Add the fix to this document so it is solved once, not repeatedly
