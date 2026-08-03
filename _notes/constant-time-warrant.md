---
title: "A constant-time claim is a trust problem, not a comprehension problem"
date: 2026-08-03
permalink: /notes/constant-time-warrant/
lang: en
alternate: /zh/notes/constant-time-warrant/
description: "Every crypto library claims its secret-touching paths are constant-time. Transferring warrant for that claim takes two things — a detector you can watch fire on purpose, and limits you state yourself — and neither one is an explanation."
excerpt: "Explaining constant-time execution is the easy part, and it isn't what a skeptical reader needs. What transfers warrant is a leak detector that must fail on purpose, and a caveat written before anyone asks for it."
---

Every crypto library says its secret-touching paths are constant-time. The phrase costs
nothing to write, and that is most of what's wrong with it: it is one of the easiest claims
to assert and one of the hardest to substantiate. A reader has no way to tell a library that
*measured* the property from one that merely *intended* it.

So when I needed to present that claim for
[`gm-crypto-rs`]({{ '/projects/gm-crypto-rs/' | relative_url }}), a pure-Rust SM2/SM3/SM4
SDK, the interesting question wasn't how to explain constant-time execution. Anyone who
cares already knows what it means, and anyone who doesn't can find a better explanation than
mine in thirty seconds. The question was how to transfer *warrant* — how to give a skeptical
reader grounds to believe this particular claim about this particular code.

That needs exactly two things, and neither of them is an explanation.

## Does the test have teeth?

The crate gates on an in-CI [dudect-bencher](https://docs.rs/dudect-bencher/) harness:
twenty targets that split inputs into two classes, measure the two timing distributions, and
reduce "how different are they" to a t-statistic. Most gate at `|tau| < 0.20`. How that gate
is wired, and what it costs on every pull request, is
[its own note]({{ '/notes/constant-time-ci-gate/' | relative_url }}).

A leak detector that reports "no leak found" is uninformative on its own. It reports the same
thing when it is broken, when it is misconfigured, and when it was never wired up at all. So
the interesting artifact is not the twenty passing targets — it's the one target that must
fail:

```rust
fn negative_control(runner: &mut CtRunner, rng: &mut BenchRng) {
    let left = [0u8; 32];
    let mut right = [0u8; 32];
    right[0] = 1;
    for _ in 0..sample_count() {
        let (class, input) = if rng.random::<bool>() {
            (Class::Left, &left)
        } else {
            (Class::Right, &right)
        };
        runner.run_one(class, || leaky_function(input));
    }
}
```

`leaky_function` branches on a secret byte: one path runs a thousand-iteration busy loop,
the other returns immediately. It is supposed to leak, floridly. The gate on this target runs
the opposite direction from every other one — it requires `|tau| > 1.0` — and it is gated on
the *minimum* across runs rather than the median, so it has to fire every single time. One
quiet run means the wiring is broken, and every green result from that run is meaningless.
If the negative control ever stops firing, CI fails.

That's the artifact worth showing. It converts "our timing harness passes" into "our timing
harness demonstrably still detects the thing it is looking for."

## Do you know what it doesn't prove?

The second thing a skeptical reader needs is the boundary of the claim, stated by the person
making it. From the README:

> The harness reports timing-leak detection events. **It does not prove constant-time.** Low
> `|tau|` values mean the test could not detect a leak with the budget given, not that no
> leak exists.

The language is lifted directly from `dudect-bencher`'s own docs, and it is kept verbatim
rather than softened. The same file carries a comparison table against the established
alternatives in which this crate's own rows read **External security audit: none** and
**Production track record: thin — first published 2026**.

Volunteering the limits of your own evidence is unusual enough that it functions as evidence
in itself. A reader who finds that caveat *before* they find it themselves updates
differently than one who finds it after.

## Why these are links and not narration

Both of those things are *locations*. Line 167 of a benchmark file. A paragraph in a README.
Their entire evidential value comes from being checkable: a reader clicks, lands on the exact
line at a pinned tag, and confirms it without taking my word for anything.

I built a [generated explainer video]({{ '/projects/explainer-engine/' | relative_url }}) for
this material first. It's the wrong medium, and the reason generalizes past my particular
attempt: narration converts a checkable fact back into an assertion. A video *can* say "there
is a deliberately-leaky negative control that CI requires to fire." It cannot hand you line
167. Everything the format does — pacing, voice, motion — is spent making a claim easier to
absorb, and none of it is spent making the claim easier to *verify*. For a trust problem
that's the wrong axis, and the polish works against you: a well-produced assertion is still
an assertion, and it now looks more authoritative than it has earned.

Video is genuinely good at building intuition for a *concept* — why timing side channels
exist, what a t-test is doing. It is bad at transferring warrant for a *claim* about specific
code. Constant-time work is almost entirely the second thing.

One practical note, since deep links are load-bearing here: pin them to a tag, not a branch.
Line 167 is line 167 at `v1.11.0` forever; on `main` it drifts the first time someone adds a
target above it, and a stale evidence link is worse than none — it reads as carelessness at
exactly the moment you are asking to be trusted.

The two anchors that shipped are about forty words of HTML and two URLs —
[`timing_leaks.rs:167`](https://github.com/frankxue831/gm-crypto-rs/blob/v1.11.0/crates/gmcrypto-core/benches/timing_leaks.rs#L167)
and
[`README.md:76`](https://github.com/frankxue831/gm-crypto-rs/blob/v1.11.0/README.md#L76).
They do more for the claim than the video did, and they took an afternoon less.
