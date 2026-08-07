# Bilingual Expression Audit Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve the five `minor` and twelve `nit` expression issues from the 2026-08-07 full bilingual audit without changing project facts, evidence availability, layout, or the older 98-row residual inventory.

**Architecture:** Pure content work on the existing Jekyll site, split into four risk-ordered change sets that each end in a build, validator run, review, and commit. English establishes the claim boundary; Chinese preserves that boundary in native prose. A final verification gate runs across the complete branch before the seventeen Notion rows are closed.

**Tech Stack:** Jekyll via the `github-pages` gem, Liquid/HTML, Markdown notes, WebVTT, SVG accessible text, Ruby post-build validator, Git, and the connected Notion issue database.

## Global Constraints

- Work only on branch `codex/fix-bilingual-expression-audit`, based on `main` at `ba3f39f`; the approved design commit is `5399182`.
- Implement exactly the seventeen issues in pass `2026-08-07 full bilingual expression audit`, including the reopened home CTA row. Leave the older 98 nits, apex-DNS major, and info rows unchanged.
- Claims parity is mandatory: English and Chinese must preserve identical facts, limitations, numbers, and confidence. Chinese should be native prose, not a word-for-word translation.
- A visible video artifact can establish only the rendered artifact and visible disclosure markers. It cannot independently establish a private source line or private gate result.
- Evidence of a maintainer's calibration is not evidence that an implementation is constant-time.
- Do not add or change version numbers, release tags, commits, repository URLs, test results, publication promises, or shipped-feature claims.
- Use `GmSSL` for the named project/implementation in public prose and metadata. Keep lowercase only in literal commands, executable names, or identifiers such as `<code>interop-gmssl</code>`.
- Do not edit CSS, JavaScript, CSP, page structure, navigation, `_data/projects.yml` facts, cue timing, SVG geometry, or video/audio assets.
- Do not add public links for private/local projects.
- Run commands from `/Users/fengxiang/Desktop/agent_workspace/frankxue831.github.io`.
- If Claude Code is used after authentication, give it one change set at a time in an isolated worktree, prohibit commits/pushes/PRs/Notion writes, inspect every diff locally, and rerun all checks in this repository before accepting the work.

---

### Task 1: Correct claims and evidence boundaries

**Files:**
- Modify: `_notes/constant-time-warrant.md:7-23,78-80,114`
- Modify: `_notes/constant-time-warrant.zh.md:15-25,59-61`
- Modify: `_notes/byte-identity.zh.md:19`
- Modify: `projects/explainer-engine.html:112-123`
- Modify: `zh/projects/explainer-engine.html:71-79`
- Test: generated note and project pages under `_site/`
- Test: `scripts/validate_site.rb`

**Interfaces:**
- Consumes: the editorial evidence boundary in `docs/superpowers/specs/2026-08-07-bilingual-expression-audit-fix-design.md`.
- Produces: calibrated EN/ZH claim text that later tasks do not reinterpret.

- [ ] **Step 1: Confirm branch, cleanliness, and the rejected source text**

Run:

```bash
git status --short --branch
rg -n "Every crypto library|exactly two things|evidence in itself|took an afternoon less|每个密码库都会说|这需要两样东西|本身就成了一种证据|一模一样的字节|verification story can be checked|核对流程对不对|一个概念能有多少" _notes projects zh/projects
```

Expected:

- branch is `codex/fix-bilingual-expression-audit` with no uncommitted files;
- the grep finds every rejected phrase in the files listed above;
- no rejected phrase appears in an unrelated public-content file.

- [ ] **Step 2: Calibrate the EN warrant metadata and opening**

In `_notes/constant-time-warrant.md`, replace the `description` value with:

```yaml
description: "Constant-time claims are common in cryptographic libraries. Two artifacts do more to transfer warrant for a particular claim than explanation: a detector you can watch fire on purpose, and limits stated before anyone asks."
```

Replace the first paragraph's opening sentence with:

```markdown
Constant-time claims are common in cryptographic libraries. The phrase costs
```

Keep the rest of the paragraph, including the measured-versus-intended distinction, unchanged.

- [ ] **Step 3: Calibrate the ZH warrant metadata and opening**

In `_notes/constant-time-warrant.zh.md`, replace the `description` value with:

```yaml
description: "密码库里，「涉密路径按常量时间设计」是个常见说法。要把某一份具体实现的可信度交给读者，两样可核对的东西比解释更有用：一个能故意触发的检测器，和一份主动写明的边界。"
```

Replace the first body sentence with:

```markdown
密码库里，「涉密路径按常量时间设计」是个很常见的说法。这句话写下来不花什么成本——问题基本就出在这儿：它是最容易断言、又最难佐证的那类说法。读者没有任何办法区分，哪个库是真的**量过**，哪个只是**打算**这么做。
```

- [ ] **Step 4: Reframe the warrant's two-artifact structure**

In the EN note, replace:

```markdown
That needs exactly two things, and neither of them is an explanation.
```

with:

```markdown
Two artifacts do more work here than explanation.
```

In the ZH note, replace:

```markdown
这需要两样东西，而两样都不是解释。
```

with:

```markdown
这里有两样可核对的东西，比解释更能建立可信度。
```

- [ ] **Step 5: Name what the caveat is evidence of**

In the EN note, replace the paragraph beginning `Volunteering the limits` with:

```markdown
Volunteering the limits of your own evidence is evidence of calibration, not evidence that
the code is constant-time. A reader who finds that caveat *before* they find it themselves
updates differently than one who finds it after.
```

In the ZH note, replace the corresponding paragraph with:

```markdown
主动交代自己证据的局限，能说明维护者愿意校准自己的说法，却不能给「代码是常量时间的」再添一份技术证据。一个读者在自己发现这条但书**之前**就先读到它，和在之后才读到，读到的可信度更新是不一样的。
```

- [ ] **Step 6: Make the EN warrant closing idiomatic**

Replace the EN note's final sentence with:

```markdown
They do more for the claim than the video did, and took one less afternoon to make.
```

Leave the ZH closing unchanged: `花的时间，还少一个下午。`

- [ ] **Step 7: Fix the byte-identity subject/object mismatch**

In `_notes/byte-identity.zh.md`, replace the question inside the opening paragraph with:

```markdown
「在相同输入、相同规则下，它产出的字节，是否与可信参考实现产出的字节*完全一致*」
```

Keep the paragraph's surrounding explanation and link unchanged.

- [ ] **Step 8: Separate visible Explainer evidence from private verification**

In `projects/explainer-engine.html`, replace the final disclosure sentences of the Evidence paragraph with:

```html
            render ran. The disclosure markers — the <code>simplified</code>
            tag and the <code>verified @ commit</code> badge — are visible in
            every frame. The video itself can verify the rendered artifact
            and those visible markers. The cited private source line and the
            gate result are not independently checkable today. If the source
            is later published, the cited line could be checked externally;
            the historical gate result would still require public run
            evidence.
```

In `zh/projects/explainer-engine.html`, replace the corresponding final disclosure sentences with:

```html
            私有快照 <code>local tag diagram-canvas</code>——没有可查看的公开源码。支撑这些说法的是产物本身：上面这段视频是引擎的真实输出，不是效果图。里面的五种力来自一份研究 wiki；屏幕上的徽标标注了「memory force」所核对的具体源码行与 commit，且渲染开始前引用校验门已通过。披露标记——<code>simplified</code> 标签、<code>verified @ commit</code>
            徽标——每一帧都看得见。视频本身只能核对产物和这些可见标记；引用的私有源码行与校验门结果，目前无法由外部独立核对。若源码以后公开，外部读者可以自行核对引用行；当时的校验门结果仍需要公开运行证据。
```

Do not alter the private snapshot label or add a source link.

- [ ] **Step 9: Fix the ZH Explainer research question**

In `zh/projects/explainer-engine.html`, replace only the unstable question in `下一步`:

```html
            目前没有承诺到里程碑的计划。方向由图示画布只答了一半的那个问题来定：一个概念有多少内容能做成动画讲出来，同时仍可按源码核对。仓库若变为公开可访问，再补源码链接。
```

- [ ] **Step 10: Verify rejected claim text is gone**

Run:

```bash
rg -n "Every crypto library|exactly two things|evidence in itself|took an afternoon less|每个密码库都会说|这需要两样东西|本身就成了一种证据|它是不是和一个可信参考实现|verification story can be checked|核对流程对不对|一个概念能有多少" _notes projects zh/projects
```

Expected: exit status 1 and no matches.

- [ ] **Step 11: Build and run the site validator**

Run:

```bash
jekyll doctor
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
```

Expected: doctor has no new warnings, build exits 0, and validator prints `Site validation passed`.

- [ ] **Step 12: Inspect rendered claim parity**

Run:

```bash
rg -n "common in cryptographic|evidence of calibration|not independently checkable today" _site/notes/constant-time-warrant/index.html _site/projects/explainer-engine/index.html
rg -n "常见说法|校准自己的说法|无法由外部独立核对|完全一致" _site/zh/notes/constant-time-warrant/index.html _site/zh/notes/byte-identity/index.html _site/zh/projects/explainer-engine/index.html
```

Expected: every new boundary appears in the intended rendered page and no file outside the listed paths is needed to satisfy the check.

- [ ] **Step 13: Review and commit Change Set 1**

Run:

```bash
git diff --check
git diff -- _notes/constant-time-warrant.md _notes/constant-time-warrant.zh.md _notes/byte-identity.zh.md projects/explainer-engine.html zh/projects/explainer-engine.html
git add _notes/constant-time-warrant.md _notes/constant-time-warrant.zh.md _notes/byte-identity.zh.md projects/explainer-engine.html zh/projects/explainer-engine.html
git commit -m "content: calibrate claims and evidence boundaries"
```

Reject the commit if the diff changes a number, link, tag, source-visibility fact, or section structure.

---

### Task 2: Repair native wording and page microcopy

**Files:**
- Modify: `_notes/starting-a-notebook.zh.md:21-25`
- Modify: `_notes/unsafe-opt-in.zh.md:15,25`
- Modify: `404.html:72`
- Modify: `index.html:219`
- Modify: `zh/index.html:200`
- Modify: `projects.html:61`
- Test: generated home, 404, project-index, and note pages under `_site/`

**Interfaces:**
- Consumes: existing links and page structure; no route changes.
- Produces: corrected visible microcopy with unchanged destinations.

- [ ] **Step 1: Capture the rejected wording**

Run:

```bash
rg -n "最吃紧的几篇|私下游记|藏在需要显式开启|拿 feature 把它们一关|链接可能已经移动|Other ways to get in touch|其他联系方式|Source is .*private/local" _notes 404.html index.html zh/index.html projects.html
```

Expected: eight findings across the files listed for this task.

- [ ] **Step 2: Fix the notebook wording**

In `_notes/starting-a-notebook.zh.md`, use these complete sentences:

```markdown
笔记索引页已经把最扎实的几篇放在前面。这篇更早：当初只是说「会有这么一栏」。那已经不够。下面是这本笔记本实际在执行的编辑契约。
```

```markdown
还在成形的想法，先留在私人笔记里就够。公开笔记要应付另一种读者：没看着你干活、冷着脸进来的人。
```

- [ ] **Step 3: Make the feature boundary explicit**

In `_notes/unsafe-opt-in.zh.md`, replace the description with:

```yaml
description: "gm-crypto-rs 的核心 crate 禁用 unsafe，把需要它的 SIMD 代码隔到另一个 crate 里、放在需要显式开启的 feature 后面。"
```

Replace the first sentence of the same-crate alternative with:

```markdown
最顺手的做法，是在同一个 crate 里用 feature 把它们关在默认构建之外，收工。
```

Keep the following explanation of why a separate crate is stronger.

- [ ] **Step 4: Correct the ZH 404 subject**

In `404.html`, replace the ZH body with:

```html
                你要找的页面可能已经移动，也可能从来就不存在。总之，不在这里。
```

- [ ] **Step 5: Correct both home contact CTAs**

In `index.html`, use:

```html
                How to get in touch <span aria-hidden="true">→</span>
```

In `zh/index.html`, use:

```html
                怎么联系 <span aria-hidden="true">→</span>
```

Do not change the existing `/contact/` or `/zh/contact/` destinations.

- [ ] **Step 6: Fix the ghrunners project-card sentence**

In the `ghrunners` case of `projects.html`, replace the status sentence with:

```html
                failure. Private/local today — source not public.
```

Remove the Liquid `downcase` interpolation only from this sentence; keep `_data/projects.yml` unchanged.

- [ ] **Step 7: Verify the old wording is absent**

Run:

```bash
rg -n "最吃紧的几篇|私下游记|藏在需要显式开启|拿 feature 把它们一关|链接可能已经移动|Other ways to get in touch|其他联系方式|Source is .*private/local" _notes 404.html index.html zh/index.html projects.html
```

Expected: exit status 1 and no matches.

- [ ] **Step 8: Build and validate**

Run:

```bash
jekyll doctor
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
```

Expected: doctor has no new warnings, build exits 0, and validator prints `Site validation passed`.

- [ ] **Step 9: Inspect rendered destinations and copy**

Run:

```bash
rg -n "How to get in touch|href=\"/contact/\"|Private/local today — source not public" _site/index.html _site/projects/index.html
rg -n "怎么联系|href=\"/zh/contact/\"|你要找的页面可能已经移动|最扎实的几篇|私人笔记里|默认构建之外" _site/zh/index.html _site/404.html _site/zh/notes/starting-a-notebook/index.html _site/zh/notes/unsafe-opt-in/index.html
```

Expected: new labels render and both CTA destinations remain unchanged.

- [ ] **Step 10: Review and commit Change Set 2**

Run:

```bash
git diff --check
git diff -- _notes/starting-a-notebook.zh.md _notes/unsafe-opt-in.zh.md 404.html index.html zh/index.html projects.html
git add _notes/starting-a-notebook.zh.md _notes/unsafe-opt-in.zh.md 404.html index.html zh/index.html projects.html
git commit -m "content: repair bilingual wording and microcopy"
```

Reject the commit if any link target or page structure changes.

---

### Task 3: Align subtitles and accessible text

**Files:**
- Modify: `assets/video/harness-field-explainer.en.vtt:28`
- Modify: `zh/projects/ghrunners.html:62`
- Modify: `_includes/figures/ghrunners-evidence.zh.svg:7`
- Test: source VTT, rendered project page, and SVG accessible title

**Interfaces:**
- Consumes: existing cue timing and SVG `aria-labelledby` wiring.
- Produces: grammatical subtitle text and one consistent `受控操作` term across visible and accessible surfaces.

- [ ] **Step 1: Capture the rejected subtitle and accessible wording**

Run:

```bash
rg -n "Constraint blocks bad action\\.$|受控的控制动作" assets/video/harness-field-explainer.en.vtt zh/projects/ghrunners.html _includes/figures/ghrunners-evidence.zh.svg
```

Expected: one VTT finding and two ZH ghrunners findings.

- [ ] **Step 2: Fix the English VTT cue without changing timing**

Replace only the cue text at `00:32.300 --> 00:34.480`:

```vtt
Constraint blocks bad actions.
```

Keep the cue identifier, timestamps, blank lines, and every other cue byte-for-byte unchanged.

- [ ] **Step 3: Align visible and accessible ghrunners wording**

In `zh/projects/ghrunners.html`, use:

```html
            <strong>受控操作，绑在它观测到的状态上。</strong>最顺手的下一步——start / stop / restart——恰恰是危险的那一步，所以
```

In `_includes/figures/ghrunners-evidence.zh.svg`, use:

```svg
  <title id="fig-ghrunners-evidence-title">launchd + ps + .runner + 日志 + API → 类型化 findings → 受控操作</title>
```

Do not change the SVG title ID, geometry, classes, or other text.

- [ ] **Step 4: Verify old wording is absent and timing is intact**

Run:

```bash
rg -n "Constraint blocks bad action\\.$|受控的控制动作" assets/video/harness-field-explainer.en.vtt zh/projects/ghrunners.html _includes/figures/ghrunners-evidence.zh.svg
rg -n -B 1 -A 1 "Constraint blocks bad actions" assets/video/harness-field-explainer.en.vtt
rg -n "受控操作" zh/projects/ghrunners.html _includes/figures/ghrunners-evidence.zh.svg
```

Expected: the first command has no matches; the cue remains at `00:32.300 --> 00:34.480`; `受控操作` appears exactly once in each ZH source.

- [ ] **Step 5: Build and validate**

Run:

```bash
jekyll doctor
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
```

Expected: doctor has no new warnings, build exits 0, and validator prints `Site validation passed`.

- [ ] **Step 6: Review and commit Change Set 3**

Run:

```bash
git diff --check
git diff -- assets/video/harness-field-explainer.en.vtt zh/projects/ghrunners.html _includes/figures/ghrunners-evidence.zh.svg
git add assets/video/harness-field-explainer.en.vtt zh/projects/ghrunners.html _includes/figures/ghrunners-evidence.zh.svg
git commit -m "content: align subtitles and accessible wording"
```

Reject the commit if VTT timestamps or SVG structure change.

---

### Task 4: Correct historical tense and GmSSL casing

**Files:**
- Modify: `projects/gm-crypto-rs-releases.html:30,63,88`
- Modify: `zh/projects/gm-crypto-rs-releases.html:27,60,85`
- Modify: `_notes/byte-identity.md:7,45`
- Modify: `_notes/byte-identity.zh.md:15,27`
- Modify: `_notes/releases-that-change-nothing.md:47`
- Modify: `_notes/releases-that-change-nothing.zh.md:27`
- Test: lowercase classification grep and generated release/note pages

**Interfaces:**
- Consumes: the public-copy casing rule from the approved design.
- Produces: `GmSSL` for every prose/metadata reference, with lowercase retained only in the two literal `interop-gmssl` identifiers.

- [ ] **Step 1: Enumerate and classify every lowercase public-content match**

Run:

```bash
rg -n "gmssl" _notes projects zh/projects
```

Classify the current matches as follows:

- change to `GmSSL`: `_notes/byte-identity.md` description and 1.0 paragraph;
- change to `GmSSL`: `_notes/byte-identity.zh.md` description and 1.0 paragraph;
- change to `GmSSL`: `_notes/releases-that-change-nothing.md` 1.0 paragraph;
- change to `GmSSL`: `_notes/releases-that-change-nothing.zh.md` 1.0 paragraph;
- change to `GmSSL`: the prose phrase `gmssl interop suite` in both release-history v1.10 rows;
- change to `GmSSL`: the v1.0.0 and v0.11.0 parenthetical references in both release-history locales;
- keep lowercase: `<code>interop-gmssl</code>` in the EN and ZH v1.10 rows.

Do not include `docs/` or the validator's historical comment in this public-copy sweep.

- [ ] **Step 2: Correct the completed v1.10 EN sentence**

In `projects/gm-crypto-rs-releases.html`, replace only the final historical sentence pair in the v1.10 row with:

```html
No runtime output of any published crate changed, so crates.io skipped <code>1.10.0</code> (the v0.14 / v0.17–v0.23 precedent). Changes shipped with <code>1.11.0</code>.
```

Keep the `Not published` label and every audit, fuzz, oracle, and version fact unchanged.

- [ ] **Step 3: Apply the proper-name casing replacements**

Make the classified replacements from Step 1. The resulting public copy must use these forms:

```text
GmSSL
GmSSL 3.1.1
GmSSL 3.2.0
GmSSL interop suite
```

The literal identifier remains:

```html
<code>interop-gmssl</code>
```

- [ ] **Step 4: Verify lowercase residue is fully classified**

Run:

```bash
rg -n "gmssl" _notes projects zh/projects
```

Expected: exactly two matches, both the literal `<code>interop-gmssl</code>` identifier in the EN and ZH v1.10 release rows. Any other lowercase match fails this task.

- [ ] **Step 5: Verify historical tense and proper-name output**

Run:

```bash
rg -n "No runtime output of any published crate changed|crates.io skipped|Changes shipped with" projects/gm-crypto-rs-releases.html
rg -n "No published crate's runtime output changes|crates.io skips|Changes ship with" projects/gm-crypto-rs-releases.html
rg -n "GmSSL" _notes projects zh/projects
```

Expected: the first command finds the corrected v1.10 wording; the second exits 1 with no matches; the third finds all prose/metadata references.

- [ ] **Step 6: Build and validate**

Run:

```bash
jekyll doctor
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
```

Expected: doctor has no new warnings, build exits 0, and validator prints `Site validation passed`.

- [ ] **Step 7: Review and commit Change Set 4**

Run:

```bash
git diff --check
git diff -- projects/gm-crypto-rs-releases.html zh/projects/gm-crypto-rs-releases.html _notes/byte-identity.md _notes/byte-identity.zh.md _notes/releases-that-change-nothing.md _notes/releases-that-change-nothing.zh.md
git add projects/gm-crypto-rs-releases.html zh/projects/gm-crypto-rs-releases.html _notes/byte-identity.md _notes/byte-identity.zh.md _notes/releases-that-change-nothing.md _notes/releases-that-change-nothing.zh.md
git commit -m "content: correct release tense and GmSSL casing"
```

Reject the commit if it alters a version, date, test count, URL, or literal identifier.

---

### Task 5: Run the final branch gate and close the scoped Notion issues

**Files:**
- Verify: every file modified in Tasks 1–4
- Verify: generated `_site/` output
- External records: the seventeen Notion issue pages listed below

**Interfaces:**
- Consumes: four reviewed content commits and design commit `5399182`.
- Produces: a clean, fully verified branch and seventeen `fixed-mid-session` issue records with source evidence.

- [ ] **Step 1: Confirm the commit sequence and clean worktree**

Run:

```bash
git status --short --branch
git log -5 --oneline --decorate
```

Expected: clean `codex/fix-bilingual-expression-audit` plus four content commits above `5399182`, in the order specified by the design.

- [ ] **Step 2: Run the complete rejected-phrase sweep**

Run:

```bash
rg -n "Every crypto library|exactly two things|evidence in itself|took an afternoon less|每个密码库都会说|这需要两样东西|本身就成了一种证据|它是不是和一个可信参考实现|私下游记|最吃紧的几篇|藏在需要显式开启|拿 feature 把它们一关|链接可能已经移动|Other ways to get in touch|其他联系方式|Source is .*private/local|一个概念能有多少|受控的控制动作|Constraint blocks bad action\\.$|No published crate's runtime output changes|crates.io skips|Changes ship with" 404.html index.html zh/index.html projects.html _notes projects zh/projects _includes/figures assets/video
```

Expected: exit status 1 and no matches.

- [ ] **Step 3: Recheck the GmSSL exception set**

Run:

```bash
rg -n "gmssl" _notes projects zh/projects
```

Expected: exactly two matches, both `<code>interop-gmssl</code>`.

- [ ] **Step 4: Run the full repository gates**

Run:

```bash
jekyll doctor
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
git diff --check main...HEAD
```

Expected: doctor has no new warnings, build exits 0, validator prints `Site validation passed`, and the diff check is silent.

- [ ] **Step 5: Review the complete diff against scope**

Run:

```bash
git diff --stat main...HEAD
git diff main...HEAD -- 404.html index.html zh/index.html projects.html _notes projects zh/projects _includes/figures assets/video docs/superpowers/specs docs/superpowers/plans
```

Confirm:

- no CSS, JavaScript, CSP, `_data/projects.yml`, navigation, or unrelated docs changed;
- no private repository link was added;
- EN/ZH limitation boundaries match;
- VTT timing and SVG structure remain unchanged;
- all four content commits are independently revertible.

- [ ] **Step 6: Update the seventeen Notion rows**

For each page ID below, append a `Resolution — 2026-08-07` section containing the final old-to-new wording, the implementing commit SHA, and the successful build/validator evidence. Then set `Status` to `fixed-mid-session`. Do not change `Pass`, `Severity`, `Location`, or `Found`.

```text
3b5a01fc-cd2b-8160-a7ad-fc02f752ead9
3b5a01fc-cd2b-811c-8178-ee82f50a3cd4
3b5a01fc-cd2b-81f3-8a7a-fee312c716e4
3b5a01fc-cd2b-811c-b85b-d592a81fefa8
3b5a01fc-cd2b-8117-a1bd-dd66d10a12fe
3b5a01fc-cd2b-81c5-9b65-c1b022253f88
3b5a01fc-cd2b-81f8-a8a3-fcd86727d430
3b5a01fc-cd2b-819b-9efe-d0af94164d56
3b5a01fc-cd2b-8198-874a-c5e98331682d
3b5a01fc-cd2b-814b-9d4a-ec4e89292dd8
3b5a01fc-cd2b-815c-9924-d21f2a6cb60b
3b5a01fc-cd2b-8150-a332-f9a6cbae9a27
3b5a01fc-cd2b-8121-a44c-ca3f4314c2a0
3b5a01fc-cd2b-8199-8838-c49423ef9dbc
3b5a01fc-cd2b-8165-8c03-e3678fc673fc
3b5a01fc-cd2b-8165-8016-c56822f8938d
3b4a01fc-cd2b-81ff-8793-c70a6e47eec7
```

The session inventory row `3b5a01fc-cd2b-81c5-8b9c-eafe1245c9bb` is not part of this update and remains `open`/`info`.

- [ ] **Step 7: Verify Notion counts and scope preservation**

Query data source `collection://42ac2f79-c175-4b9d-a0e4-f977c06a3bfc` by `Status` and `Severity`.

Expected after closure, assuming no unrelated concurrent changes:

```text
open major: 1
open minor: 0
open nit: 98
open info: 99
```

Also query `Pass = "2026-08-07 full bilingual expression audit" AND Status = "open"`. The only remaining row for that pass should be the `info` session inventory.

- [ ] **Step 8: Record the final handoff**

Report:

- branch and all five commit SHAs (design plus four content commits);
- exact validation commands and their outputs;
- Notion count verification;
- any skipped check or unresolved issue;
- that the older 98-nit batch remains untouched.

Do not push or open a pull request until the user explicitly requests publishing.
