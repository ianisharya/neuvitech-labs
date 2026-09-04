# ADR-0004: Next.js 15 as Presentation/BFF, Holding No Business Logic

**Status:** Accepted · **Date:** 2026-08-30

## Context
SEO is a first-class requirement across Program, Track, Specialization, Masterclass and certificate-verification pages. The LMS half is an authenticated, app-like experience. The team is two backend engineers with no frontend specialist, and the product must be best-in-class on UI/UX.

## Decision
Next.js 15 (App Router) + TypeScript strict as presentation and BFF only. It renders, caches and forwards an opaque session cookie. **All business logic lives in FastAPI.** Types are generated from OpenAPI into `packages/contracts`, with CI failing on drift.

Implementation is deliberately conservative given the team's skill profile: **React Server Components by default**, shadcn/ui vendored for accessible primitives, **no client-state library**, Tailwind utilities only.

## Alternatives Considered
**Next.js fullstack with logic in route handlers**: rejected. Splits the domain across two languages: the worst outcome.
**Pure SPA (Vite + React)**: rejected. Forfeits SEO, an explicit requirement.
**Server-rendered Jinja templates from FastAPI**: genuinely considered, since it keeps the team in one language. Rejected because the learning player, checkout and admin console need real interactivity, and htmx-style approaches would fight us there. Server Components give us most of the "return HTML" simplicity anyway.
**Astro**: excellent for the content half, weaker for the authenticated app half.

## Consequences
**Positive:** SSR/ISR for SEO · RSC keeps catalog pages near-zero-JS, which directly serves the Core Web Vitals budgets · one clear boundary between the two tracks · generated types catch cross-track breakage at compile time.
**Negative:** two runtimes and toolchains · a network hop · **the team has no frontend expertise**, the largest execution risk in the programme, mitigated by the conservative approach in doc 11 and the Sprint 10 track swap.

## Cost
Free and open source.

## Security
No business logic in the browser-facing layer. Session cookie is `httpOnly`/`Secure`/`SameSite=Lax`; the browser never holds a token it could leak. **Risk: caching an authenticated response is a cross-user data leak**: treated as a security issue in the troubleshooting guide, not a performance note.

## Scalability
Stateless, horizontally scalable. ISR and CDN absorb the ~85% cacheable catalog traffic.

## Migration Path
Because the frontend holds no logic, replacing it is a presentation rewrite only; the API contract is unchanged.

## Revisit Trigger
Track B consistently overrunning by Sprint 8 → simplify the admin console, swap tracks earlier, or contract a frontend engineer for the catalog and checkout surfaces.
