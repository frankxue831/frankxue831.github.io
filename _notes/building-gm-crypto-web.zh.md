---
title: "做 gm-crypto-web 这件事"
# Display-only line-break hints for the ZH h1 (#100 spec B); title stays plain for <title>/OG.
# nowrap keeps "gm-crypto-web" from breaking at its hyphen.
title_breaks: "做 <span class=\"nowrap\">gm-crypto-web</span><wbr>这件事"
date: 2026-10-13
permalink: /zh/notes/building-gm-crypto-web/
lang: zh
locale: zh_CN
# ZH share card. Notes live in _notes/ (not under zh/), so the _config.yml
# path-scoped default cannot reach them — same reason `locale` is set here.
image:
  path: /assets/img/social-card.zh.png
  width: 1200
  height: 630
  alt: "Frank Xue——软件工程师。借助 AI，做有用的软件。"
alternate: /notes/building-gm-crypto-web/
description: "为什么给 gm-crypto-rs 做一个浏览器工具：SM2/SM3/SM4 怎样在 WebAssembly 里本地运行，自检到底证明了什么，限制又在哪里。"
excerpt: "一个不用装任何东西、在浏览器里就能拿已知向量核对 SM2、SM3、SM4 的小工具——以及几件我宁愿说在明处的事。"
---

调试 SM2、SM3、SM4 的时候，真正耗时间的往往不是算法本身，而是算法周围那些问题：这串十六进制是密钥还是 IV？这段密文是不是 C1C3C2？这是 Base64 还是 hex？我的输出和标准向量到底对不对得上？想回答这些，通常得先装一套工具，翻出正确的参数，再祈祷它的默认设置和你要对照的系统一致。

gm-crypto-web 就是我给自己的答案。它是 [frankxue.dev/gm-crypto-web](/gm-crypto-web/?lang=zh) 上的一个页面：可以用 SM3 算摘要，用 SM4（ECB、CBC）加解密，用 SM2 生成密钥、签名、验签、加解密，输入输出在 hex 和 Base64 之间随时切换。不用安装，也不用配置。

## 同一份代码，编译成 WebAssembly

我不想再写一套实现。一个调试工具如果和它要帮忙调试的库结论不一致，还不如没有。所以页面里跑的就是 gm-crypto-rs 本身：`gmcrypto-core` 1.16.0，钉在一个固定的 commit 上，经 `wasm-bindgen` 编译成 WebAssembly。发布构建为了体积做了优化、开了 LTO，但算的还是这个库发布出去的那套逻辑。

这也顺带回答了"在哪儿算"的问题：全部在你的浏览器里。没有后端，没有账号，也不存任何东西；你贴进去的密钥和消息不会离开页面。这与其说是一条要你相信的承诺，不如说是它本来的结构——数据根本没有地方可去。

## 真的会跑的自检

页面顶部的徽章写着"自检 11/11"。我希望这个数字每次都是挣来的，而不是当初往 HTML 里敲一次就完事。所以页面一打开，就会悄悄把自检用例跑一遍 WebAssembly 模块，徽章显示的是这一次运行的结果。总数来自代码里的用例列表，不来自页面标记；要是列表和结果对不上，自检会直接报错，而不是显示通过。

SM3、SM4 对照国标（GB/T）测试向量；SM2 用往返校验：密钥推导，默认或自定义用户 ID 下签名并验签，篡改消息和错误用户 ID 必须失败，加密后再解密还原。一个永远只会说"对"的工具，什么也没证明。

自检也可以手动再跑一次，看每一条的结果。

## 说在明处的限制

有几件事，我宁愿直说。

**它没有经过安全审计。** 用来学习、调试和做互操作测试。请别把生产密钥贴进来——贴进任何网页都不该。

**输入有大小上限。** SM4 的输入最多 256 KB，SM3 和 SM2 最多 1 MB。这两个数不是图整齐随手定的，是量出来的：SM4 在 WebAssembly 里大约每 MB 要 2.1 秒，SM3 和 SM2 都很快。按这个上限，在 Chromium、Firefox 和 WebKit 里每个操作都能控制在一秒左右以内。一个会把标签页卡死的调试工具，帮不了谁调试。

**范围故意做得小。** 不做 X.509，不做 GCM、CCM、XTS。这些需求都是真的，但加进来，一个专注的核对工具就会变成一套做了一半的工具箱。

## 怎么验证的

页面用 Playwright 在 Chromium、Firefox、WebKit 三个引擎上测，桌面和手机尺寸都测，中英文两种界面都测。脚本放在仓库的 `pw/` 目录里：像真正的访客那样打开页面、填输入、把输出和期望字节逐个比对，检查剪贴板和报错的行为，还会盯着那些会让页面卡住的长任务。

这替代不了审计，我也不会把它说成审计。它给我的是一个页面：每次改动之后，它说的每句话我都能重新核一遍——这和我在 gm-crypto-rs 里想守的是同一条规矩。

如果你也在和国密标准打交道，也常常为"是字节错了还是格式错了"耗掉一个小时，希望它能帮你省下这一小时。[去试试](/gm-crypto-web/?lang=zh)；要是它和你信得过的参考实现结论不一致，我很想知道。
