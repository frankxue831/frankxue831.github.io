---
title: "把 unsafe 挡在默认构建之外"
date: 2026-06-02
permalink: /zh/notes/unsafe-opt-in/
lang: zh
locale: zh_CN
alternate: /notes/unsafe-opt-in/
description: "gm-crypto-rs 的核心 crate 禁用 unsafe，把需要它的 SIMD 代码隔到另一个 crate 里、藏在需要显式开启的 feature 后面。"
excerpt: "快路径需要 unsafe。与其让它们进核心，不如把它们放进一个你主动选用的 crate——这样默认构建始终是 #![forbid(unsafe_code)]。"
---

Rust 里的 `unsafe` 不是罪过，它是一条边界。它标出这么个地方：编译器不再替你检查，由人来担责任。有用的问题不是「你用没用它」，而是「别人能不能一眼看出它在哪、自己是不是主动选了它」。[`gm-crypto-rs`]({{ '/zh/projects/gm-crypto-rs/' | relative_url }}) 是用 crate 边界来回答这个问题的。

核心 crate `gmcrypto-core` 顶着 `#![forbid(unsafe_code)]`——不是 `deny`（一句游离的 `allow` 就能把它放松），而是 `forbid`：对整个 crate 生效，本地覆盖不了。SM2/SM3/SM4 核心的每一行都被编译器查过；`forbid` 不给任何例外留口子。这正是我想让它默认成立、而且不读代码也能核实的性质：用默认配置装上这个 crate，你跑的、属于这个项目的代码里没有 unsafe。

但有几条快路径需要它。SM4 的快 S-box 是 bitsliced 的，要用到 SIMD intrinsics；SM4 的 AEAD 模式背后那个无进位乘法的 GHASH 也一样。这些 intrinsics 是 `unsafe` 的——今天没有安全的写法。性能值得要；问题是它们能落在哪儿。

最顺手的做法，是在同一个 crate 里拿 feature 把它们一关，收工。我没这么干，因为在一个 `forbid(unsafe_code)` 的 crate 里加一个会引入 `unsafe` 的 feature，本身就是个矛盾，你只能靠削弱那个 `forbid` 来化解。于是这些 SIMD 代码都落在*另一个* crate 里——`gmcrypto-simd`，只能通过显式开启的 feature 够到：bitsliced S-box 在 `sm4-bitsliced-simd` 后面，GHASH 那条在 `sm4-aead` 后面。核心那个 `forbid` 一点没动；unsafe 有了名字、有了边界、也得你主动开启。

代价是实打实的，而且是该付的那个：这些路径都不是默认。一个标准构建跑的是更慢的线性扫描 S-box。你要用上那些 SIMD 版本，得拉进一个 crate、打开一个 feature——一个明确、看得见的选择——换来的是：你可以按 crate 名去审这个项目的安全链，而不必满世界 grep `unsafe`。一个从不开启它的人，从这个项目里一行 unsafe 都不会编译进去。

这个套路不止用在密码学。当一处性能例外需要 `unsafe` 的时候，别为了拿到它，去稀释那个所有人都在用的东西的安全性。把这处例外放到一条边界后面——一个单独的 crate、一个有名字的 feature、一笔讲明白的代价——让安全那条路保持默认，让 unsafe 那条路是有人特意做出的决定。crate 的拆分、那些 feature、还有那个 `forbid`，都在[公开源码]({{ '/zh/projects/gm-crypto-rs/' | relative_url }})里——你要是更想读边界本身，而不是听我说，去翻就是。
