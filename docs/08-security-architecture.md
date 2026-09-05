# 08: Security Architecture

Security is an architectural concern applied at every layer, not a pre-launch checklist.

```
Browser → CDN → WAF/reverse proxy → Next.js → FastAPI → PostgreSQL
 ↓ ↓
 Object store Workers → Providers → AI
```

## 1. The question every sensitive flow answers

**WHO** (authenticated principal, including agents) · **WHAT** (action + resource) · **WHY** (business context, grant reason) · **WHEN** (UTC) · **FROM WHERE** (IP, user agent, request id) · **WITH WHAT AUTHORIZATION** (the permission that allowed it) · **WHAT DATA** (before/after diff) · **WHAT AUDIT TRAIL** (append-only row).

## 2. Authentication

- **Argon2id** password hashing, tuned parameters, transparent rehash on login when parameters change.
- **Opaque server-side sessions, not JWTs.** 256-bit random token in an `httpOnly; Secure; SameSite=Lax` cookie; only a SHA-256 hash stored. Redis lookup with Postgres fallback. Sliding expiry with absolute cap.
 **Why not JWT:** we require immediate revocation on logout, password change, role change, MFA enrolment and compromise. Stateless JWTs cannot revoke without a denylist, at which point you have server-side state anyway, minus the simplicity. "JWTs scale better" does not apply: a Redis GET is ~0.2 ms.
- **TOTP MFA** mandatory for any principal holding an admin-tier permission. Recovery codes single-use and hashed.
- **Step-up re-authentication** for superuser grants, refunds, credential revocation and catalog publishing.
- **Email verification** required before enrolment; single-use, hashed, time-boxed tokens.
- **Password reset** returns an identical response whether or not the account exists (no user enumeration) and invalidates all sessions on completion.
- **Brute-force controls:** per-account and per-IP token buckets, exponential backoff, temporary lock with audit.

## 3. Authorization

- **RBAC + resource scoping.** Permissions are strings: `catalog.program.publish`, `commerce.refund.create`, `credential.revoke`. Roles are permission sets. Users hold roles, optionally scoped (an instructor scoped to a cohort).
- **Exactly one policy decision point:** `security/authz.py` exposing `require_permission(...)` as a FastAPI dependency. Authorization logic appears nowhere else; CI fails the build on ad-hoc role comparisons in routers.
- **Entitlements are checked separately from permissions.** Permissions answer "may this role perform this action type"; entitlements answer "has this user been granted this product". Both must pass for learning content.
- ```
```
   DEFAULT DENY: you cannot ship an accidentally open route

   endpoint declared with a permission   -->  allowed, checked
   endpoint explicitly marked public     -->  allowed, deliberate
   endpoint declaring NEITHER            -->  FAILS AT STARTUP

   The third case is the whole point. A forgotten access
   declaration crashes the application on boot rather than
   quietly serving private data to the world.
```

**Default deny.** Every endpoint declares a permission or is explicitly `@public`. One that declares neither **fails a startup assertion**: you cannot ship an accidentally open route.

## 4. Superuser

`SUPERUSER_EMAIL` is read once by an idempotent bootstrap that creates the user if absent and grants `platform_superuser`. The account is created **pending**: no password in config, and must complete an out-of-band invitation plus MFA enrolment before it can authenticate.

**CI fails the build on any hard-coded email comparison outside the single bootstrap module.** Privilege exists only as roles and permissions.

Superuser actions are audited, MFA-gated and rate-limited. Impersonation, if implemented, is time-boxed, banner-visible, forbidden on payment actions, and heavily audited.

## 5. Application controls

| Control | Implementation |
|---|---|
| Input validation | Pydantic v2 at every boundary; strict types; no `Any` in request models |
| SQL injection | Parameterised queries only; raw SQL requires review and explicit binding |
| XSS | React escaping; `dangerouslySetInnerHTML` forbidden except through a sanitiser allow-list; strict CSP with nonces |
| CSRF | `SameSite=Lax` + double-submit token on state-changing routes + Origin checks |
| SSRF | No user-supplied URL fetched server-side without an allow-list; DNS-rebinding-safe resolver; private CIDRs blocked |
| Security headers | HSTS preload, CSP, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`, `X-Frame-Options: DENY` |
| CORS | Explicit origin allow-list per environment; never `*` with credentials |
| Rate limiting | Redis token bucket, tiered by endpoint class and principal, thresholds in settings |
| Secrets | Nine bootstrap env vars; everything else encrypted in the database. Gitleaks in pre-commit **and** CI, full-history scan |
| Encryption | TLS 1.3 in transit; at-rest on database and object storage; application-level for MFA seeds and provider tokens |
| Errors | Stack traces never reach users, error code plus correlation id only |
| Dependencies | Committed lockfiles, Dependabot, `pip-audit`, `npm audit` |

## 6. File and media security

Type validation by **content sniffing, not extension**. Size caps per type. Randomised storage keys, never the user's filename. **Private buckets by default**; access only via short-lived signed URLs issued after an authorization check. Malware scanning (ClamAV in a worker) with quarantine until clean. Uploads served from a **separate origin** so a malicious file cannot execute in the application's origin. EXIF stripped from images.

## 7. Threat model: top risks

| Threat | Mitigation |
|---|---|
| Forged or replayed payment webhook | Signature verification on **raw bytes** + unique provider event id + amount/currency match against the order |
| Price tampering | Server-side price resolution; requests containing amounts are **rejected and logged as security events** |
| Coupon abuse / race | Row lock + partial unique indexes + per-user caps + explicit concurrency tests |
| Free-path escalation to a paid product | `commerce_policy` resolved server-side from the registry; explicit regression test |
| Paid video scraping | Signed, short-lived, session-bound URLs; no direct object URLs |
| Certificate forgery | Ed25519 signature + server-side verification + revocation list |
| Privilege escalation via role edit | Superuser + MFA + audit; all sessions invalidated on role change |
| Prompt injection → tool misuse | Tools authorised against the **user's** permissions, never the agent's (doc 12) |
| Supply chain | Pinned lockfiles, Dependabot, Trivy, SBOM, provenance attestation |
| Insider or admin misuse | Append-only audit, MFA, step-up auth, least privilege, alerting on anomalous grant volume |

## 8. Security tooling in CI: all free and open source

| Stage | Tool | Blocking |
|---|---|---|
| Pre-commit | Gitleaks, Ruff, Prettier | Yes |
| SAST | Semgrep, Bandit | Yes on HIGH |
| Dependencies | Dependabot, `pip-audit`, `npm audit` | Yes on CRITICAL |
| Containers | Trivy | Yes on HIGH/CRITICAL |
| IaC | Checkov | Yes on HIGH |
| DAST | OWASP ZAP baseline against DEV | Report and triage |
| Secrets | Gitleaks full-history | Yes |

## 9. Privacy

Data minimisation. Documented retention per data class. Access control on every read, audit on sensitive reads. DSAR export and erasure paths. **PII excluded from logs, metrics, traces and AI observability by an allow-list serialiser**: an allow-list, not a blocklist, because a blocklist fails silently the moment a new field is added. IP addresses hashed where retained for analytics.
