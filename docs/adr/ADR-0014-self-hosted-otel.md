# ADR-0014: Self-Hosted OpenTelemetry Stack over SaaS APM

**Status:** Accepted · **Date:** Sprint 4

## Context

Observability is a first-class requirement from Sprint 2 (`docs/14`), covering logs, metrics, traces, dashboards and alerts across the API, presentation app, workers and infrastructure. Student data, including, eventually, AI conversation metadata (`docs/12` §6), flows through the system, and privacy commitments (`docs/08` §9) constrain where that data may go.

## Decision

A self-hosted stack: OpenTelemetry for instrumentation, Prometheus for metrics, Loki for logs, Tempo for traces, Grafana as the shared dashboard layer, GlitchTip for error tracking (`docs/14` §1), not a commercial SaaS APM product (Datadog, New Relic, Sentry-hosted).

## Alternatives Considered

**A commercial SaaS APM platform** (Datadog, New Relic, or similar). Seriously considered for the operational convenience, no infrastructure to run, polished dashboards out of the box, and less Sprint 4 setup work. Rejected on two grounds. First, privacy: these platforms mean shipping application data, potentially including fragments of student activity or AI interaction metadata, to a third party's infrastructure, which sits uneasily against the data-minimisation stance already taken in `docs/08` §9, self-hosting means observability data never leaves infrastructure we control. Second, cost trajectory: commercial APM pricing typically scales with data volume or host count, which becomes a real, growing line item exactly as the product succeeds, the self-hosted stack's cost is infrastructure only, not a per-event or per-seat fee.

**Sentry, hosted, for error tracking specifically** (as distinct from full APM). Rejected in favour of GlitchTip, which is API-compatible with Sentry's SDK and protocol but self-hostable and free, meaning the same client-side instrumentation works, without sending error payloads (which can contain sensitive request context) to a third party.

**No structured observability stack at all, logs to stdout, manual `docker logs` inspection, no metrics or tracing.** Rejected outright per `docs/14`'s own opening line: observability is part of the product, not an afterthought, and Sprint 13's entire premise (validating every alert by deliberately breaking things) requires a real stack to validate in the first place.

## Consequences

**Positive:** no application or student data leaves our own infrastructure boundary · no per-event or per-host billing that scales against us as the product grows · OpenTelemetry as the instrumentation layer means the *backend* is swappable later without touching instrumentation code, a config change, not a re-instrumentation effort, if a future need ever justifies revisiting this decision · Grafana provides one pane across all three signals (logs, metrics, traces), avoiding the tool-switching cost of separate systems per signal.

**Negative:** genuine setup and ongoing operational cost, five services (Prometheus, Loki, Tempo, Grafana, GlitchTip) to run, monitor, and keep healthy ourselves, rather than a vendor's SLA · no vendor support line to call when something in the observability stack itself breaks · dashboards and alert rules are built by us from scratch rather than inherited from a mature commercial product's defaults.

## Trade-offs

We take on real operational responsibility for the tools meant to tell us when something else is broken, a legitimate risk (who observes the observability stack?), in exchange for data never leaving our infrastructure and a cost structure that does not penalise growth. Given the explicit privacy commitments already made elsewhere in this pack, the trade favours self-hosting.

## Cost

Free and open source software; the cost is the compute to run it, which is small relative to the application infrastructure it observes, and does not scale per-event the way commercial APM billing typically does.

## Security

Observability data, logs, traces, metrics, never crosses our infrastructure boundary. PII exclusion is enforced by an allow-list serialiser (`docs/14` §2) regardless of backend, but self-hosting removes the additional risk of a third-party vendor's own security posture as a second point of exposure for that data.

## Scalability

Each component (Prometheus, Loki, Tempo) scales independently and is designed for exactly this workload profile at far larger scale than we need. Sample rates for traces are configurable in settings (`docs/14` §4) rather than fixed, so cost and volume can be tuned without redeploying.

## Migration Path

Because OpenTelemetry is the instrumentation layer rather than any specific backend, switching to a commercial platform later, if the operational burden of self-hosting ever outweighs the privacy and cost benefits, is a collector configuration change, not a rewrite of instrumentation throughout the codebase.

## Revisit Trigger

The operational burden of running five self-hosted services becomes a genuine drag on sprint capacity with no engineer able to own it reliably → revisit a commercial platform, accepting the privacy and cost trade-offs explicitly at that point rather than by default now.
