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
[pinned to a fixed commit](https://github.com/frankxue831/gm-crypto-web/blob/6b88d03c4330999bc771f9057759650554cb8eb4/Cargo.toml#L11) and compiled to WebAssembly through
`wasm-bindgen`. The release build is size-optimised with link-time
optimisation, but the arithmetic is the same arithmetic the crate ships.

That also settles where the computation happens. Everything runs in your
browser. The tool has no backend or account and does not upload or persist
the keys and messages you enter. It does [save your language preference
in localStorage](https://github.com/frankxue831/gm-crypto-web/blob/6b88d03c4330999bc771f9057759650554cb8eb4/www/i18n.js#L108).
That describes this implementation, not a security guarantee.

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

{% include picture.html src_base='/assets/img/gm-crypto-web/sm4'
   alt_en="gm-crypto-web SM4 encryption in ECB mode with the GB/T 32907 test vector: key and plaintext 0123456789abcdeffedcba9876543210 give the output 681edf34d206965e86b3e94f536e4246, with a green check reading &quot;Matches the official test vector (GB/T 32907)&quot;."
   alt_zh="gm-crypto-web 用 GB/T 32907 标准测试向量做 SM4 加密（ECB 模式）：密钥和明文都是 0123456789abcdeffedcba9876543210，输出 681edf34d206965e86b3e94f536e4246，下方绿色对勾提示“与国标向量一致”。"
   width=1200 height=750
   caption_en="The tool checks itself against the GB/T 32907 example vector." caption_zh="工具会用 GB/T 32907 的标准示例自检。" %}

You can also run the self-test by hand and see each case's result.

## Honest limits

A few things I'd rather say out loud than leave implied.

**It's unaudited.** It's for learning, debugging and interoperability
testing. Please don't paste production keys into it, or into any web
page.

**Inputs have size limits.** SM4 inputs are capped at 256 KB, and SM3 and
SM2 inputs at 1 MB, measured in decoded bytes, with room for padding or
ciphertext overhead when decrypting. The [implementation records a
development measurement](https://github.com/frankxue831/gm-crypto-web/blob/6b88d03c4330999bc771f9057759650554cb8eb4/www/app.js#L20)
of roughly 2.1 seconds per megabyte for SM4 in WebAssembly. The caps aim
to keep actions responsive; they do not guarantee a one-second response
on every device or browser. A debugging tool that freezes the tab isn't
helping anyone debug.

**The scope is deliberately small.** No X.509, no GCM, CCM or XTS. Those
are real needs, but they'd turn a focused checker into a half-finished
toolkit.

## How I checked it

The page is tested with Playwright across Chromium, Firefox and WebKit,
on desktop and mobile viewports, in both English and Chinese. The scripts
live in the [public repo's `pw/` folder](https://github.com/frankxue831/gm-crypto-web/tree/6b88d03c4330999bc771f9057759650554cb8eb4/pw). They load the page the way a visitor
would, drive the inputs, compare outputs against expected bytes, check
clipboard and error behaviour, and, in Chromium, watch for long tasks
when rejecting oversized inputs.

It's not a substitute for an audit, and I don't present it as one. What
it does give me is a page whose claims I can re-check whenever I change
something, the same discipline I try to keep in gm-crypto-rs itself.

If you work with the Chinese national standards and spend too long
wondering whether the bytes are wrong or the format is, I hope it saves
you that hour. [Try it](/gm-crypto-web/?lang=en), and if it disagrees
with a reference you trust, I'd like to know.
