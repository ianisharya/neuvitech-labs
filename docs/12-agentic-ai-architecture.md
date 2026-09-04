# 12 - Agentic AI and the AI Tutor

The platform uses AI where it genuinely helps a learner and nowhere it does not. This document was revised to define the AI tutor as a real, memory-carrying, agentic feature built on open-source models and open tooling, to add the tutor's role in the problem-solving and interview surfaces, and to be explicit about memory. The privacy stance from ADR-0014 is preserved throughout: AI tooling that would send learner data to a third party is not used. Everything here runs against open-source models with tracing into the platform's own systems.

## 1. Deterministic first, AI where it earns its place

The starting principle has not changed. Something does not become an agent merely because a model can be dropped into it. A course recommendation is a database query and a ranking, explainable and instant and free, not a model call. Search is search. A calculation must be correct, so it is computed and only its explanation is phrased by a model. AI is reached for when the task genuinely benefits from understanding language or from multi-step reasoning, and avoided when a deterministic method is more correct, cheaper, and more explainable.

Where AI earns its place is in helping a learner understand something they are stuck on, in conducting a practice interview, in reviewing a resume, in answering questions grounded in course content, and in generating a personalised learning path. These are the tutor's jobs.

## 2. The AI tutor, what it is

The AI tutor is a learner-facing agent that helps a learner learn. It answers questions about course material, grounded in the actual content rather than made up. It helps with problem-solving exercises, explaining reasoning and giving hints without simply handing over answers. It conducts mock interviews and gives structured feedback. It reviews resumes. It suggests what to learn next based on where the learner is. It is available as a chat interface beside the learning content, and it is agentic where the task needs multiple steps, such as conducting an interview or assembling a learning path, and a simpler single response where that is all the task needs.

It is built on open-source models, using LangChain and LangGraph for orchestrating multi-step reasoning where that genuinely beats a hand-written state machine, a decision made on evidence rather than by default. Tracing and observability of the AI use the platform's own self-hosted systems, described in doc 14. LangSmith, the paid hosted tracing service, is deliberately not used, because it would send learner interactions to a third party and that contradicts the privacy stance the platform committed to in ADR-0014. Open-source tracing into the platform's own stack gives the same insight without the same exposure.

## 3. Memory, so the tutor actually knows the learner

A tutor that forgets everything between sessions is a worse tutor. The AI tutor carries memory, and this section is explicit about what that means, because memory of learner data is exactly the kind of thing that must be handled carefully rather than casually.

The tutor remembers, across sessions, what a learner has studied, where they have struggled, what they have asked before, their current progress and goals, and the thread of an ongoing conversation. This lets it pick up where it left off, avoid re-explaining what the learner already understands, notice recurring weak spots, and tailor its help to the individual rather than treating every session as a first meeting.

This memory lives in the platform's own database, never in a third-party service, which keeps it consistent with the privacy stance and keeps the learner's data under the platform's own control and protection. Memory is structured in layers. There is short-term memory, the current conversation, which gives immediate continuity. There is longer-term memory derived from the learner's actual activity, their progress, completions, and assessment results, which the tutor reads rather than having to be told. And there is a summarised memory of past tutoring interactions, distilled so that the tutor has a useful sense of the learner's history without carrying every word ever exchanged.

Memory is the learner's, and the learner has rights over it. They can see what the tutor remembers, and they can have it cleared. Memory is never used to expose one learner's information to another, and it is subject to the same data-minimisation and privacy rules as everything else on the platform, described in doc 08. Sensitive personal information is kept out of the tutor's memory by the same allow-list discipline that keeps it out of logs.

## 4. The AI gateway, the single controlled doorway

Every use of AI on the platform passes through one gateway, and nothing calls a model directly around it. This is the chokepoint where all the controls live, and centralising them is the only way to enforce them reliably.

Through the gateway, in order: the learner is authenticated, their permission for the requested action is checked, their usage against budget and rate limits is checked, the input is screened by guardrails and stripped of sensitive information before it reaches a model, relevant content is retrieved with the learner's own access scope applied so the tutor can never surface content the learner is not entitled to see, the prompt is assembled from a reviewed and versioned template, the model is called through an adapter with a timeout and a retry and a circuit breaker, the output is validated against an expected shape, any tool the agent wants to use is checked against the learner's own permissions before it runs, high-risk actions wait for a human to approve them, the response is checked for anything it should not contain, and the whole interaction is recorded for audit and for cost tracking. Only then does the learner get their answer.

The reason for this single doorway is that budgets, guardrails, prompt control, memory access, and audit are each impossible to enforce reliably if any caller can bypass them. One doorway, every control applied every time.

## 5. Guardrails, so the tutor stays helpful and safe

Input is screened before it reaches a model. Its length is bounded. Sensitive personal information is detected and removed. Attempts to manipulate the model into ignoring its instructions, the class of trick known as prompt injection, are watched for. Content that comes from untrusted places, such as course material or a learner's own uploaded file, is always clearly marked as data to be reasoned about and never treated as instructions to follow, which is the core defence against a document that tries to hijack the tutor.

Retrieval is scoped to the learner's own access. When the tutor pulls in relevant content to ground its answer, it can only pull content the learner is entitled to, because the access filter is applied inside the retrieval query itself and not bolted on afterward. A learner without access to a paid course cannot have the tutor read it to them, because the retrieval simply never returns it.

Output is checked before it reaches the learner. It is validated to be the expected shape, so downstream code can rely on it. For answers meant to be grounded in course content, the grounding is checked so the tutor is not fabricating. And the output is scanned to ensure it does not leak sensitive information. Every prompt the tutor uses is a reviewed, versioned template held like code, so prompts can be improved and rolled back and are never scattered untracked through the codebase.

## 6. Tools and authority, the most important safety rule

When the agent uses a tool, to look something up, to record something, to take an action, that tool runs with the learner's own authority and never with authority the learner does not have. The agent has no ambient power of its own. It carries the learner's permissions, reduced to the specific small set of tools a given task allows, and every tool call is checked against those permissions before it runs.

There are things the agent is never given: direct access to the database, the ability to run arbitrary code, access to production infrastructure, the power to move money or grant access or change prices, the power to change anyone's roles or permissions, or access to secrets. Anything genuinely consequential follows a pattern where the agent proposes, a human approves, and the system carries it out under the human's authority. The agent never holds the dangerous capability itself, even after approval.

This is what makes an agentic tutor safe to give to learners. It can help, explain, conduct an interview, and suggest a path, all within the learner's own permissions, and it structurally cannot do the things that would be dangerous, because it was never given the authority to.

## 7. Grounded answers, retrieval done well

When the tutor answers a question about course content, it does not answer from the model's general knowledge alone, which would be prone to confident invention. It retrieves the relevant material from the course and grounds its answer in that, and it can cite what it drew on so the learner can verify. Retrieval combines keyword matching with meaning-based matching, because a learner's question rarely uses the exact words of the material, and because pure meaning-based matching alone stumbles on exact technical terms that must match precisely. The two together find the right material more reliably than either alone.

## 8. Cost and failure, kept in bounds

AI has a real per-use cost, so the gateway enforces budgets, per learner and per capability and per day, and cheaper small models are used for simple tasks like classification while the more capable models are reserved for genuine tutoring. Usage, tokens, and cost are tracked as first-class measurements, so a cost problem is seen early.

And crucially, AI is always an enhancement and never a dependency of the core learning path. If every AI provider were down, learners could still browse, enrol, watch lectures, take assessments, submit projects, be graded by humans, and earn certificates. The mock interview would offer its human mode. The tutor would show as temporarily unavailable. Nothing essential would hang waiting on a model, because nothing essential is allowed to depend on one. This is a firm rule, and it is what lets the platform offer AI generously without making itself fragile.

## 9. Evaluation, so quality does not drift

The tutor's quality is measured against sets of known-good examples, and changes to prompts or models are tested against those examples before they ship, the same way code is tested. A prompt change that makes the tutor worse is caught before a learner ever sees it. This keeps a system that is inherently a little unpredictable as reliable as it can be made, and it means improvements are real improvements and not just changes.
