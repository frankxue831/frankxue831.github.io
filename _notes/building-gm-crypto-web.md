---
title: "Building gm-crypto-web"
date: 2026-10-13
permalink: /notes/building-gm-crypto-web/
lang: en
alternate: /zh/notes/building-gm-crypto-web/
description: "Why gm-crypto-rs got a browser tool, how it runs SM2/SM3/SM4 locally in WebAssembly, what its self-test actually proves, and where its limits are."
excerpt: "A small browser tool for checking SM2, SM3 and SM4 against known vectors without installing anything — and the parts I'd rather say out loud than leave implied."
---

Most of the time I spend debugging SM2, SM3 or SM4 isn't spent on the
algorithm. It's spent on the question around it: is this hex string the
key or the IV, is that ciphertext C1C3C2 or something else, is this
Base64 or hex, and does my output match the reference vector or not. To
answer that today, you install a toolkit, find the right flags, and hope
the defaults match the system you're comparing against.

gm-crypto-web is my answer to that. It's a page at
[frankxue.dev/gm-crypto-web](/gm-crypto-web/) where you can hash with SM3,
encrypt and decrypt with SM4 (ECB and CBC), and generate keys, sign,
verify, encrypt and decrypt with SM2, switching between hex and Base64.
Nothing to install, nothing to configure.

## The same code, compiled to WebAssembly

I didn't want a second implementation. A debugging tool that disagrees
with the library it's meant to help debug is worse than no tool. So the
page runs gm-crypto-rs itself: the `gmcrypto-core` crate at 1.16.0,
pinned to a fixed commit and compiled to WebAssembly through
`wasm-bindgen`. The release build is size-optimised with link-time
optimisation, but the arithmetic is the same arithmetic the crate ships.

That also settles where the computation happens. Everything runs in your
browser. There's no backend, no account and no storage; the keys and
messages you paste don't leave the page. That's not a policy I'm asking
you to trust so much as the shape of the thing: there's nowhere for them
to go.

## A self-test that actually runs

The badge at the top of the page says the tool passes 11/11. I wanted
that number to be earned every time, not typed once into the HTML. So on
load the page quietly runs its self-test cases through the WebAssembly
module and the badge reflects that run. The total comes from the case
list in the code, not from the markup, and if the list and the results
ever fall out of step the self-test throws instead of showing a pass.

SM3 and SM4 are checked against the GB/T test vectors. SM2 is checked by
round trip: key derivation, sign and verify with the default or a custom
ID, tampered message and wrong ID must fail, and encrypt then decrypt. A
tool that only ever says "yes" hasn't shown you anything.

You can also run the self-test by hand and see each case's result.

## Honest limits

A few things I'd rather say out loud than leave implied.

**It's unaudited.** It's for learning, debugging and interoperability
testing. Please don't paste production keys into it, or into any web
page.

**Inputs have size limits.** SM4 inputs are capped at 256 KB, and SM3 and
SM2 inputs at 1 MB. Those numbers weren't picked for being round. I
measured: SM4 in WebAssembly costs roughly 2.1 seconds per megabyte here,
while SM3 and SM2 are fast, so these caps keep every action under about
a second in Chromium, Firefox and WebKit. A debugging tool that freezes
the tab isn't helping anyone debug.

**The scope is deliberately small.** No X.509, no GCM, CCM or XTS. Those
are real needs, but they'd turn a focused checker into a half-finished
toolkit.

## How I checked it

The page is tested with Playwright across Chromium, Firefox and WebKit,
on desktop and mobile viewports, in both English and Chinese. The scripts
live in the repo's `pw/` folder. They load the page the way a visitor
would, drive the inputs, compare outputs against expected bytes, check
clipboard and error behaviour, and watch for long tasks that would make
the page feel stuck.

It's not a substitute for an audit, and I don't present it as one. What
it does give me is a page whose claims I can re-check whenever I change
something, the same discipline I try to keep in gm-crypto-rs itself.

If you work with the Chinese national standards and spend too long
wondering whether the bytes are wrong or the format is, I hope it saves
you that hour. [Try it](/gm-crypto-web/?lang=en), and if it disagrees
with a reference you trust, I'd like to know.
