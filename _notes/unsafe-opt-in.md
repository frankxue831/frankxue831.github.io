---
title: "Keeping unsafe out of the default build"
date: 2026-06-02
permalink: /notes/unsafe-opt-in/
lang: en
alternate: /zh/notes/unsafe-opt-in/
description: "gm-crypto-rs forbids unsafe in its core crate and quarantines the SIMD code that needs it behind opt-in features in a separate crate."
excerpt: "The fast paths needed unsafe. Rather than let them into the core, they live in a crate you opt into — so the core keeps unsafe_code = \"forbid\"."
---

`unsafe` in Rust isn't a sin; it's a boundary. It marks the place where the
compiler stops checking and a human takes responsibility. The useful question
isn't "did you use it" but "can someone tell, at a glance, where it is and
whether they signed up for it." [`gm-crypto-rs`]({{ '/projects/gm-crypto-rs/' | relative_url }})
answers that with crate boundaries.

The core crate, `gmcrypto-core`, forbids unsafe in its `Cargo.toml` `[lints]`
table — `unsafe_code = "forbid"`. Not `deny`, which a stray `allow` can loosen,
but `forbid`, which holds for the whole crate and can't be locally overridden. Every line of the SM2/SM3/SM4 core is checked
by the compiler; `forbid` leaves no room for an exception. That property holds
by default and can be checked without reading the code: install the crate with
its defaults, and none of this project's own code that you run carries
`unsafe`.

But the fast paths want it. The bitsliced SM4 S-box reaches for SIMD intrinsics;
so does the carryless-multiply GHASH behind SM4's AEAD modes. Those intrinsics
are `unsafe` — there's no safe way to spell them today. The performance is worth
having; the question is where it's allowed to live.

The obvious move would be to gate them behind feature flags in the same crate.
That would break the guarantee: a feature that introduces `unsafe` into a
`forbid(unsafe_code)` crate is a contradiction you can only resolve by weakening
the `forbid`. Instead, all of that SIMD code lives in a *separate* crate,
`gmcrypto-simd`, which `gmcrypto-core` pulls in only through opt-in features —
the bitsliced S-box behind `sm4-bitsliced-simd`, the GHASH path behind
`sm4-aead`. The core's default feature set is empty, and its
[`Cargo.toml`](https://github.com/frankxue831/gm-crypto-rs/blob/v1.16.0/crates/gmcrypto-core/Cargo.toml#L51-L54)
gives the reason for the split: the sibling crate quarantines the unavoidable `unsafe`
of SIMD intrinsics so that `gmcrypto-core` itself can keep
`unsafe_code = "forbid"`. The core keeps its `forbid` intact; the unsafe has a
name, a boundary, and an opt-in.

The cost is real, and it's the right one to pay: those paths aren't the default.
A stock build runs the slower linear-scan S-box. You reach the SIMD versions by
pulling in a crate and turning on a feature — a deliberate, visible choice — and
in exchange you can audit the project's safety story by crate name instead of
grepping for `unsafe`. Someone who never opts in never compiles a line of unsafe
from this project.

The pattern outlives the crypto. When a performance exception needs `unsafe`,
don't dilute the safety of the thing everyone uses in order to get it. Put the
exception behind a boundary — a separate crate, a named feature, a stated cost —
so the safe path stays the default and the unsafe path is a decision someone
made on purpose. The crate split, the features, and the `forbid` are all in the
[public source](https://github.com/frankxue831/gm-crypto-rs) if you'd rather
read the boundary than take my word for it.
