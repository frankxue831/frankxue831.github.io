---
title: "Catching constant-time regressions in CI"
date: 2026-05-31
permalink: /notes/constant-time-ci-gate/
lang: en
alternate: /zh/notes/constant-time-ci-gate/
description: "A credible constant-time CI gate must pass normal paths, make a negative control fire deliberately, and publish its measurements, thresholds, and evidence limits."
excerpt: "Constant-time is easy to satisfy once and lose without noticing. Here's the CI tripwire that fails the build when a leak creeps back — a detector, not a proof."
---

"Constant-time" is one of those properties you can satisfy once and then lose
without anyone noticing. A routine that doesn't branch on secret bits today picks
up a fast path next month, a dependency bumps, a review waves it through — and the
timing leak is back, quietly, with nothing watching for it.

[`gm-crypto-rs`]({{ '/projects/gm-crypto-rs/' | relative_url }}) lives in that gap.
It implements SM2, SM3, and SM4, and the secret-dependent paths are *designed* to
run in constant time — but design intent is asserted at review time and then erodes.
So the question I actually care about isn't *is it constant-time today* — it's *what
keeps it constant-time on every commit.*

The answer is a [dudect](https://crates.io/crates/dudect-bencher)-style harness wired
into CI. dudect is a timing-leak detector: it runs a secret-dependent operation over
two input classes — say a fixed key versus random keys — measures the two
execution-time distributions, and reduces "how different are they" to a single
statistic, *t* (I'll call it τ). If the timing doesn't depend on the secret, the
distributions overlap and \|τ\| stays small. If it does, \|τ\| climbs.

The harness covers twenty secret-touching paths as of `v1.11.0`. A core set is *gated*
on every pull request: if \|τ\| crosses **0.20**, the build fails. Not a warning in a log
nobody reads — a red check on the PR. The leak has to be dealt with before the change
can land.

The caveat is the important part: this is a *detection*, not a proof. A small \|τ\|
means no leak was detected under the measurement budget that run. It does **not** mean
no leak exists — that's dudect's own framing, and I keep it verbatim. Statistics can
tell you "I didn't see it"; they can't turn that into "it isn't there." A constant-time
gate is a smoke detector, not a guarantee, because the alternative is a green check
that quietly overclaims.

Not every path can be gated. A full leak measurement is expensive, and a pull request
has a time budget, so the harness splits the work in two. The core set fails the build.
A second tier — the field-inversion diagnostics, the k-class signing path, and — since
2026-06-17 — HMAC-SM3 — is
measured as telemetry: watched on the nightly run against a **0.55** gross-regression
sentinel rather than enforced at 0.20 on every PR. The k-class path carried a tighter
0.25 nightly gate until 2026-06-07, when shared-runner class-split noise kept firing it
falsely; HMAC-SM3 followed ten days later for the same noise. Each was demoted with
the reasoning published rather than quietly relaxed. It's
an honest trade. Those paths are observed, not enforced, and the split needs ongoing
maintenance — but it keeps the per-PR signal fast and the gate meaningful.

None of this makes the crate "provably constant-time." Nothing does, on real hardware;
on a CPU whose multiply latency depends on its operands, the guarantee doesn't even hold
in principle. What the harness buys is a tripwire: the day a change reintroduces a
secret-dependent timing difference, a build goes red instead of a weakness shipping
silently. The harness, the target list, and the thresholds are all in the
[public repo](https://github.com/frankxue831/gm-crypto-rs) if you want to read
the wiring rather than take my word for it.

That covers what the gate *does*. The harder half is why anyone should believe a
"no leak detected" result at all — which needs a detector you can watch fail on
purpose. That's [a separate note]({{ '/notes/constant-time-warrant/' | relative_url }}).
