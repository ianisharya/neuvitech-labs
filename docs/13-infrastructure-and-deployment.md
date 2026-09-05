# 13 - Infrastructure, Deployment and Scale

This document was revised to design honestly for thousands of concurrent learners, starting from a baseline of five thousand and built to scale beyond it, and to account for video at scale. The earlier version deferred heavy infrastructure on the reasonable grounds that two part-time engineers should not operate a large system early. That instinct is still right, and the design here holds to it by leaning on managed services and a content delivery network to carry the heavy load, rather than by building and operating that machinery ourselves.

## 1. Environments

There are four environments. Local is the Dev Container on each engineer's machine. Development is a cloud environment that updates automatically when work merges. QA is a cloud environment that mirrors production for testing, with its own isolated and anonymised data. Production is the live platform at the real domain, with a managed database that has point-in-time recovery and a read replica.

The rules that separate them do not bend. No environment holds another's credentials. QA never points at the production database. No production data ever reaches a lower environment without being irreversibly anonymised first. Non-production environments tell search engines not to index them, because an indexed QA site is a real and common embarrassment. Secrets live in per-environment stores that a lower environment physically cannot read.

## 2. Build once, promote the same artefact

A commit that passes the pipeline produces one container image, tagged with the commit it came from. That exact image is deployed to development, then the same image is promoted to QA, then the same image is promoted to production. Nothing is rebuilt between environments, because rebuilding means shipping something you never tested. The image and the database migration head are recorded together on each release, so a rollback is exact and not a guess.

## 3. The production shape, designed for five thousand concurrent and up

```
          PRODUCTION SHAPE, SIZED FOR 5,000 CONCURRENT

                    learners
                       |
              [ CDN + edge cache ]  <-- carries almost ALL
                       |                bytes: video, assets
                       |                (the heaviest load,
                       |                 offloaded entirely)
                [ load balancer ]
                       |
        +--------------+--------------+
        |                             |
   [ web copies ]              [ api copies ]   stateless:
   [ x N        ]              [ x N        ]   scale by adding
        |                             |         more copies
        +--------------+--------------+
                       |
     +---------+-------+-------+----------+
     |         |               |          |
  managed   managed        object     background
  Postgres   Redis         storage      workers
  primary   cache,            |         (video,
    +       sessions,      served       email,
  replicas  queue,         via CDN      billing,
     |      limits                      karma)
  reads go
  to replicas

   The hard, stateful parts are MANAGED SERVICES on
   purpose. Two engineers should not be hand-operating
   failover and point-in-time recovery.
```

The application is built to run as several identical stateless copies behind a load balancer, and this is the single most important fact about how it scales. Because no copy holds any state that another copy needs, handling more learners is a matter of running more copies, and running more copies is something the platform can do automatically as load rises and undo as it falls. Five thousand concurrent learners is the starting point the system is sized for, and the same design carries to far more by adding copies, because nothing in the request path assumes a fixed number of them.

State that must be shared lives in services built to be shared. The database is a managed PostgreSQL with a primary for writes and one or more read replicas for the many reads, because a learning platform reads vastly more than it writes, and catalogue and content reads can be served from replicas to keep the primary free for the writes that genuinely need it. A managed Redis carries caching, sessions, rate limiting, and the queue for background work. Object storage holds media, served through the content delivery network. None of these is something the two engineers operate by hand; they are managed services chosen precisely so that the hard parts, failover, patching, point-in-time recovery, are the provider's responsibility and not a two-person team's.

The heaviest load, video, largely does not touch the application at all. As described in doc 41, video is served from the content delivery network's edge, close to learners, and the application's only involvement is checking entitlement and issuing a short-lived signed URL. This is what makes five thousand concurrent learners watching video affordable: the application handles five thousand quick permission checks, and the content delivery network handles the actual gigabytes. If video came from the application's own servers, the design would fall over at a fraction of this scale and cost many times more. It does not, by deliberate design.

## 4. What carries the load, piece by piece

The content delivery network carries video bandwidth and static assets, serving the vast majority of bytes from edge caches without touching origin. This is the largest load and it is almost entirely offloaded.

The read replicas carry catalogue and content reads, which are the bulk of database work, and these are further cushioned by caching in Redis and by a content delivery network in front of public catalogue pages, so that a popular program's page is served from cache to most visitors and reaches the database rarely.

The application copies carry the genuine application work: authentication, entitlement checks, enrolment, progress writes, commerce, the AI gateway. This work is light per request and scales by adding copies.

Background workers carry everything slow or scheduled: video processing, email, certificate generation, subscription renewals, reconciliation, karma calculation. These run separately from the request path and scale on their own, so a burst of video processing never slows down a learner loading a page.

## 5. The scaling path, taken in order and only when measured

```
   THE SCALING ORDER: cheapest and highest leverage first

   1. Raise CDN cache hit ratio      cheapest win, cuts
                                     cost AND load
   2. Add application copies         trivial, stateless
   3. Widen Redis caching            fewer reads reach DB
   4. Add / strengthen replicas      catalogue reads
   5. Add worker capacity            background throughput
   6. Partition high-volume tables   progress, analytics

   Each step is taken because a DASHBOARD METRIC crossed
   a threshold, never on a hunch. The dashboards in doc 14
   exist partly to make these decisions on evidence.
```

Scaling is done in a deliberate order, cheapest and highest-leverage first, and each step is taken because a measurement showed it was needed, never on a hunch.

First, raise the content delivery network's cache effectiveness, because a higher cache hit ratio is the cheapest possible win and directly reduces both cost and load. Second, add application copies, which is trivial because they are stateless. Third, widen caching in Redis so more reads never reach the database. Fourth, add or strengthen read replicas for catalogue and content reads. Fifth, add background worker capacity. Sixth, partition the highest-volume tables, the streams of progress and analytics events, so they stay fast as they grow. Each of these is triggered by a dashboard metric crossing a threshold, and the dashboards in doc 14 exist partly to make these decisions on evidence.

## 6. On Kubernetes, an honest reassessment

The earlier plan deferred Kubernetes, on the sound reasoning that its operational complexity would consume a two-person team's capacity for capability they did not yet need. That decision is recorded in ADR-0013, and the move to a larger scale target of five thousand concurrent and up naturally raises the question of whether it still holds.

It does hold, and here is the honest reasoning. The thing that makes large scale hard to operate is stateful, sprawling infrastructure, and the design here deliberately pushes almost all of that onto managed services and a content delivery network. The application itself remains simple: stateless copies behind a load balancer, scaled up and down automatically by the hosting platform. Modern managed container platforms do this automatic scaling perfectly well without Kubernetes, and they do it without asking two engineers to become cluster operators. Kubernetes earns its complexity when you have many different services with different scaling needs owned by different teams, or when you need scheduling sophistication that a simpler platform cannot provide. The platform has one application, one worker pool, and two engineers. It does not have that problem. Choosing Kubernetes here would be paying a large operational tax for flexibility that would sit unused, and taking on a large new surface of failure modes that the team would have to learn under production pressure.

So the decision stands, and it stands for a reason that scale did not change: the application is stateless and the heavy state is managed elsewhere, so it scales by running more copies, and running more copies does not require Kubernetes. The revisit trigger is unchanged and honest: if the platform grows to many independently scaled services, or to multiple teams needing independent deploys, or to a scheduling need a simpler platform cannot meet, Kubernetes comes back onto the table. Until one of those is actually true, it is complexity without payoff. ADR-0013 is updated to record this reassessment rather than being contradicted by it.

## 7. Deployment and rollback

```
   DEPLOY: one artefact, promoted unchanged

   commit --> pipeline --> ONE image, tagged by commit
                                |
                                v
                        deploy to DEV
                                |
                       promote SAME image
                                v
                        deploy to QA
                                |
                       promote SAME image
                                v
                       deploy to PROD
                          |
                          +-- migrate (old code still works
                          |            against new schema)
                          +-- canary: small slice of traffic
                          +-- watch errors and latency
                          +-- full rollout
                          +-- smoke tests
                          +-- watch before calling it done

   Nothing is rebuilt between environments, because
   rebuilding means shipping something you never tested.
```

Deploying is a careful sequence. The pipeline is confirmed green, QA is signed off, migrations are reviewed, and a rollback plan is stated before anything ships. Migrations are applied in a way that keeps the old code working against the new schema, so that the new and old versions can briefly coexist during a rollout, which is what makes a zero-downtime deploy and a safe rollback possible at all. A new version goes out to a small slice of traffic first, is watched for errors and latency, and only then rolls out fully. Smoke tests run against production after the deploy, and the release is watched for a period before it is considered done.

```
   ROLLBACK: three paths, two need no deploy at all

   bad application code  -->  redeploy previous image
                              minutes

   bad configuration     -->  change a setting in the DB
                              NO DEPLOY, seconds

   bad feature           -->  turn the feature flag off
                              NO DEPLOY, seconds

   Two of the three fastest recoveries need no deployment.
   That is the direct payoff of the database-driven
   configuration decision in doc 05.
```

Rollback is fast because of how deploys are built. Bad application code is undone by redeploying the previous image, in minutes. A bad configuration is undone by changing a setting in the database, with no deploy at all, because configuration is data as described in doc 05. A bad feature is turned off with a feature flag, again with no deploy. Two of the three fastest recoveries need no deployment, which is the direct payoff of the database-driven configuration decision.

## 8. Domain, network and certificates

The platform runs at neuvitechlabs.com, with the website, the development and QA environments, and the mail-sending domain all configured in DNS. Traffic is protected in transit by current TLS, with certificates renewed automatically and an alert well before any certificate could expire, because a silently expired certificate is a classic and avoidable outage. A web application firewall sits in front of the platform to absorb obvious abuse before it reaches the application.

## 9. Cost, named honestly

The dominant variable cost is video bandwidth from the content delivery network, which scales with how much learners watch. This is the good kind of cost, because it grows with engagement, but it is real and it is watched from day one through the cost metrics in doc 14. After that come the managed database and its replicas, the managed Redis, object storage split between fast and cold tiers, the application and worker compute, and AI inference for the tutor, which is bounded by budgets described in doc 12. Everything expensive is either offloaded to a service that charges for what is used, or bounded by an explicit budget, so that cost scales with the platform's success rather than lying in wait as a fixed liability. A cost model with real numbers is built once the hosting provider is chosen, and cost is reviewed regularly rather than discovered on a bill.

## 10. Business continuity

The database is backed up continuously with point-in-time recovery, so the platform can be restored to any moment rather than only to last night. This is rehearsed on a schedule, because a backup nobody has restored is a hope and not a backup. Object storage is versioned so that content cannot be lost to an accidental overwrite. The recovery targets, how much data could be lost and how long recovery takes, are set explicitly and validated in a real drill rather than assumed.
