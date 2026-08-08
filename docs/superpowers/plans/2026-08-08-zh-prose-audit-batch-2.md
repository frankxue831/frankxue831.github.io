# Chinese Prose Audit Batch 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Correct 21 high-confidence Chinese prose problems across seven pages, close five duplicate Notion rows, and record one separate mobile-navigation visual nit without changing site behavior or evidence claims.

**Architecture:** Treat each editorial theme as an independently reviewable content task with a RED residue check before editing and a GREEN residue/build check afterward. Repository edits finish and validate before any Notion mutation; Notion closure is then applied from an explicit row map and re-queried before the branch is published.

**Tech Stack:** Jekyll, Liquid/HTML, Ruby site validator, ripgrep residue checks, Git, Notion connector, in-app Browser.

## Global Constraints

- Do not change DNS, deployment configuration, CSS, JavaScript, layout, or navigation behavior.
- Do not change English pages.
- Do not change versions, dates, status labels, snapshot labels, evidence URLs, publication boundaries, or technical claims.
- Do not translate stable code identifiers, CLI command names, crate names, protocol names, standards, or public API symbols.
- Preserve the site's compact first-person voice; edit only the 21 canonical issues in the approved specification.
- Mark exactly five selected duplicate rows as `duplicate`; leave all other open Notion rows unchanged.
- Create exactly one new open `nit` for the mobile-navigation background sliver; do not fix it in this branch.
- Apply repository edits with `apply_patch`.
- Use branch `codex/fix-zh-prose-audit-batch-2`; do not work directly on `main`.
- Approved design: `docs/superpowers/specs/2026-08-08-zh-prose-audit-batch-2-design.md`.

---

### Task 1: Clarify Explainer Engine and ghrunners terminology

**Files:**
- Modify: `zh/projects/explainer-engine.html:28-74`
- Modify: `zh/projects/ghrunners.html:9-93`
- Test: targeted `rg` residue checks plus Jekyll build and site validator

**Interfaces:**
- Consumes: the exact approved rewrite rules for the Explainer Engine and ghrunners sections.
- Produces: idiomatic first-use glosses for `beat` and `verb`, explicit provenance-marker wording, traceable determinism wording, and accurate GitHub API enrichment wording.

- [ ] **Step 1: Run the RED residue check**

Run:

```sh
rg -n '每个 beat|新的 beat 类型|被渲染进了画面|披露装置|追回输入上的差异|类型化 findings 与受控操作，落在|每个 verb|某个 verb|控制 verb|GitHub API 接入' \
  zh/projects/explainer-engine.html \
  zh/projects/ghrunners.html
```

Expected: exit `0`, with matches at Explainer lines 29, 60, and 64 and ghrunners lines 9, 66, 87, and 93. The check must visibly detect the old wording before any edit.

- [ ] **Step 2: Apply the Explainer Engine replacements**

Use `apply_patch` to make these exact substitutions in `zh/projects/explainer-engine.html`:

```text
每个 beat 可以是
→ 每个 beat（镜头段落）可以是

被渲染进了画面
→ 直接显示在画面中

每一帧都带着这套披露装置
→ 每一帧都带着这套常设出处标记

输出上的任何差异都能追回输入上的差异
→ 任何输出差异都能追溯到输入差异

新的 beat 类型
→ 新的镜头段落类型

披露标记——
→ 出处标记——
```

Do not change the neighboring sentences about private-source verification or pixels spent on provenance.

- [ ] **Step 3: Apply the ghrunners replacements**

Use `apply_patch` to make these exact substitutions in `zh/projects/ghrunners.html`:

```text
summary_outcome: "类型化 findings 与受控操作，落在同一份权威的 launchd 状态上。"
→ summary_outcome: "类型化 findings 与受控操作，都基于同一份权威的 launchd 状态。"

<code>control</code> 子命令
→ <code>control</code> 子命令（verb）

其余每个 verb 的目标都是确定的
→ 其余每个子命令的目标都是确定的

而在某个 verb 可能干掉
→ 而在某个子命令可能干掉

v0.2 加了控制 verb
→ v0.2 加了控制子命令

更深的 GitHub API 接入
→ 更深的 GitHub API 信息补全
```

Keep code tokens such as `control`, `bootstrap`, `unload`, and `restart` unchanged.

- [ ] **Step 4: Run the GREEN terminology checks**

Run the RED command from Step 1 again.

Expected: exit `1` with no matches.

Then run:

```sh
rg -n 'beat（镜头段落）|常设出处标记|追溯到输入差异|control</code> 子命令（verb）|每个子命令|GitHub API 信息补全' \
  zh/projects/explainer-engine.html \
  zh/projects/ghrunners.html
```

Expected: exit `0`; every new expression appears in its intended file.

- [ ] **Step 5: Build and validate the two-page change**

Run:

```sh
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
git diff --check
```

Expected: Jekyll exits `0`, validator prints `Site validation passed`, and `git diff --check` emits nothing.

- [ ] **Step 6: Commit the terminology change**

```sh
git add zh/projects/explainer-engine.html zh/projects/ghrunners.html
git commit -m "content(zh): clarify explainer and runner terminology"
```

Expected: one commit containing only the two listed files.

---

### Task 2: Repair gm-crypto-rs release-history calques

**Files:**
- Modify: `zh/projects/gm-crypto-rs-releases.html:23-36`
- Test: targeted release-history residue checks plus Jekyll build and site validator

**Interfaces:**
- Consumes: the English release-history facts and the approved Chinese rewrite map.
- Produces: clearer explanations of additive opt-in traits, wrapper behavior, byte idempotence, certificate-chain checks, and byte-string interfaces without altering release facts.

- [ ] **Step 1: Run the RED release-history check**

Run:

```sh
rg -n '增量、可选|固有 AEAD|薄壳不加密码学|字节幂等|原始 Name（名称）衔接|中间 CA 资格|逐字节进、逐字节出' \
  zh/projects/gm-crypto-rs-releases.html
```

Expected: exit `0`, with matches in v1.11.0, v1.10.0, v1.8.0, and v1.7.0.

- [ ] **Step 2: Rewrite the v1.11.0 entry**

Use `apply_patch` to replace only the following fragments on the v1.11.0 entry:

```text
trait 适配（增量、可选）
→ trait 适配（非破坏式新增、需显式启用）

是一层盖在固有 AEAD 路径上的薄壳
→ 是在既有 AEAD 路径之上的轻量包装层

薄壳不加密码学；涉密路径就是原来那套代码
→ 包装层不引入新的密码学实现；涉密路径仍是原来那套代码
```

Leave all feature flags, type names, dependency versions, MSRV, fuzz target names, census values, and ABI counts unchanged.

- [ ] **Step 3: Rewrite the v1.10.0, v1.8.0, and v1.7.0 entries**

Use `apply_patch` for these exact substitutions:

```text
把四个 DER 模糊测试加强到字节幂等
→ 把四个 DER 模糊测试加强为字节级幂等检查（同一变换重复执行后，字节结果保持不变）

逐边的 SM2 签名与原始 Name（名称）衔接、中间 CA 资格
→ 逐边的 SM2 签名、证书原始 Name 字段的衔接、中间证书的 CA 资格

为四个 SM2 系列套件提供字节流进、字节流出的保护 / 解保护
→ 为四个 SM2 系列套件提供以字节串为输入和输出的保护 / 解保护
```

Do not change the surrounding claims about chain ordering, trust decisions, server authentication, constant-time behavior, or caller responsibility.

- [ ] **Step 4: Run the GREEN release-history checks**

Run the RED command from Step 1 again.

Expected: exit `1` with no matches.

Then run:

```sh
rg -n '非破坏式新增、需显式启用|既有 AEAD 路径|包装层不引入新的密码学实现|字节级幂等检查|字节结果保持不变|证书原始 Name 字段|中间证书的 CA 资格|以字节串为输入和输出' \
  zh/projects/gm-crypto-rs-releases.html
```

Expected: exit `0` and seven positive matches.

- [ ] **Step 5: Build and validate the release-history change**

Run:

```sh
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
git diff --check
```

Expected: Jekyll exits `0`, validator prints `Site validation passed`, and the diff check emits nothing.

- [ ] **Step 6: Commit the release-history change**

```sh
git add zh/projects/gm-crypto-rs-releases.html
git commit -m "content(zh): clarify release-history terminology"
```

Expected: one commit containing only the Chinese release-history page.

---

### Task 3: Align project, profile, and colophon wording

**Files:**
- Modify: `zh/projects/gm-crypto-rs.html:104-127`
- Modify: `zh/projects/repolens-rs.html:46-77`
- Modify: `zh/about.html:29-31`
- Modify: `zh/colophon.html:24-28`
- Test: targeted cross-page residue checks plus Jekyll build and site validator

**Interfaces:**
- Consumes: the approved safe-core, C-ABI, RepoLens, About, and colophon wording.
- Produces: explicit `unsafe` scope, accurate maintenance-surface wording, first-use glosses for RepoLens concepts, and idiomatic build-description prose.

- [ ] **Step 1: Run the RED cross-page check**

Run:

```sh
rg -n '安全的核心，SIMD|工作量等于翻倍|文件、符号、依赖图、profile|记忆、wiki|自用（dogfood）评估契约|dudect 泄漏 harness|零件保持得少|设计 token' \
  zh/projects/gm-crypto-rs.html \
  zh/projects/repolens-rs.html \
  zh/about.html \
  zh/colophon.html
```

Expected: exit `0`, with matches in all four files.

- [ ] **Step 2: Clarify gm-crypto-rs scope and maintenance cost**

Use `apply_patch` for these exact substitutions in `zh/projects/gm-crypto-rs.html`:

```text
<strong>安全的核心，SIMD 单独按需开。</strong>
→ <strong>核心禁止 unsafe，SIMD 单独按需开。</strong>

每个模式都得在三个已发布的 crate 里测一遍、维护一遍，工作量等于翻倍。
→ 每个模式都得在三个已发布的 crate 里测一遍、维护一遍，测试和维护面也随之翻倍。
```

Keep the following paragraph's `unsafe_code = "forbid"` evidence and feature-gate names unchanged.

- [ ] **Step 3: Add RepoLens first-use glosses**

Use `apply_patch` for these exact substitutions in `zh/projects/repolens-rs.html`:

```text
文件、符号、依赖图、profile
→ 文件、符号、依赖图、仓库画像（profile）

约定提取、记忆、wiki
→ 约定提取、记忆、知识库（wiki）

一份自用（dogfood）评估契约
→ 一份项目自用的评估契约
```

Keep `pack`, `MCP`, `eval`, and command names unchanged because they are stable product identifiers already explained elsewhere on the page.

- [ ] **Step 4: Align About and colophon wording**

Use `apply_patch` for these exact substitutions:

```text
zh/about.html:
dudect 泄漏 harness
→ dudect 泄漏回归 harness

zh/colophon.html:
零件保持得少：
→ 组成很精简：

一份手写、基于设计 token 的样式表
→ 一份手写、基于一套设计变量（design tokens）的样式表
```

Do not change the counts of JavaScript files or lines, CSP statements, analytics statements, or hosting description.

- [ ] **Step 5: Run the GREEN cross-page checks**

Run the RED command from Step 1 again.

Expected: exit `1` with no matches.

Then run:

```sh
rg -n '核心禁止 unsafe|测试和维护面也随之翻倍|仓库画像（profile）|知识库（wiki）|项目自用的评估契约|dudect 泄漏回归 harness|组成很精简|设计变量（design tokens）' \
  zh/projects/gm-crypto-rs.html \
  zh/projects/repolens-rs.html \
  zh/about.html \
  zh/colophon.html
```

Expected: exit `0`; all eight approved expressions appear.

- [ ] **Step 6: Build and validate the cross-page change**

Run:

```sh
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
git diff --check
```

Expected: Jekyll exits `0`, validator prints `Site validation passed`, and the diff check emits nothing.

- [ ] **Step 7: Commit the cross-page change**

```sh
git add \
  zh/projects/gm-crypto-rs.html \
  zh/projects/repolens-rs.html \
  zh/about.html \
  zh/colophon.html
git commit -m "content(zh): align project and site terminology"
```

Expected: one commit containing exactly the four listed files.

---

### Task 4: Verify the complete repository change and rendered pages

**Files:**
- Verify: all seven edited Chinese pages
- Verify: `_site/zh/` rendered output
- Test: full Jekyll and browser acceptance suite

**Interfaces:**
- Consumes: the three content commits from Tasks 1-3.
- Produces: a merge-ready repository state and the evidence required before Notion closure.

- [ ] **Step 1: Run the complete rejected-phrase sweep**

Run:

```sh
rg -n '被渲染进了画面|披露装置|追回输入上的差异|每个 verb|某个 verb|控制 verb|GitHub API 接入|增量、可选|固有 AEAD|薄壳不加密码学|字节幂等|原始 Name（名称）衔接|中间 CA 资格|逐字节进、逐字节出|安全的核心，SIMD|工作量等于翻倍|dogfood|dudect 泄漏 harness|零件保持得少|设计 token' \
  zh/projects/explainer-engine.html \
  zh/projects/ghrunners.html \
  zh/projects/gm-crypto-rs-releases.html \
  zh/projects/gm-crypto-rs.html \
  zh/projects/repolens-rs.html \
  zh/about.html \
  zh/colophon.html
```

Expected: exit `1`, no output.

- [ ] **Step 2: Run the full static-site suite**

Run:

```sh
bundle exec jekyll doctor
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
git diff --check a1e8712..HEAD
```

Expected: doctor reports `Everything looks fine`, build exits `0`, validator prints `Site validation passed`, and the diff check emits nothing. Existing RubyGems and optional `faraday-retry` warnings are non-blocking if unchanged.

- [ ] **Step 3: Inspect the immutable-fact boundary**

Run:

```sh
git diff --word-diff=plain a1e8712..HEAD -- \
  zh/projects/explainer-engine.html \
  zh/projects/ghrunners.html \
  zh/projects/gm-crypto-rs-releases.html \
  zh/projects/gm-crypto-rs.html \
  zh/projects/repolens-rs.html \
  zh/about.html \
  zh/colophon.html
```

Expected: the diff contains only the exact wording substitutions from Tasks 1-3. Reject the change if a version, date, URL, status, snapshot label, feature flag, public symbol, or numeric count changed.

- [ ] **Step 4: Start a local preview**

Run in a persistent terminal session:

```sh
bundle exec jekyll serve --host 127.0.0.1 --port 4000
```

Expected: Jekyll reports `Server address: http://127.0.0.1:4000/` and remains running for Step 5.

- [ ] **Step 5: Inspect all seven changed routes in the in-app Browser**

Check these routes at 1440 × 1000 and 390 × 844:

```text
http://127.0.0.1:4000/zh/projects/explainer-engine/
http://127.0.0.1:4000/zh/projects/ghrunners/
http://127.0.0.1:4000/zh/projects/gm-crypto-rs/releases/
http://127.0.0.1:4000/zh/projects/gm-crypto-rs/
http://127.0.0.1:4000/zh/projects/repolens-rs/
http://127.0.0.1:4000/zh/about/
http://127.0.0.1:4000/zh/colophon/
```

For every route, capture the viewport containing the changed copy and confirm: one `h1`, `lang="zh-CN"`, no horizontal overflow, no missing images, no text overlap or clipping, and no browser console warning/error. Save accepted screenshots under the active audit artifact directory with route-specific names.

- [ ] **Step 6: Stop the local preview and confirm a clean repository state**

Stop only the Jekyll server session started in Step 4, then run:

```sh
git status --short --branch
```

Expected: branch is `codex/fix-zh-prose-audit-batch-2`; no generated `_site` files are tracked; only the already committed plan/spec and content commits exist.

---

### Task 5: Close selected Notion rows and record the mobile-navigation nit

**Files:**
- External update: Notion data source `collection://42ac2f79-c175-4b9d-a0e4-f977c06a3bfc`
- Test: Notion SQL queries and page fetches

**Interfaces:**
- Consumes: green repository and browser verification from Task 4.
- Produces: 21 rows at `fixed-mid-session`, five rows at `duplicate`, one new open mobile-navigation `nit`, and no changes to other backlog rows.

- [ ] **Step 1: Fetch the Notion Markdown specification and data-source schema**

Use `notion_fetch` for:

```text
notion://docs/enhanced-markdown-spec
collection://42ac2f79-c175-4b9d-a0e4-f977c06a3bfc
```

Expected schema: `Name` title, `Location` text, `Pass` text, `Severity` select, `Status` select, and `date:Found:start` date fields. Stop if the schema differs.

- [ ] **Step 2: Verify the 26 selected rows are still open**

Query the data source for these exact IDs:

```text
3b4a01fccd2b814eba37fc88b982cae3
3b4a01fccd2b814db478db5465b6d88d
3b4a01fccd2b81c3ab48d90dceed9ee2
3b4a01fccd2b8168b07cc9d6aeea6212
3b4a01fccd2b819d98ebefcab0708b2b
3b4a01fccd2b8131a481d001e832bd8d
3b4a01fccd2b81f7a5b6d93b8d81061c
3b4a01fccd2b8191bc18d1ed58c43623
3b4a01fccd2b81118ec0c85fb145e217
3b4a01fccd2b81628bd3f64ff42b7d1e
3b4a01fccd2b8164b31cee3610e5f3fe
3b4a01fccd2b816b93fbca512a66b776
3b4a01fccd2b8130ba6aee8472c1815e
3b4a01fccd2b816e80daed9991c3c6ba
3b4a01fccd2b81469979e32492d7ad92
3b4a01fccd2b8102af8fc36f1e829ea6
3b4a01fccd2b8112a5a4c76d73233b2e
3b4a01fccd2b81aa9adbee8d8c67eba0
3b4a01fccd2b813c907ac591fdc6f9a4
3b4a01fccd2b811aa6fdce140a00c658
3b4a01fccd2b8195aa51f0f85414d252
3b4a01fccd2b81e3a289fe11929c79a5
3b4a01fccd2b814daa9ccbdca63f9c9d
3b4a01fccd2b81c8b228f4100a9e5c59
3b4a01fccd2b818596b1d2b7a2f1ab7c
3b4a01fccd2b8104b068f3fb60d59ce2
```

Expected: 26 rows, each `Severity = nit` and `Status = open`. If any row is no longer open, fetch it and exclude it from mutation rather than overwriting newer work.

- [ ] **Step 3: Append resolution sections to the 21 canonical rows**

For every canonical fixed row, first fetch the page, then use `notion_update_page` with `command: "insert_content"`, `position: {"type":"end"}`, and this exact structure:

```markdown
## Resolution — 2026-08-08

Fixed in `<file>`: `<old wording>` → `<new wording>`. Verified by the targeted residue sweep, Jekyll build, site validator, and rendered-page inspection.
```

Use this row-to-resolution map; the strings in the right column replace the three angle-bracket fields above:

| Row ID | Resolution sentence |
| --- | --- |
| `3b4a01fccd2b814eba37fc88b982cae3` | `zh/projects/explainer-engine.html`: `beat` → `beat（镜头段落）` / `镜头段落类型` |
| `3b4a01fccd2b814db478db5465b6d88d` | `zh/projects/explainer-engine.html`: `被渲染进了画面` → `直接显示在画面中` |
| `3b4a01fccd2b81c3ab48d90dceed9ee2` | `zh/projects/explainer-engine.html`: `披露装置` → `常设出处标记` |
| `3b4a01fccd2b819d98ebefcab0708b2b` | `zh/projects/explainer-engine.html`: `追回输入上的差异` → `追溯到输入差异` |
| `3b4a01fccd2b8131a481d001e832bd8d` | `zh/projects/ghrunners.html`: `落在同一份…状态上` → `都基于同一份…状态` |
| `3b4a01fccd2b81f7a5b6d93b8d81061c` | `zh/projects/ghrunners.html`: bare `verb` → first-use `子命令（verb）`, then `子命令` |
| `3b4a01fccd2b81118ec0c85fb145e217` | `zh/projects/ghrunners.html`: `GitHub API 接入` → `GitHub API 信息补全` |
| `3b4a01fccd2b8164b31cee3610e5f3fe` | `zh/projects/gm-crypto-rs-releases.html`: `增量、可选` → `非破坏式新增、需显式启用` |
| `3b4a01fccd2b816b93fbca512a66b776` | `zh/projects/gm-crypto-rs-releases.html`: `固有 AEAD 路径` → `既有 AEAD 路径` |
| `3b4a01fccd2b816e80daed9991c3c6ba` | `zh/projects/gm-crypto-rs-releases.html`: `薄壳不加密码学` → `包装层不引入新的密码学实现` |
| `3b4a01fccd2b81469979e32492d7ad92` | `zh/projects/gm-crypto-rs-releases.html`: `字节幂等` → `字节级幂等检查` plus gloss |
| `3b4a01fccd2b8102af8fc36f1e829ea6` | `zh/projects/gm-crypto-rs-releases.html`: `原始 Name（名称）衔接` → `证书原始 Name 字段的衔接` |
| `3b4a01fccd2b8112a5a4c76d73233b2e` | `zh/projects/gm-crypto-rs-releases.html`: `中间 CA 资格` → `中间证书的 CA 资格` |
| `3b4a01fccd2b81aa9adbee8d8c67eba0` | `zh/projects/gm-crypto-rs-releases.html`: `逐字节进、逐字节出` → `以字节串为输入和输出` |
| `3b4a01fccd2b813c907ac591fdc6f9a4` | `zh/projects/gm-crypto-rs.html`: `安全的核心` → `核心禁止 unsafe` |
| `3b4a01fccd2b8195aa51f0f85414d252` | `zh/projects/gm-crypto-rs.html`: `工作量等于翻倍` → `测试和维护面也随之翻倍` |
| `3b4a01fccd2b81e3a289fe11929c79a5` | `zh/projects/repolens-rs.html`: `profile` / `wiki` → `仓库画像（profile）` / `知识库（wiki）` |
| `3b4a01fccd2b814daa9ccbdca63f9c9d` | `zh/projects/repolens-rs.html`: `自用（dogfood）评估契约` → `项目自用的评估契约` |
| `3b4a01fccd2b81c8b228f4100a9e5c59` | `zh/about.html`: `dudect 泄漏 harness` → `dudect 泄漏回归 harness` |
| `3b4a01fccd2b818596b1d2b7a2f1ab7c` | `zh/colophon.html`: `零件保持得少` → `组成很精简` |
| `3b4a01fccd2b8104b068f3fb60d59ce2` | `zh/colophon.html`: `设计 token` → `设计变量（design tokens）` |

Expected: 21 pages receive one new resolution section each.

- [ ] **Step 4: Set the 21 canonical rows to fixed**

For the 21 IDs in Step 3, call `notion_update_page` with:

```json
{
  "command": "update_properties",
  "properties": {"Status": "fixed-mid-session"}
}
```

Expected: all 21 canonical rows report `Status = fixed-mid-session`.

- [ ] **Step 5: Mark the five duplicate rows**

Use this duplicate-to-canonical map:

```text
3b4a01fccd2b8168b07cc9d6aeea6212 → 3b4a01fccd2b81c3ab48d90dceed9ee2
3b4a01fccd2b8191bc18d1ed58c43623 → 3b4a01fccd2b81f7a5b6d93b8d81061c
3b4a01fccd2b81628bd3f64ff42b7d1e → 3b4a01fccd2b81118ec0c85fb145e217
3b4a01fccd2b8130ba6aee8472c1815e → 3b4a01fccd2b816b93fbca512a66b776
3b4a01fccd2b811aa6fdce140a00c658 → 3b4a01fccd2b813c907ac591fdc6f9a4
```

Fetch each duplicate, append:

```markdown
## Duplicate — 2026-08-08

Duplicate of canonical row `<canonical row ID>`. The canonical row records the repository fix and validation evidence.
```

Then set its `Status` property to `duplicate`.

Expected: exactly five rows report `Status = duplicate`.

- [ ] **Step 6: Create the mobile-navigation audit row**

Call `notion_create_pages` with parent data source `42ac2f79-c175-4b9d-a0e4-f977c06a3bfc` and exactly these values:

```json
{
  "properties": {
    "Name": "mobile nav：展开面板底部露出正文窄条",
    "Location": "mobile primary navigation / assets/css/style.css",
    "Pass": "2026-08-08 production UX audit",
    "Severity": "nit",
    "Status": "open",
    "date:date:Found:start:start": "2026-08-08",
    "date:date:Found:start:is_datetime": 0
  },
  "content": "## Observation\n\nAt a 390 × 844 viewport, the expanded mobile navigation leaves a narrow strip of page content visible at the bottom. The menu remains usable, its links are exposed semantically, and `aria-expanded` updates correctly. This is a visual containment issue, not a navigation blocker.\n\n## Scope\n\nExcluded from the prose batch because fixing it requires a separate CSS and interaction decision."
}
```

The date keys above are the exact expanded SQL property names returned by the
current data-source schema. Stop without creating the row if a fresh schema
fetch returns different names.

Expected: one new `open` / `nit` row with Pass `2026-08-08 production UX audit`.

- [ ] **Step 7: Verify Notion postconditions**

Query the data source and confirm:

```text
Selected canonical IDs: 21 fixed-mid-session
Selected duplicate IDs: 5 duplicate
2026-08-08 production UX audit: 1 open nit
DNS major row: still open and unchanged
All unselected rows: statuses unchanged
```

Fetch one fixed row, one duplicate row, and the new audit row to confirm their appended/created bodies match the templates above.

---

### Task 6: Final verification and draft pull request

**Files:**
- Verify: entire branch diff against `main`
- Publish: branch `codex/fix-zh-prose-audit-batch-2`
- Create: draft pull request targeting `main`

**Interfaces:**
- Consumes: green repository checks and verified Notion postconditions.
- Produces: a pushed branch and draft PR ready for human review.

- [ ] **Step 1: Re-run final verification after Notion closure**

Run:

```sh
bundle exec jekyll doctor
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
git diff --check a1e8712..HEAD
git status --short --branch
```

Expected: all site commands exit `0`; validator prints `Site validation passed`; diff check emits nothing; working tree is clean on `codex/fix-zh-prose-audit-batch-2`.

- [ ] **Step 2: Review branch scope**

Run:

```sh
git log --oneline --decorate a1e8712..HEAD
git diff --stat a1e8712..HEAD
git diff --name-only a1e8712..HEAD
```

Expected files: the approved design, this implementation plan, and the seven Chinese content pages. No CSS, JavaScript, English page, deployment, or DNS file may appear.

- [ ] **Step 3: Push the branch**

Run:

```sh
git push -u origin codex/fix-zh-prose-audit-batch-2
```

Expected: push succeeds without force and the local branch tracks the remote branch.

- [ ] **Step 4: Create a draft pull request**

Create a draft PR targeting `main` with:

```text
Title: Clarify the next Chinese prose audit batch

Summary:
- clarify high-confidence Chinese terminology across seven pages
- preserve release facts, evidence boundaries, status, and personal voice
- close 21 Notion findings, deduplicate five rows, and log one separate mobile-nav nit

Validation:
- bundle exec jekyll doctor
- bundle exec jekyll build
- LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
- rejected-phrase residue sweep
- desktop and 390 × 844 rendered-page inspection
```

Expected: a draft PR URL on `frankxue831/frankxue831.github.io` with base `main` and head `codex/fix-zh-prose-audit-batch-2`.
