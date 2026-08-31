# 12 — Agentic AI Architecture

## 1. Position: deterministic first

*Do not make something an agent simply because an LLM can be inserted into it.*

| Capability | Implementation | Why |
|---|---|---|
| Course recommendation | **Deterministic** — skill-gap SQL + ranking | Explainable, testable, free, instant |
| Skill-gap analysis | **Deterministic** + LLM for prose only | The computation must be correct; only the phrasing needs a model |
| Search | **Postgres FTS**, hybrid with pgvector later | Keyword search is not an LLM problem |
| Q&A over course content | **RAG**, single-shot | Genuine value, no autonomy needed |
| Resume/portfolio feedback | **LLM, structured output** | Bounded, human reads the output |
| Code review of submissions | **LLM assist + human decision** | Never auto-grades a certificate-bearing assessment |
| Learning-path generation | **Agentic (Sprint 19)** | Multi-step, stateful, genuinely benefits from planning |
| Interview preparation | **Agentic** | Stateful multi-turn dialogue with retrieval |

**LangChain/LangGraph are evaluated, not pre-adopted.** Sprint 18 uses plain provider SDK calls behind our own gateway with Pydantic-enforced structured outputs. LangGraph is adopted in Sprint 19 only if a spike shows it beats a hand-rolled state machine. **LangSmith is not adopted by default** — it is paid SaaS that would receive learner data; self-hosted OTel is the default.

## 2. The AI gateway — single chokepoint

Every model call goes through `modules/ai/gateway.py`. No module calls a provider SDK directly; `import-linter` enforces it.

```
User request
 → authN → authZ → rate & budget check (per user, per capability, per day)
 → input guardrails (PII scrub, injection heuristics, token caps)
 → retrieval (ACL-filtered IN THE QUERY)
 → prompt assembly (versioned template from ai_prompt_version)
 → model invocation (adapter, timeout, retry, circuit breaker)
 → output validation (Pydantic schema, safety checks)
 → tool permission layer (allow-list + per-call authorization)
 → tool execution (least privilege, audited)
 → human approval gate (high-risk actions)
 → response validation (citation grounding, PII leak scan)
 → audit + telemetry → user
```

**Why a chokepoint:** budgets, guardrails, prompt versioning, audit and observability are each impossible to enforce reliably if callers can bypass them.

## 3. Guardrails

**Input** — length and token caps; PII detection and redaction before the prompt is built; injection heuristics. **Untrusted content — course text, learner submissions, uploaded files — is always wrapped in explicit delimiters and labelled as data, never concatenated as instructions.**

**Retrieval** — the user's access scope is a **query predicate, not a post-filter.** A learner without an entitlement cannot retrieve chunks from that content because the vector search never returns them. Post-filtering is a data leak waiting to happen: the model would already have seen the text.

**Prompts** — every system prompt lives in `ai_prompt_version` (capability, version, template, model constraints, active). Reviewed like code, rollback-able. **No prompt string is inlined in a service.**

**Output** — structured outputs enforced by Pydantic; invalid output triggers one bounded repair attempt then a deterministic fallback, never a silent malformed response. Grounding check for RAG. PII leak scan outbound. Refusals recorded, not swallowed.

## 4. Tool authorization — the most important control

**A tool call is authorized against the *invoking user's* permissions, never the agent's.** The agent has no ambient authority; it carries the user's scope reduced by a per-capability allow-list.

```
agent_identity(id, name, allowed_tools, max_tokens_per_run,
               max_tool_calls_per_run, requires_human_approval)
ai_tool_invocation(session_id, agent_id, user_id, tool_name, arguments_digest,
               authorized_by_permission, result_state, latency_ms)
ai_action_approval(session_id, proposed_action, risk_level, state, approver_id, decided_at)
```

**An agent never gets:** raw database access (no SQL tool, ever — tools call typed service functions) · shell or filesystem · production infrastructure or deploy credentials · payment execution, refunds, coupon creation or price mutation · role/permission mutation or impersonation · secrets, GitHub production credentials or Jira administration.

High-risk actions follow **Recommend → Human Approve → Execute**, where **the system executes under the human's authority**. The agent never holds the credential, even after approval.

Loop safety: max tool calls per run, max wall clock, max tokens, cycle detection, per-tool timeouts, circuit breaker per provider.

## 5. RAG design
Chunking by semantic boundary with overlap; embeddings in `pgvector` alongside their ACL scope; **hybrid retrieval** (Postgres FTS + vector cosine, reciprocal-rank fusion) because pure vector search underperforms on exact technical terms — "Kubernetes CRD" must match lexically. Citations returned with every answer and rendered as links so learners can verify.

## 6. Observability
`ai_invocation` records request id, user, agent, capability, model, prompt version, token counts, estimated cost, latency, tool calls, retrieval doc ids, guardrail events, refusals, eval scores, error class. Emitted as OTel spans following GenAI semantic conventions.

**Prompt and completion text are not stored by default** — only digests and metadata — because private student data must not be exposed through observability. Full-text capture is opt-in, per-capability, retention-bounded and access-controlled.

Evaluation: golden datasets per capability, regression evals in CI on prompt changes. **Prompt changes are code changes and cannot ship without passing evals.**

## 7. Test matrix
Prompt injection (direct, indirect via course content, indirect via uploaded file) · unauthorized tool call · tool permission violation · cross-user leakage via retrieval · PII in output · malicious/oversized input · grounding on hallucination-sensitive workflows · invalid structured output → repair → fallback · rate limit · token budget · human-approval bypass attempt · agent infinite loop · tool timeout · provider outage → graceful degradation.

## 8. Failure posture
**AI is always an enhancement, never a dependency of a core learning or commerce path.** With every provider down, learners still browse, buy, learn, submit, are graded by humans, and receive certificates. **Nothing in the critical path waits on a model.**
