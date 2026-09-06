# ADR-0022: Local Development on Constrained Hardware

**Status:** Accepted
**Date:** 2026-09-06

## Context

Development occurs on two machines: an Apple Silicon M1 with 8 GB of unified memory, and a Windows machine with 16 GB of RAM. The 8 GB machine is the binding constraint, because a development environment that only functions on the larger machine violates the requirement that both engineers work in an identical environment.

The production architecture comprises an API service, a web application, background workers, PostgreSQL, Redis, object storage, an observability stack, a model inference server, and Kubernetes. The aggregate memory requirement of running all of these simultaneously exceeds 8 GB. This is a measurable fact about the resource requirements of the components, not an estimate.

A local development design that assumes the full stack runs locally is therefore not viable. This ADR records the design that follows from accepting that constraint rather than working around it.

## Decision

Local development uses profile-based service composition. A developer starts only the services the current task requires. There is no default profile that starts everything.

Kubernetes is not the local development mode. Docker Compose is, with a lightweight Kubernetes cluster available on demand for tasks that specifically concern Kubernetes manifests or behaviour. This preserves the Dev Container guarantee of an identical toolchain across machines while not requiring a local control plane for routine work.

Model inference is not assumed to run locally. Three modes are supported and selected by configuration: a small quantized model through local Ollama, a shared inference endpoint reachable over the network, or the in-memory test implementation of the model provider interface. The third mode requires no inference at all and is the default for tests and for work that does not concern AI behaviour.

## Profiles

Profiles are defined by what a task requires, and the composition is declared rather than assembled by hand.

- **Minimal.** API and PostgreSQL. Sufficient for domain logic, schema work, and the majority of backend tasks.
- **Web.** Adds the web application. Sufficient for interface work against a running API.
- **Full local.** Adds Redis, object storage, and mail capture. Required for work on caching, queuing, media handling, or notification.
- **AI.** Adds local inference. Required only for work on AI behaviour, and explicitly optional even then, given the alternative modes above.
- **Observability.** Adds the metrics, logging, and tracing stack. Required only for work on observability itself. This profile is not part of routine development because its aggregate memory requirement is significant relative to the constrained machine.
- **Kubernetes.** A lightweight local cluster for manifest and cluster-behaviour work. Mutually exclusive with the other profiles on the constrained machine.

## Design Requirements That Follow

Several architectural properties are required in order for profile-based development to function. These are consequences of this decision and are binding on other components.

The application must start and serve requests when optional dependencies are absent. A missing cache degrades to direct database reads. A missing object store disables media features and reports them as unavailable. A missing inference provider disables AI features. In each case the application starts, reports the degraded capability through the readiness endpoint, and continues serving what it can. An application that requires every dependency to start cannot support profiles.

Test execution must not require infrastructure beyond PostgreSQL. Tests that require Redis, object storage, or inference use the in-memory implementations of the corresponding provider interfaces defined in ADR-0021. This is a direct dependency between the two decisions: profile-based development is practical because the provider abstraction makes in-memory substitution available.

Container images used locally are selected for size and memory footprint. Alpine or slim base images where the workload permits. This reduces both memory pressure and image pull time on constrained hardware.

## Alternatives Considered

**Require the full stack locally, and require hardware capable of running it.** Rejected. It makes the 8 GB machine unusable for development, which is not an available outcome.

**Remote development environments, with local machines as thin clients.** Not rejected, and recorded as a viable future option. It resolves the constraint entirely by moving execution to adequate hardware. It is not selected now because it introduces a recurring cost that the cost constraints direct against, and a dependency on connectivity for all development work.

**Kubernetes as the local development mode, using a lightweight distribution.** Rejected as the default. A local control plane consumes memory that the constrained machine requires for the workloads under development. It remains available as a profile for tasks that specifically concern Kubernetes.

**Local inference as a requirement for all development.** Rejected. Model inference has a memory requirement that competes directly with the services under development. Making it optional, through the provider abstraction, removes that competition for the majority of tasks that do not concern AI behaviour.

## Consequences

**Enabled:** development is viable on both machines. Routine tasks start quickly because they start few services. Test execution is fast because it requires minimal infrastructure.

**Costs:** a developer must select an appropriate profile rather than starting everything, which is a small operational burden and a source of confusion if a task fails because a required service is not running. This is mitigated by the readiness endpoint reporting which dependencies are absent, so the failure mode is a clear report rather than an obscure error.

Integration behaviour that only manifests with the full stack running is not exercised locally. This is a real gap and it is addressed by continuous integration running the full composition, not by claiming local coverage that does not exist.

## Verification Requirement

The claim that a given profile functions within the memory available on the constrained machine is not asserted in this document. It is verified by measurement on the actual hardware, and the measured figures are recorded in the development environment documentation once obtained. No memory figures are stated here because none have been measured.

## Revisit Trigger

Revisit if development hardware changes, or if the proportion of tasks requiring the full stack rises to the point where profile switching is a material burden. In either case remote development environments are the first alternative to reconsider.
