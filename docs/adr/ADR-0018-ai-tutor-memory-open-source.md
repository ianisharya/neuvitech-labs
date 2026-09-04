# ADR-0018 - AI Tutor: Agentic, Open-Source Models, Persistent Memory, No Third-Party Tracing

**Status:** Accepted · **Date:** 3 Sep 2026

## Context

The AI tutor is now a central, learner-facing feature: it answers questions grounded in course content, helps with problem-solving exercises, conducts mock interviews, reviews resumes, and suggests learning paths. To be genuinely useful it needs to remember the learner across sessions. To be affordable and private it needs the right model and tooling choices. And it must not undermine the privacy commitment already made in ADR-0014, which chose self-hosted observability specifically to keep learner data out of third-party services.

## Decision

Build the tutor as an agentic system on open-source models, orchestrated with LangChain and LangGraph where multi-step reasoning genuinely benefits, with all tracing and observability going to the platform's own self-hosted systems and not to LangSmith or any hosted third-party service. Give the tutor persistent memory of the learner, stored in the platform's own database, layered into short-term conversation, activity-derived context, and summarised interaction history, with the learner able to view and clear it.

## Alternatives Considered

**Use LangSmith for tracing, as the founder initially named.** Rejected after raising the conflict directly. LangSmith is a paid hosted service that receives AI interaction data, including whatever learners type to the tutor. Using it would contradict ADR-0014's deliberate choice of self-hosted observability on privacy grounds. Open-source tracing into the platform's own stack gives the same operational insight without sending learner data to a third party, so the privacy commitment is kept intact at no real cost.

**A memoryless tutor that treats every session as a first meeting.** Rejected as simply a worse tutor. Without memory it re-explains what the learner already knows, cannot notice recurring weak spots, and cannot tailor help to the individual. Memory is much of what makes a tutor feel like a tutor rather than a search box.

**Storing tutor memory in a third-party memory or vector service.** Rejected for the same reason as LangSmith. Learner memory is sensitive learner data, and it belongs in the platform's own database under the platform's own protection, not in an outside service.

**Proprietary hosted models as the default.** Rejected as the default in favour of open-source models, which keep cost bounded and keep data within the platform's control. The provider adapter behind the gateway means a proprietary model could be used for a specific task if it ever proved clearly better and the privacy tradeoff were explicitly accepted, but that is a deliberate exception, not the default.

**No memory rights for the learner.** Rejected. Because memory is the learner's data, the learner must be able to see it and clear it, consistent with the platform's data-minimisation and privacy stance in doc 08.

## Consequences

**Positive.** The tutor is genuinely helpful, remembering the learner and tailoring its help. Learner data stays within the platform, honouring the privacy commitment. Cost stays bounded through open-source models and budgets. The learner has real rights over what the tutor remembers.

**Negative.** Self-hosting the model serving and tracing is real operational work, more than calling a hosted API would be. Memory of learner data is sensitive and must be handled with care, kept free of the most sensitive personal information, and protected like any personal data. Open-source models may need more effort to reach the quality a top proprietary model gives out of the box, which is why evaluation against known-good examples matters.

## Trade-offs

More operational work running open models and self-hosted tracing, in exchange for keeping learner data private and cost bounded. Given the platform already committed to self-hosted observability for exactly this reason, this is consistent rather than a new burden, and it keeps a promise rather than quietly breaking it.

## Cost

Bounded by design. Open-source models avoid per-call proprietary pricing. The gateway enforces budgets per learner, per capability, and per day. Small cheap models handle simple tasks while capable models are reserved for real tutoring. Cost is tracked as a first-class metric.

## Security

Everything runs through the single AI gateway, where authentication, permission checks, budget checks, guardrails, scoped retrieval, output validation, tool authorisation, and audit all apply. The agent acts only with the learner's own authority and is never given dangerous capabilities. Memory is scoped to the individual learner and never exposes one learner's data to another. Sensitive personal information is kept out of memory by the same allow-list discipline used for logs.

## Scalability

AI runs outside the core request path and is bounded by budgets and rate limits, so it cannot overwhelm the platform, and if it is unavailable the core learning path continues unaffected. Model serving scales independently of the application.

## Migration Path

Because all AI use goes through one gateway with a provider adapter, changing the underlying model, or making a deliberate exception for a proprietary one, is a change behind the gateway and not a change to every feature that uses AI. Memory stored in the platform's own database is portable in a way a third-party service's memory would not be.

## Revisit Trigger

If open-source model quality proves insufficient for a specific high-value task and the privacy tradeoff of a proprietary model is explicitly weighed and accepted, revisit the model choice for that task alone. If the operational cost of self-hosting outweighs its privacy benefit in practice, revisit, but only by explicitly re-opening ADR-0014's privacy decision rather than quietly working around it.
