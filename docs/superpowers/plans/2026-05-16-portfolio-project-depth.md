# Portfolio Project Depth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the portfolio project section production-worthy by adding public-source-aware metadata, refreshing project summaries, and creating detail pages for RepoLens and ghrunners.

**Architecture:** Keep the existing static Jekyll structure. Add `_data/projects.yml` for repeated metadata only, then use it where home/project-index facts currently drift. Keep long-form EN/ZH detail copy as hand-written pages so the site's current editorial voice stays intact.

**Tech Stack:** Jekyll, Liquid, YAML data files, hand-written HTML, custom CSS in `assets/css/style.css`, vanilla JS unchanged.

---

## Scope Check

This plan covers one subsystem: the portfolio project section. It intentionally excludes contact/email, notes/blog, visual redesign, and any claim based only on untagged local branch state.

## File Structure

- Create `_data/projects.yml`: shared project metadata for `gm-crypto-rs`, `repolens-rs`, and `ghrunners`.
- Modify `index.html`: render featured project facts from `_data/projects.yml` and link to internal detail pages when available.
- Modify `zh/index.html`: Chinese mirror of the home-page project summaries.
- Modify `projects.html`: render all three project summaries from metadata, with detail links for every project.
- Modify `zh/projects.html`: Chinese mirror of the project index.
- Modify `projects/gm-crypto-rs.html`: refresh shipped/next wording around the latest public tag.
- Modify `zh/projects/gm-crypto-rs.html`: Chinese mirror of the gm-crypto-rs refresh.
- Create `projects/repolens-rs.html`: English detail page.
- Create `zh/projects/repolens-rs.html`: Chinese detail page.
- Create `projects/ghrunners.html`: English detail page.
- Create `zh/projects/ghrunners.html`: Chinese detail page.
- Modify `_data/i18n.yml` only if implementation introduces shared labels through an include. Avoid it if all new labels stay page-local.
- Do not commit untracked `CLAUDE.md` unless the user explicitly asks.

---

### Task 1: Re-Verify Public Source State

**Files:**
- Read: `../gm-crypto-rs`
- Read: `../repolens-rs`
- Read: `../ghrunners`
- No site files changed in this task.

- [ ] **Step 1: Confirm the site worktree is clean except known untracked files**

Run:

```bash
git status --short --branch
```

Expected today:

```text
## main...origin/main [ahead 3]
untracked: CLAUDE.md
```

If other modified/tracked files appear, stop and inspect before editing.

- [ ] **Step 2: Verify gm-crypto-rs public tags and main**

Run:

```bash
git -C ../gm-crypto-rs ls-remote --tags origin
git -C ../gm-crypto-rs ls-remote origin HEAD refs/heads/main
curl -I -L https://github.com/frankxue831/gm-crypto-rs
```

Expected on 2026-05-16: latest public tag is `v0.7.0`, public `origin/main` points at the `v0.7.0` commit, and unauthenticated visitor access to the GitHub web URL returns HTTP 404 from this environment.

If a newer public tag appears, update all `gm-crypto-rs` metadata and copy to that newer tag. Only mention untagged newer work under `Next` / `下一步`. If the GitHub web URL still returns HTTP 404 for visitors, keep `repo_url` empty, set `public_source: false`, and omit the detail-page source link while retaining public crate/docs links.

- [ ] **Step 3: Verify repolens-rs main state and visitor visibility**

Run:

```bash
git -C ../repolens-rs ls-remote --tags origin
git -C ../repolens-rs ls-remote origin HEAD refs/heads/main
curl -I -L https://github.com/frankxue831/repolens-rs
```

Expected on 2026-05-16: authenticated `origin/main` exists, tags are milestone tags rather than semver releases, the main SHA short label is `afd7a6b`, and unauthenticated visitor access to the GitHub URL returns HTTP 404.

If a semver release tag exists and the repository is visitor-public by implementation time, use `status: released` and `release_source: public_tag`. If the repository becomes visitor-public without a semver release tag, use `status: public-pre-release`, `release_source: public_main`, the public repo URL, and `public_source: true`. Otherwise use `status: private-pre-release`, `release_source: private_main`, `release: "origin/main @ <7-char-sha>"`, empty `repo_url`, and `public_source: false`.

- [ ] **Step 4: Verify ghrunners local/private state**

Run:

```bash
git -C ../ghrunners tag --sort=-creatordate
git ls-remote https://github.com/frankxue831/ghrunners.git HEAD refs/heads/main refs/heads/master
```

Expected on 2026-05-16: local latest tag is `v0.1.1`; public GitHub lookup returns repository not found.

If the repository becomes publicly reachable by implementation time, use the public repo URL and `public_source: true`. Otherwise omit `repo_url` and keep `public_source: false`.

- [ ] **Step 5: Record source-state result in the task commit message later**

Use the verified labels from this task in `_data/projects.yml`. No commit yet; this task only establishes source facts.

---

### Task 2: Add Project Metadata

**Files:**
- Create: `_data/projects.yml`
- Test: `bundle exec jekyll build`

- [ ] **Step 1: Create `_data/projects.yml` with verified metadata**

Use this exact shape if Task 1 results match the 2026-05-16 snapshot:

```yaml
- slug: gm-crypto-rs
  title: gm-crypto-rs
  years:
    en: "2025 - now"
    zh: "2025 - 至今"
  tags:
    en: ["Rust", "Cryptography", "no_std"]
    zh: ["Rust", "密码学", "no_std"]
  status: released
  status_label:
    en: "Released"
    zh: "已发布"
  release: "v0.7.0"
  release_source: public_tag
  repo_url:
  crate_url: "https://crates.io/crates/gmcrypto-core"
  docs_url: "https://docs.rs/gmcrypto-core"
  detail_url: "/projects/gm-crypto-rs/"
  zh_detail_url: "/zh/projects/gm-crypto-rs/"
  public_source: false

- slug: repolens-rs
  title: RepoLens
  years:
    en: "2025 - now"
    zh: "2025 - 至今"
  tags:
    en: ["Rust", "MCP", "Agent tooling"]
    zh: ["Rust", "MCP", "Agent 工具"]
  status: private-pre-release
  status_label:
    en: "Private pre-release"
    zh: "私有预发布"
  release: "origin/main @ afd7a6b"
  release_source: private_main
  repo_url:
  crate_url:
  docs_url:
  detail_url: "/projects/repolens-rs/"
  zh_detail_url: "/zh/projects/repolens-rs/"
  public_source: false

- slug: ghrunners
  title: ghrunners
  years:
    en: "2026"
    zh: "2026"
  tags:
    en: ["Rust", "CLI", "macOS"]
    zh: ["Rust", "CLI", "macOS"]
  status: private-local
  status_label:
    en: "Private/local"
    zh: "本地/私有"
  release: "local tag v0.1.1"
  release_source: local_tag
  repo_url:
  crate_url:
  docs_url:
  detail_url: "/projects/ghrunners/"
  zh_detail_url: "/zh/projects/ghrunners/"
  public_source: false
```

- [ ] **Step 2: Build to verify YAML parses**

Run:

```bash
bundle exec jekyll build
```

Expected: build exits `0`.

- [ ] **Step 3: Commit metadata**

Run:

```bash
git add _data/projects.yml
git commit -m "feat: add project metadata"
```

Expected: commit includes only `_data/projects.yml`.

---

### Task 3: Update Home Page Project Summaries

**Files:**
- Modify: `index.html`
- Modify: `zh/index.html`
- Test: `bundle exec jekyll build`

- [ ] **Step 1: Update English home selected-work rows to use metadata**

In `index.html`, replace the three hard-coded `<a class="work-list__row">` rows inside the `Selected work` section with this Liquid-driven version:

```liquid
{% assign projects = site.data.projects %}
{% for project in projects %}
<li class="work-list__item">
    <a class="work-list__row"
       href="{{ project.detail_url | relative_url }}">
        <span class="work-list__year">{{ project.years.en }}</span>
        <span class="work-list__title"><em>{{ project.title }}</em></span>
        <span class="work-list__tags">{{ project.tags.en | join: ' · ' }}</span>
    </a>
</li>
{% endfor %}
```

Keep the section title and `See all work` link unchanged.

- [ ] **Step 2: Update Chinese home selected-work rows to use metadata**

In `zh/index.html`, replace the three hard-coded rows inside the `作品` section with:

```liquid
{% assign projects = site.data.projects %}
{% for project in projects %}
<li class="work-list__item">
    <a class="work-list__row"
       href="{{ project.zh_detail_url | relative_url }}">
        <span class="work-list__year">{{ project.years.zh }}</span>
        <span class="work-list__title"><em>{{ project.title }}</em></span>
        <span class="work-list__tags">{{ project.tags.zh | join: ' · ' }}</span>
    </a>
</li>
{% endfor %}
```

- [ ] **Step 3: Build and inspect generated home links**

Run:

```bash
bundle exec jekyll build
rg -n 'href="/projects/(gm-crypto-rs|repolens-rs|ghrunners)/"|href="/zh/projects/(gm-crypto-rs|repolens-rs|ghrunners)/"' _site/index.html _site/zh/index.html
```

Expected: all three English detail links and all three Chinese detail links appear.

- [ ] **Step 4: Commit home summary update**

Run:

```bash
git add index.html zh/index.html
git commit -m "feat: render home project summaries from metadata"
```

Expected: commit includes only `index.html` and `zh/index.html`.

---

### Task 4: Update Project Index Pages

**Files:**
- Modify: `projects.html`
- Modify: `zh/projects.html`
- Test: `bundle exec jekyll build`

- [ ] **Step 1: Replace English project index list with metadata-backed rows and hand-written notes**

In `projects.html`, keep the page header. Replace the `<ul class="work-list">...</ul>` body with this structure:

```liquid
{% assign projects = site.data.projects %}
{% for project in projects %}
<li class="work-list__item">
    <a class="work-list__row"
       href="{{ project.detail_url | relative_url }}">
        <span class="work-list__year">{{ project.years.en }}</span>
        <span class="work-list__title"><em>{{ project.title }}</em></span>
        <span class="work-list__tags">{{ project.tags.en | join: ' · ' }}</span>
    </a>
    {% case project.slug %}
    {% when 'gm-crypto-rs' %}
    <p class="work-list__note">
        Pure-Rust SM2 / SM3 / SM4 SDK for the Chinese national crypto
        standards. Public {{ project.release }} adds the user-callable
        SM4 cipher-mode surface: length-flexible batch encryption/decryption,
        single-shot SM4-CTR, streaming SM4-CTR, and a new
        <code>dudect-bencher</code> target for CTR encryption. Next work is
        AEAD: SM4-GCM and SM4-CCM.
        <a href="{{ project.detail_url | relative_url }}" class="work-list__more">Read more →</a>
    </p>
    {% when 'repolens-rs' %}
    <p class="work-list__note">
        Agent-facing repository memory and context layer. It scans repos into
        structured packs, exposes 26 MCP tools, and pairs them with typed,
        decaying memory. Status: {{ project.release }}; shipped surfaces are
        real, while some memory-safety schema work remains planned.
        <a href="{{ project.detail_url | relative_url }}" class="work-list__more">Read more →</a>
    </p>
    {% when 'ghrunners' %}
    <p class="work-list__note">
        One-shot, read-only observability CLI for GitHub Actions self-hosted
        runners on macOS. It discovers runner plists, launchd state, process
        state, logs, and optional GitHub API status, then reports typed
        findings. Status: {{ project.release }}; source is private/local for now.
        <a href="{{ project.detail_url | relative_url }}" class="work-list__more">Read more →</a>
    </p>
    {% endcase %}
</li>
{% endfor %}
```

- [ ] **Step 2: Replace Chinese project index list with metadata-backed rows and hand-written notes**

In `zh/projects.html`, keep the page header. Replace the `<ul class="work-list">...</ul>` body with:

```liquid
{% assign projects = site.data.projects %}
{% for project in projects %}
<li class="work-list__item">
    <a class="work-list__row"
       href="{{ project.zh_detail_url | relative_url }}">
        <span class="work-list__year">{{ project.years.zh }}</span>
        <span class="work-list__title"><em>{{ project.title }}</em></span>
        <span class="work-list__tags">{{ project.tags.zh | join: ' · ' }}</span>
    </a>
    {% case project.slug %}
    {% when 'gm-crypto-rs' %}
    <p class="work-list__note">
        国密 SM2 / SM3 / SM4 的纯 Rust SDK。公开的 {{ project.release }}
        把 v0.6 的 SM4 SIMD 能力推到用户可直接调用的密码模式表面:
        批量分组加解密、单次 SM4-CTR、流式 SM4-CTR,以及 CTR 加密的
        <code>dudect-bencher</code> 门控。下一步是 AEAD:
        SM4-GCM 和 SM4-CCM。
        <a href="{{ project.zh_detail_url | relative_url }}" class="work-list__more">继续读 →</a>
    </p>
    {% when 'repolens-rs' %}
    <p class="work-list__note">
        给编程 Agent 用的仓库记忆和上下文层。它把仓库扫成结构化 pack,
        通过 26 个 MCP 工具暴露给 Agent,再配上类型化、会随时间衰减的记忆。
        状态:{{ project.release }}; 已有表面是真的,部分记忆安全 schema 仍在规划中。
        <a href="{{ project.zh_detail_url | relative_url }}" class="work-list__more">继续读 →</a>
    </p>
    {% when 'ghrunners' %}
    <p class="work-list__note">
        macOS 上 GitHub Actions self-hosted runner 的一次性只读观测 CLI。
        它发现 runner plist、launchd 状态、进程状态、日志和可选 GitHub API
        状态,再输出类型化 findings。状态:{{ project.release }};
        目前源码仍是本地/私有。
        <a href="{{ project.zh_detail_url | relative_url }}" class="work-list__more">继续读 →</a>
    </p>
    {% endcase %}
</li>
{% endfor %}
```

- [ ] **Step 3: Build and inspect project index links**

Run:

```bash
bundle exec jekyll build
rg -n 'Read more|继续读|repolens-rs|ghrunners' _site/projects/index.html _site/zh/projects/index.html
```

Expected: both project index pages contain all three detail links and no external `ghrunners` GitHub link.

- [ ] **Step 4: Commit project index update**

Run:

```bash
git add projects.html zh/projects.html
git commit -m "feat: expand project index summaries"
```

Expected: commit includes only `projects.html` and `zh/projects.html`.

---

### Task 5: Refresh gm-crypto-rs Detail Pages

**Files:**
- Modify: `projects/gm-crypto-rs.html`
- Modify: `zh/projects/gm-crypto-rs.html`
- Test: `bundle exec jekyll build`

- [ ] **Step 1: Update English gm-crypto-rs status language**

In `projects/gm-crypto-rs.html`, update the Status `<dl class="version-grid">` so the shipped/current rows match the verified latest public tag. If Task 1 still confirms `v0.7.0`, use:

```html
<dt>v0.7.0</dt>
<dd>Shipped publicly — public batch APIs, single-shot SM4-CTR, streaming SM4-CTR, and the <code>ct_sm4_ctr_encrypt</code> dudect target.</dd>

<dt>Next</dt>
<dd>AEAD — SM4-GCM and SM4-CCM, plus GHASH work and dedicated detectable-leak regression targets. This is planned work, not part of v0.7.0.</dd>
```

Remove any wording that says `v0.7.0` is still in flight. If Task 1 still
shows the GitHub web URL returning HTTP 404, omit the public source link from
the detail-page link list.

- [ ] **Step 2: Ensure English gm-crypto-rs has the five editorial sections**

Keep or rename sections so the detail page contains, in order:

```html
<h2>What it is</h2>
<h2>What is shipped</h2>
<h2>What's different about it</h2>
<h2>Next</h2>
<h2>What it isn't</h2>
```

Keep the existing `Safety posture` material, but place it under `What's different about it` or immediately after it. Do not use absolute `constant-time` claims.

- [ ] **Step 3: Update Chinese gm-crypto-rs status language**

In `zh/projects/gm-crypto-rs.html`, update the Status grid to mirror the English meaning. If Task 1 still confirms `v0.7.0`, use:

```html
<dt>v0.7.0</dt>
<dd>已公开发布 — 批量分组 API、单次 SM4-CTR、流式 SM4-CTR,以及 <code>ct_sm4_ctr_encrypt</code> dudect 目标。</dd>

<dt>下一步</dt>
<dd>AEAD — SM4-GCM 和 SM4-CCM,再加 GHASH 工作和专门的泄漏检测回归目标。这是下一步,不是已发布功能。</dd>
```

- [ ] **Step 4: Ensure Chinese gm-crypto-rs has localized editorial sections**

Keep or rename sections so the Chinese detail page contains, in order:

```html
<h2>是什么</h2>
<h2>已经发布了什么</h2>
<h2>跟其他实现差在哪儿</h2>
<h2>下一步</h2>
<h2>它不是什么</h2>
```

- [ ] **Step 5: Build and verify next-work placement**

Run:

```bash
bundle exec jekyll build
rg -n 'v0\\.7\\.0|v0\\.8|AEAD|SM4-GCM|SM4-CCM|Next|下一步' _site/projects/gm-crypto-rs/index.html _site/zh/projects/gm-crypto-rs/index.html
```

Expected: `v0.7.0` appears as shipped/released; `v0.8`, `AEAD`, `SM4-GCM`, and `SM4-CCM` appear only under `Next` / `下一步`.

- [ ] **Step 6: Commit gm-crypto-rs refresh**

Run:

```bash
git add projects/gm-crypto-rs.html zh/projects/gm-crypto-rs.html
git commit -m "feat: refresh gm-crypto-rs project detail"
```

Expected: commit includes only the two gm-crypto-rs detail pages.

---

### Task 6: Add RepoLens Detail Pages

**Files:**
- Create: `projects/repolens-rs.html`
- Create: `zh/projects/repolens-rs.html`
- Test: `bundle exec jekyll build`

- [ ] **Step 1: Create English RepoLens detail page**

Create `projects/repolens-rs.html` with this front matter and section structure:

```html
---
layout: default
title: "RepoLens"
description: RepoLens is an agent-facing repository memory and context layer for AI coding agents.
permalink: /projects/repolens-rs/
lang: en
alternate: /zh/projects/repolens-rs/
---

<section class="page-header wrap">
    <p class="page-header__eyebrow">(02)  Work / Detail</p>
    <h1 class="page-header__title"><em>RepoLens</em></h1>
    <p class="page-header__lede">
        An agent-facing repository memory and context layer that helps
        coding agents recover project understanding across sessions.
    </p>
</section>

<section class="section wrap">
    <article class="project-detail prose">
        <h2>What it is</h2>
        <p>
            <code>RepoLens</code> scans a repository into structured packs,
            exposes that model through an MCP server, and pairs it with a
            typed, decaying memory graph. The goal is not to write code for
            the agent. The goal is to stop every new session from starting
            cold.
        </p>

        <h2>What is shipped</h2>
        <p>
            Private pre-release snapshot: <code>origin/main @ afd7a6b</code>
            unless Task 1 verifies a newer private snapshot or visitor-public
            repository. The shipped surface includes repo scanning, 26 MCP
            tools, tiered summaries, convention extraction, pack comparison,
            grounded long-term memory recall, <code>repolens init</code>,
            <code>brief</code>, <code>remember</code>,
            <code>eval list/start</code>, and warnings-only
            <code>validate-plan</code>.
        </p>

        <h2>What's different about it</h2>
        <p>
            RepoLens treats repository understanding as structured perception,
            not as a bigger prompt dump. Memories have types, anchors, decay,
            and grounding status; tool responses carry epistemic metadata so
            an agent can see whether it is reading observation, heuristic, or
            interpretation.
        </p>

        <h2>Next</h2>
        <p>
            The planned v0.1 direction is agent legibility and memory safety:
            richer memory types such as hypotheses, constraints, failed
            attempts, and friction findings, plus explicit confidence labels.
            Those pieces should be described as planned until they ship in a
            visitor-public release or verified main snapshot.
        </p>

        <h2>What it isn't</h2>
        <ul>
            <li>Not an autonomous coding agent.</li>
            <li>Not a replacement for tests or human review.</li>
            <li>Not a generic RAG store.</li>
            <li>Not multi-repo or org-wide memory today.</li>
            <li>Not a guarantee that recalled memory is correct.</li>
        </ul>

        <div class="project-detail__links">
            <a href="{{ '/projects/' | relative_url }}">← All work</a>
        </div>
    </article>
</section>
```

If Task 1 verifies a different authenticated `origin/main` short SHA, replace `afd7a6b` before committing.

- [ ] **Step 2: Create Chinese RepoLens detail page**

Create `zh/projects/repolens-rs.html` with the same meaning:

```html
---
layout: default
title: "RepoLens"
description: RepoLens 是给 AI 编程 Agent 用的仓库记忆和上下文层。
permalink: /zh/projects/repolens-rs/
lang: zh
alternate: /projects/repolens-rs/
---

<section class="page-header wrap">
    <p class="page-header__eyebrow">(02)  作品 / 详情</p>
    <h1 class="page-header__title"><em>RepoLens</em></h1>
    <p class="page-header__lede">
        给编程 Agent 用的仓库记忆和上下文层,让新的 session
        不必每次都从零开始理解项目。
    </p>
</section>

<section class="section wrap">
    <article class="project-detail prose">
        <h2>是什么</h2>
        <p>
            <code>RepoLens</code> 把仓库扫描成结构化 pack,
            通过 MCP server 暴露给 Agent,再配上类型化、会随时间衰减的记忆图。
            它不是替 Agent 写代码,而是给 Agent 一个更稳定的项目理解起点。
        </p>

        <h2>已经发布了什么</h2>
        <p>
            私有预发布快照:<code>origin/main @ afd7a6b</code>,
            除非 Task 1 验证到更新的私有快照或访客可访问的公开仓库。已经可用的表面包括仓库扫描、
            26 个 MCP 工具、分层摘要、约定提取、pack 对比、有 grounding
            状态的长期记忆召回,以及 <code>repolens init</code>、
            <code>brief</code>、<code>remember</code>、
            <code>eval list/start</code> 和只给 warning 的
            <code>validate-plan</code>。
        </p>

        <h2>跟别的工具差在哪儿</h2>
        <p>
            RepoLens 把仓库理解当成结构化感知来做,不是把更多文件塞进提示词。
            记忆有类型、anchor、衰减和 grounding 状态;工具响应也带 epistemic
            元数据,让 Agent 知道自己看到的是观察、启发式判断,还是解释。
        </p>

        <h2>下一步</h2>
        <p>
            v0.1 的方向是 Agent 可读性和记忆安全:更丰富的记忆类型,
            比如 hypothesis、constraint、failed attempt、friction finding,
            以及明确的 confidence 标签。这些在访客可访问的公开 release
            或已验证 main 快照落地之前,都应该写成规划中。
        </p>

        <h2>它不是什么</h2>
        <ul>
            <li>不是自动写代码的 Agent。</li>
            <li>不能替代测试或人工 review。</li>
            <li>不是通用 RAG 存储。</li>
            <li>今天还不是多仓库或组织级记忆。</li>
            <li>不保证召回出来的记忆一定正确。</li>
        </ul>

        <div class="project-detail__links">
            <a href="{{ '/zh/projects/' | relative_url }}">← 全部作品</a>
        </div>
    </article>
</section>
```

- [ ] **Step 3: Build and verify RepoLens pages exist**

Run:

```bash
bundle exec jekyll build
test -f _site/projects/repolens-rs/index.html
test -f _site/zh/projects/repolens-rs/index.html
rg -n 'Private pre-release|私有预发布|origin/main @' _site/projects/repolens-rs/index.html _site/zh/projects/repolens-rs/index.html
! rg -n "github\\.com/frankxue831/repolens-rs" _site/projects/repolens-rs/index.html _site/zh/projects/repolens-rs/index.html
```

Expected: both files exist, both pages show the private-pre-release label, and neither page shows a public RepoLens source link.

- [ ] **Step 4: Commit RepoLens pages**

Run:

```bash
git add projects/repolens-rs.html zh/projects/repolens-rs.html
git commit -m "feat: add repolens project detail"
```

Expected: commit includes only the two RepoLens detail pages.

---

### Task 7: Add ghrunners Detail Pages

**Files:**
- Create: `projects/ghrunners.html`
- Create: `zh/projects/ghrunners.html`
- Test: `bundle exec jekyll build`

- [ ] **Step 1: Create English ghrunners detail page**

Create `projects/ghrunners.html`:

```html
---
layout: default
title: "ghrunners"
description: ghrunners is a read-only observability CLI for GitHub Actions self-hosted runners on macOS.
permalink: /projects/ghrunners/
lang: en
alternate: /zh/projects/ghrunners/
---

<section class="page-header wrap">
    <p class="page-header__eyebrow">(02)  Work / Detail</p>
    <h1 class="page-header__title"><em>ghrunners</em></h1>
    <p class="page-header__lede">
        A one-shot, read-only observability CLI for GitHub Actions
        self-hosted runners on macOS.
    </p>
</section>

<section class="section wrap">
    <article class="project-detail prose">
        <h2>What it is</h2>
        <p>
            <code>ghrunners</code> checks the local Mac for GitHub Actions
            self-hosted runner installs, launchd state, process state, logs,
            and optional GitHub API status. It reports the result as a quiet
            table or JSON, with typed findings when something looks wrong.
        </p>

        <h2>What is shipped</h2>
        <p>
            Local/private status: <code>local tag v0.1.1</code>, unless
            Task 1 verifies a newer local tag or a newly public repository.
            The shipped CLI includes <code>status</code>, <code>describe</code>,
            and <code>logs</code>; API enrichment is opt-in via
            <code>--api</code>.
        </p>

        <h2>What's different about it</h2>
        <p>
            The tool is deliberately read-only and partial-output friendly.
            Permission-denied paths become row-level findings instead of
            fatal errors, and missing sudo or missing GitHub API access is
            reflected in provenance rather than hidden.
        </p>

        <h2>Next</h2>
        <p>
            Public source link comes after the repository is reachable. Control
            verbs such as start, stop, and restart are outside the current
            shipped scope.
        </p>

        <h2>What it isn't</h2>
        <ul>
            <li>Not a runner installer or unregister tool.</li>
            <li>Not a daemon or persistent monitor.</li>
            <li>Not Linux or Windows tooling.</li>
            <li>Not fleet management.</li>
            <li>Not a public-source project until the repository is reachable.</li>
        </ul>

        <div class="project-detail__links">
            <a href="{{ '/projects/' | relative_url }}">← All work</a>
        </div>
    </article>
</section>
```

Do not add a GitHub source link unless Task 1 verifies the repository is public.

- [ ] **Step 2: Create Chinese ghrunners detail page**

Create `zh/projects/ghrunners.html`:

```html
---
layout: default
title: "ghrunners"
description: ghrunners 是 macOS 上 GitHub Actions self-hosted runner 的只读观测 CLI。
permalink: /zh/projects/ghrunners/
lang: zh
alternate: /projects/ghrunners/
---

<section class="page-header wrap">
    <p class="page-header__eyebrow">(02)  作品 / 详情</p>
    <h1 class="page-header__title"><em>ghrunners</em></h1>
    <p class="page-header__lede">
        macOS 上 GitHub Actions self-hosted runner 的一次性、只读观测 CLI。
    </p>
</section>

<section class="section wrap">
    <article class="project-detail prose">
        <h2>是什么</h2>
        <p>
            <code>ghrunners</code> 会检查本机 Mac 上的 GitHub Actions
            self-hosted runner 安装、launchd 状态、进程状态、日志,
            以及可选的 GitHub API 状态。输出可以是安静的表格,
            也可以是 JSON;异常会落成类型化 findings。
        </p>

        <h2>已经发布了什么</h2>
        <p>
            本地/私有状态:<code>local tag v0.1.1</code>,
            除非 Task 1 验证到更新的本地 tag 或公开仓库。已经有的 CLI 包括
            <code>status</code>、<code>describe</code> 和 <code>logs</code>;
            GitHub API 增强通过 <code>--api</code> 显式开启。
        </p>

        <h2>跟别的工具差在哪儿</h2>
        <p>
            它刻意只读,也刻意允许部分输出。权限不足的路径会变成单行 finding,
            而不是让整个命令失败;缺 sudo 或缺 GitHub API 权限也会体现在来源信息里,
            不会被藏起来。
        </p>

        <h2>下一步</h2>
        <p>
            等仓库可以公开访问以后再加源码链接。start、stop、restart
            这类控制命令不属于当前已发布范围。
        </p>

        <h2>它不是什么</h2>
        <ul>
            <li>不是 runner 安装或注销工具。</li>
            <li>不是 daemon 或持续监控器。</li>
            <li>不支持 Linux 或 Windows。</li>
            <li>不是 fleet 管理工具。</li>
            <li>在仓库可公开访问前,它不是公开源码项目。</li>
        </ul>

        <div class="project-detail__links">
            <a href="{{ '/zh/projects/' | relative_url }}">← 全部作品</a>
        </div>
    </article>
</section>
```

- [ ] **Step 3: Build and verify ghrunners pages exist without public source link**

Run:

```bash
bundle exec jekyll build
test -f _site/projects/ghrunners/index.html
test -f _site/zh/projects/ghrunners/index.html
! rg -n "github\\.com/frankxue831/(ghrunners|repolens-rs)" _site
rg -n 'local tag v0\\.1\\.1|本地/私有' _site/projects/ghrunners/index.html _site/zh/projects/ghrunners/index.html
```

Expected: both pages exist; no generated page links to `github.com/frankxue831/ghrunners`.

- [ ] **Step 4: Commit ghrunners pages**

Run:

```bash
git add projects/ghrunners.html zh/projects/ghrunners.html
git commit -m "feat: add ghrunners project detail"
```

Expected: commit includes only the two ghrunners detail pages.

---

### Task 8: Final Validation And Polish

**Files:**
- Review all changed implementation files.
- Do not modify docs/specs or docs/plans in this task unless a validation failure reveals a plan/spec typo.

- [ ] **Step 1: Run Jekyll checks**

Run:

```bash
bundle exec jekyll doctor
bundle exec jekyll build
```

Expected: both commands exit `0`. The Faraday retry middleware warning is acceptable if it is the only warning.

- [ ] **Step 2: Run generated-page existence checks**

Run:

```bash
test -f _site/projects/gm-crypto-rs/index.html
test -f _site/projects/repolens-rs/index.html
test -f _site/projects/ghrunners/index.html
test -f _site/zh/projects/gm-crypto-rs/index.html
test -f _site/zh/projects/repolens-rs/index.html
test -f _site/zh/projects/ghrunners/index.html
```

Expected: all commands exit `0`.

- [ ] **Step 3: Run content-safety checks**

Run:

```bash
! rg -n "github\\.com/frankxue831/ghrunners" _site
! rg -n "\\b(production-ready|guaranteed|secure)\\b" _site/projects _site/zh/projects
rg -n 'Next|下一步|v0\\.8|AEAD|SM4-GCM|SM4-CCM' _site/projects/gm-crypto-rs/index.html _site/zh/projects/gm-crypto-rs/index.html
```

Expected:
- No generated `ghrunners` or `repolens-rs` public source link while those
  repos are private.
- No forbidden broad claims in project pages.
- Any `v0.8`, `AEAD`, `SM4-GCM`, or `SM4-CCM` occurrences are visibly under `Next` / `下一步`.

- [ ] **Step 4: Inspect metadata-driven links**

Run:

```bash
rg -n '/projects/(gm-crypto-rs|repolens-rs|ghrunners)/|/zh/projects/(gm-crypto-rs|repolens-rs|ghrunners)/' _site/index.html _site/zh/index.html _site/projects/index.html _site/zh/projects/index.html
```

Expected: home and project-index pages link to all three detail pages in their own language.

- [ ] **Step 5: Review git diff**

Run:

```bash
git diff --stat HEAD
git diff HEAD -- _data/projects.yml index.html zh/index.html projects.html zh/projects.html projects/gm-crypto-rs.html zh/projects/gm-crypto-rs.html projects/repolens-rs.html zh/projects/repolens-rs.html projects/ghrunners.html zh/projects/ghrunners.html
```

Expected: diffs are limited to portfolio project-depth implementation files. `CLAUDE.md` remains untracked unless explicitly requested.

- [ ] **Step 6: Commit final validation fixes if any**

If Task 8 required any edits, run:

```bash
git add _data/projects.yml index.html zh/index.html projects.html zh/projects.html projects/gm-crypto-rs.html zh/projects/gm-crypto-rs.html projects/repolens-rs.html zh/projects/repolens-rs.html projects/ghrunners.html zh/projects/ghrunners.html
git commit -m "fix: polish portfolio project pages"
```

Expected: no commit is created if Task 8 required no edits.

---

## Self-Review Checklist

- Spec coverage:
  - Source-of-truth verification: Task 1.
  - `_data/projects.yml` schema: Task 2.
  - Home and project index summaries: Tasks 3 and 4.
  - `gm-crypto-rs` shipped/next correction: Task 5.
  - RepoLens detail pages without public source link while private: Task 6.
  - ghrunners detail pages without public source link: Task 7.
  - Build, existence, unreachable-link, overclaim, and next-section checks: Task 8.
- Placeholder scan: this plan contains no unresolved placeholder markers or unspecified implementation steps.
- Type consistency:
  - Metadata fields match the design spec: `slug`, `title`, `years`, `tags`, `status`, `status_label`, `release`, `release_source`, `repo_url`, `crate_url`, `docs_url`, `detail_url`, `zh_detail_url`, `public_source`.
  - `status` values are `released`, `public-pre-release`,
    `private-pre-release`, and `private-local`.
  - `release_source` values are `public_tag`, `public_main`, `private_main`,
    and `local_tag`.
