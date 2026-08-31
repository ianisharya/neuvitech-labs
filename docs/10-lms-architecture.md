# 10 — LMS & Learning Architecture

The LMS **consumes** the first-class catalog rather than redefining Programs, Tracks, Specializations, Masterclasses, Free Certification Courses, Certificates and Brochures.

## 1. Delivery model

```
Enrolment (pinned to catalog_item_version)
   └─ LearningComponent tree  (MODULE → LESSON)
        ├─ content_type: VIDEO | TEXT | CODE_LAB | QUIZ | ASSIGNMENT | PROJECT | LIVE_SESSION | RESOURCE
        ├─ estimated_minutes · ordinal · is_required
        └─ completion_rule JSONB   (watched %, quiz passed, submission accepted)
```

`learning_component` is a self-referencing tree attached to a `catalog_item`. Because enrolments pin to a **version**, a learner's curriculum cannot change under them after purchase.

## 2. Progress

```
progress_event(user_id, enrolment_id, component_id, event_type, position_seconds,
               payload JSONB, occurred_at)     -- monthly partitions, append-only
lesson_progress(user_id, component_id, state, percent, last_position_seconds,
                completed_at)                   -- current state, derived
```

Events are **batched client-side and flushed every 15 seconds or on unload**, then written asynchronously. Writing a row per second per learner would generate ~250 writes/s at target scale for data nobody queries at that resolution.

Completion is computed from `completion_rule` in the enrolled version — so the rules a learner was sold are the rules applied.

## 3. Video pipeline

```
Upload (admin) → private object storage → worker: transcode to HLS ladder
  → thumbnails + captions → store manifest → mark READY
Playback: authorize (entitlement) → issue short-lived signed URL → CDN → player
  → progress events → resume position
```

**Never streamed through the application server.** Signed URLs are short-lived and session-bound. Direct object URLs are never exposed. Video egress is the dominant variable cost of this product, so CDN cache-hit ratio is a tracked metric from Sprint 9.

## 4. Assessments

```
assessment(catalog_item_id, type: QUIZ|EXAM|ASSIGNMENT|PROJECT, weight, pass_mark,
           max_attempts, time_limit_minutes, shuffle, show_answers_after)
question(assessment_id, type: MCQ|MULTI|SHORT|CODE, prompt, points, ordinal)
attempt(user_id, assessment_id, state, started_at, submitted_at, score, passed)
submission(user_id, assessment_id, artefact_type, media_id?, repo_url?, notes)
evaluation(submission_id, evaluator_id, rubric_id, scores JSONB, feedback, state)
```

**Grading is server-side.** Correct answers are never sent to the client before submission — a mistake that is trivial to make with a naive API and impossible to walk back once learners notice.

Projects follow `Assignment → Submission → Evaluation → Feedback → Resubmission → Completion → Portfolio`. Submissions are private by default; publishing to a portfolio is an explicit learner action.

## 5. Live learning

```
Program/Masterclass → Cohort → LiveSession → MeetingProvider → Attendance → Recording → LMS
```

Behind a `MeetingProvider` protocol; **Zoom is the chosen implementation**. Per-user join links, credentials in encrypted settings — **never a shared hardcoded URL in a component**. Attendance recorded from provider webhooks and reconciled by a scheduled job. Recordings ingested asynchronously into private storage and served via signed URLs.

Capacity is enforced with a row lock; over-capacity registrations go to a waitlist.

## 6. Free Certification Courses

Same code path as paid, with the payment step skipped by server-side policy (doc 09 §2). Assessment thresholds are real; completion requires genuine progress plus a passing score defined in `certificate_policy`.

**A free certificate that anyone can click through is worth less than no certificate**, because it teaches the market that our credentials are meaningless.

## 7. Notifications

`notification_template` rows (doc 05) drive every message. Events: enrolment, payment, upcoming class, assignment deadline, evaluation complete, completion, certificate issued, subscription renewal, payment failure, career application, brochure download, contact confirmation.

Channel-agnostic by design (email now, in-app and WhatsApp later) with per-user preferences and unsubscribe honoured.

## 8. Learner surfaces

| Surface | Purpose |
|---|---|
| Dashboard | Active enrolments, next session, deadlines, progress, recommended next step |
| Learning player | Curriculum navigation, video, notes, resources, progress |
| Assessment | Quizzes, exams, submissions, feedback |
| Portfolio | Public profile with projects and verified credentials |
| Credentials | Issued certificates with verification links |
| Orders | Purchase history, invoices, subscription management |
