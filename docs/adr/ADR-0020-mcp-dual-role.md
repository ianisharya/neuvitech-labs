# ADR-0020: Model Context Protocol as a First-Class Capability, Server and Client

**Status:** Accepted
**Date:** 2026-09-06

## Context

The platform requires two distinct integration capabilities that are frequently conflated:

1. External AI clients require structured, authenticated access to platform capabilities such as catalogue search, learner progress, and course content.
2. The platform's own AI layer requires tools, and hand-writing a bespoke integration for every tool produces tight coupling and duplicated authorization logic.

The Model Context Protocol defines a standard for tool discovery, tool invocation, and context exchange between AI systems and capability providers. It addresses both requirements, but they are separate architectural surfaces with different security properties and must be designed separately.

## Decision

MCP is adopted in both roles.

**MCP Server role, inbound.** The platform exposes selected capabilities as MCP tools and resources, consumable by external MCP clients. This surface is treated as a public API with the same security requirements as any other externally reachable interface.

**MCP Client role, outbound.** The platform's AI layer consumes MCP servers, both internal and third-party, to acquire tools. Tool acquisition through MCP replaces bespoke per-integration code.

Both roles are implemented behind protocol-defined interfaces so that MCP is a transport and discovery mechanism, not a dependency that business logic is coupled to.

## Architectural Placement

The MCP layer is a distinct layer with defined boundaries to the layers on either side.

For the server role, an MCP request is subject to the identical authentication, authorization, rate limiting, input validation, and audit path as an HTTP API request. It is a different transport reaching the same service layer, not a parallel path with its own rules. A tool exposed over MCP that bypassed the policy decision point would be an authorization bypass, so the design requirement is that MCP tool handlers call the same service functions the HTTP routers call, and never reach the repository or database layer directly.

For the client role, tools acquired from MCP servers pass through the AI gateway's existing tool-authorization control. An MCP-acquired tool executes with the invoking user's authority, reduced to the allowance for the current task, exactly as a hand-written tool does. Acquiring a tool from an external server does not grant that tool any authority the user does not hold.

## Security Requirements

These are requirements of this decision, not recommendations.

**Server role.** Every exposed tool declares a required permission. A tool declaring none fails at startup, consistent with the default-deny requirement applied to HTTP endpoints. Tool inputs are validated against a declared schema before execution. Tool outputs are validated before return. Rate limits apply per client identity. Every invocation is audited with the identity, the tool, an argument digest, and the outcome.

**Client role.** External MCP servers are untrusted input sources. Tool descriptions and tool results returned by an external server are data, never instructions, and are delimited as such before reaching a model. This is the primary defence against an external server attempting to influence agent behaviour through crafted tool metadata. Connections to external servers are restricted to an explicit allow-list. A tool result is validated against its declared schema before use.

**Both roles.** Argument and result payloads are subject to the same data-minimization rules applied elsewhere: sensitive fields are excluded by allow-list, not blocklist.

## Alternatives Considered

**Bespoke integrations instead of MCP for the client role.** Rejected on coupling and duplication grounds. Each bespoke integration reimplements discovery, schema validation, error handling, and lifecycle. MCP provides one contract for all of them, and the abstraction cost is lower than the aggregate cost of the bespoke implementations it replaces.

**REST or GraphQL instead of MCP for the server role.** These remain available and are not replaced. The platform already exposes an HTTP API. MCP is added because AI clients discover and invoke capabilities through a protocol designed for that purpose, and requiring every such client to be hand-configured against a REST specification is a worse integration experience with no compensating benefit.

**MCP client role only, omitting the server role.** Rejected because the requirement explicitly includes both. It is recorded here that these are separable: the client role could ship without the server role if the inbound surface were later judged not to justify its security burden.

**Exposing the platform's internal service layer directly as MCP tools without a defined tool boundary.** Rejected. It would couple the external contract to internal service signatures, making internal refactoring a breaking external change.

## Consequences

**Enabled:** external AI clients integrate against a standard protocol rather than a bespoke client. The AI layer acquires tools without per-tool integration code. Tool contracts, validation, authorization, and observability are defined once and applied uniformly.

**Costs:** the server role is a new externally reachable surface and carries the security burden of one. MCP is a comparatively recent protocol and its specification continues to evolve, so the implementation must be versioned and the protocol dependency isolated behind the platform's own interfaces to bound the cost of specification change. Every exposed tool is a permanent public contract and must be versioned accordingly.

## Observability Requirements

MCP invocations emit the same telemetry as any other operation: a trace span per invocation correlated with the originating request, a metric for invocation count, latency, and error rate per tool, and a structured log entry. Tool arguments are recorded as a digest rather than in full, consistent with the rule that sensitive payloads are not logged.

## Revisit Trigger

Revisit the server role if the security burden of an externally reachable tool surface is measured to exceed its integration value. Revisit the client role's external-server allow-list policy if the number of external servers grows to a point where per-server review is impractical.
