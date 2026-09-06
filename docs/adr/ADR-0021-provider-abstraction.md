# ADR-0021: Provider Abstraction for Replaceable Infrastructure and Model Components

**Status:** Accepted
**Date:** 2026-09-06

## Context

The architecture requires that components with multiple viable implementations can be substituted without modifying business logic. The stated requirement is specific: moving from open-source local models to hosted model APIs must be a configuration change, not a rewrite.

This property is required for more than models. Payment processing, object storage, meeting provision, embedding generation, reranking, vector storage, and notification delivery all have multiple viable implementations, all are subject to change over the life of the system, and all are currently referenced by business logic that must not be coupled to a specific choice.

Without a deliberate abstraction, provider-specific types and calls propagate into service and domain code, and substitution becomes a cross-cutting change touching every call site.

## Decision

Every replaceable external capability is accessed through a protocol-defined interface. Business logic depends on the interface. Concrete implementations depend on the interface. Neither depends on the other, which is dependency inversion applied to the infrastructure boundary.

The mechanism uses Python's `typing.Protocol` for structural interface definition, a registry mapping a provider identifier to an implementation, and dependency injection supplying the resolved implementation to consumers. Provider selection is a configuration value resolved at composition time, not a conditional in business logic.

The following capabilities are defined as replaceable and accessed through this mechanism:

- Language model inference
- Text embedding generation
- Reranking
- Vector storage and similarity search
- Payment processing
- Object storage
- Meeting and live session provision
- Transactional notification delivery
- Full-text search

## Interface Design Requirements

An interface in this scheme is defined in terms of the domain need, not the capabilities of any one implementation. This is the requirement that determines whether the abstraction actually works.

An interface modelled on a specific provider's API surface fails the moment a second provider with a different shape is introduced. An interface modelled on what the domain requires accommodates any implementation that can satisfy that requirement. Concretely, a language model interface expresses generation, streaming generation, and structured generation against a declared schema, because those are the operations the domain performs. It does not expose provider-specific parameters as required arguments.

Implementation-specific configuration is supplied to the implementation at construction, from the configuration system, and is not visible to callers.

Where implementations differ in capability rather than in interface, the interface declares capability queries. A caller that requires a capability queries for it and degrades explicitly if it is absent, rather than calling and failing.

## Model Provider Specifics

The model provider abstraction supports local inference through Ollama and remote inference through hosted APIs behind the same interface. Selection is configuration.

Ollama is used for local development and for self-hosted inference. It is open source, runs on Apple Silicon and on Windows, exposes a stable HTTP interface, and supports quantized models that fit within constrained local memory. Its selection is a consequence of the cost constraint and the local hardware constraint, both documented.

The interface does not assume local execution. A hosted API implementation satisfies the same interface. No business logic distinguishes them.

Model selection per capability is configuration, not code. A classification task and a tutoring task may be routed to different models, and that routing is a configuration value.

## Alternatives Considered

**Direct provider SDK usage in service code.** Rejected. It couples business logic to a provider, makes substitution a cross-cutting change, and makes testing require either network access or SDK-specific mocking.

**A framework's built-in provider abstraction used as the application's abstraction.** Rejected as the primary mechanism. Adopting a framework's abstraction as the application's own boundary makes the framework itself the coupling. Framework abstractions may be used inside a concrete implementation, behind the platform's own interface.

**Configuration-driven dynamic import without a defined interface.** Rejected. It provides substitutability without type safety or a contract, moving failures from definition time to runtime.

**Abstracting every external dependency without exception.** Rejected as over-application. Abstraction has a cost in indirection. It is applied where substitution is a realistic requirement. The primary relational database is not abstracted behind a provider interface, because the architecture depends on its specific capabilities and substituting it is not a realistic requirement that the abstraction would serve.

## Consequences

**Enabled:** provider substitution is a configuration change. Testing uses in-memory implementations of the interfaces rather than network access or SDK mocks, which makes the test suite fast and deterministic. New providers are added by implementing an interface and registering it, without modifying callers.

**Costs:** an additional layer of indirection between business logic and provider. Interfaces must be designed against domain needs rather than a convenient provider shape, which requires more design effort at definition time. Provider-specific capabilities that fall outside an interface are either unavailable or require a capability query, which is a deliberate constraint.

## Testing Requirement

Each interface has an in-memory implementation used in tests. A test that exercises business logic does not reach a network. This is a requirement of the decision, because an abstraction that is not exercised by a second implementation is not verified to be an abstraction.

## Revisit Trigger

Revisit an individual interface if a required capability cannot be expressed without leaking provider specifics into the contract. That condition indicates the interface was modelled incorrectly and requires redesign rather than a provider-specific escape.
