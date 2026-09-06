# 12: AI Architecture

This document specifies the AI layer: its abstractions, its execution model, its controls, and its integration with the rest of the system. The governing decisions are ADR-0018, ADR-0020, and ADR-0021.

## 1. Position on where AI is applied

AI is applied where the task genuinely requires language understanding or multi-step reasoning. It is not applied where a deterministic method produces a more correct, cheaper, and more explainable result.

The following are deterministic and are not model calls: catalogue recommendation based on skill gaps, which is a query and a ranking; keyword search, which is a text index; any computation whose correctness matters, which is computed and may then have its explanation phrased by a model.

The following genuinely benefit from a model: answering a learner's question grounded in course content, conducting a practice interview, reviewing a submitted document, and generating a personalised learning path across multiple constraints.

This distinction is recorded because introducing agents where deterministic logic suffices increases cost, latency, and failure surface without improving the result.

## 2. Provider abstraction

Every model capability is accessed through a protocol-defined interface, per ADR-0021. The interfaces are defined by what the domain requires, not by the shape of any provider's API.

```
   Domain and service layer
        |
        | depends on interfaces only
        v
   +--------------------------------------------------+
   |  AI PORTS                                        |
   |                                                  |
   |  LanguageModel      generate, stream, structured |
   |  EmbeddingModel     embed one, embed batch       |
   |  Reranker           rerank candidates            |
   |  VectorStore        upsert, search, delete       |
   +--------------------------------------------------+
        ^                    ^                    ^
        |                    |                    |
   +---------+        +-------------+     +--------------+
   | Ollama  |        | Hosted API  |     | In-memory    |
   | local   |        | remote      |     | test double  |
   +---------+        +-------------+     +--------------+

   Selection is configuration. No business logic branches
   on which implementation is active.
```

**Ollama** is the local and self-hosted inference implementation. It is open source, runs on Apple Silicon and Windows, exposes a stable HTTP interface, and supports quantized models that fit constrained memory. Its selection follows from the cost constraint and the local hardware constraint.

**Hosted API implementations** satisfy the same interfaces. Moving a capability from local to hosted inference is a configuration change.

**In-memory implementations** return deterministic canned responses and require no inference. They are used in tests and in development profiles that do not concern AI behaviour, per ADR-0022.

Model selection is per capability rather than global. A classification task and a tutoring task may route to different models, and that routing is configuration.

### 2.1 Structured output

Structured generation is a first-class interface operation, not a parsing convention applied to free text. The caller supplies a schema; the implementation returns data conforming to it or raises. Where a provider supports constrained decoding natively, the implementation uses it. Where it does not, the implementation applies a bounded repair attempt and then fails explicitly rather than returning malformed data.

## 3. The gateway

All AI execution passes through a single gateway. No component calls a model implementation directly. Centralisation is required because budget enforcement, guardrails, prompt versioning, memory access, and audit cannot be reliably applied if callers can bypass them.

```
   Request from a caller
        |
   [1]  Authenticate the principal
        |
   [2]  Authorize the requested capability
        |
   [3]  Evaluate budget and rate limits
        |     per principal, per capability, per period
        |
   [4]  Input guardrails
        |     length bounds, sensitive-data removal,
        |     injection heuristics
        |
   [5]  Retrieval, scoped by the principal's entitlements
        |     the access constraint is part of the query,
        |     so inaccessible content is never returned
        |
   [6]  Memory load
        |     conversation, activity-derived, summarised
        |
   [7]  Prompt assembly from a versioned template
        |
   [8]  Model invocation through the port
        |     timeout, bounded retry, circuit breaker
        |
   [9]  Output validation
        |     schema conformance, grounding check where
        |     applicable, sensitive-data scan
        |
   [10] Tool authorization, per invocation
        |     against the PRINCIPAL's permissions
        |
   [11] Tool execution, local or via MCP client
        |
   [12] Human approval gate for designated actions
        |
   [13] Audit and cost record
        |
        v
   Response
```

## 4. Execution patterns

Three execution patterns are available. Selection is by task characteristics, not by preference.

**Single-turn generation.** One model call producing one result. Applied to summarisation, phrasing, and classification. Lowest cost and latency.

**Retrieval-augmented generation.** Retrieve relevant material, then generate grounded in it, with citations. Applied to answering questions about course content. The retrieval scope is the principal's entitlements.

**Agentic execution.** A model plans, invokes tools, observes results, and iterates toward a goal. Applied where the task genuinely requires multiple dependent steps: conducting an interview across turns, assembling a learning path against multiple constraints.

Agentic execution is bounded on every axis: maximum tool invocations per run, maximum wall-clock duration, maximum token consumption, and cycle detection. An agent that exceeds a bound is terminated and reports the limitation. Unbounded agent loops are a known failure mode with direct cost consequences, so the bounds are mandatory rather than configurable to unlimited.

Graph-structured agent orchestration is used where an execution has genuinely conditional or cyclic structure. It is not used for linear sequences, where it adds indirection without benefit.

## 5. Retrieval

Retrieval combines lexical and semantic matching. Lexical matching handles exact technical terms, where semantic similarity performs poorly because a specific identifier must match precisely. Semantic matching handles paraphrase, where a learner's phrasing differs from the source material. Results from both are fused into a single ranking, and a reranking stage orders the fused candidates by relevance to the query.

The access constraint is applied within the retrieval query. Content the principal is not entitled to access is not returned by the query and therefore cannot reach the model. Filtering after retrieval is not acceptable, because the model would already have received the content.

Vector storage is accessed through the VectorStore interface. The initial implementation uses the vector extension of the primary database, which avoids operating a separate system. The interface permits substitution if measured recall or latency requires it.

## 6. Memory

Memory persists in the platform's own database. It is not held in a third-party service, consistent with ADR-0018.

```
   SHORT-TERM        the current conversation
                     provides continuity within a session

   ACTIVITY-DERIVED  read from the learner's recorded activity:
                     progress, completions, assessment outcomes
                     not written by the AI layer; read from the
                     authoritative record

   SUMMARISED        distilled history of prior interactions
                     bounded in size; not a verbatim transcript
```

Activity-derived memory is read from the existing record rather than maintained separately, which avoids a second source of truth that could diverge from the authoritative one.

Memory is scoped to a single principal. No retrieval path returns another principal's memory. The principal can inspect and delete their memory. Sensitive categories are excluded by allow-list at write time, consistent with the logging rule.

## 7. Tools

A tool has a declared name, an input schema, an output schema, a required permission, and an implementation. Tools originate either from platform code or from an MCP server, per document 43. Both kinds are subject to identical controls.

Authorization is evaluated per invocation against the invoking principal's permissions, reduced to the allowance for the current capability. The agent holds no authority independent of the principal.

The following are not available to any tool: direct database access, arbitrary code execution, infrastructure control, movement of funds, granting or revoking access, modification of roles or permissions, and access to secrets. Operations in these categories follow a propose-approve-execute pattern in which the model proposes, a human approves, and the system executes under the human's authority. The model never holds the capability.

## 8. Prompt management

Prompts are versioned records, not inline strings. Each carries a capability, a version, the template, model constraints, and an active flag. Prompts are reviewed as code and can be rolled back.

A prompt change is a behavioural change and is gated by evaluation before activation, per section 10.

## 9. Cost and resource control

Budgets are enforced at the gateway per principal, per capability, and per period. Exceeding a budget produces an explicit refusal, not a silent degradation.

Cost is reduced by routing simple tasks to smaller models, caching embeddings for unchanged content rather than recomputing, batching embedding generation, and applying deterministic methods where they suffice.

Token consumption, invocation counts, latency, and estimated cost are recorded per invocation and exposed as metrics.

## 10. Evaluation

Each capability has a set of reference cases with expected properties. Changes to prompts, models, or retrieval configuration are evaluated against these before activation. A change that degrades measured quality does not ship.

This is required because model-driven behaviour has no compiler and no type system. Evaluation is the mechanism that makes change safe.

**Not yet established:** the specific reference case sets and the quality thresholds for each capability. These are defined when the corresponding capabilities are implemented and cannot be specified in advance without fabricating them.

## 11. Observability

Each invocation records: correlation identifier, principal, capability, model and provider, prompt version, token counts, latency, tool invocations, retrieval identifiers, guardrail events, and outcome. Emitted as trace spans and metrics into the platform's own observability stack.

Prompt and completion text are not stored by default. Digests and metadata are stored. Full-text capture is opt-in per capability, retention-bounded, and access-controlled, because completions may contain learner-authored content.

## 12. Failure behaviour

AI is an enhancement and never a dependency of a core path. With all inference unavailable: catalogue browsing, enrolment, commerce, content delivery, assessment, human grading, and credential issuance all continue unaffected. AI capabilities report unavailability. Mock interviews offer their human-conducted mode.

No commerce, learning, or credential operation blocks on model availability. This is a hard constraint on the design of those paths, not a property of the AI layer.

## 13. Security controls

Untrusted content, including course material, learner submissions, uploaded documents, and MCP tool results, is delimited as data and never placed in instruction positions within a prompt.

Retrieval is entitlement-scoped within the query.

Tool authorization is per invocation against the principal.

Output is validated for schema conformance and scanned for sensitive data before return.

Prompt injection defence is layered: input heuristics, content delimiting, tool authorization independent of model output, and human approval for consequential actions. No single control is treated as sufficient, because prompt injection has no complete solution and defence in depth is the available approach.
