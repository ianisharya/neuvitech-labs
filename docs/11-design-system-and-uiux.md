# 11: Design System & UI/UX Strategy

**Goal: be the best-looking, best-feeling technology education platform in the market.** Not "good for a startup". Genuinely better than the incumbents.

This document explains how that is achieved with two engineers and no full-time designer, and why the approach is credible rather than aspirational.

---

## 1. The honest starting position

Neither of you is a designer. That is not fatal, because **most of what separates a world-class interface from an amateur one is not taste, it is discipline, and discipline is an engineering skill you already have.**

The gap breaks down as:

| Contributor to "looks premium" | Requires taste? | How we get it |
|---|---|---|
| Consistent spacing | No | An enforced token scale |
| Consistent typography | No | A locked type scale |
| Correct visual hierarchy | Mostly no | Rules, stated below |
| Accessible contrast | No | Tokens chosen to satisfy 4.5:1 by construction |
| All states implemented | No | Component checklist |
| Smooth, purposeful motion | Partly | A motion token set with strict rules |
| Fast, no layout shift | No | Performance budgets in CI |
| Distinctive visual identity | **Yes** | The one place we invest real design effort |

**Seven of eight are mechanical.** We industrialise those, then spend our limited design judgement on the eighth.

## 2. Foundation: vendored shadcn/ui, then restyled

`shadcn/ui` copies component **source into the repository**. It is not a dependency, it is our code from the moment it lands.

- **What we take:** correct behaviour. Focus trapping in dialogs, roving tabindex in menus, ARIA relationships, keyboard semantics for comboboxes. These take a specialist a day each and a non-specialist a week each, and the non-specialist version is still subtly wrong for screen readers.
- **What we replace:** all of the visual layer. Default shadcn styling is recognisable, and a recognisable template is the opposite of what we want. Sprint 5 restyles every primitive against our own tokens.

**Result:** correct accessibility from day one, distinctive appearance by Sprint 5, zero lock-in.

## 3. The token system: single source of truth, database-backed

Tokens live in the database (`setting` group `brand`) and are emitted as CSS custom properties by the Next.js root layout, so **brand changes require no deploy** (see `05-configuration-architecture.md`).

### Typography: one scale, six sizes, never deviate
```
display clamp(2.5rem, 5vw, 4rem) 700 -0.03em 1.05
h1 clamp(2rem, 3.5vw, 3rem) 700 -0.02em 1.15
h2 1.75rem 600 -0.01em 1.25
h3 1.25rem 600 0 1.35
body 1rem 400 0 1.65
small 0.875rem 400 0.01em 1.5
```
Two families: one geometric sans for UI and headings, one monospace for code. **Nothing else.** `1.65` body line-height is deliberate, technical reading is dense, and generous leading is the cheapest readability win available.

### Spacing: 4px base, eight steps
`4 · 8 · 12 · 16 · 24 · 32 · 48 · 64 · 96`. An arbitrary `13px` fails lint.

### Colour: semantic, never raw
```
--surface --surface-raised --surface-sunken
--content --content-muted --content-subtle
--accent --accent-hover --accent-contrast
--border --border-strong
--success --warning --danger --info (each with -subtle and -contrast)
```
Components reference `--accent`, never a hex value. Dark mode is a token swap, not a second stylesheet. Contrast ratios are verified in CI, not by eye.

### Elevation, radius, motion
Three shadow levels. Three radii. Motion tokens: `fast 120ms`, `base 200ms`, `slow 320ms`, easing `cubic-bezier(0.32, 0.72, 0, 1)`, a decelerating curve that feels responsive rather than floaty.

## 4. The five rules that produce "premium"

**1. Hierarchy through space and weight, not colour and borders.** Amateur interfaces separate things with lines and background colours. Good interfaces use whitespace and type weight. When two elements feel too close, add space before adding a border.

**2. One accent colour, used sparingly.** The accent marks the primary action and nothing else. A page with six accent-coloured elements has no primary action. Restraint reads as confidence.

**3. Motion must mean something.** Every animation communicates state change, spatial relationship, or continuity. Decorative motion is deleted. Nothing exceeds 320 ms. Everything honours `prefers-reduced-motion`.

**4. Every state is designed.** Default · hover · focus-visible · active · disabled · **loading · empty · error**. The last three are where amateur interfaces are exposed, because they only appear when something has gone wrong and nobody designed for it. **A component PR without empty and error states is rejected.**

**5. Content sets the width.** Prose caps at ~68 characters. Cards obey a grid. Nothing stretches edge-to-edge on a 27-inch monitor because a `div` had no max-width.

## 5. Where we spend real design effort

Three surfaces determine whether the product feels premium, because they are what a prospective learner sees before deciding:

| Surface | Why | Sprint |
|---|---|---|
| **Homepage** | The first ten seconds decide credibility | 5, refined 12 |
| **Program / Specialization detail page** | Where the purchase decision is made | 5, refined 12 |
| **Learning player** | Where learners spend hundreds of hours | 9, refined 13 |

Everything else, admin, forms, tables, settings, needs to be clean, fast and consistent, not distinctive. **Do not spend a weekend making the admin console beautiful.** It has an audience of two.

## 6. Performance is part of the design

A beautiful interface that takes four seconds to load is not beautiful. Budgets enforced by Lighthouse CI, failing the build on regression:

| Metric | Budget |
|---|---|
| LCP (catalog, 4G mid-tier mobile) | < 2.0 s |
| INP | < 200 ms |
| CLS | **< 0.05** |
| TTFB cached / uncached | < 300 ms / < 800 ms |
| JS shipped, catalog page | < 120 KB gzipped |

**CLS below 0.05 is the one that most affects perceived quality.** Content jumping while loading reads as broken regardless of how good the static design is. Every image has explicit dimensions; every async region reserves its space with a skeleton.

**Server Components by default.** Catalog pages ship almost no JavaScript. `"use client"` only for genuine interactivity, pushed as far down the tree as possible.

## 7. Accessibility: a gate, not an aspiration

WCAG 2.2 AA. Semantic HTML. Full keyboard operability. Visible focus rings, **never `outline: none`**. Labelled controls. Contrast verified by token construction. Reduced-motion honoured. Screen-reader-tested critical flows.

`axe` runs in component tests and Playwright E2E. **Violations fail the build.**

This is not only ethics and compliance. Keyboard navigation and correct semantics are what make an interface feel *responsive and solid* to everyone.

## 8. Quality gates in CI

| Gate | Fails the build on |
|---|---|
| ESLint custom rules | Raw hex colours, arbitrary spacing, hard-coded user-facing strings, `outline: none` |
| axe (component + E2E) | Any serious or critical violation |
| Lighthouse CI | Any budget in §6 exceeded |
| Visual regression (Playwright screenshots) | Unintended visual change on key surfaces |
| Bundle size | Catalog JS over budget |

**A component PR must include:** all eight states, keyboard operation, an axe-clean test, mobile at 320px, dark mode, and a Storybook-free usage example in the PR description.

## 9. Responsive strategy

Mobile-first. Breakpoints `640 / 768 / 1024 / 1280 / 1536`. Touch targets ≥ 44×44 px. Tables become cards below `768`. The learning player is genuinely usable on a phone, a large share of learners in this market study on mobile, and treating mobile as a shrunken desktop is the most common failure in EdTech interfaces.

## 10. How this scales past two engineers

Because tokens are database-backed and components are vendored and documented, a designer hired in month six changes the entire product's appearance by editing token values in the admin UI, no code, no deploy. And a new frontend engineer inherits a component library with enforced rules rather than a codebase of one-off styles.

**That is the actual test of a design system: whether the fifth person to touch it produces work consistent with the first.**
