# 43: Model Context Protocol Architecture

This document specifies the platform's use of the Model Context Protocol in both roles established by ADR-0020: as a server exposing platform capabilities to external AI clients, and as a client consuming tools from MCP servers. The two roles are separate surfaces with different trust properties and are specified separately.

## 1. Scope and rationale

MCP provides a standard for tool discovery, tool invocation, and context exchange between AI systems and capability providers. Adopting it addresses two requirements that would otherwise be met by bespoke code:

External AI clients require structured access to platform capabilities. Without a protocol, each client requires a hand-built integration against the HTTP API, and the platform has no standard way to describe what it offers.

The platform's own AI layer requires tools. Without a protocol, each tool requires bespoke integration code that reimplements discovery, schema validation, error handling, and lifecycle management.

## 2. The two roles

```
   SERVER ROLE, inbound                CLIENT ROLE, outbound

   External MCP client                 Platform AI agent
   (an AI application,                        |
    an IDE, an assistant)                     |
          |                                   v
          |                            AI gateway
          v                                   |
   Platform MCP server                        v
          |                            MCP client
          v                                   |
   Same authorization,                        v
   same service layer,                 External or internal
   same audit as HTTP                  MCP servers
          |                                   |
          v                                   v
   Platform capabilities               Tools, executed under
   exposed as tools                    the user's authority

   Trust: the client is             Trust: the server is
   untrusted. Authenticate,         untrusted. Its tool
   authorize, rate limit,           descriptions and results
   validate, audit.                 are data, never instructions.
```

The trust direction differs between the roles, and the controls follow from that difference. In the server role the platform is the resource owner and the caller is untrusted. In the client role the platform is the caller and the remote server's output is untrusted input.

## 3. Server role: exposing platform capabilities

### 3.1 Architectural placement

The MCP server is a separate workload class, deployed and scaled independently of the HTTP API, but it is not a separate application. It runs the same codebase and calls the same service layer.

```
   MCP request
        |
        v
   MCP transport layer          protocol framing, session handling
        |
        v
   Tool handler                 the MCP equivalent of an HTTP router
        |                       validates arguments against the
        |                       declared schema, resolves identity,
        |                       evaluates the declared permission
        v
   Service layer                IDENTICAL to the layer HTTP routes call
        |
        v
   Domain and repository
```

The requirement that tool handlers call the service layer, and never reach repositories or the database directly, is a security boundary rather than a style preference. Business rules, authorization checks embedded in services, and audit writes all live in the service layer. A tool handler that bypassed it would bypass those controls, producing an authorization path that differs from the HTTP path for the same operation.

### 3.2 Tool contract requirements

Every exposed tool declares:

- A stable name, which is a public contract and is versioned as such.
- A description sufficient for an AI client to determine when the tool applies.
- An input schema, against which arguments are validated before execution.
- An output schema, against which results are validated before return.
- A required permission, or an explicit public marker.
- A rate limit class.

A tool that declares no permission and no public marker causes a startup assertion failure, consistent with the default-deny rule applied to HTTP routes. This makes an unprotected tool a deployment-time failure rather than a runtime exposure.

### 3.3 Capability exposure

The following capability categories are appropriate for exposure. The specific tool set is an implementation decision to be made when the corresponding features exist, and is not enumerated here to avoid specifying tools for features that are not yet built.

- Catalogue discovery and retrieval, subject to published and public visibility rules.
- Learner progress and enrolment state, restricted to the authenticated principal's own data.
- Course content retrieval, subject to entitlement.
- Credential verification, which is already a public capability.

Administrative capabilities, commerce operations, and any operation that moves money, grants access, or modifies permissions are not exposed through MCP. This is a deliberate restriction: the inbound surface is for retrieval and learner-scoped state, not for privileged mutation.

### 3.4 Authentication and authorization

MCP clients authenticate with credentials issued and revocable per client. A client's authorization is the intersection of the authenticated principal's permissions and the permissions granted to that client registration. A client cannot exceed the principal on whose behalf it acts.

Rate limits apply per client registration and per tool class, with limits sourced from configuration rather than hard-coded.

### 3.5 Audit

Every invocation is recorded with the client identity, the principal identity, the tool name, a digest of the arguments, the outcome, and the duration. Arguments are recorded as a digest rather than in full, consistent with the data-minimization rule applied to logging. This record is the basis for detecting anomalous access patterns.

## 4. Client role: consuming tools

### 4.1 Architectural placement

The MCP client sits inside the AI layer, behind the gateway. It is a source of tools, and tools from it are subject to the same controls as tools defined in the platform's own code.

```
   Agent determines a tool is required
        |
        v
   Tool registry                  tools from all sources: locally
        |                         defined, and MCP-acquired
        v
   Authorization check            against the INVOKING USER's
        |                         permissions, reduced to the
        |                         allowance for the current task
        v
   MCP client                     invokes the remote tool
        |
        v
   Remote MCP server
        |
        v
   Result validated against declared schema
        |
        v
   Result delimited as untrusted data
        |
        v
   Returned to the agent
```

The authorization check occurs before invocation and is against the user's permissions. Acquiring a tool from a remote server confers no authority. This is the same rule that governs locally defined tools and is stated again here because the indirection of a remote source makes it easy to assume otherwise.

### 4.2 Treating remote servers as untrusted

A remote MCP server controls two things the platform must treat as untrusted input: the descriptions of the tools it advertises, and the results it returns.

Tool descriptions are incorporated into model context. A crafted description is therefore a prompt injection vector. Descriptions from remote servers are delimited as data and are never concatenated into instruction positions in a prompt.

Tool results are likewise delimited. A result that contains text resembling an instruction is data about which the model reasons, not an instruction the model follows.

Connections are restricted to an explicit allow-list. A server not on the list is not contacted. Addition to the list is a reviewed change, on the same basis as adding a dependency.

### 4.3 Failure handling

Remote servers are subject to the standard resilience controls: connection and invocation timeouts, bounded retries with exponential backoff and jitter, and a circuit breaker per server that stops invocation after repeated failure rather than continuing to attempt it.

An unavailable server results in the affected tools being unavailable. The agent proceeds without them or reports the limitation. Server unavailability does not fail the request.

## 5. Observability

MCP operations emit the same telemetry as any other operation, correlated by the same identifier.

- A trace span per invocation, a child of the originating request span, so that an MCP call appears in the trace of the request that caused it.
- Metrics per tool: invocation count, latency distribution, error rate, and for the client role, per-server availability and circuit breaker state.
- A structured log entry per invocation, with argument digests rather than argument contents.
- Authorization denials recorded as security events, distinct from ordinary errors.

## 6. Versioning and protocol dependency

The MCP specification is comparatively recent and continues to evolve. Two measures bound the cost of specification change.

The protocol implementation is isolated behind the platform's own interfaces. Application code depends on the platform's tool abstraction, not on protocol types. A specification change affects the transport layer, not the tool handlers or the service layer.

Exposed tool names and schemas are versioned as public contracts. A breaking change to a tool is a new version, with the previous version retained through a deprecation period. This is required because external clients depend on these contracts and cannot be updated in lockstep.

## 7. Open items requiring decision

The following are unresolved and are recorded as such rather than assumed:

- The specific tool set to expose in the server role, which depends on which features exist at the time of implementation.
- The client registration and credential issuance mechanism, which depends on whether external clients are first-party, partner, or public.
- Whether the server role is exposed publicly or restricted to authenticated partners at initial release.
