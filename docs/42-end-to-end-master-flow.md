# 42 - The Complete Application Flow, End to End

This is the one document to read if you want to understand how the whole platform actually works as a single connected system rather than as a set of separate architectural concerns. Every other document goes deep on one area. This one follows a single continuous thread from a stranger arriving on the website through to a graduate being contacted by an employer, and at every step it names the technology doing the work, the logic being applied, the conditions being checked, and what happens when things go wrong.

Read this first if you are new. Read the specific architecture documents afterward for depth.

## 1. The technology at every stage, in one table

Before the flow itself, here is what runs where. Nothing in this document uses a technology that is not in this table.

| Stage | Technology | What it does here |
|---|---|---|
| Browser | The learner's device | Runs the player and the interface |
| Edge and caching | CDN with edge caches | Serves video segments and static assets from a location near the learner, absorbing the majority of all bytes |
| Presentation | Next.js 15, TypeScript, React Server Components | Renders pages on the server for speed and search visibility, holds no business logic |
| Styling | Tailwind, design tokens read from the database | Visual layer, restyled without a deploy |
| API | Python 3.12, FastAPI, Pydantic | Every business rule, every authorization decision, the system of record for behaviour |
| Data access | SQLAlchemy 2.0 async, Alembic for migrations | Typed access to the database, versioned schema change |
| Primary store | PostgreSQL 16, with read replicas | The single source of truth for every fact the platform holds |
| Cache, sessions, limits, queue | Redis 7 | Session lookup, cache-aside reads, rate limiting, idempotency keys, the job queue |
| Background work | ARQ workers, sharing the API codebase | Video processing, email, certificates, billing cycles, karma, reconciliation |
| Object storage | S3-compatible storage, private by default | Source video, processed video, documents, uploads |
| Payments | Razorpay behind a provider protocol | Subscription billing and one-time purchase |
| AI | Open-source models, LangChain and LangGraph, all behind one gateway | The tutor, mock interviews, resume review, learning paths |
| Observability | OpenTelemetry to Prometheus, Loki, Tempo, Grafana, and GlitchTip | Metrics, logs, traces, dashboards, alerts, errors |
| Environment | Docker, VS Code Dev Containers | An identical development environment on every machine |
| Pipeline | GitHub Actions | Lint, type-check, test, build once, promote through environments |

## 2. The whole journey in one picture

```
   STRANGER                                          GRADUATE
      |                                                  ^
      v                                                  |
   discovers  ->  signs up  ->  free course  ->  subscribes
      |              |              |                |
      |              |              |                v
      |              |              |            learns, live
      |              |              |            and recorded
      |              |              |                |
      |              |              |                v
      |              |              |            assessed
      |              |              |                |
      |              |              |                v
      |              |              +----------> certified
      |              |                               |
      |              |                               v
      |              +-------------------------> portfolio
      |                                              |
      |                                              v
      +----------------------------------------> employer
                                                  contact

   Running alongside all of it, continuously:
     karma accrues on verified progress
     streak multiplies it while the learner stays consistent
     the AI tutor remembers and assists
     observability records what happened
```

Each of these steps is now taken in turn.

## 3. Discovery, the anonymous visitor

A stranger arrives at a program page from a search engine. Nothing about them is known. Speed and search visibility are the only things that matter here, because a slow or invisible page means the journey never starts.

```
   REQUEST FOR A PUBLIC CATALOGUE PAGE

   browser
     |
     v
   CDN edge  --- cache hit? ---> yes ---> served from edge
     |                                    in milliseconds,
     no                                   never touches us
     v
   Next.js server component
     |
     +--> reads public settings (cached in Redis)
     |    branding, navigation, feature flags
     |
     +--> calls FastAPI for the catalogue item
              |
              v
        FastAPI: is this item PUBLISHED and PUBLIC?
              |
        +-----+-----+
        |           |
       yes          no
        |           |
        |           +--> 404, and deliberately not 403,
        |                because a 403 would confirm the
        |                item exists
        v
   read model lookup (a single row, pre-assembled
   at publish time, not a six-table join)
        |
        v
   HTML rendered on the server, almost no JavaScript
        |
        v
   cached at the edge for the next visitor
```

The conditional that matters most here is the published-and-public check. An item that is draft, scheduled, or private is invisible to the world, and the response is a 404 rather than a 403 so that the existence of unreleased products is not leaked to anyone probing the URL space.

The read model is the reason this is fast. At the moment an item is published, the platform assembles its entire page representation into a single row. A visitor's request is then one primary-key lookup rather than a traversal of the catalogue graph.

## 4. Signing up

```
   REGISTRATION

   email and password submitted
        |
        v
   Pydantic validates shape at the boundary
        |
        v
   is the email already registered?
        |
   +----+----+
   |         |
  yes        no
   |         |
   |         v
   |    create user, password hashed with Argon2id
   |         |
   |         v
   |    generate single-use verification token,
   |    store only its hash, set an expiry
   |         |
   |         v
   |    queue verification email (ARQ, not inline)
   |         |
   +----+----+
        |
        v
   IDENTICAL success response either way

   The response never differs. Telling a visitor
   "that email is already registered" hands an
   attacker a way to enumerate who has an account.
```

The password is hashed with Argon2id, which is memory-hard and deliberately slow, so that a stolen database is not a stolen list of passwords. The email is queued rather than sent inline, because an email provider being slow must never make registration slow, and because a failed send should retry rather than fail the signup.

## 5. Logging in, and what a session actually is

```
   LOGIN

   credentials submitted
        |
        v
   rate limit check (Redis token bucket,
   per account AND per IP)
        |
   over limit? --> yes --> refused, backoff, audited
        |
        no
        v
   verify password against Argon2id hash
        |
   +----+----+
   |         |
  fail      pass
   |         |
   |         v
   |    is the email verified?  no --> refuse, prompt
   |         |                          to verify
   |        yes
   |         v
   |    does this account require MFA?
   |         |
   |    +----+----+
   |    |         |
   |   yes        no
   |    |         |
   |    v         |
   | TOTP check   |
   |    |         |
   |    +----+----+
   |         |
   |         v
   |    create session: 256 bits of randomness,
   |    store only the SHA-256 hash
   |         |
   |         v
   |    write to Redis (fast path) and PostgreSQL
   |    (durable fallback)
   |         |
   |         v
   |    set httpOnly, Secure, SameSite cookie
   |         |
   +----+----+
        |
        v
   identical timing and response shape on failure
```

Sessions are opaque random tokens looked up on the server, not self-contained tokens like JWTs. The reason is revocation. When a learner logs out, changes their password, has their role changed, or is compromised, their access must end immediately. A stateless token cannot be revoked without maintaining a list of revoked tokens, at which point the server holds state anyway and has gained nothing. A Redis lookup costs a fraction of a millisecond, so the usual scaling argument for stateless tokens does not apply at this scale.

## 6. The request lifecycle, in full

Every authenticated request that follows takes this path. It is worth seeing once in detail, because everything after this section relies on it.

```
   ONE AUTHENTICATED REQUEST, EVERY LAYER

   browser sends cookie
        |
        v
   [1] request id assigned, or propagated if present
        |     this id appears in every log line, every
        |     trace span, and every error for this request
        v
   [2] structured log entry opened, OpenTelemetry span started
        v
   [3] security headers and CORS applied
        v
   [4] rate limit checked in Redis
        |
        over limit --> 429, logged
        v
   [5] session resolved: cookie -> hash -> Redis
        |
        miss --> PostgreSQL fallback --> still missing? 401
        v
   [6] AUTHORIZATION: does this endpoint declare a
       permission, or is it explicitly public?
        |
        declares neither --> the application refused to
        |                    start; this cannot reach
        |                    production
        v
       does the principal hold that permission?
        |
        no --> 403, or 404 where existence is sensitive
        v
   [7] Pydantic validates the request body
        v
   [8] router delegates to the service layer
        |     the router does four things only: validate,
        |     authorize, delegate, return
        v
   [9] service applies business rules, opens a transaction
        v
  [10] repository executes queries with ownership
       filtered INSIDE the query, never checked after
        v
  [11] PostgreSQL, primary for writes, replica for reads
        v
  [12] response schema built, never a raw database model
        |     returning a model leaks whatever column
        |     someone adds later
        v
  [13] audit row written if this changed anything
        v
  [14] span closed, metrics recorded, log entry closed
        v
   response to the browser
```

Two of these steps deserve emphasis. Step six fails at application startup, not at request time, if an endpoint has forgotten to declare its access requirement. This means an accidentally public endpoint cannot be deployed. Step ten filters ownership inside the query, so another learner's row is not merely rejected but unreachable, which removes the possibility of a forgotten check leaking data during a later refactor.

## 7. Enrolling in a free course

The first taste of the product, and deliberately the same machinery as a paid purchase.

```
   FREE ENROLMENT

   learner clicks enrol on a free course
        |
        v
   server resolves the PRODUCT and its price
        |     the browser never sends a price; a request
        |     that contains one is rejected and logged
        |     as a security event
        v
   is the resolved price zero?
        |
   +----+----+
   |         |
  yes        no  --> refuse. This is the check that stops
   |             a paid course being acquired through the
   |             free path
   v
   create Order, total zero
        |
        v
   payment step SKIPPED by server-side policy
        |     skipped, not faked; there is no fake
        |     payment record and no separate free-only
        |     code path to drift out of sync
        v
   create Entitlement
        source     = FREE_ENROLMENT
        valid_until= null, meaning never expires
        |
        v
   create Enrolment, pinned to the published VERSION
        |     the curriculum cannot change under the
        |     learner after they enrol
        v
   learner is in
```

## 8. Subscribing, and the three tiers meeting

When the learner wants the wider library, they subscribe. This is where all three access tiers become visible as one model.

```
   THE THREE TIERS, ONE CHECK

   FREE                SUBSCRIPTION          ONE-TIME
   zero-value order    monthly or annual     purchase
        |                    |                   |
        v                    v                   v
   Entitlement          Entitlement         Entitlement
   FREE_ENROLMENT       SUBSCRIPTION        PAYMENT
   valid_until          valid_until =       valid_until =
   = null               period end +        published
   (forever)            grace               duration + 1yr
                        (moves on each      (fixed at
                         renewal)            purchase,
                                             never moves)
        |                    |                   |
        +---------+----------+-------------------+
                  |
                  v
        "is now before valid_until,
         and is revoked_at still null?"
                  |
                  v
   LMS, video player, certificates, portfolio

   Every delivery system asks that one question and
   never learns which tier answered it.
```

## 9. Payment, the flow that must never be wrong

```
   PAID CHECKOUT

   learner submits: product id, quantity, coupon code
        |     never an amount
        v
   idempotency key attached
        |     a double-clicked checkout must not charge twice
        v
   server resolves price, applies offer, validates coupon
        |
        +--> coupon expired?            refuse
        +--> over its global limit?     refuse
        +--> over this user's limit?    refuse
        +--> below minimum purchase?    refuse
        +--> wrong product?             refuse
        |
        v
   coupon redemption locked with SELECT FOR UPDATE
        |     a coupon capped at 100 uses is redeemed
        |     exactly 100 times, even under a rush
        v
   Order created, state PENDING_PAYMENT
        |
        v
   redirect to Razorpay
        |
   +----+--------------------+
   |                         |
  learner pays          abandons or fails
   |                         |
   |                         v
   |                    order stays PENDING_PAYMENT
   |                    retry path shown
   |                    NO access granted
   v
   Razorpay sends a webhook to us
        |
        v
   VERIFY, all four must pass:
     1. signature valid against the RAW BYTES
        (parsing and re-serialising changes bytes
         and breaks the signature)
     2. provider event id never seen before
        (unique constraint; providers retry routinely,
         so duplicates are normal, not exceptional)
     3. amount matches the order
     4. currency matches the order
        |
   +----+----+
   |         |
  fail      pass
   |         |
   |         v
   |    Entitlement granted, source = PAYMENT
   |         |
   |         v
   |    Enrolment created
   |         |
   |         v
   |    receipt queued, audit row written
   |
   +--> rejected, logged as a security event,
        no entitlement, return 200 so the provider
        stops retrying a request we have decided about

   SEPARATELY, on a schedule:
   reconciliation finds orders still PENDING_PAYMENT
   past a reasonable window and asks Razorpay directly.
   Webhooks get lost. Money must not.
```

The browser's success screen grants nothing. It only redirects. Access is granted by the verified webhook or by reconciliation, both server-side, because anything the browser claims can be forged.

## 10. Learning, live and recorded

```
   PRESSING PLAY

   learner opens a lesson
        |
        v
   entitlement check: valid grant, right now,
   for this catalogue item?
        |
   +----+----+
   |         |
  no        yes
   |         |
   |         v
   |    issue a SHORT-LIVED SIGNED URL
   |    minutes only, bound to this session
   |         |
   |         v
   |    CDN validates the signature and serves
   |    segments from an edge near the learner
   |         |
   |         v
   |    player measures throughput and adapts
   |    quality per segment, so the lecture keeps
   |    playing rather than freezing to buffer
   |         |
   |         v
   |    progress events batched client-side,
   |    flushed periodically, written async
   |         |
   |         v
   |    genuine watching recorded; scrubbing to
   |    the end does not count as watched
   |
   +--> refused. No permanent public URL to paid
        video exists anywhere, so a copied link
        expires within minutes and was tied to
        someone else's session regardless
```

A live session takes the same path with one difference: the segments are being created a few seconds ahead of being watched, and a chat panel sits beside the player. When the session ends, the recording is processed and occupies the same lesson slot, so a learner who missed it opens the identical lesson and watches through the identical player.

```
   WHAT HAPPENS AFTER A LIVE SESSION ENDS

   recording captured
        |
        v
   ARQ worker picks it up (background, blocking no one)
        |
        v
   validate -> transcode to quality ladder -> segment
        -> thumbnails, captions -> write to the
        structured storage path
        |
        v
   mark the lesson READY   <-- only now does the
        |                      player offer it
        v
   learners who missed the live session watch it

   Idempotent and resumable: a failed transcode retries
   without duplicating, and a stuck job raises an alert
   rather than leaving a silently missing video.
```

## 11. Assessment and certification

```
   PROVING IT, AND BEING CERTIFIED

   learner completes lessons
        |
        v
   completion computed from the rule in the
   VERSION they enrolled in, not the current one
        |
        v
   assessment submitted
        |
        v
   graded ON THE SERVER
        |     correct answers are never sent to the
        |     browser before submission; a naive API
        |     that ships the answer key is trivially
        |     cheated and impossible to walk back
        v
   passed at the required mark?
        |
   +----+----+
   |         |
  no        yes
   |         |
   |         v
   |    attempts remaining? --> retry path
   |         |
   |         v
   |    certificate eligibility evaluated:
   |    required progress AND required score
   |         |
   |         v
   |    ARQ worker issues the credential
   |         |
   |         +--> signed with Ed25519
   |         +--> unique constraint prevents a
   |         |    duplicate under retry
   |         +--> rendered to a document
   |         |
   |         v
   |    public verification page, indexable,
   |    rate-limited, cacheable
   |         |
   |         v
   |    anyone can confirm it is genuine,
   |    and revocation is a state change with
   |    an audit trail, never a deletion
```

A free certification runs this identical path. The free tier is generous with access and strict with assessment, because a certificate nobody can fail is worth nothing and would damage the brand it is meant to build.

## 12. Karma and streaks, running alongside everything

```
   KARMA AWARDED ON A VERIFIED EVENT

   a real completion occurs
   (video genuinely watched, assessment passed,
    project completed, course finished)
        |
        v
   base karma looked up from settings
        |     tunable in the database, no deploy
        v
   is the learner's streak alive today?
        |
   +----+----+
   |         |
  no        yes
   |         |
   |         v
   |    multiplier applied, rising with streak
   |    length up to a cap
   |         |
   +----+----+
        |
        v
   ledger entry appended, server-side only
        |     the client never states an amount,
        |     exactly as it never states a price
        v
   balance = the sum of all entries, always
   recomputable, never a mutable number

   Result: the same content earns a consistent daily
   learner far more than a binge-and-vanish learner,
   because every award was multiplied while their
   streak held. Over weeks the gap compounds.
```

Spending karma reuses the commerce system entirely. A goodie is a product priced in karma, redeemed through the same order and fulfilment path as a purchase, with a locked balance check standing in for a payment authorisation.

## 13. The AI tutor, available throughout

At any point above, the learner can ask the tutor for help. Every such request takes one path.

```
   THE AI GATEWAY, THE ONLY DOORWAY

   learner asks a question
        |
        v
   authenticate -> authorize -> budget and rate check
        |
        v
   input guardrails: strip sensitive data, screen for
   attempts to manipulate the model
        |
        v
   RETRIEVE, filtered by the learner's own entitlements
        |     inside the query, so content they cannot
        |     access is never returned and therefore
        |     can never be read to them
        v
   load memory: this conversation, their real activity,
   a summarised history of past tutoring
        |
        v
   assemble prompt from a versioned template
        |
        v
   call an open-source model, with timeout, retry,
   and a circuit breaker
        |
        v
   validate output: expected shape, grounded in the
   retrieved material, no leaked sensitive data
        |
        v
   any tool call checked against the LEARNER's
   permissions, never the agent's own
        |
        v
   audit and cost recorded
        |
        v
   answer returned

   If every model provider is down: the tutor shows as
   unavailable, mock interviews offer their human mode,
   and everything else continues untouched. Nothing in
   the core learning or commerce path waits on a model.
```

## 14. Career, the far end of the journey

```
   FROM CREDENTIAL TO EMPLOYER

   learner earns credentials and completes projects
        |
        v
   chooses, explicitly, to publish to their portfolio
        |     opt-in, always
        v
   chooses, explicitly, to enter the talent pool
        |     opt-in again. Employers never get a
        |     default view of anyone
        v
   employer searches the pool
        |
        v
   sees only what the learner consented to share,
   and credentials are referenced live, so a revoked
   certificate disappears automatically rather than
   lingering as a stale copy
        |
        v
   employer expresses interest, logged and auditable
        |
        v
   learner responds, or does not
```

## 15. What happens when things fail

The platform is built so that a failure in one place degrades one capability rather than stopping the product.

```
   DEGRADATION, BY DEPENDENCY

   Redis down          cache misses fall through to
                       PostgreSQL; rate limiting fails
                       CLOSED for auth, OPEN for reads
                       so a cache outage cannot lock
                       everyone out

   Object storage or   video unavailable; browsing,
   CDN down            checkout, text lessons, and
                       assessments all continue

   Payment provider    checkout disabled with an honest
   down                message; learning continues for
                       everyone already enrolled

   Email provider      queued with retry; nothing blocks
   down                on delivery

   AI provider down    tutor unavailable, mock interviews
                       offer human mode, everything else
                       unaffected

   Read replica down   reads fall back to the primary,
                       slower but correct

   Primary DB down     the platform is down. This is the
                       one dependency with no graceful
                       degradation, which is why it is a
                       managed service with point-in-time
                       recovery and a rehearsed restore
```

## 16. How a change reaches production

The same discipline applies to shipping the code that runs all of the above.

```
   COMMIT TO PRODUCTION

   commit on a branch
        |
        v
   GitHub Actions: lint, type-check, unit tests,
   integration tests against real PostgreSQL and Redis,
   migration tested UP and DOWN, contract tests,
   security scans, guardrail checks
        |
        any failure --> merge blocked
        v
   pull request reviewed by the other track
        |
        v
   ONE image built, tagged with the commit
        |
        v
   deploy to DEV --------+
        |                | the SAME image
   promote to QA --------+ is promoted, never
        |                | rebuilt, because a
   promote to PROD ------+ rebuild means shipping
        |                  something you never tested
        v
   migrate (expand phase only, so the previous
   image still works against the new schema)
        |
        v
   canary: a small slice of traffic first
        |
        v
   health checks and error rate watched
        |
   +----+----+
   |         |
  bad       good
   |         |
   |         v
   |    full rollout, smoke tests, watched period
   |
   +--> ROLLBACK
        bad code    -> redeploy previous image, minutes
        bad config  -> change a setting, NO DEPLOY
        bad feature -> flip a feature flag, NO DEPLOY
```

## 17. The five rules that explain most of the design

If you remember nothing else from this document, remember these, because almost every decision above follows from one of them.

The client is never trusted for anything the server can determine. Prices, user identity, entitlement source, karma amounts, and roles are all resolved server-side. A request carrying any of them is rejected and logged.

Paying and being allowed are separate facts. Access is always checked against an entitlement, never against a payment or a subscription record, which is what lets free, subscription, purchase, scholarship, and corporate sponsorship all converge on one path.

Access is default-deny, enforced at startup. An endpoint that declares neither a permission nor an explicit public marker prevents the application from starting, so an accidentally open route cannot ship.

Nothing a non-engineer might change is hard-coded. Configuration, branding, navigation, pricing rules, feature flags, and karma values all live in the database, which is why two of the three fastest production rollbacks require no deployment at all.

The catalogue is data, not code. A new kind of product is a row in a registry, which is why none of the flows above branch on what kind of thing is being sold, learned, or certified.
