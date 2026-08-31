# Security Policy

## Reporting a vulnerability

Email **security@neuvitechlabs.com** with steps to reproduce, affected component and assessed impact. Do not open a public issue.

We aim to acknowledge within 48 hours. Please give us a reasonable window to remediate before public disclosure.

## For contributors

### Secrets

Nine bootstrap environment variables exist. Everything else — including third-party API keys — is stored encrypted in the database and changed through the admin UI.

Never commit a secret to code, images, logs, Jira or documentation.

**If a secret is ever committed, rotate the credential immediately.** Removing the file does not help: it is in git history, and history is public the moment anyone clones. Rotation is the fix; deletion is theatre.

Gitleaks runs pre-commit and in CI, including full history.

### Non-negotiables

- **Default deny.** Every endpoint declares a permission or is explicitly public.
- **One policy decision point.** Authorization lives only in `security/authz.py`. No ad-hoc role checks.
- **Filter ownership inside the query**, never after fetching. Fetch-then-check is one forgotten `if` away from IDOR, and that `if` gets dropped during a refactor.
- **Never trust the client** for price, `user_id`, entitlement source, role or order state. A request containing a price is rejected and logged as a security event.
- **Verify webhook signatures on raw bytes**, before parsing. Check `provider_event_id` against a unique constraint — providers retry, so duplicates are normal.
- **Compare secrets with `hmac.compare_digest`**, never `==`. `==` short-circuits and leaks length and prefix through timing.
- **Never log** passwords, tokens, card data, full request bodies on sensitive routes, or PII. Exclusion uses an allow-list, not a blocklist — a blocklist fails silently the moment someone adds a field.
- **Never return a stack trace to a user.** Error code plus correlation id only.

### Scanning

Gitleaks, Semgrep, Bandit, Trivy, Checkov, `pip-audit` and `npm audit` run in CI. HIGH and CRITICAL findings block merge.

Full model: [`docs/08-security-architecture.md`](docs/08-security-architecture.md).
