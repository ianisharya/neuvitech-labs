## What and why

<!-- What changed, and why it exists. Link the ticket. -->

Closes NVL-

## How to verify

<!-- Exact steps for the reviewer to run this. Not "test it" — the commands. -->

```bash
```

## Checklist

**Implementation**
- [ ] Acceptance criteria demonstrated, not asserted
- [ ] Nothing hard-coded that belongs in settings
- [ ] No `TODO` without a linked ticket

**Tests**
- [ ] Unit tests for logic and branches
- [ ] Integration tests where a database is involved
- [ ] **Failure paths tested**, not only the happy path
- [ ] `make check` green locally

**Security**
- [ ] Permission declared, or explicitly `@public`
- [ ] Input validated at the boundary
- [ ] Ownership filtered **inside** the query
- [ ] No secrets

**Data** *(delete if no migration)*
- [ ] Migration reviewed line by line — autogenerate is a first draft
- [ ] `upgrade` **and** `downgrade` tested
- [ ] Expand/contract; backward-compatible with the running image
- [ ] Indexes justified with `EXPLAIN ANALYZE`

**Observability**
- [ ] Logs emitted for business events
- [ ] Alert plus runbook added if this can fail in production

**Human validation**
- [ ] Run and manually verified — state which machine below
- [ ] Reviewed by the other track

Verified on: <!-- macOS / Windows / both -->

## Honesty check

<!-- Anything IMPLEMENTED but not VERIFIED? Anything you could not test? Say so
     here. This section being empty is usually a sign nobody looked closely. -->
