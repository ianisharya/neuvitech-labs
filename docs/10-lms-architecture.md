# 10 - Learning and LMS Architecture

The learning system is what a learner actually spends their hours inside, so it has to be both correct and pleasant. It consumes the catalogue defined in doc 06 rather than redefining it, delivers content of several kinds through one consistent experience, tracks progress honestly, and hands off to certificates, portfolio, and karma. This document was revised to make live sessions, recorded lectures, and pre-recorded courses all first-class citizens delivered through one player, and to add the problem-solving and interview-preparation surfaces.

## 1. The shape of learning content

A learner enrols in something from the catalogue, and that thing has a structure: a program holds specializations, a specialization holds courses, a course holds modules, a module holds lessons. A lesson is the atom of learning, the thing a learner sits down to do, and a lesson is one of several kinds.

A lesson might be a video, live or recorded or pre-recorded, all delivered the same way. It might be a reading, a text with images and code. It might be a problem-solving exercise. It might be a quiz or an assessment. It might be a project brief. It might be a downloadable resource. The learner moves through lessons in an order the course defines, and each lesson knows what it takes to be considered complete, whether that is watching a video to genuine completion, passing a quiz at a set mark, or having a project submission accepted.

Because enrolments pin to a specific published version of the catalogue item, as described in doc 06, the curriculum a learner sees never shifts under them after they enrol. What they signed up for is what they get, even if the course is later revised for new learners.

## 2. One player for live, recorded, and pre-recorded

The most important experience decision in the LMS is that all video is watched through one player, whether it is a live broadcast happening now, a recording of a live session that ended last week, or a pre-recorded lecture produced in advance. The learner does not context-switch between a live tool and a video tool. They open a lesson and it plays.

A live lesson shows the near-live broadcast described in doc 41, with a live chat beside it for questions and interaction. When the live session ends, its recording is processed and takes the same slot in the same course structure, so a learner who missed it opens the identical lesson and watches the recording in the identical player, losing only the live chat. A pre-recorded lecture is simply a video lesson that was never live. To the learner, and to the progress and completion machinery, these are the same thing: video in a lesson, watched in a player, generating progress as it plays.

This uniformity is deliberate and it is what keeps the experience coherent. It also means the whole platform's video handling, entitlement checks, signed URLs, adaptive streaming, progress tracking, lives in one place and serves every kind of video, rather than being reimplemented for live and recorded separately.

## 3. Progress, tracked honestly

As a learner works, the platform records progress. For video, it records how much has genuinely been watched, not merely that the player was opened, so that scrubbing to the end does not count as watching and completion means what it says. Progress events are gathered as the learner watches and saved in the background without interrupting them, and they are batched sensibly rather than saved every single second, because a lecture watched by thousands of learners would otherwise generate an unreasonable flood of writes for data nobody needs at that resolution.

The learner's current position is remembered, so they resume exactly where they left off, on any device. Completion of a lesson is computed from the lesson's own rule, and completion of a course, specialization, or program is computed up the hierarchy from its parts. This honest progress is what feeds certificates, which must reflect real completion, and karma, which must reward real learning and not time with a tab left open.

## 4. Assessments and projects

Learning has to be provable, or a certificate from it means nothing. Assessments come in several forms: quizzes with automatically graded questions, longer exams, and project submissions that a human or a rubric evaluates.

Grading of anything that decides a credential happens on the server. Correct answers are never sent to the learner's browser before they submit, because a naive design that ships the answer key to the client is trivial to cheat and impossible to walk back once learners notice. Quizzes are graded against server-held answers. Projects follow a cycle of submission, evaluation against a rubric, feedback, and where needed resubmission, until the work meets the bar or the attempts run out.

This is the machinery that makes both free and paid certifications credible. A free certification is generous with access and strict with assessment precisely because the assessment is real and server-graded.

## 5. The problem-solving platform

Beyond passive lessons, the platform offers a problem-solving surface: a library of exercises, each with a problem statement, and each with a worked solution that unlocks appropriately. This is not an in-browser code execution environment. Learners work problems in their own tools and check their understanding against the provided solutions and against the AI tutor. The decision to not run learner-submitted code on the platform's own infrastructure is deliberate and is a security decision, because running arbitrary submitted code safely is a major and dangerous undertaking, and the learning value of exercises with solutions and a tutor to explain them is available without it.

Each exercise can carry a worked solution in text, a recorded video of an instructor explaining the solution, or both, so a learner who is stuck can read the reasoning, watch it explained, and ask the AI tutor follow-up questions in a chat beside the problem. The AI tutor's role here is described in doc 12, and it is bounded: it helps the learner understand, it works against the learner's own context, and it operates through the same guardrailed gateway as every other use of AI on the platform.

## 6. Mock interviews and resume review

Career readiness is part of the product, not an afterthought, so the platform includes interview preparation and resume review as real features.

Mock interviews run in two modes. In the AI mode, the learner sits a simulated interview conducted by the agentic AI tutor, behavioural or technical or system-design or domain-specific, and receives structured feedback afterward on clarity, correctness, and communication. In the human mode, a mentor conducts the interview and evaluates it through the same rubric and feedback machinery that grades projects, so a mentor-reviewed mock interview is assessed exactly like any other reviewed work rather than through a separate parallel system. When the AI provider is unavailable, AI mode degrades gracefully to offering human mode or a clear unavailable state, because nothing in the core learning path is ever allowed to hang waiting on an AI model.

Resume review works the same way: the learner submits a resume, and receives structured feedback either from the AI tutor working through the guardrailed gateway or from a human mentor through the evaluation machinery. A strong mock interview or a polished resume can, at the learner's choice, be surfaced in their portfolio, which is the same opt-in publishing action as showcasing a project.

## 7. Live cohorts

Some learning is organised into cohorts, groups of learners moving through a program together on a schedule, with live sessions at set times. A cohort has a capacity, and enrolment into a full cohort is prevented by a lock so that a limited cohort is filled exactly to its limit and no further, with overflow going to a waitlist rather than silently overbooking. Live sessions belong to the cohort, are broadcast near-live and recorded as described in doc 41, and attendance is recorded from the session so that a learner's participation is known. Recordings drop into the course structure for anyone who missed the live moment.

Cohorts are what make a subscription feel like a course rather than a library, and they are a large part of why consistent engagement matters, which connects directly to the karma and streak system in doc 40.

## 8. Notifications and the rhythm of learning

Learning falls apart without rhythm, so the platform reaches out at the right moments: a reminder before a live session, a nudge when a deadline approaches, a note when feedback on a project is ready, a congratulation when a certificate is earned, a gentle prompt when a learner's streak is about to break. These messages are driven by templates held in the database, described in doc 05, so their wording and timing can be tuned without a code change, and every one of them respects the learner's preferences and the right to turn them off. The streak reminder in particular is designed to protect consistency, which the whole platform is built to reward, without becoming the kind of nagging that makes a learner mute everything.

## 9. What the learner sees

The learner's home is a dashboard that shows what matters now: what to do next, the next live session, approaching deadlines, current progress, current streak and karma, and a sensible recommendation for what to learn next. From there they enter the player for lessons, the problem-solving surface for exercises, the assessment views for quizzes and projects, their portfolio for showcasing work and credentials, their account for managing subscription and purchases, and the goodies store for spending karma. The whole thing is one coherent place, and the coherence is the point. A learner should never feel like they are switching between separate products bolted together.
