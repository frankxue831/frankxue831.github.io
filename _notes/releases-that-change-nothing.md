---
title: "Skipping the releases that change nothing"
date: 2026-06-03
permalink: /notes/releases-that-change-nothing/
lang: en
alternate: /zh/notes/releases-that-change-nothing/
description: "Why gm-crypto-rs leaves gaps in its version line — assurance cycles that change no output bytes don't earn a published release."
excerpt: "A published version is a promise about bytes, not a diary of work. Here's why some of gm-crypto-rs's hardest cycles were never published at all."
---

A published version number is a promise to whoever depends on you. The easy
mistake is to treat it as a log of effort — every sprint earns a bump, every
merge a new number on crates.io. But a dependency doesn't care how hard you
worked; it cares whether the bytes it links against changed. So
[`gm-crypto-rs`]({{ '/projects/gm-crypto-rs/' | relative_url }}) follows a rule:
a version is a promise about *output*, and a cycle that changes no output doesn't
earn one.

That rule shows up as gaps in the public version line. crates.io has no
`0.14.0`. The work was real — a `cargo-fuzz` sweep, sixteen targets over the
untrusted-input decode and decrypt surface, run to completion with zero crashes.
It raised my confidence in the parser; it changed not a single output byte.
Publishing it as `0.14.0` would have told every downstream "something moved,
re-test, re-audit" when nothing they could observe had. So it merged as
assurance and stayed unpublished.

The bigger gap is `0.17` through `0.23`. That stretch was the pre-1.0 readiness
work: freezing the public API behind a `cargo-public-api` drift-check,
decoupling `crypto-bigint` from the always-on surface, a multi-model adversarial
re-audit before committing to stability. Seven version numbers' worth of the
most consequential work in the project — and crates.io skips all of them. The
changes shipped together, once, in `1.0.0`.

The discipline underneath is easy to state and easy to violate: publish when the
artifact someone consumes changes, not when you've been busy. Assurance work —
fuzzing that finds nothing, an audit that confirms what you hoped, a test added
for peace of mind — is the work you most want to point at. The temptation is to
package it as a release so it shows up. But a release is a request: re-resolve,
re-test, re-deploy. Asking for that when the bytes are identical spends your
users' attention on your bookkeeping.

`1.0.0` is where it converged: all three crates published lockstep at `=1.0.0`,
with the runtime wire output — SM2 signatures and ciphertexts, SM4 mode bytes —
byte-identical to `0.16.0` and cross-checked against gmssl on eleven of eleven
interop vectors. The breaking changes in 1.0 are API *shape*, not behavior; a
`0.16` consumer gets the same bytes out. From there, `cargo-semver-checks` gates
forward breaks, so the next number means what it says.

There's a cost, and it mirrors the constant-time gate's: a version line with
deliberate holes needs explaining. A reader scanning crates.io sees `0.13`, then
`0.16`, then `1.0`, and has to be told the missing numbers aren't abandonment —
they're cycles that refused to bill assurance churn as a byte-changing release.
I'd rather owe that explanation than overstate a release. The full history, with
the skipped cycles named and explained, is on the
[project page]({{ '/projects/gm-crypto-rs/' | relative_url }}) and in the public
repo.
