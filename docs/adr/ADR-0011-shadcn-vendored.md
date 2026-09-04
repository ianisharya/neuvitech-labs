# ADR-0011: shadcn/ui Vendored, Restyled to Our Own Tokens

**Status:** Accepted · **Date:** Sprint 5

## Context

The product must be best-in-class on UI/UX (`docs/11`) with a two-person team, neither of whom is a frontend specialist. Accessible component behaviour, focus management, keyboard navigation, ARIA semantics, is genuinely hard to get right from scratch, and getting it wrong is invisible to a sighted, mouse-using developer testing their own work.

## Decision

`shadcn/ui` primitives, with source **copied into the repository** rather than installed as a dependency, then restyled entirely against our own design tokens from Sprint 5 (`docs/11` §2–3).

## Alternatives Considered

**A traditional component library dependency (MUI, Chakra, Ant Design).** Rejected. These ship their own visual identity baked into the component, which fights against building something that does not read as templated (`docs/11`'s explicit goal). Overriding a dependency's default styling consistently, across every component, every state, is harder than styling something we own outright, and every library update risks a visual regression we did not choose.

**Build every primitive from scratch.** Rejected. Correct focus trapping in a dialog, correct roving tabindex in a menu, correct ARIA relationships in a combobox, each takes a specialist the better part of a day to get right and a non-specialist the better part of a week to get *nearly* right, often with subtle screen-reader bugs that do not surface until real assistive-technology testing. Neither engineer has that specialism; shadcn/ui's primitives (built on Radix) already do.

**Install shadcn/ui as a conventional npm dependency instead of vendoring the source.** Rejected. shadcn/ui's own distribution model is a CLI that copies component source into your project specifically so you own and can modify it, installing it as a black-box dependency would mean fighting the tool's own design intent, and would reintroduce exactly the "can't fully restyle without overriding" problem the traditional-library alternative above has.

## Consequences

**Positive:** correct accessibility behaviour from day one, without either engineer needing frontend accessibility expertise · full ownership of every component's visual layer from the moment it lands, so restyling against our tokens (`docs/11` §3) is unconstrained · no dependency version to manage for these components, once vendored, a Radix upgrade is a deliberate choice, not something that arrives silently in `npm update` · zero lock-in, the code is ours.

**Negative:** we do not get upstream bug fixes automatically; a Radix accessibility fix requires us to notice it and re-vendor · more code in the repository to maintain long-term, since these components are now ours rather than a dependency's · initial restyling work in Sprint 5 is real effort, not a config flag.

## Trade-offs

We give up automatic upstream updates in exchange for full styling control and zero risk of a dependency update silently changing our visual identity. Given the explicit goal is a distinctive, non-templated interface (`docs/11` §1), the trade favours ownership.

## Cost

Free and open source, both shadcn/ui's CLI and the underlying Radix primitives.

## Security

Vendored code is reviewed like any other code in the repository, a security issue in a Radix primitive is caught by our own review process, not silently patched by an upstream release we never see. This cuts both ways: we also do not get an automatic fix without noticing the need for one.

## Scalability

No different from any other frontend component, server-rendered by default (`docs/11` §6), client-side interactivity only where genuinely needed.

## Migration Path

Because the components are vendored source, not a dependency, there is no "migrate away from shadcn/ui" scenario in the conventional sense, we already own the code. A future decision to restructure component internals is a normal refactor, not a dependency migration.

## Revisit Trigger

A specific Radix or shadcn/ui upstream fix (accessibility, security) becomes important enough to justify re-vendoring that component → do so deliberately, reviewed like any other change. The team gaining genuine frontend/design specialism such that vendored primitives become a maintenance burden rather than a starting point → revisit whether a different foundation serves better at that point.
