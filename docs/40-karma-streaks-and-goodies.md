# 40 - Karma, Streaks and the Goodies Store

The platform rewards learning with a second kind of value called karma, earned by making real progress and spent on physical goodies. The design has one governing principle, given at the outset by the founder and honoured in every choice below: only consistent learners should be meaningfully rewarded. A person who binges for a weekend and vanishes should earn far less than a person who shows up a little every day, and the whole system is shaped to make that true while staying fair and never feeling mean.

## 1. What karma is for

Karma turns the thing the platform most wants, consistent genuine learning, into something the learner can see growing and can eventually spend. It is a motivator and a reward, not a currency the learner pays with to access learning. Learning access is governed by the three tiers in doc 09. Karma is separate: it is earned by learning and spent on goodies, and it never gates access to a lesson.

## 2. How karma is earned, and why it cannot be farmed

Karma is earned for meaningful progress, never for mere activity. This distinction is the heart of keeping it honest. Opening a page earns nothing. Leaving a video playing to an empty room earns nothing. What earns karma is genuine progress that the platform can verify: finishing a lecture with real watching, as the honest progress tracking in doc 10 measures it and not by scrubbing to the end, passing an assessment, completing a project, completing a module or a course, maintaining a learning streak, and contributing usefully to the community.

The amounts are scaled to effort. A passed assessment is worth more than a watched video. A completed project is worth more than a passed quiz. Finishing a whole course is worth a real milestone amount. The exact numbers live in configuration, in the database as described in doc 05, so they can be tuned as the platform learns what motivates without a code change.

Every award is calculated and granted on the server, on a verified event, and never from anything the learner's browser claims. This is the same discipline as never trusting the client for a price. The moment karma buys real goodies, some people will try to cheat it, and the defence is that the client never says how much karma to grant. The server observes a real, verified completion and grants the karma itself. A learner cannot mint karma by lying to the platform, because the platform does not ask them.

## 3. The streak, where consistency is actually rewarded

The streak is the mechanism that makes consistency pay, and it is deliberately the most powerful lever in the system.

A learner has a streak as long as they do something meaningful each day. Meaningful means the same verified progress that earns karma, so a streak cannot be kept alive by merely logging in; the learner must actually learn something, however small. Each consecutive day extends the streak.

The streak applies a multiplier to the karma the learner earns. On day one the multiplier is modest. As the streak lengthens, the multiplier grows, up to a cap so it never becomes absurd. This means the same completed lesson earns a consistent daily learner substantially more karma than it earns someone returning after a long absence, because the consistent learner's multiplier is high and the returner's has reset. Over weeks, the gap compounds enormously, which is exactly the intent: the consistent learner pulls far ahead, not because they did dramatically more, but because they showed up steadily.

When a day is missed, the streak resets and the multiplier falls back to its starting value. This is the honest cost of inconsistency, and it is what gives the streak its meaning. But the reset is designed to be firm without being cruel, and the platform helps the learner protect a streak they have built.

## 4. Protecting a streak without going soft

A system that punishes a single missed day too harshly makes learners anxious and then makes them quit, which serves nobody. So the streak has humane edges that do not undermine its purpose.

The learner is reminded, gently and in good time, before a streak is about to break, through the notification system in doc 10, and the learner controls those reminders. Beyond reminders, the platform offers a small, earned protection: a way to shield a streak against an occasional missed day, granted sparingly and accumulated slowly through consistency itself, so that a genuinely committed learner who misses a day to life does not lose weeks of built-up momentum, while someone who is simply not showing up cannot indefinitely paper over their absence. The protection is limited by design. It softens the occasional real-life gap; it does not turn an inconsistent pattern into a rewarded one. Consistency is still the only thing that builds and holds a strong streak.

This balance, firm reset softened by earned and limited protection, is what makes the system both company-friendly and student-friendly. The company rewards exactly the behaviour it wants, consistent engagement. The student is treated as a human being with a life, not a machine that owes a perfect record.

## 5. The goodies store

Accumulated karma is spent in the goodies store on physical items: merchandise and rewards the platform offers. This is where karma becomes tangible, and it is what gives the whole system a real payoff rather than a number that only ever grows.

The store is not a new commerce system. As described in doc 09, a goodie is a product priced in karma instead of money, and redeeming karma for it runs through the same order and fulfilment path as any purchase, with karma as the payment method and a balance check standing in for a payment authorisation. This reuse is deliberate and it keeps the store honest and consistent: the same audited, server-side order machinery that handles money handles karma, so a goodie redemption is as carefully controlled as a purchase.

Redemption is atomic. A learner's karma balance is held in a ledger, and spending it locks the balance, confirms there is enough, debits it, and creates the order in one indivisible step, so that two rapid redemptions cannot both spend the same karma. A redemption attempted without enough karma is refused cleanly. Because goodies are physical, the store handles the real-world parts: stock, so a goodie that has run out cannot be redeemed, and shipping details, collected and protected like any personal data.

## 6. The karma ledger, an honest accounting

Karma is tracked in a ledger, not as a single mutable number, and this matters for trust and for debugging. Every award and every spend is a recorded entry, with its reason and its moment, and the learner's balance is the sum of their entries. This means the platform can always answer where a learner's karma came from and where it went, can never silently lose or invent karma, and can show the learner an honest history of what they earned and spent. An append-only ledger is the same discipline the platform applies to money and to audit generally: the record of what happened is never quietly rewritten.

## 7. How it all fits together

Karma sits on top of the honest progress tracking already in the platform and turns it into motivation. The learner watches a lecture, and because the platform already measures genuine watching for the sake of completion and certificates, it can grant karma for genuine watching too, with no new tracking needed. The learner keeps a streak, and the streak multiplies their karma, rewarding the consistency the platform is built around. The learner spends karma in a store that is the existing commerce system pointed at a different currency. Nothing here is a separate island; it is a reward layer woven through systems that already exist, which is why it adds motivation without adding much machinery. And every piece of it, earning, streaks, spending, is calculated and enforced on the server on verified events, so the whole thing is fair and cannot be gamed.
