# Home Page Readability Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refresh the English and Chinese home pages so the typography, hierarchy, and project rows are easier to read while preserving the site identity.

**Architecture:** Keep the static Jekyll architecture intact. Update shared typography tokens in `assets/css/style.css`, keep serif type for display moments, use a readable sans stack for body/interface text, and update only the two home page files for copy and markup cleanup.

**Tech Stack:** Jekyll, Liquid, hand-written CSS, Google Fonts, existing `_data/projects.yml` project metadata.

---

## File Structure

- Modify `_includes/head.html`: load the sans CJK font needed by the new `--sans` stack while retaining existing display serif and mono fonts.
- Modify `assets/css/style.css`: update type tokens, remove continuous viewport-based type scaling from key tokens, and tune hero/preview/work-list selectors for readability.
- Modify `index.html`: update English hero copy, keep project data loop, and replace the inline "See all work" margin with a CSS class.
- Modify `zh/index.html`: mirror the English structure and readability changes in Chinese, using natural Chinese phrasing.

No new includes, data files, JavaScript, project links, or project claims are required.

## Implementation Notes

- Leave the untracked `CLAUDE.md` file untouched.
- Do not add external project source links.
- Keep all internal links as trailing-slash paths through `relative_url`.
- Keep `site.data.projects` as the only source for project titles, years, tags, and detail URLs.
- Use ASCII punctuation in English files. Existing Chinese text may retain Chinese punctuation where it already reads naturally.

### Task 1: Update Font Loading and Type Tokens

**Files:**
- Modify: `_includes/head.html`
- Modify: `assets/css/style.css`

- [ ] **Step 1: Replace the Google Fonts link**

In `_includes/head.html`, replace the current Google Fonts `<link href=...>` line with:

```html
    <link href="https://fonts.googleapis.com/css2?family=EB+Garamond:ital,wght@0,400..800;1,400..800&amp;family=Noto+Sans+SC:wght@400;500;600;700&amp;family=Noto+Serif+SC:wght@400;500;600&amp;family=IBM+Plex+Mono:wght@400;500;600&amp;display=swap" rel="stylesheet">
```

Expected: the page still loads EB Garamond, IBM Plex Mono, Noto Serif SC, and now also Noto Sans SC.

- [ ] **Step 2: Replace the typography comment and font stacks**

In `assets/css/style.css`, replace the opening file comment with:

```css
/* =========================================================
   Frank Xue - frankxue.dev
   Aesthetic: Codex - paper & ink. Light, monograph-feel.
   Display: EB Garamond. Body/UI: system sans + Noto Sans SC.
   Mono: IBM Plex Mono.
   ========================================================= */
```

Then replace the `/* Type ... */` block inside `:root` through `--mono` with:

```css
    /* Type - serif for identity, sans for reading, mono for metadata. */
    --serif: 'EB Garamond', 'Noto Serif SC', 'Iowan Old Style', Georgia, serif;
    --sans: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Inter', 'Noto Sans SC', 'PingFang SC', 'Microsoft YaHei', Arial, sans-serif;
    --mono: 'IBM Plex Mono', ui-monospace, SFMono-Regular, Menlo, 'Noto Sans Mono CJK SC', monospace;
```

Expected: `body` keeps using `font-family: var(--sans);`, so default reading surfaces switch to the sans stack.

- [ ] **Step 3: Replace continuous viewport-based type tokens**

In the same `:root` block, replace:

```css
    --text-4xl: clamp(2rem, 4vw + 0.5rem, 3rem);
    --text-5xl: clamp(2.5rem, 6vw + 0.5rem, 4.5rem);
    --text-display: clamp(3.5rem, 10vw + 0.5rem, 8.5rem);
```

with:

```css
    --text-4xl: 2.5rem;
    --text-5xl: 3.5rem;
    --text-display: 5.75rem;
```

Expected: core type tokens no longer scale continuously with viewport width.

- [ ] **Step 4: Add responsive type overrides**

Immediately after the `:root { ... }` block, add:

```css
@media (max-width: 759px) {
    :root {
        --text-4xl: 2rem;
        --text-5xl: 2.5rem;
        --text-display: 3.25rem;
    }
}
```

Expected: mobile type remains controlled at a breakpoint without viewport-width scaling.

- [ ] **Step 5: Build after token changes**

Run:

```bash
bundle exec jekyll build
```

Expected: build exits with status 0.

- [ ] **Step 6: Commit typography foundation**

Run:

```bash
git add _includes/head.html assets/css/style.css
git commit -m "feat: update readable typography foundation"
```

Expected: commit includes only `_includes/head.html` and `assets/css/style.css`.

### Task 2: Update English Home Page Copy and Markup

**Files:**
- Modify: `index.html`

- [ ] **Step 1: Replace the English hero title and lede**

In `index.html`, replace the existing `<h1 class="hero__title">...</h1>` and following `<p class="hero__lede">...</p>` with:

```html
    <h1 class="hero__title">
        Building reliable tools
        <em>for code, crypto, and agents.</em>
    </h1>

    <p class="hero__lede">
        I'm a software engineer working mostly in Rust. This site collects
        selected projects, notes on how they are built, and the smaller tools
        that help me think clearly.
    </p>
```

Expected: the hero states the work area directly and keeps the display serif moment.

- [ ] **Step 2: Replace English hero metadata**

In `index.html`, replace the full `<dl class="hero__meta">...</dl>` with:

```html
    <dl class="hero__meta">
        <div>
            <dt>Focus</dt>
            <dd>Rust, cryptography, agent tooling, CLIs</dd>
        </div>
        <div>
            <dt>Recent</dt>
            <dd><em>gm-crypto-rs</em> v0.7.0</dd>
        </div>
        <div>
            <dt>Work</dt>
            <dd>Three selected project writeups</dd>
        </div>
    </dl>
```

Expected: no new project source link is introduced in the hero metadata.

- [ ] **Step 3: Tighten the English about preview copy**

In `index.html`, replace the paragraph inside `.preview__body` under the About section with:

```html
            <p>
                I'm a software engineer who cares about <em>clarity</em>:
                code that can be audited, tools that explain their state, and
                interfaces that do not make routine work feel mysterious.
            </p>
```

Expected: the preview reads as body copy rather than a display quote.

- [ ] **Step 4: Remove the inline project-link style**

In `index.html`, replace:

```html
    <a href="{{ '/projects/' | relative_url }}" class="preview__link" style="margin-top: var(--space-8);">
```

with:

```html
    <a href="{{ '/projects/' | relative_url }}" class="preview__link preview__link--section">
```

Expected: no inline style remains on the English "See all work" link.

- [ ] **Step 5: Build after English markup changes**

Run:

```bash
bundle exec jekyll build
```

Expected: build exits with status 0 and `_site/index.html` contains `Building reliable tools`.

- [ ] **Step 6: Commit English home update**

Run:

```bash
git add index.html
git commit -m "feat: sharpen English home page copy"
```

Expected: commit includes only `index.html`.

### Task 3: Update Chinese Home Page Copy and Markup

**Files:**
- Modify: `zh/index.html`

- [ ] **Step 1: Replace the Chinese hero title and lede**

In `zh/index.html`, replace the existing `<h1 class="hero__title">...</h1>` and following `<p class="hero__lede">...</p>` with:

```html
    <h1 class="hero__title">
        写可靠的工具,
        <em>给代码、密码学和 Agent 用。</em>
    </h1>

    <p class="hero__lede">
        我主要用 Rust 写软件。这里放一些项目、实现笔记,
        以及帮助我把事情想清楚的小工具。
    </p>
```

Expected: Chinese copy mirrors the English meaning without relying on italic emphasis for meaning.

- [ ] **Step 2: Replace Chinese hero metadata**

In `zh/index.html`, replace the full `<dl class="hero__meta">...</dl>` with:

```html
    <dl class="hero__meta">
        <div>
            <dt>方向</dt>
            <dd>Rust、密码学、Agent 工具、CLI</dd>
        </div>
        <div>
            <dt>最近</dt>
            <dd><em>gm-crypto-rs</em> v0.7.0</dd>
        </div>
        <div>
            <dt>作品</dt>
            <dd>三个项目说明</dd>
        </div>
    </dl>
```

Expected: no new project source link is introduced in Chinese hero metadata.

- [ ] **Step 3: Tighten the Chinese about preview copy**

In `zh/index.html`, replace the paragraph inside `.preview__body` under the About section with:

```html
            <p>
                我是个软件工程师,很在意<em>清楚</em>这件事:
                代码要能被审计,工具要说明自己的状态,
                界面不要把日常工作变复杂。
            </p>
```

Expected: the Chinese section remains parallel to English and does not depend on italic styling.

- [ ] **Step 4: Remove the inline project-link style**

In `zh/index.html`, replace:

```html
    <a href="{{ '/zh/projects/' | relative_url }}" class="preview__link" style="margin-top: var(--space-8);">
```

with:

```html
    <a href="{{ '/zh/projects/' | relative_url }}" class="preview__link preview__link--section">
```

Expected: no inline style remains on the Chinese "See all work" equivalent.

- [ ] **Step 5: Build after Chinese markup changes**

Run:

```bash
bundle exec jekyll build
```

Expected: build exits with status 0 and `_site/zh/index.html` contains `写可靠的工具`.

- [ ] **Step 6: Commit Chinese home update**

Run:

```bash
git add zh/index.html
git commit -m "feat: sharpen Chinese home page copy"
```

Expected: commit includes only `zh/index.html`.

### Task 4: Tune Home Page Readability Styles

**Files:**
- Modify: `assets/css/style.css`

- [ ] **Step 1: Replace section heading typography**

In `assets/css/style.css`, replace the `.section__title` block with:

```css
.section__title {
    font-family: var(--serif);
    font-weight: 600;
    font-size: var(--text-4xl);
    line-height: 1.12;
    letter-spacing: 0;
    color: var(--fg);
    max-width: 16ch;
}
```

Expected: headings keep the serif identity but become less compressed.

- [ ] **Step 2: Replace the home hero CSS blocks**

In the `Hero (home)` section, replace `.hero`, `.hero__eyebrow`, `.hero__eyebrow::before`, `.hero__title`, `.hero__title em`, `.hero__lede`, `.hero__meta`, `.hero__meta dt`, `.hero__meta dd`, and `.hero__meta a:hover` with:

```css
.hero {
    padding-block: var(--space-24) var(--space-20);
    position: relative;
}

.hero__eyebrow {
    font-family: var(--sans);
    font-size: var(--text-sm);
    color: var(--fg-muted);
    letter-spacing: 0;
    display: inline-flex;
    align-items: center;
    gap: var(--space-3);
    margin-bottom: var(--space-6);
}
.hero__eyebrow::before {
    content: "";
    width: 32px;
    height: 1px;
    background: var(--accent);
}

.hero__title {
    font-family: var(--serif);
    font-weight: 600;
    font-size: var(--text-display);
    line-height: 1.04;
    letter-spacing: 0;
    color: var(--fg);
    max-width: 12ch;
    margin-bottom: var(--space-6);
}
.hero__title em {
    font-style: italic;
    font-weight: 400;
    color: var(--accent-cool);
    display: block;
}

.hero__lede {
    font-family: var(--sans);
    font-size: var(--text-xl);
    line-height: 1.65;
    font-weight: 400;
    color: var(--fg-muted);
    max-width: 58ch;
    margin-bottom: var(--space-8);
}

.hero__meta {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: var(--space-4);
    max-width: 760px;
    font-family: var(--sans);
    font-size: var(--text-sm);
    color: var(--fg-muted);
    letter-spacing: 0;
}
.hero__meta div {
    padding-top: var(--space-3);
    border-top: 1px solid var(--rule);
}
.hero__meta dt {
    color: var(--fg-subtle);
    text-transform: uppercase;
    font-family: var(--mono);
    font-size: var(--text-xs);
    letter-spacing: 0.04em;
    margin-bottom: var(--space-2);
}
.hero__meta dd {
    color: var(--fg);
    line-height: 1.5;
}
.hero__meta a:hover { color: var(--accent); }
```

Expected: the hero has smaller, more readable body text and metadata cards.

- [ ] **Step 3: Replace hero CTA typography**

Replace the `.hero__cta` block with:

```css
.hero__cta {
    display: inline-flex;
    align-items: center;
    gap: var(--space-3);
    margin-top: var(--space-8);
    padding: var(--space-3) 0;
    font-family: var(--sans);
    font-size: var(--text-base);
    font-weight: 600;
    color: var(--fg);
    border-bottom: 1px solid var(--accent);
    transition: gap var(--dur) var(--ease), color var(--dur) var(--ease);
}
```

Expected: the main CTA reads like an action rather than technical metadata.

- [ ] **Step 4: Replace preview body and link styles**

Replace `.preview__body` through `.preview__link:hover` with:

```css
.preview__body {
    font-family: var(--sans);
    font-size: var(--text-lg);
    line-height: 1.7;
    color: var(--fg);
    max-width: 62ch;
}
.preview__body p + p { margin-top: var(--space-6); }
.preview__body em {
    font-style: normal;
    font-weight: 600;
    color: var(--accent-cool);
}

.preview__link {
    display: inline-flex;
    align-items: baseline;
    gap: var(--space-2);
    margin-top: var(--space-6);
    font-family: var(--sans);
    font-size: var(--text-base);
    font-weight: 600;
    color: var(--fg-muted);
    border-bottom: 1px solid var(--rule);
    padding-bottom: 2px;
    transition: color var(--dur) var(--ease), border-color var(--dur) var(--ease);
}
.preview__link--section {
    margin-top: var(--space-8);
}
.preview__link:hover {
    color: var(--accent);
    border-color: var(--accent);
}
```

Expected: preview text becomes readable paragraph text and the new class replaces removed inline styles.

- [ ] **Step 5: Replace work-list text styles**

Replace `.work-list__row`, `.work-list__year`, `.work-list__title`, and `.work-list__tags` blocks with:

```css
.work-list__row {
    display: grid;
    grid-template-columns: 88px minmax(0, 1fr) minmax(180px, auto);
    gap: var(--space-6);
    align-items: baseline;
    padding: var(--space-5) 0;
    transition: padding var(--dur) var(--ease);
}

.work-list__year {
    font-family: var(--mono);
    font-size: var(--text-xs);
    color: var(--fg-subtle);
    letter-spacing: 0.02em;
}

.work-list__title {
    font-family: var(--sans);
    font-size: var(--text-xl);
    font-weight: 600;
    color: var(--fg);
    line-height: 1.35;
    transition: color var(--dur) var(--ease);
}

.work-list__tags {
    font-family: var(--sans);
    font-size: var(--text-sm);
    color: var(--fg-muted);
    text-align: right;
    line-height: 1.45;
    letter-spacing: 0;
}
```

Expected: project rows become easier to scan and long tags have a stable third column.

- [ ] **Step 6: Add mobile hero metadata override**

Inside the existing `@media (max-width: 759px)` block near the work-list mobile rules, add:

```css
    .hero {
        padding-block: var(--space-16) var(--space-12);
    }
    .hero__title {
        max-width: 11ch;
    }
    .hero__lede {
        font-size: var(--text-lg);
        line-height: 1.65;
    }
    .hero__meta {
        grid-template-columns: 1fr;
        gap: var(--space-4);
    }
```

Expected: mobile hero text and metadata stack without overlap.

- [ ] **Step 7: Build and scan generated home pages**

Run:

```bash
bundle exec jekyll build
rg -n 'Building reliable tools|Three selected project writeups|写可靠的工具|三个项目说明' _site/index.html _site/zh/index.html
rg -n '/projects/(gm-crypto-rs|repolens-rs|ghrunners)/|/zh/projects/(gm-crypto-rs|repolens-rs|ghrunners)/' _site/index.html _site/zh/index.html
```

Expected: build exits with status 0; both scans find the new home copy and all three project detail links.

- [ ] **Step 8: Commit readability style tuning**

Run:

```bash
git add assets/css/style.css
git commit -m "feat: tune home page readability styles"
```

Expected: commit includes only `assets/css/style.css`.

### Task 5: Final Verification

**Files:**
- Verify generated output only.

- [ ] **Step 1: Run Jekyll checks**

Run:

```bash
bundle exec jekyll doctor
bundle exec jekyll build
```

Expected: both commands exit with status 0.

- [ ] **Step 2: Confirm docs are excluded**

Run:

```bash
test ! -d _site/docs/superpowers
```

Expected: command exits with status 0.

- [ ] **Step 3: Confirm no private project source links were introduced**

Run:

```bash
! rg -n 'github\.com/frankxue831/(gm-crypto-rs|repolens-rs|ghrunners)' _site/index.html _site/zh/index.html
```

Expected: command exits with status 0 and prints no matching private/unavailable project links.

- [ ] **Step 4: Confirm inline styles were removed from home project links**

Run:

```bash
! rg -n 'style="margin-top: var\(--space-8\);"' index.html zh/index.html
```

Expected: command exits with status 0.

- [ ] **Step 5: Visually verify desktop and mobile**

Start the local Jekyll server:

```bash
bundle exec jekyll serve --host 127.0.0.1 --port 4000
```

Open `http://127.0.0.1:4000/` and `http://127.0.0.1:4000/zh/` in the browser. Verify:

- Desktop hero title, lede, metadata, and CTA do not overlap.
- Mobile hero metadata stacks in one column.
- English and Chinese selected-work rows remain scannable.
- The paper background, blue accent, and serif display identity are still visible.

Expected: no visual overlap or unreadable text at desktop or mobile viewport widths.

- [ ] **Step 6: Commit final verification note only if fixes were needed**

If Step 5 requires CSS fixes, make those fixes in `assets/css/style.css`, rerun Steps 1-5, and commit:

```bash
git add assets/css/style.css
git commit -m "fix: polish home page responsive readability"
```

Expected: skip this commit when Step 5 passes without additional edits.
