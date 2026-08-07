---
title: "Conformance is byte-identity, or it's nothing"
date: 2026-06-01
permalink: /notes/byte-identity/
lang: en
alternate: /zh/notes/byte-identity/
description: "How gm-crypto-rs checks its SM2/SM3/SM4 output: byte-for-byte against KAT vectors, GmSSL, and OpenSSL — including the mode-semantics traps that make 'looks right' a lie."
excerpt: "Crypto tests don't ask whether the output looks right. They ask whether it's the same bytes as a reference under the same mode semantics — the subtle half."
---

Most code can be tested by asking "does this look right." Cryptography can't. A
cipher that is almost correct produces output statistically indistinguishable
from one that is exactly correct — high-entropy bytes either way — right up until
it silently fails to interoperate with anyone else, or worse, leaks. So the test
for a primitive isn't "does it look right"; it's "is it the *same bytes* a
trusted reference produces, for the same input, under the same rules."
[`gm-crypto-rs`]({{ '/projects/gm-crypto-rs/' | relative_url }}) holds every
output to that bar, and it has two halves — the second subtler than the first.

The first is known-answer tests. The standards ship fixed input/output vectors
(KATs), and the implementation has to reproduce them exactly, bit for bit. That
catches the obvious wrong — a transposed constant, an endianness slip, an
off-by-one in a key schedule. Necessary, but not sufficient: a KAT only covers
the inputs someone thought to write down.

So the second half is differential testing against independent implementations.
SM2/SM3/SM4 output is cross-checked byte-for-byte against GmSSL 3.2.0 — an
in-CI job pinned to a from-source oracle build since the v1.10 cycle — and the
tweakable disk-encryption mode, SM4-XTS, against OpenSSL 3.x. When two
implementations written by different people from the same standard agree on the
bytes across a wide range of inputs, the chance that all of them share my exact
bug drops sharply.

And here is where "same bytes" earns its precision. One named algorithm can
carry *different conventions*, and comparing across them shows a mismatch that
isn't a bug — or, worse, hides one that is. OpenSSL's SM4-XTS must be told
`xts_standard=GB` to follow the GB/T convention rather than the IEEE one; ask
for the wrong standard and the ciphertexts diverge for reasons that have nothing
to do with correctness. So conformance isn't "same bytes as OpenSSL" — it's
"same bytes as OpenSSL *configured to the same mode semantics*." Getting the
comparison harness right is half the work.

This is also what let `1.0.0` make a claim a user can check: the wire output is
byte-identical to `0.16.0` — same SM2 signatures and ciphertexts, same SM4 mode
bytes — verified against GmSSL on eleven of eleven interop vectors, so the 1.0
breaking changes are API shape only, not behavior. You can upgrade and diff the
bytes yourself.

Byte-identity is a strong conformance signal, not a proof of correctness: it
shows you agree with your references — including anywhere they are all wrong
together — and only on the inputs you tested. It sits alongside the
[constant-time gate]({{ '/notes/constant-time-ci-gate/' | relative_url }}) and
the fuzzing, not in place of them. The vectors, the interop targets, and the
comparison configuration are all in the
[public repo](https://github.com/frankxue831/gm-crypto-rs).
