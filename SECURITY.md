# Security Policy

Security is not a feature of this platform, it is a property of how the whole thing is built, and this document covers both how to report a problem and the rules every contributor follows to avoid creating one. The full architectural treatment is in `docs/08-security-architecture.md`; this is the practical policy.

## Reporting a vulnerability

If you find a security vulnerability, report it privately. Do not open a public issue, because a public issue tells everyone about the weakness before it can be fixed.

Send the report to the security contact configured for the repository, or open a private security advisory through the repository's security tab if that is available to you. Include what you found, the steps to reproduce it, the component affected, and your assessment of the impact. A report that lets us reproduce the problem quickly is a report we can fix quickly.

We aim to acknowledge a report within a couple of days and to keep you informed as we work through it. Please give us a reasonable window to remediate before any public disclosure, and we will credit you if you would like to be credited.

## The rules every contributor follows

These are the practices that keep the platform secure by default. They are enforced by a combination of automated checks and code review, and several of them will fail the build if broken.

### Secrets

The platform runs on a small, fixed set of bootstrap configuration values held in the environment, and everything else, including every third-party credential, is stored encrypted in the database. This is deliberate, because it means a credential is changed through an administrative action rather than a code deploy, and it keeps secrets out of the codebase entirely.

Never commit a secret to the repository, in code, in configuration, in a test, in documentation, or anywhere else. If a secret is ever committed, rotate the credential immediately. Removing the file in a later commit does not help, because the secret remains in the history, and the history is readable by anyone who has ever cloned the repository. Rotation is the fix; deletion is theatre. A secret-scanning tool runs before every commit and in the pipeline, including a scan of the full history.

### Access control

Access is default-deny. Every endpoint declares the permission it requires or explicitly marks itself public, and an endpoint that declares neither fails at startup rather than shipping open to the world.

Authorization lives in one place, a single policy decision point, and is never scattered as ad-hoc role checks through the code. Check a permission, never a role name, because roles change and a hard-coded role name is a latent bug.

Filter ownership inside the database query, not after fetching the row. Fetching a record and then checking whether the current user owns it is one forgotten check away from letting a user read another user's data, and that check is exactly what gets dropped during a later refactor. A query that can only ever return the current user's rows cannot leak.

Permissions and entitlements are separate questions. A permission is whether a role may perform a kind of action. An entitlement is whether a specific user has been granted access to a specific product. Learning content requires both, and conflating them breaks the access model.

### Handling untrusted input

Never trust anything the client sends for a value the server can determine itself. The price of a product, the identity of the current user, the source of an entitlement, the role of an account: all of these are resolved on the server, never accepted from the browser. A request that arrives carrying a price or an amount is rejected and logged as a security event, not quietly honoured.

Validate all input at the boundary, with strict types. Verify payment provider webhooks by checking the signature against the exact raw bytes received, before parsing, because parsing and re-serialising can change the bytes and invalidate the signature. Treat any content that comes from an untrusted source, including a learner's uploaded file or the text of course material fed to the AI tutor, as data to be handled and never as instructions to be followed.

### Comparisons, errors, and logs

Compare secrets and signatures with a constant-time comparison, never with ordinary equality, because ordinary equality returns as soon as it finds a difference and that timing leaks information about the secret.

Never return a stack trace or an internal error detail to a user. Return an error code and a correlation identifier, so that the user gets something useful to report and an attacker gets nothing useful to exploit.

Never log passwords, tokens, card data, full request bodies on sensitive routes, the content of AI conversations, or personal information. Sensitive fields are kept out of logs by an allow-list that names what may be logged, rather than a block-list that tries to name everything that may not, because a block-list silently fails the moment someone adds a new sensitive field.

### The AI tutor and learner data

The AI tutor carries memory of each learner, and that memory is sensitive learner data. It lives in the platform's own database, never in a third-party service, and is subject to every rule above. A learner can see what the tutor remembers about them and can have it cleared. The tutor acts only with the learner's own authority and is never given the ability to move money, grant access, change permissions, or reach secrets. This is covered in full in `docs/12-agentic-ai-architecture.md`.

### Dependencies and scanning

Dependencies are pinned and their manifests committed, so that a build is reproducible and a dependency cannot change without a reviewed pull request. Automated scanning for known vulnerabilities in dependencies, in container images, and in infrastructure definitions runs in the pipeline, and findings above a defined severity block a merge. Static analysis runs on every change. This is covered in `docs/08-security-architecture.md` and `docs/21-cicd-pipeline.md`.

## The principle behind all of it

Every one of these rules answers a specific way systems get breached, and most of them are enforced by tooling precisely so that security does not depend on a tired engineer remembering to be careful on a Friday afternoon. When a rule here seems inconvenient, that inconvenience is usually the rule doing its job.
