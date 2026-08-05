# Content Expression Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the gm-crypto-rs release history onto its own page, reframe the notes surface, and consolidate the site's entry-point copy — per `docs/superpowers/specs/2026-08-05-content-expression-design.md`.

**Architecture:** Pure content and template work on a Jekyll static site. Two new pages (EN + ZH mirror), edits to six existing pages, and three guard changes in the post-build validator. No CSS, no JS, no new components, no data-model change.

**Tech Stack:** Jekyll (github-pages gem), Liquid templates, hand-written CSS (untouched here), `scripts/validate_site.rb` as the only test harness.

## Global Constraints

- **Build + test invocation** (system Ruby 2.6 needs a user-installed bundler and a UTF-8 locale, or both the build and the validator fail):
  ```bash
  export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH" LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
  bundle exec jekyll build
  ruby scripts/validate_site.rb
  ```
  Success output is exactly `Site validation passed`. Baseline confirmed green at 2026-08-05 before this plan was written.
- **Claims parity, native voice.** Every change lands on the EN page and its ZH mirror **in the same commit**. Disclosures, hedges, numbers, and framing stance match exactly; register stays natively Chinese. Avoid future-promising hedges (暂时 / 尚未 / 等…再) where EN states present fact.
- **Source-of-truth rule.** No version number, release claim, or shipped-feature statement changes in this work. Release copy is *moved*, never restated. Do not invent a referent for a claim that does not have one in the source text.
- **No design-system change.** No new tokens, colors, components, or CSS. Reuse only existing classes: `page-header`, `page-header__eyebrow`, `page-header__title`, `page-header__lede`, `section`, `wrap`, `reveal`, `project-detail`, `prose`, `version-grid`, `drawer`, `project-detail__links`.
- **CSP unchanged.** No new JS, no inline scripts, no inline `style=` attributes, no external origins.
- **Permalinks are `pretty`.** Internal links use trailing-slash paths (`/projects/gm-crypto-rs/releases/`), never `.html`.
- **Do not add the new pages to `project_pages`** (`scripts/validate_site.rb:188`). That list requires `SoftwareSourceCode` JSON-LD, a `project-summary` include, and a `data-toc-label` body attribute — none of which a release-history page needs.

---

### Task 1: Split the gm-crypto-rs release history

**Files:**
- Create: `projects/gm-crypto-rs-releases.html`
- Create: `zh/projects/gm-crypto-rs-releases.html`
- Modify: `projects/gm-crypto-rs.html:214-299` (replace)
- Modify: `zh/projects/gm-crypto-rs.html:211-295` (replace)
- Modify: `scripts/validate_site.rb` — `core_pages` hash (after the `zh/notes/index.html` entry ending at line 171) and the two `version_before` guards (lines 566 and 577)
- Test: `scripts/validate_site.rb` (whole-site validator; there is no unit-test suite)

**Interfaces:**
- Produces: two new permalinks that Task 2 and Task 3 do not touch — `/projects/gm-crypto-rs/releases/` and `/zh/projects/gm-crypto-rs/releases/`.
- Consumes: the existing `site.data.i18n[page.lang].details.earlier_releases` key (EN: `"Earlier releases (v0.6.0 – v0.13.0)"`, ZH: `"更早的版本（v0.6.0 – v0.13.0）"`). This key stays in `_data/i18n.yml` unchanged — the `<details>` drawer moves onto the releases page rather than disappearing, so the `validate_site.rb:732` guard remains valid.

- [ ] **Step 1: Branch off main**

```bash
git checkout -b content-expression
```

- [ ] **Step 2: Add the failing validator guards**

In `scripts/validate_site.rb`, insert into the `core_pages` hash immediately after the `zh/notes/index.html` entry (which closes at line 171):

```ruby
  "projects/gm-crypto-rs/releases/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/projects/gm-crypto-rs/releases/" },
      { hreflang: "en", href: "#{BASE_URL}/projects/gm-crypto-rs/releases/" },
      { hreflang: "x-default", href: "#{BASE_URL}/projects/gm-crypto-rs/releases/" }
    ]
  },
  "zh/projects/gm-crypto-rs/releases/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/projects/gm-crypto-rs/releases/" },
      { hreflang: "en", href: "#{BASE_URL}/projects/gm-crypto-rs/releases/" },
      { hreflang: "x-default", href: "#{BASE_URL}/projects/gm-crypto-rs/releases/" }
    ]
  },
```

- [ ] **Step 3: Run the validator to verify it fails**

```bash
export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH" LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
bundle exec jekyll build && ruby scripts/validate_site.rb
```

Expected: FAIL, with two missing-file errors naming `projects/gm-crypto-rs/releases/index.html` and `zh/projects/gm-crypto-rs/releases/index.html`.

- [ ] **Step 4: Create the EN releases page**

Create `projects/gm-crypto-rs-releases.html`:

```html
---
layout: default
title: "gm-crypto-rs — release history"
description: The full release line for gm-crypto-rs, v0.6.0 through v1.11.0, including the cycles that merged without a published version.
permalink: /projects/gm-crypto-rs/releases/
lang: en
alternate: /zh/projects/gm-crypto-rs/releases/
---

<section class="page-header wrap">
    <p class="page-header__eyebrow">(03)  Work / Detail</p>
    <h1 class="page-header__title">
        gm-crypto-rs <em>release history</em>
    </h1>
    <p class="page-header__lede">
        Every cycle from v0.6.0 to v1.11.0, newest first — including the ones
        that merged without a published version because they changed no output
        bytes. The case study is
        <a href="{{ '/projects/gm-crypto-rs/' | relative_url }}">here</a>.
    </p>
</section>

<section class="section wrap reveal">
    <article class="project-detail prose">
        <dl class="version-grid">
        <!-- v1.11.0 down to v0.14.0 — see Step 5 -->
        </dl>

        <details class="drawer">
            <summary>{{ site.data.i18n[page.lang].details.earlier_releases | escape }}</summary>
            <dl class="version-grid">
            <!-- v0.13.0 down to v0.6.0 — see Step 5 -->
            </dl>
        </details>

        <div class="project-detail__links">
            <a href="{{ '/projects/gm-crypto-rs/' | relative_url }}">← gm-crypto-rs</a>
            <a href="{{ '/projects/' | relative_url }}">← All work</a>
        </div>
    </article>
</section>
```

- [ ] **Step 5: Move the EN release entries in, newest-first**

Copy every `<dt>`/`<dd>` pair **verbatim** — no rewording, no renumbering, no fact changes — from `projects/gm-crypto-rs.html` into the new page, reordering to newest-first.

From the outer `<dl>` (source lines 248–299) into the new page's outer `<dl>`, in this exact order:

`v1.11.0, v1.10.0, v1.9.0, v1.8.0, v1.7.0, v1.6.0, v1.5.0, v1.4.0, v1.3.0, v1.2.0, v1.1.0, v1.0.1, v1.0.0, 0.17 – 0.23, v0.16.0, v0.15.0, v0.14.0`

From the `<details>` drawer (source lines 219–246) into the new page's drawer `<dl>`, in this exact order:

`v0.13.0, v0.12.0, v0.11.0, v0.10.0, v0.9.0, v0.8.0, v0.7.0, v0.6.0`

The four `<em>Not published.</em>` entries (v0.14.0, `0.17 – 0.23`, v1.5.0, v1.10.0) keep their wording exactly — they carry the release-discipline argument.

- [ ] **Step 6: Create the ZH releases page**

Create `zh/projects/gm-crypto-rs-releases.html`:

```html
---
layout: default
title: "gm-crypto-rs——版本线"
description: gm-crypto-rs 从 v0.6.0 到 v1.11.0 的完整版本线，包含那几轮没有发版、直接合进主干的周期。
permalink: /zh/projects/gm-crypto-rs/releases/
lang: zh
alternate: /projects/gm-crypto-rs/releases/
---

<section class="page-header wrap">
    <p class="page-header__eyebrow">(03)  作品 / 详情</p>
    <h1 class="page-header__title">
        gm-crypto-rs <em>版本线</em>
    </h1>
    <p class="page-header__lede">
        从 v0.6.0 到 v1.11.0 的每一轮，新的在上面——也包括那几轮因为没改动任何输出字节、
        所以没发版就合进主干的周期。案例页在
        <a href="{{ '/zh/projects/gm-crypto-rs/' | relative_url }}">这里</a>。
    </p>
</section>

<section class="section wrap reveal">
    <article class="project-detail prose">
        <dl class="version-grid">
        <!-- v1.11.0 down to v0.14.0 — copied verbatim from zh/projects/gm-crypto-rs.html:244-295 -->
        </dl>

        <details class="drawer">
            <summary>{{ site.data.i18n[page.lang].details.earlier_releases | escape }}</summary>
            <dl class="version-grid">
            <!-- v0.13.0 down to v0.6.0 — copied verbatim from zh/projects/gm-crypto-rs.html:215-242 -->
            </dl>
        </details>

        <div class="project-detail__links">
            <a href="{{ '/zh/projects/gm-crypto-rs/' | relative_url }}">← gm-crypto-rs</a>
            <a href="{{ '/zh/projects/' | relative_url }}">← 全部作品</a>
        </div>
    </article>
</section>
```

Move the ZH entries the same way: outer `<dl>` from source lines 244–295, drawer from source lines 215–242, both reordered newest-first using the same two version sequences as Step 5.

- [ ] **Step 7: Run the validator — hreflang guards should now pass**

```bash
export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH" LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
bundle exec jekyll build && ruby scripts/validate_site.rb
```

Expected: `Site validation passed`. At this point the release entries exist on **both** the case-study page and the releases page — the duplication is removed in the next step.

- [ ] **Step 8: Retarget the `version_before` guards to make the removal testable**

In `scripts/validate_site.rb`, change line 566 (EN entry) and line 577 (ZH entry):

```ruby
    caveat: "detection events", version_before: ["<h2>Next</h2>", "v1.11.0"],
```

```ruby
    caveat: "检测事件", version_before: ["<h2>下一步</h2>", "v1.11.0"],
```

- [ ] **Step 9: Replace the EN case-study release block**

In `projects/gm-crypto-rs.html`, replace lines **214–299** (the "version line below" `<p>`, the `<details>` drawer, and the outer `<dl>`) with:

```html
        <p>
            The release line carries deliberate gaps: a cycle that changes no
            output bytes merges without a published version.
            <a href="{{ '/notes/releases-that-change-nothing/' | relative_url }}">Why, in one note</a>.
        </p>
        <dl class="version-grid">
            <dt>Current</dt>
            <dd><strong>v1.11.0</strong>, 2026-08-01 — opt-in RustCrypto <code>aead</code> 0.6 trait fit for SM4-GCM / SM4-CCM. The C ABI surface stays 104 entry points.</dd>

            <dt>Unpublished</dt>
            <dd>Four cycles merged with no crates.io release — v0.14, 0.17–0.23, v1.5, v1.10 — because none of them changed an output byte.</dd>

            <dt>Full history</dt>
            <dd><a href="{{ '/projects/gm-crypto-rs/releases/' | relative_url }}">Every cycle from v0.6.0 →</a></dd>
        </dl>
```

Leave `{% include dudect-chart.html %}` (line 213) and everything above it untouched. Leave `<h2>Next</h2>` and its own `<dl class="version-grid">` untouched — that list is the forward-looking statement, not history.

- [ ] **Step 10: Replace the ZH case-study release block**

In `zh/projects/gm-crypto-rs.html`, replace lines **211–295** with:

```html
        <p>
            版本线上有刻意留下的缺口：一轮没改任何输出字节的工作，不发版，直接合进主干。
            <a href="{{ '/zh/notes/releases-that-change-nothing/' | relative_url }}">为什么，一篇笔记讲清</a>。
        </p>
        <dl class="version-grid">
            <dt>当前版本</dt>
            <dd><strong>v1.11.0</strong>，2026-08-01——SM4-GCM / SM4-CCM 的 RustCrypto <code>aead</code> 0.6 trait 适配（可选特性）。C ABI 仍是 104 个入口点。</dd>

            <dt>未发布</dt>
            <dd>有四轮合进了主干但没发到 crates.io——v0.14、0.17–0.23、v1.5、v1.10——因为它们都没改动任何输出字节。</dd>

            <dt>完整版本线</dt>
            <dd><a href="{{ '/zh/projects/gm-crypto-rs/releases/' | relative_url }}">从 v0.6.0 起的每一轮 →</a></dd>
        </dl>
```

Leave `{% include dudect-chart.html %}` (line 210) and everything above it untouched. Leave `<h2>下一步</h2>` and its `<dl class="version-grid">` (lines 297–301) untouched.

- [ ] **Step 11: Run the validator**

```bash
export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH" LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
bundle exec jekyll build && ruby scripts/validate_site.rb
```

Expected: `Site validation passed`.

- [ ] **Step 12: Verify the move was complete and lossless**

```bash
export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
echo -n "case-study words (want ~1650): "
ruby -e 'puts File.read("projects/gm-crypto-rs.html", encoding: "UTF-8").split.length'
echo -n "EN releases <dt> (want 25): "; grep -c "<dt>" projects/gm-crypto-rs-releases.html
echo -n "ZH releases <dt> (want 25): "; grep -c "<dt>" zh/projects/gm-crypto-rs-releases.html
grep -n "see Step 5\|copied verbatim from" \
     projects/gm-crypto-rs-releases.html zh/projects/gm-crypto-rs-releases.html \
  || echo "clean — no scaffold comments left"
```

Expected: `~1650`, `25`, `25`, `clean — no scaffold comments left`.

The source pages carry 17 outer entries plus 8 drawer entries per locale (verified 2026-08-05), so **25** is the lossless count. A lower number means entries were dropped in the reorder. If the word count is still above 2,000, the outer `<dl>` was not fully removed from the case study.

The scaffold-comment grep matters because the page templates in Steps 4 and 6 ship with HTML comments standing in for the entries; those comments must be replaced by real content, not left in the committed file.

- [ ] **Step 13: Commit**

```bash
git add projects/gm-crypto-rs.html projects/gm-crypto-rs-releases.html \
        zh/projects/gm-crypto-rs.html zh/projects/gm-crypto-rs-releases.html \
        scripts/validate_site.rb docs/superpowers/specs/2026-08-05-content-expression-design.md \
        docs/superpowers/plans/2026-08-05-content-expression.md
git commit -m "content: split gm-crypto-rs release history onto its own page

The version grid was 42% of the case-study page in both locales, sitting
between Evidence and Next. Move it to /projects/gm-crypto-rs/releases/
(newest-first) and leave a compact release-line block behind, so the
case study reads Evidence -> Next -> What it isn't as one movement.

Retargets the version_before validator guard from v1.2.0 to v1.11.0;
the guard's intent (release state stated under Evidence) is unchanged.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 2: Reframe the notes surface

**Files:**
- Modify: `notes.html:17-21` (lede)
- Modify: `zh/notes.html:17-20` (lede)
- Modify: `index.html:167-174` (section title + `limit`)
- Modify: `zh/index.html:159-165` (section title + `limit`)
- Test: `scripts/validate_site.rb`

**Interfaces:**
- Consumes: `/notes/constant-time-warrant/` and `/zh/notes/constant-time-warrant/`, which already exist (`_notes/constant-time-warrant.md`, `_notes/constant-time-warrant.zh.md`). The internal-link sweep will fail the build if either path is mistyped.
- Produces: nothing Task 3 depends on.

- [ ] **Step 1: Rewrite the EN notes lede**

In `notes.html`, replace lines 17–21:

```html
    <p class="page-header__lede">
        Short pieces working through a specific problem in the projects —
        what a claim would have to look like to be checkable, why a release
        that changes nothing still ships, what conformance actually means for
        a cipher. If you only read one, start with
        <a href="{{ '/notes/constant-time-warrant/' | relative_url }}">the one
        on constant-time claims</a>.
    </p>
```

The phrase "Nothing polished — just things worth writing down" is removed and must not come back.

- [ ] **Step 2: Rewrite the ZH notes lede**

In `zh/notes.html`, replace lines 17–20:

```html
    <p class="page-header__lede">
        每篇都在把项目里的一个具体问题想透：一个说法要长成什么样才算可核对、
        为什么一轮什么都没改的工作也值得单独交代、对一个分组密码来说「符合标准」到底指什么。
        只读一篇的话，从<a href="{{ '/zh/notes/constant-time-warrant/' | relative_url }}">讲常量时间说法的那篇</a>开始。
    </p>
```

- [ ] **Step 3: Widen and sharpen the EN home teaser**

In `index.html`, change the section title (line 168–170) from `Latest <em>notes.</em>` to:

```html
        <h2 id="writing-h" class="section__title">
            Working through <em>a problem.</em>
        </h2>
```

and change line 174 from `{%- for note in latest_notes limit: 2 -%}` to:

```liquid
        {%- for note in latest_notes limit: 3 -%}
```

- [ ] **Step 4: Widen and sharpen the ZH home teaser**

In `zh/index.html`, change the section title (line 159–161) from `最新的<em>笔记。</em>` to:

```html
        <h2 id="writing-h" class="section__title">
            把一个问题<em>想透。</em>
        </h2>
```

and change line 165 from `{%- for note in latest_notes limit: 2 -%}` to:

```liquid
        {%- for note in latest_notes limit: 3 -%}
```

- [ ] **Step 5: Run the validator**

```bash
export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH" LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
bundle exec jekyll build && ruby scripts/validate_site.rb
```

Expected: `Site validation passed`. The notes-index guard (`validate_site.rb:839`) requires `class="work-list__item` on both notes index pages — untouched by this task — and the home-page teaser guard (line 872) requires the `/notes/` and `/zh/notes/` links, which the section CTAs still carry.

- [ ] **Step 6: Confirm three notes render on the home page**

```bash
export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ruby -e 'h=File.read("_site/index.html",encoding:"UTF-8"); i=h.index("writing-h"); puts h[i..-1].scan(/work-list__item/).length'
```

Expected: `3`.

- [ ] **Step 7: Commit**

```bash
git add notes.html zh/notes.html index.html zh/index.html
git commit -m "content: reframe the notes surface

The notes index leded with 'Nothing polished — just things worth writing
down' above the strongest writing on the site. Replace it with what the
notes actually are, point a first-time reader at the constant-time warrant
note, and widen the home teaser from two to three.

Section order and numbering are unchanged.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 3: Entry altitude and disclosure consolidation

**Files:**
- Modify: `index.html:22-26` (hero lede)
- Modify: `zh/index.html:23-26` (hero lede)
- Modify: `about.html:29-40` (the four-project sentence), `about.html:53-61` (disclosure)
- Modify: `zh/about.html:52-59` (disclosure only — see note below)
- Modify: `projects.html:17-26` (lede)
- Modify: `zh/projects.html:17-23` (lede)
- Test: `scripts/validate_site.rb`

**Interfaces:**
- Consumes: nothing from Tasks 1–2.
- Produces: nothing.

**Note on ZH parity here:** `zh/about.html` **already** breaks the four projects into separate paragraphs (第一件…第四件, lines 28–42). EN does not — it crams all four into one 90-word four-semicolon sentence. This task brings EN up to the ZH structure; the ZH project paragraphs are **not** edited. Only the ZH disclosure paragraph changes, to stay in claims-parity with the EN one.

- [ ] **Step 1: Rewrite the EN hero lede**

In `index.html`, replace lines 22–26:

```html
            <p class="hero__lede">
                Cryptographic software, repository context for coding agents,
                and local developer infrastructure — tools built so their
                correctness, state, and limits stay inspectable. Release state
                and evidence are on every project page, including for the work
                that isn't public.
            </p>
```

- [ ] **Step 2: Rewrite the ZH hero lede**

In `zh/index.html`, replace lines 23–26:

```html
            <p class="hero__lede">
                密码学软件、给编程 Agent 用的仓库上下文、本地开发基础设施——
                做的工具都想让正确性、当前状态和限制保持可查。
                每个项目页都写清发布到哪一步、凭什么这么说；没公开的项目也一样。
            </p>
```

- [ ] **Step 3: Break the EN four-project sentence**

In `about.html`, replace lines 29–40 (the single `<p>` beginning "Lately that's meant four things:") with four paragraphs, mirroring the structure `zh/about.html` already uses:

```html
        <p>
            Lately that's meant four things.
        </p>
        <p>
            <em>gm-crypto-rs</em> is a pure-Rust SDK for the Chinese national
            crypto standards. Its secret-handling paths are designed to run in
            constant time, and an in-CI leak harness re-checks that on every
            commit rather than trusting the design review.
        </p>
        <p>
            <em>RepoLens</em> is a repository memory layer for AI coding
            agents — a typed, decaying memory graph exposed over MCP, so a new
            session doesn't start cold.
        </p>
        <p>
            <em>ghrunners</em> is a small observability CLI that exists
            because debugging self-hosted GitHub Actions runners on macOS
            shouldn't take an hour.
        </p>
        <p>
            <em>Explainer Engine</em> is a rendering pipeline for concept
            videos that refuses to draw an explanatory claim it can't verify
            against the source.
        </p>
```

- [ ] **Step 4: Fold the EN about-page disclosure to a clause**

In `about.html`, replace lines 53–61:

```html
        <p>
            The <a href="{{ '/projects/' | relative_url }}">project pages here</a>
            are the honest snapshot — each states its release state, evidence,
            and limits, including for the work that isn't public.
            <a href="https://github.com/{{ site.github_username }}" rel="noopener noreferrer">GitHub</a>
            carries the source for what is public.
        </p>
```

The sentence "Today only gm-crypto-rs has public source and public tags; the others stay private, with the same discipline on the page" is removed here — it survives at full weight in the hero proof panel (`index.html:65-69`), which is untouched.

- [ ] **Step 5: Fold the ZH about-page disclosure to match**

In `zh/about.html`, replace lines 52–59:

```html
        <p>
            想看每个项目做到哪一步，
            <a href="{{ '/zh/projects/' | relative_url }}">这里的项目页</a>
            是最诚实的快照——发到哪了、凭什么这么说、哪些做不到，都写在页面上；
            没公开的项目也一样。已经公开的部分，源码在
            <a href="https://github.com/{{ site.github_username }}" rel="noopener noreferrer">GitHub</a>。
        </p>
```

The sentence "眼下只有 gm-crypto-rs 源码和 tag 都公开；其余还是私有，但页面上的规矩一样" is removed, matching the EN cut.

- [ ] **Step 6: Reduce the EN projects-index lede to a pointer**

In `projects.html`, replace lines 17–26:

```html
    <p class="page-header__lede">
        A short, honest list. Things I'm building and documenting — mostly
        in Rust, mostly at the seam between developer tools and the systems
        they sit on top of. A project lands here once I can state honestly
        what it does, where it stands, and what its limits are. Each page
        carries its own release state and evidence, so what you can check
        from outside is visible per project rather than promised here.
    </p>
```

- [ ] **Step 7: Reduce the ZH projects-index lede to match**

In `zh/projects.html`, replace lines 17–23:

```html
    <p class="page-header__lede">
        一份短而诚实的清单。多是 Rust，多在开发者工具和底层系统的接缝上。
        讲不清做什么、做到哪、限制在哪的，不会放上来。
        每个项目页都写着自己的发布状态和证据——外面能核对到哪一步，
        看各自的页面，不在这里一句话打包。
    </p>
```

- [ ] **Step 8: Run the validator**

```bash
export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH" LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
bundle exec jekyll build && ruby scripts/validate_site.rb
```

Expected: `Site validation passed`. The hero-proof guard (`validate_site.rb:288`) requires `class="hero-proof"` on both home pages and the public release label `v1.11.0` present — both untouched by this task.

- [ ] **Step 9: Confirm the disclosure now appears once per locale**

```bash
export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
echo -n "EN hero (want 1):     "; grep -c "Only public-tagged work is independently verifiable" _site/index.html || true
echo -n "EN about (want 0):    "; grep -c "public source and public tags" _site/about/index.html || true
echo -n "EN projects (want 0): "; grep -c "independently verifiable from outside" _site/projects/index.html || true
echo -n "ZH hero (want 1):     "; grep -c "已打公开 tag 的作品" _site/zh/index.html || true
echo -n "ZH about (want 0):    "; grep -c "源码和 tag 都公开" _site/zh/about/index.html || true
echo -n "ZH projects (want 0): "; grep -c "只有 gm-crypto-rs" _site/zh/projects/index.html || true
```

Expected: `1, 0, 0, 1, 0, 0`. The full statement survives in the hero proof panel of each locale and nowhere else. A `1` on either about or projects row means the disclosure sentence was not actually cut.

- [ ] **Step 10: Commit**

```bash
git add index.html zh/index.html about.html zh/about.html projects.html zh/projects.html
git commit -m "content: fix entry altitude, state the evidence asymmetry once

The hero lede was a category list plus a methodology claim; the About page
compressed four projects into one 90-word sentence (ZH already broke these
out — this brings EN up to it). The 'only gm-crypto-rs is verifiable'
disclosure appeared three times before the reader saw any work; it now
stays once at full weight in the hero proof panel, where the claims are.

Nothing is softened or removed — the same fact is stated once well
instead of three times at diminishing weight.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Verification (after all three tasks)

- [ ] **Full clean build and validate**

```bash
export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH" LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
rm -rf _site && bundle exec jekyll build && ruby scripts/validate_site.rb
```

Expected: `Site validation passed`.

- [ ] **Visual check of the two changed pages**

```bash
python3 -m http.server 4000 --directory _site
```

Open `http://localhost:4000/projects/gm-crypto-rs/` and `http://localhost:4000/projects/gm-crypto-rs/releases/`, then the ZH mirrors. Confirm: the case study runs Evidence → release-line block → Next → What it isn't with no changelog in between; the releases page lists newest-first with the drawer at the bottom; the language switcher appears on both new pages (it renders only when `alternate` is set correctly).

- [ ] **Confirm nothing outside scope moved**

```bash
git diff main --stat
```

Expected: exactly 15 files — 2 created pages (`projects/gm-crypto-rs-releases.html`, `zh/projects/gm-crypto-rs-releases.html`), 10 modified pages (`projects/gm-crypto-rs.html`, `zh/projects/gm-crypto-rs.html`, `notes.html`, `zh/notes.html`, `index.html`, `zh/index.html`, `about.html`, `zh/about.html`, `projects.html`, `zh/projects.html`), `scripts/validate_site.rb`, the spec, and the plan — and nothing under `assets/`, `_data/`, `_includes/`, or `_layouts/`.
