# Visual Evolution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the approved visual-evolution spec — a monograph figure system on the three project pages, low-dose editorial drama (ghost numerals + double rules), and a second-design dark pass with hero-proof hover parity — as three independently shippable PRs.

**Architecture:** Pure CSS + markup + inline SVG inside the existing Jekyll site. Drawings are shared includes (`_includes/figures/*.svg`) styled by classes in `assets/css/style.css` using existing tokens, so light/dark theming is automatic. No JS, no CSP changes, no inline `style=""` attributes (CSP is `style-src 'self'`). Every page edit lands on the EN page and its ZH mirror in the same commit.

**Tech Stack:** Jekyll (github-pages gem), hand-written CSS custom properties, inline SVG, `scripts/validate_site.rb` as the test harness.

**Spec:** `docs/superpowers/specs/2026-06-11-visual-evolution-design.md`

**Build & test commands (run from repo root; the LC_ALL prefix is required on macOS):**

```bash
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
```

Expected: build ends with `done in …s`; the validator prints a pass summary and exits 0. Any line naming a failure means stop and fix before committing.

---

# Stage 1 — Figure system (branch `design/visual-evolution`, PR 1)

The spec commit (`e882a3b`) already sits on this branch. Stay on it:

```bash
git checkout design/visual-evolution
```

### Task 1: Validator guards first (the failing test)

The validator is the test harness; teach it to require the new artifacts before they exist.

**Files:**
- Modify: `scripts/validate_site.rb:709-711` (required dudect i18n keys)
- Modify: `scripts/validate_site.rb:741` area (style.css checks)

- [ ] **Step 1: Add `fig_num` to the required dudect i18n keys**

In `scripts/validate_site.rb`, find (≈line 709):

```ruby
  %w[title intro axis_label gate_label control_label cluster_label caveat
     provenance source table_caption col_target col_measures col_tau col_gate
     col_status status_pass status_fire].each do |key|
```

Replace with:

```ruby
  %w[title fig_num intro axis_label gate_label control_label cluster_label caveat
     provenance source table_caption col_target col_measures col_tau col_gate
     col_status status_pass status_fire].each do |key|
```

- [ ] **Step 2: Add the figure-styles check**

Find (≈line 741):

```ruby
  record(failures, "style.css: missing .dudect visualizer styles") unless css.include?(".dudect__chart")
```

Add directly below it:

```ruby
  record(failures, "style.css: missing monograph figure styles (.fig__cap)") unless css.include?(".fig__cap")
```

- [ ] **Step 3: Build, then run the validator — expect exactly these new failures**

Expected failures (and no others):
- `i18n.yml: missing en.dudect.fig_num`
- `i18n.yml: missing zh.dudect.fig_num`
- `style.css: missing monograph figure styles (.fig__cap)`

- [ ] **Step 4: Commit**

```bash
git add scripts/validate_site.rb
git commit -m "test(validator): require figure styles + dudect fig_num i18n key

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 2: i18n keys + figure CSS (make the guards pass)

**Files:**
- Modify: `_data/i18n.yml` (en.dudect ≈line 60, zh.dudect ≈line 170)
- Modify: `assets/css/style.css` (insert before the `.dudect` block, ≈line 2143)

- [ ] **Step 1: Add the `fig_num` strings**

In `_data/i18n.yml`, under `en:` → `dudect:`, directly after `title: "Constant-time, measured"`:

```yaml
    fig_num: "fig. 3.2"
```

Under `zh:` → `dudect:`, directly after `title: "把常量时间测出来"`:

```yaml
    fig_num: "图 3.2"
```

- [ ] **Step 2: Add the figure CSS**

In `assets/css/style.css`, insert immediately above the `/* … */` comment block that precedes `.dudect {` (≈line 2143):

```css
/* =========================================================
   Monograph figures — inline SVG plates + mono captions.
   Drawings live in _includes/figures/ and are styled here
   (classes + tokens only; CSP style-src 'self' forbids
   style="" attributes), so they follow light/dark for free.
   Spec: docs/superpowers/specs/2026-06-11-visual-evolution-design.md
   ========================================================= */
.fig {
    margin: var(--space-8) 0;
    padding-top: var(--space-4);
    border-top: 1px solid var(--fg);
    max-width: 30rem;
}
.fig svg {
    display: block;
    width: 100%;
    height: auto;
}
.fig-box { fill: var(--bg-sunk); stroke: var(--fg); stroke-width: 1; }
.fig-line { stroke: var(--fg); stroke-width: 1; fill: none; }
.fig-line--soft { stroke: var(--rule); stroke-width: 1; fill: none; }
.fig-line--dash { stroke-dasharray: 3 3; }
.fig-arrow { fill: var(--fg); }
.fig-label { font-family: var(--mono); font-size: 12px; fill: var(--fg); }
.fig-label--muted { font-family: var(--mono); font-size: 11px; fill: var(--fg-muted); }
.fig__cap {
    font-family: var(--mono);
    font-size: var(--text-sm);
    color: var(--fg-muted);
    margin-top: var(--space-3);
    letter-spacing: 0.02em;
}
```

Design notes baked into the values: the 360-unit-wide viewBoxes below render ≈1:1 on a 375px phone (12px labels stay ≥11px effective) and scale up to the 30rem cap on desktop. `--bg-sunk` fills + `--fg` strokes are the paper-and-ink plate look; dark mode flips via tokens with no extra rules.

- [ ] **Step 3: Build + validate — expect a clean pass (Task 1's three failures gone)**

- [ ] **Step 4: Commit**

```bash
git add _data/i18n.yml assets/css/style.css
git commit -m "feat(figures): monograph figure styles + dudect fig_num strings

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 3: gm-crypto-rs crate figure (fig. 3.1)

**Files:**
- Create: `_includes/figures/gm-crypto-crates.svg`
- Modify: `projects/gm-crypto-rs.html` (after the "What it is" paragraph, ≈line 56)
- Modify: `zh/projects/gm-crypto-rs.html` (after the 是什么 paragraph, ≈line 54)

- [ ] **Step 1: Verify the public entry-point count (source-of-truth rule)**

```bash
curl -fsSL https://raw.githubusercontent.com/frankxue831/gm-crypto-rs/v1.2.0/CHANGELOG.md | grep -n -i "entry point"
```

Expected: the v1.2.0 entry mentions the FFI surface growing to **72** entry points (63 → 72). If the public number differs, use the public number in both captions below.

- [ ] **Step 2: Create `_includes/figures/gm-crypto-crates.svg`**

```svg
<svg viewBox="0 0 360 236" role="img" xmlns="http://www.w3.org/2000/svg">
  <title>sm2 / sm3 / sm4 modules feed gmcrypto-core, which feeds gmcrypto-ffi (C ABI)</title>
  <rect class="fig-box" x="12" y="12" width="88" height="34"/>
  <rect class="fig-box" x="136" y="12" width="88" height="34"/>
  <rect class="fig-box" x="260" y="12" width="88" height="34"/>
  <text class="fig-label" x="56" y="34" text-anchor="middle">sm2</text>
  <text class="fig-label" x="180" y="34" text-anchor="middle">sm3</text>
  <text class="fig-label" x="304" y="34" text-anchor="middle">sm4</text>
  <line class="fig-line" x1="56" y1="46" x2="152" y2="94"/>
  <line class="fig-line" x1="180" y1="46" x2="180" y2="94"/>
  <line class="fig-line" x1="304" y1="46" x2="208" y2="94"/>
  <rect class="fig-box" x="104" y="94" width="152" height="38"/>
  <text class="fig-label" x="180" y="118" text-anchor="middle">gmcrypto-core</text>
  <line class="fig-line" x1="180" y1="132" x2="180" y2="170"/>
  <polygon class="fig-arrow" points="176,170 184,170 180,178"/>
  <rect class="fig-box" x="84" y="178" width="192" height="44"/>
  <text class="fig-label" x="180" y="198" text-anchor="middle">gmcrypto-ffi</text>
  <text class="fig-label--muted" x="180" y="214" text-anchor="middle">C ABI</text>
</svg>
```

Labels are locale-neutral (crate/module names only); the translated caption carries the prose. The `<title>` is the accessible name (`role="img"`).

- [ ] **Step 3: Insert the figure into the EN page**

In `projects/gm-crypto-rs.html`, the "What it is" paragraph ends:

```html
            <a href="https://github.com/frankxue831/gm-crypto-rs-demo" rel="noopener noreferrer">gm-crypto-rs-demo</a>.
        </p>

        <h2>The problem</h2>
```

Insert the figure between `</p>` and `<h2>The problem</h2>`:

```html
        <figure class="fig">
            {% include figures/gm-crypto-crates.svg %}
            <figcaption class="fig__cap">fig. 3.1 — crate &amp; C ABI surface (72 entry points at v1.2.0)</figcaption>
        </figure>
```

- [ ] **Step 4: Insert the figure into the ZH page**

In `zh/projects/gm-crypto-rs.html`, the 是什么 paragraph ends with `<code>verify</code>）。` followed by `</p>` and `<h2>要解决的问题</h2>`. Insert between them:

```html
        <figure class="fig">
            {% include figures/gm-crypto-crates.svg %}
            <figcaption class="fig__cap">图 3.1 — crate 与 C ABI 结构（v1.2.0 共 72 个 FFI 入口）</figcaption>
        </figure>
```

- [ ] **Step 5: Build + validate (clean), spot-check both rendered pages**

```bash
grep -c "fig__cap" _site/projects/gm-crypto-rs/index.html _site/zh/projects/gm-crypto-rs/index.html
```

Expected: `1` from each file.

- [ ] **Step 6: Commit**

```bash
git add _includes/figures/gm-crypto-crates.svg projects/gm-crypto-rs.html zh/projects/gm-crypto-rs.html
git commit -m "feat(figures): gm-crypto-rs crate & C ABI plate (fig. 3.1, EN+ZH)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 4: dudect chart joins the numbering (fig. 3.2)

**Files:**
- Modify: `_includes/dudect-chart.html:24`
- Modify: `assets/css/style.css` (after the `.dudect__title` rule, ≈line 2157)

- [ ] **Step 1: Prefix the figcaption**

In `_includes/dudect-chart.html`, replace:

```html
  <figcaption id="dudect-cap" class="dudect__title">{{ t.title | escape }}</figcaption>
```

with:

```html
  <figcaption id="dudect-cap" class="dudect__title"><span class="dudect__fignum">{{ t.fig_num | escape }} —</span> {{ t.title | escape }}</figcaption>
```

- [ ] **Step 2: Style the prefix (the title is uppercase mono; the fig number must stay lowercase)**

In `assets/css/style.css`, directly after the `.dudect__title { … }` rule, add:

```css
.dudect__fignum { text-transform: none; color: var(--fg-muted); }
```

- [ ] **Step 3: Build + validate (clean — the title string itself is not pinned; the `@ v1.2.0` tokens live in untouched `source`/`table_caption` keys)**

- [ ] **Step 4: Spot-check the rendered prefix**

```bash
grep -o 'dudect__fignum[^<]*' _site/projects/gm-crypto-rs/index.html _site/zh/projects/gm-crypto-rs/index.html | head -4
```

Expected: `fig. 3.2 —` (EN) and `图 3.2 —` (ZH).

- [ ] **Step 5: Commit**

```bash
git add _includes/dudect-chart.html assets/css/style.css
git commit -m "feat(figures): dudect chart joins the figure numbering as fig. 3.2

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 5: RepoLens flow figure (fig. 3.1)

**Files:**
- Create: `_includes/figures/repolens-flow.svg`
- Modify: `projects/repolens-rs.html` (after the "What it is" paragraph, ≈line 34)
- Modify: `zh/projects/repolens-rs.html` (after the 是什么 paragraph; locate with `grep -n "要解决的问题" zh/projects/repolens-rs.html`)

- [ ] **Step 1: Create `_includes/figures/repolens-flow.svg`**

The three shrinking soft ticks beside `memory` are the decay notation the caption explains.

```svg
<svg viewBox="0 0 360 248" role="img" xmlns="http://www.w3.org/2000/svg">
  <title>repository → packs + memory → mcp × 26 → agent</title>
  <rect class="fig-box" x="120" y="10" width="120" height="34"/>
  <text class="fig-label" x="180" y="32" text-anchor="middle">repository</text>
  <line class="fig-line" x1="180" y1="44" x2="100" y2="76"/>
  <line class="fig-line" x1="180" y1="44" x2="260" y2="76"/>
  <rect class="fig-box" x="40" y="76" width="120" height="34"/>
  <text class="fig-label" x="100" y="98" text-anchor="middle">packs</text>
  <rect class="fig-box" x="200" y="76" width="120" height="34"/>
  <text class="fig-label" x="260" y="98" text-anchor="middle">memory</text>
  <line class="fig-line--soft" x1="328" y1="86" x2="346" y2="86"/>
  <line class="fig-line--soft" x1="328" y1="94" x2="340" y2="94"/>
  <line class="fig-line--soft" x1="328" y1="102" x2="334" y2="102"/>
  <line class="fig-line" x1="100" y1="110" x2="172" y2="142"/>
  <line class="fig-line" x1="260" y1="110" x2="188" y2="142"/>
  <rect class="fig-box" x="120" y="142" width="120" height="34"/>
  <text class="fig-label" x="180" y="164" text-anchor="middle">mcp × 26</text>
  <line class="fig-line" x1="180" y1="176" x2="180" y2="204"/>
  <polygon class="fig-arrow" points="176,204 184,204 180,212"/>
  <rect class="fig-box" x="120" y="212" width="120" height="34"/>
  <text class="fig-label" x="180" y="234" text-anchor="middle">agent</text>
</svg>
```

- [ ] **Step 2: Insert into the EN page**

In `projects/repolens-rs.html`, "What it is" ends:

```html
            <em>Evidence</em> below.
        </p>

        <h2>The problem</h2>
```

Insert between `</p>` and `<h2>The problem</h2>`:

```html
        <figure class="fig">
            {% include figures/repolens-flow.svg %}
            <figcaption class="fig__cap">fig. 3.1 — packs + decaying memory behind 26 MCP tools</figcaption>
        </figure>
```

- [ ] **Step 3: Insert into the ZH page**

Same position (between the 是什么 closing `</p>` and `<h2>要解决的问题</h2>`):

```html
        <figure class="fig">
            {% include figures/repolens-flow.svg %}
            <figcaption class="fig__cap">图 3.1 — packs 与会衰减的记忆，经 26 个 MCP 工具暴露给 Agent</figcaption>
        </figure>
```

- [ ] **Step 4: Build + validate (clean); `grep -c "fig__cap" _site/projects/repolens-rs/index.html _site/zh/projects/repolens-rs/index.html` → `1` each**

- [ ] **Step 5: Commit**

```bash
git add _includes/figures/repolens-flow.svg projects/repolens-rs.html zh/projects/repolens-rs.html
git commit -m "feat(figures): RepoLens context/memory flow plate (fig. 3.1, EN+ZH)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 6: ghrunners evidence figure (fig. 3.1)

**Files:**
- Create: `_includes/figures/ghrunners-evidence.svg`
- Modify: `projects/ghrunners.html` (after the "What it is" paragraph, ≈line 38)
- Modify: `zh/projects/ghrunners.html` (locate with `grep -n "要解决的问题" zh/projects/ghrunners.html`)

- [ ] **Step 1: Create `_includes/figures/ghrunners-evidence.svg`**

The dashed connector marks the GitHub API as the optional source.

```svg
<svg viewBox="0 0 360 224" role="img" xmlns="http://www.w3.org/2000/svg">
  <title>launchd, ps, logs, api → findings → control</title>
  <rect class="fig-box" x="8" y="12" width="78" height="30"/>
  <rect class="fig-box" x="97" y="12" width="78" height="30"/>
  <rect class="fig-box" x="186" y="12" width="78" height="30"/>
  <rect class="fig-box" x="275" y="12" width="78" height="30"/>
  <text class="fig-label" x="47" y="32" text-anchor="middle">launchd</text>
  <text class="fig-label" x="136" y="32" text-anchor="middle">ps</text>
  <text class="fig-label" x="225" y="32" text-anchor="middle">logs</text>
  <text class="fig-label" x="314" y="32" text-anchor="middle">api</text>
  <line class="fig-line" x1="47" y1="42" x2="140" y2="92"/>
  <line class="fig-line" x1="136" y1="42" x2="166" y2="92"/>
  <line class="fig-line" x1="225" y1="42" x2="194" y2="92"/>
  <line class="fig-line fig-line--dash" x1="314" y1="42" x2="220" y2="92"/>
  <rect class="fig-box" x="100" y="92" width="160" height="38"/>
  <text class="fig-label" x="180" y="116" text-anchor="middle">findings</text>
  <line class="fig-line" x1="180" y1="130" x2="180" y2="158"/>
  <polygon class="fig-arrow" points="176,158 184,158 180,166"/>
  <rect class="fig-box" x="100" y="166" width="160" height="38"/>
  <text class="fig-label" x="180" y="190" text-anchor="middle">control</text>
</svg>
```

- [ ] **Step 2: Insert into the EN page**

In `projects/ghrunners.html`, "What it is" ends:

```html
            <em>Evidence</em> below.
        </p>

        <h2>The problem</h2>
```

Insert between `</p>` and `<h2>The problem</h2>`:

```html
        <figure class="fig">
            {% include figures/ghrunners-evidence.svg %}
            <figcaption class="fig__cap">fig. 3.1 — four evidence sources → typed findings → guarded control</figcaption>
        </figure>
```

- [ ] **Step 3: Insert into the ZH page (between the 是什么 closing `</p>` and `<h2>要解决的问题</h2>`)**

```html
        <figure class="fig">
            {% include figures/ghrunners-evidence.svg %}
            <figcaption class="fig__cap">图 3.1 — 四路证据 → 类型化结论 → 受控的 launchd 控制</figcaption>
        </figure>
```

- [ ] **Step 4: Build + validate (clean); `grep -c "fig__cap" _site/projects/ghrunners/index.html _site/zh/projects/ghrunners/index.html` → `1` each**

- [ ] **Step 5: Commit**

```bash
git add _includes/figures/ghrunners-evidence.svg projects/ghrunners.html zh/projects/ghrunners.html
git commit -m "feat(figures): ghrunners evidence-convergence plate (fig. 3.1, EN+ZH)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 7: Visual check + PR 1

- [ ] **Step 1: Serve and eyeball all six project pages (see Visual Verification appendix) — light + dark, desktop + 375px. Look for: figure legibility at phone width, dark-mode stroke contrast, caption wrapping.**

- [ ] **Step 2: Push and open the PR**

```bash
git push -u origin design/visual-evolution
gh pr create --title "feat(figures): monograph figure system + three project plates" --body "## Summary
- Stage 1 of the visual-evolution spec (rides with the spec doc, docs/superpowers/specs/2026-06-11-visual-evolution-design.md)
- Reusable .fig pattern: inline SVG plates in _includes/figures/, styled by classes + tokens only (dark mode automatic, CSP untouched, no JS)
- gm-crypto-rs: crate & C ABI plate (fig. 3.1); the dudect chart joins the numbering as fig. 3.2
- RepoLens: context/memory flow plate; ghrunners: evidence-convergence plate (fig. 3.1 each)
- Validator now requires the figure styles and the dudect fig_num strings
- EN/ZH mirrored throughout

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

---

# Stage 2 — Editorial dose (branch `design/editorial-dose`, PR 2)

Start only after PR 1 merges:

```bash
git checkout main && git pull --ff-only origin main
git checkout -b design/editorial-dose
```

### Task 8: The `--ghost-ink` token (all four theme paths)

**Files:**
- Modify: `assets/css/style.css` `:root` block (≈line 111), `[data-theme="dark"]` block (≈line 208), no-JS dark block (≈line 237), print block (≈line 262)

- [ ] **Step 1: `:root` — after `--danger: #b91c1c;` (the line above `/* Semantic status` comment block context), add:**

```css
    --ghost-ink: rgba(26, 24, 20, 0.07);
```

- [ ] **Step 2: dark block — find this exact context (the dark block ends before the grain comment):**

```css
    --status-private: #8a8276;
    --danger: #f87171;
}
/* Paper grain doesn't translate to dark
```

Insert `--ghost-ink: rgba(237, 228, 204, 0.05);` after that `--danger` line (before `}`).

- [ ] **Step 3: no-JS dark block — find the twin context (it ends before `:root:not([data-theme]) .grain`), insert the same `--ghost-ink: rgba(237, 228, 204, 0.05);` before its closing brace.**

- [ ] **Step 4: print block — after the print `--danger: #b91c1c;` line, add `--ghost-ink: transparent;` (ghosts must not print).**

- [ ] **Step 5: Build + validate (clean). Commit:**

```bash
git add assets/css/style.css
git commit -m "feat(editorial): --ghost-ink token across light/dark/no-JS/print

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 9: Ghost numeral + double-rule CSS

**Files:**
- Modify: `assets/css/style.css` — insert after the `@media (max-width: 759px)` block that follows `.section__title em` (≈line 682, before the Hero banner comment)

- [ ] **Step 1: Confirm `.section__head` only exists on the two home pages**

```bash
grep -rln "section__head" --include="*.html" . | grep -v _site
```

Expected: `./index.html` and `./zh/index.html` only. (If more appear, scope the border rules below with a `.section__head--plate` modifier instead and note it in the commit.)

- [ ] **Step 2: Add the CSS**

```css
/* =========================================================
   Editorial dose — ghost numerals + monograph double rules.
   Ghosts are aria-hidden decoration painted behind the head
   (z-index -1; .reveal's transform keeps them inside the
   section's stacking context). --ghost-ink: ~7% ink light,
   ~5% dark, transparent in print.
   Spec: docs/superpowers/specs/2026-06-11-visual-evolution-design.md
   ========================================================= */
.ghost-num {
    position: absolute;
    top: -0.16em;
    left: -0.05em;
    z-index: -1;
    font-family: var(--serif);
    font-style: italic;
    font-weight: 400;
    font-size: clamp(72px, 12vw, 128px);
    line-height: 1;
    color: var(--ghost-ink);
    pointer-events: none;
    user-select: none;
}
.section__head {
    position: relative;
    padding-bottom: var(--space-4);
    border-bottom: 2px solid var(--fg);
}
.page-header--plate {
    position: relative;
    border-bottom: 2px solid var(--fg);
}
.section__head::after,
.page-header--plate::after {
    content: "";
    position: absolute;
    left: 0;
    right: 0;
    bottom: -5px;
    height: 1px;
    background: var(--rule);
}
```

- [ ] **Step 3: Build + validate (clean). Commit:**

```bash
git add assets/css/style.css
git commit -m "feat(editorial): ghost numeral + double-rule styles

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 10: Home-page ghosts (EN + ZH, 8 heads)

**Files:**
- Modify: `index.html:74-76, 97-99, 157-159, 190-192`
- Modify: `zh/index.html:72-74, 93-95, 151-153, 184-186`

- [ ] **Step 1: In `index.html`, insert a ghost span as the first child of each `<header class="section__head">`, matching the section's number. Pattern (About shown; repeat for all four):**

```html
    <header class="section__head">
        <span class="ghost-num" aria-hidden="true">02</span>
        <p class="section__num">(02)  About</p>
```

The four anchors and their numbers: `(02)  About` → `02`, `(03)  Selected work` → `03`, `(04)  Writing` → `04`, `(05)  Contact` → `05`.

- [ ] **Step 2: Same in `zh/index.html`: `(02)  关于` → `02`, `(03)  作品` → `03`, `(04)  写作` → `04`, `(05)  联系` → `05`.**

- [ ] **Step 3: Build + validate (clean); `grep -c "ghost-num" _site/index.html _site/zh/index.html` → `4` each. Commit:**

```bash
git add index.html zh/index.html
git commit -m "feat(editorial): ghost numerals on home section heads (EN+ZH)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 11: Top-level page headers (8 pages)

**Files:**
- Modify: `about.html:10-11`, `projects.html:10-11`, `notes.html:10-11`, `contact.html:10-11` and the four `zh/` mirrors

Project **detail** pages, `colophon.html`, and `404.html` stay untouched (spec: chapters stay quiet).

- [ ] **Step 1: For each of the eight pages, add the `page-header--plate` class and the ghost span. Pattern (about.html shown):**

Before:

```html
<section class="page-header wrap">
    <p class="page-header__eyebrow">(02)  About</p>
```

After:

```html
<section class="page-header page-header--plate wrap">
    <span class="ghost-num" aria-hidden="true">02</span>
    <p class="page-header__eyebrow">(02)  About</p>
```

Numbers per page: about `02`, projects `03`, notes `04`, contact `05` — same on the ZH mirrors (`(02)  关于`, `(03)  作品`, `(04)  写作`, `(05)  联系`).

- [ ] **Step 2: Build + validate (clean); `grep -rc "ghost-num" _site/about/index.html _site/zh/about/index.html _site/projects/index.html _site/zh/projects/index.html _site/notes/index.html _site/zh/notes/index.html _site/contact/index.html _site/zh/contact/index.html` → `1` each.**

- [ ] **Step 3: Visual check (appendix): home + the four top-level pages, light/dark, desktop/375px. Look for: ghost not overlapping the nav, no horizontal scrollbar at 375px, double rule sitting cleanly under heads, print preview free of ghosts (`Cmd+P` in the served page or `emulate` print media).**

- [ ] **Step 4: Commit, push, PR:**

```bash
git add about.html projects.html notes.html contact.html zh/about.html zh/projects.html zh/notes.html zh/contact.html
git commit -m "feat(editorial): ghost numerals + plate rule on top-level page headers (EN+ZH)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
git push -u origin design/editorial-dose
gh pr create --title "feat(editorial): ghost numerals + monograph double rules" --body "## Summary
- Stage 2 of the visual-evolution spec: low-dose editorial drama
- aria-hidden serif ghost numerals behind the home section heads and the four top-level page headers (EN+ZH); detail pages stay quiet
- Monograph double rule (2px ink over hairline) under the same heads
- New --ghost-ink token across light/dark/no-JS-dark/print (transparent in print)
- CSS + decorative spans only; no JS, no CSP change, no layout shift

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

---

# Stage 3 — Second-design dark + hover parity (branch `design/dark-second-design`, PR 3)

Start only after PR 2 merges:

```bash
git checkout main && git pull --ff-only origin main
git checkout -b design/dark-second-design
```

### Task 12: Hero-proof hover parity

**Files:**
- Modify: `assets/css/style.css:799-809` (the `.hero-proof__row` block) and the mobile block ≈line 1464/1491

- [ ] **Step 1: Replace the row block. Before:**

```css
.hero-proof__row {
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    gap: var(--space-4);
    align-items: center;
    padding: var(--space-4) 0;
}
.hero-proof__row:hover .hero-proof__title,
.hero-proof__row:focus-visible .hero-proof__title {
    color: var(--accent);
}
```

After:

```css
.hero-proof__row {
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    gap: var(--space-4);
    align-items: center;
    padding: var(--space-4) 0;
    transition: padding var(--dur) var(--ease),
                background var(--dur-fast) var(--ease),
                box-shadow var(--dur-fast) var(--ease);
}
/* Parity with the work-list reward (.work-list__item:hover .work-list__row):
   surface tint + 2px inset accent rail, padding nudge instead of layout shift. */
.hero-proof__row:hover,
.hero-proof__row:focus-visible {
    padding-left: var(--space-3);
    background: var(--bg-elevated);
    box-shadow: inset 2px 0 0 var(--accent);
}
.hero-proof__row:hover .hero-proof__title,
.hero-proof__row:focus-visible .hero-proof__title {
    color: var(--accent);
}
```

(The global `prefers-reduced-motion` reset at ≈line 280 already neutralises the new transitions.)

- [ ] **Step 2: Mirror the mobile zeroing. In the `@media (max-width: 759px)` block, the work list does this at ≈line 1491:**

```css
    .work-list__item:hover .work-list__row,
    .work-list__row:focus-visible { padding-left: 0; }
```

Add directly below it:

```css
    .hero-proof__row:hover,
    .hero-proof__row:focus-visible { padding-left: 0; }
```

- [ ] **Step 3: Build + validate (clean). Commit:**

```bash
git add assets/css/style.css
git commit -m "feat(dark): hero-proof rows get the work-list hover/focus reward

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 13: The dark pass (both dark paths)

**Files:**
- Modify: `assets/css/style.css` — new section at the end of the file, plus twins inside the existing `@media (prefers-color-scheme: dark)` block (≈line 219-240)

Pill note (spec coverage): `.status-pill` has no border or panel — its dot already carries dark-tuned status tokens, so it needs **no** override. Say so in the PR body rather than adding a no-op rule.

- [ ] **Step 1: Append the explicit-theme rules at the end of `style.css`:**

```css
/* =========================================================
   Second-design dark — deliberate choices, not value flips.
   Light keeps sunken paper panels; dark raises them to the
   warm elevated surface and lets accents go moonlit (release
   numerals, the proof-ledger hairline). Status pills need no
   override — their dots already carry dark-tuned tokens.
   Twin rules for the no-JS dark path live in the
   prefers-color-scheme block near the top of this file.
   Spec: docs/superpowers/specs/2026-06-11-visual-evolution-design.md
   ========================================================= */
[data-theme="dark"] .dudect,
[data-theme="dark"] .install {
    background: var(--bg-elevated);
}
[data-theme="dark"] details.drawer > summary:hover {
    background: var(--bg-sunk);
}
[data-theme="dark"] details.drawer {
    background: var(--bg-elevated);
}
[data-theme="dark"] .hero-proof {
    border-top-color: var(--accent);
}
[data-theme="dark"] .hero-proof__release,
[data-theme="dark"] .work-list__rel {
    color: var(--accent);
}
```

- [ ] **Step 2: Add the no-JS twins inside the existing `@media (prefers-color-scheme: dark)` block, after the `:root:not([data-theme]) .grain { display: none; }` line:**

```css
    :root:not([data-theme]) .dudect,
    :root:not([data-theme]) .install {
        background: var(--bg-elevated);
    }
    :root:not([data-theme]) details.drawer > summary:hover {
        background: var(--bg-sunk);
    }
    :root:not([data-theme]) details.drawer {
        background: var(--bg-elevated);
    }
    :root:not([data-theme]) .hero-proof {
        border-top-color: var(--accent);
    }
    :root:not([data-theme]) .hero-proof__release,
    :root:not([data-theme]) .work-list__rel {
        color: var(--accent);
    }
```

- [ ] **Step 3: Build + validate (clean).**

- [ ] **Step 4: Visual check (appendix): home + gm-crypto-rs page in dark — proof ledger shows the moonlit top hairline, release numerals in accent, dudect/install panels elevated; drawer summary hover visibly "presses" to sunken; light mode unchanged. Also verify the no-JS path: serve, then in DevTools disable JS, set OS/emulated `prefers-color-scheme: dark`, reload.**

- [ ] **Step 5: Commit, push, PR:**

```bash
git add assets/css/style.css
git commit -m "feat(dark): second-design dark pass — elevated panels, moonlit accents

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
git push -u origin design/dark-second-design
gh pr create --title "feat(dark): second-design dark + hero-proof hover parity" --body "## Summary
- Stage 3 of the visual-evolution spec
- Hero-proof rows get the same hover/focus reward as the work list (tint + inset accent rail), with the mobile padding zeroed like the work list
- Dark is now a designed second theme: dudect/install/drawer panels rise to the warm elevated surface, the proof ledger gets a moonlit top hairline, release numerals go accent
- Both dark paths covered (explicit data-theme and the no-JS prefers-color-scheme fallback); print untouched
- Status pills audited and intentionally unchanged — their dots already carry dark-tuned status tokens

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

---

# Appendix: Visual verification recipe (chrome-devtools MCP)

1. `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bundle exec jekyll serve` (background) → http://localhost:4000.
2. Scroll-reveal hides below-fold content in screenshots — force it first:
   `document.querySelectorAll('.reveal').forEach(el => el.classList.add('is-revealed'))`.
3. Dark mode: `document.documentElement.setAttribute('data-theme','dark')` (and `'light'` to restore).
4. Mobile: `resize_page` clamps at the 500px window minimum — use `emulate` with viewport `375x812x2,mobile,touch` instead.
5. Scrolling in screenshots: `document.scrollingElement.scrollTop = N` (`window.scrollTo` is a no-op here).
