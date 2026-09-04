# ADR-0017 - Video Delivery: Adaptive Bitrate over CDN, Near-Live Broadcast for Live

**Status:** Accepted · **Date:** 3 Sep 2026

## Context

The platform delivers three kinds of video as first-class content: live sessions, recordings of those live sessions, and pre-recorded lectures. It must serve these to a baseline of five thousand concurrent learners and beyond, keep playback fast, and keep cost proportional. Video is the heaviest thing the platform does in bandwidth, storage, and cost, so how it is delivered is a decision with large consequences.

## Decision

Deliver all recorded and pre-recorded video as adaptive bitrate streams over a content delivery network, using the widely supported HLS standard. Deliver live sessions as near-live broadcast, delayed by several seconds and carried over the same adaptive bitrate and content delivery network path as recorded video, with learner interaction through live chat rather than real-time voice. Protect all video with short-lived signed URLs issued only after an entitlement check.

## Alternatives Considered

**Serving video directly from the application's own servers.** Rejected outright. It would overwhelm the servers at a fraction of the target scale, cost many times more, and be slow for learners far from the server. Video bandwidth must be offloaded to a content delivery network for the platform to work at all at this scale.

**A single video quality per lecture instead of adaptive bitrate.** Rejected. A single quality forces a bad choice between learners on strong and weak connections, and produces buffering for anyone whose connection does not match the chosen quality. Adaptive bitrate lets each learner's player find the right quality moment to moment, which is the single biggest factor in video feeling fast.

**True low-latency interactive live streaming, under two seconds, with real-time learner voice.** Seriously considered and rejected as the default. It is genuinely hard and expensive, needs specialised infrastructure, and does not scale cheaply to thousands. It is the right choice only when real-time back-and-forth voice is the core of the product, and a large live class is not that. Thousands of learners cannot all speak at once regardless, so interaction through chat is what a large live class actually is.

**Near-live broadcast with chat interaction.** Chosen. It scales to many thousands on the same affordable infrastructure as recorded video, because to the delivery network a live broadcast is just video created a few seconds ahead of when it is watched. The delay of several seconds is invisible to the learning experience, and chat is how large live classes genuinely interact.

**Embedding a third-party video platform such as YouTube or a webinar tool.** Rejected. It would put paid content on infrastructure the platform does not control, break the unified player experience, prevent proper entitlement control, and forgo the structured storage and progress integration that make video a first-class part of the learning system rather than a link out.

## Consequences

**Positive.** Video is fast, adapts to every learner's connection, and scales to thousands affordably because the content delivery network carries the bytes and the application only checks permission. Live, recorded, and pre-recorded video all flow through one pipeline and one player, so the experience is coherent and the code is not duplicated. Paid video is protected by signed URLs tied to entitlement.

**Negative.** A processing pipeline stands between upload and playback, so video is not watchable the instant it is uploaded, and that pipeline is real machinery to build and operate. Video remains the dominant variable cost, driven by how much is watched, which must be watched closely. Near-live broadcast means live interaction is through chat and not voice, which is the right trade for a large class but is a real constraint to be clear about with instructors.

## Trade-offs

A processing pipeline and a several-second live delay, in exchange for fast video that scales to thousands at a cost proportional to how much is watched. The alternative of real-time interactive streaming would buy voice interaction the product does not need at the cost of an expensive, hard-to-operate system, which is the wrong trade for a large class taught by one instructor.

## Cost

Video bandwidth from the content delivery network is the dominant variable cost, scaling with how much learners watch. This is mitigated by high cache hit ratios, by adaptive bitrate serving smaller files to weak connections, and by cold storage for archival source. It is measured from day one as a first-class metric, so it is seen early rather than discovered on an invoice.

## Security

No permanent public video links exist. Every play is authorised by an entitlement check, after which a short-lived signed URL tied to the session is issued. The content delivery network refuses expired or forged requests. Storage is private by default, reachable only through signed URLs. Paid content cannot be copied and shared, because the link expires in minutes and was session-bound to begin with.

## Scalability

This is the decision that makes scale affordable. Because the content delivery network serves video from edge caches, the application handles only lightweight permission checks regardless of how many learners are watching, and video scales with the network's global capacity rather than with the platform's own servers.

## Migration Path

Because the player, the pipeline, and the storage layout are the platform's own, and the content delivery network sits behind a boundary, the delivery network itself could be changed for another without touching how learning content references video. The standard HLS format keeps playback portable across providers.

## Revisit Trigger

If real-time interactive teaching, with learner voice and sub-two-second latency, becomes a core product need rather than a large-class broadcast, revisit the live streaming approach for that specific use, while keeping near-live broadcast for large classes. If video cost per learner rises out of proportion despite cache tuning, revisit encoding and delivery settings against the measured numbers.
