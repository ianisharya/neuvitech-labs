# 41 - Video, Streaming and Media Architecture

Video is the heaviest thing the platform does, in bandwidth, in storage, in cost, and in the impact of getting it wrong. A course that buffers is a course learners abandon. This document defines how live sessions, recorded lectures, and pre-recorded courses are delivered, stored, and kept fast, and it is honest about what fast actually means, because there is no such thing as zero latency and pretending otherwise would be the opposite of the discipline this whole plan is built on.

## 1. What we mean by fast, stated as budgets rather than a promise

Light takes time to cross a country. Networks have distance and congestion. Nobody can deliver zero latency, and any document that claims to is lying. What can be engineered, measured, and held to are specific budgets, and these are the ones the platform commits to.

For the website and application, the target is that a catalogue or learning page becomes useful in under one second for a learner on a normal connection, and that the interface never visibly stalls while loading. This is achieved by serving pages from edge locations close to the learner, by sending almost no JavaScript on content pages, and by reserving the exact space content will occupy so nothing jumps as it arrives.

For recorded and pre-recorded video, the target is that playback begins in under one second from the moment the learner presses play, that quality adapts smoothly to the learner's connection without them touching anything, and that rebuffering, the dreaded spinner mid-lecture, essentially never happens on a reasonable connection. This is achieved by adaptive bitrate streaming delivered from a content delivery network, described below.

For live sessions, the target is a near-live broadcast with a delay of roughly five to twenty seconds between the instructor speaking and the learner hearing it, with interaction happening through chat rather than through real-time voice. This is a deliberate choice, explained in section 4, and it is what makes live sessions to thousands of concurrent learners affordable rather than ruinous.

## 2. Adaptive bitrate, the core idea

A single video file at a single quality is the wrong way to serve video to a diverse audience. A learner on fibre and a learner on a train on mobile data need different things from the same lecture, and neither should have to choose manually.

Every piece of video on the platform is processed into multiple quality levels, from low resolution for weak connections up to high resolution for strong ones, and each level is chopped into small segments of a few seconds each. The player, running in the learner's browser, requests segments one at a time and continuously measures how quickly they arrive. When the connection is strong, it reaches for higher quality. When the connection weakens, it quietly steps down to a lower quality rather than stopping to buffer. The learner sees a lecture that stays playing and adjusts its sharpness, rather than a lecture that freezes. This is the same technology every large streaming service uses, and it is the single most important decision for making video feel fast.

The platform uses HLS, the widely supported standard for this, so that playback works across browsers and devices without special plugins.

## 3. The content delivery network, why video never comes straight from us

If every learner pulled video directly from the platform's own servers, those servers would be overwhelmed, the cost would be enormous, and a learner far from the server would wait. Instead, video is served from a content delivery network, which is a global fleet of edge servers that cache content close to learners.

The first time a learner in a city requests a segment, it is fetched from origin storage and cached at the edge server nearest them. Every subsequent learner in that region gets it from that nearby edge, fast and without touching the platform's origin. For popular content, which is most content, the origin serves each segment rarely and the edge serves it thousands of times. This is what makes serving video to thousands of concurrent learners both fast and affordable, and it is why the cost of video scales with how much is watched rather than with how many servers we run.

Access to video is protected even though it is served from a public network. The player never receives a permanent public link to a video file. Instead, when a learner with a valid entitlement presses play, the platform issues a short-lived signed URL, valid for minutes, tied to that session. The content delivery network honours the signature and refuses expired or forged requests. A learner cannot copy a link and share paid content, because the link stops working almost immediately and was tied to their session in the first place. Entitlement is checked before the signed URL is issued, so the three-tier access model in doc 09 governs video exactly as it governs everything else.

## 4. Live sessions, and the honest choice behind them

There are two ways to stream live to a large audience, and they are very different in difficulty and cost.

One way is true low-latency interactive streaming, where the delay is under two seconds and learners can speak back and it feels like a video call. This is genuinely hard and genuinely expensive, requires specialised infrastructure, and does not scale cheaply to thousands. It is the right choice only when real-time back-and-forth voice is the core of the product.

The other way is near-live broadcast, where the instructor's stream is delayed by a handful of seconds, delivered through the same adaptive bitrate and content delivery network as recorded video, with learner interaction happening through a live chat alongside the video. This scales to tens of thousands of concurrent learners on the same affordable infrastructure as recorded playback, because to the delivery network a live broadcast is just recorded video that is being created a few seconds ahead of when it is watched.

The platform uses the second approach. This is not a compromise forced by cost so much as a recognition of what a live class of thousands actually is. Thousands of people cannot all speak at once anyway. The instructor teaches, and interaction flows through chat, questions, and polls, which is how large live classes genuinely work. The delay of several seconds is invisible to the learning experience and is what lets a live cohort scale without a specialised and expensive real-time system.

A live session is captured, broadcast near-live, and simultaneously recorded. The moment it ends, the recording is processed into the same adaptive bitrate format as any other video and placed into the course structure, so a learner who missed the live session watches the recording through the identical player, in the identical place, with no difference in experience beyond the absence of live chat.

## 5. Where recordings live, the storage structure

Recordings and pre-recorded lectures are stored in a structured, predictable layout in object storage, organised by where they belong in the catalogue rather than dumped in a flat pile. The structure mirrors the learning hierarchy: a program contains specializations, which contain courses, which contain modules, which contain lessons, and a lesson's video lives at a path that reflects exactly that position. This makes content addressable, auditable, and movable, and it means the storage layout is legible to a human browsing it, not an opaque heap of identifiers.

Original uploaded video and finished live recordings are kept as source material in one storage tier, and the processed adaptive bitrate versions that learners actually watch are kept in another, served through the content delivery network. Storage tiers are chosen by access pattern, so that frequently watched content sits in fast storage and rarely touched archival source material sits in cheaper cold storage, which keeps the storage bill proportional to what is actually used.

Every stored object is private by default. Nothing is world-readable. Access is always mediated by the signed URL mechanism, so storage being on a public cloud does not mean content is publicly reachable.

## 6. The processing pipeline, what happens between upload and playback

When a lecture is uploaded, or when a live session ends and its recording is ready, it does not become watchable immediately. It goes through a pipeline, run as background work so it never blocks anyone, and the platform tracks its state so the interface can honestly show a lecture as still processing rather than presenting a broken player.

The pipeline validates the file, transcodes it into the ladder of quality levels, segments each level for adaptive streaming, generates thumbnails and a preview, extracts or attaches captions, writes everything to the correct storage path, and finally marks the lesson ready. Only then does the player offer it. Captions are treated as part of the deliverable, not an afterthought, because they serve learners with hearing difficulties, learners in noisy places, and learners whose first language is not the instructor's, and because searchable transcripts make video content findable in a way raw video never is.

Processing is idempotent and resumable. If a transcode fails partway, it retries without producing duplicates, and a stuck job surfaces as an alert rather than as a silently missing video.

## 7. How video ties into the rest of the platform

Video is not a separate island. A lesson's video is a piece of learning content in the LMS, described in doc 10, and playing it emits the same kind of progress events as any other lesson, so watching counts toward completion, toward certificates, and toward karma. Progress is recorded as the learner watches, so they resume where they left off across devices, and so the platform can tell genuine completion from someone scrubbing to the end, which matters because karma rewards real watching and not gaming.

Entitlement governs every play. A free video plays for anyone. A subscription video plays for an active subscriber. A purchased course plays until its access window ends. The player does not know or care which tier applies. It asks for a signed URL, and the entitlement service decides whether to issue one.

## 8. The cost reality, stated plainly

Video is the dominant variable cost of the platform, and this is worth being honest about rather than burying. The bill is driven by how much video is watched, specifically by bandwidth served out of the content delivery network, and secondarily by how much video is stored and how much is transcoded. This cost scales with success, which is the good kind of problem, but it is real and it must be watched.

The architecture is built to keep this cost proportional and controllable. The content delivery network means popular content is served from cache rather than reprocessed or re-served from origin. Adaptive bitrate means learners on weak connections consume less bandwidth rather than the platform always pushing the largest files. Cold storage for archival source keeps the storage bill down. And the cost is measured from day one, with cache hit ratio and bandwidth per learner tracked as first-class metrics in doc 14, so that a cost problem is seen early rather than discovered on an invoice.
