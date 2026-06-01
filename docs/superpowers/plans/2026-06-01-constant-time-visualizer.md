# Constant-time Visualizer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an honest `|τ|`-vs-0.20-gate number-line visualizer to the gm-crypto-rs Evidence section (EN+ZH), server-rendered as inline SVG with an always-visible data-table fallback, sourced only from public v0.16.0 dudect values.

**Architecture:** A `_data/dudect.yml` facts file + a Liquid `_includes/dudect-chart.html` that renders inline SVG (coordinates computed in Liquid) and a `<table>`, pulling bilingual strings from `i18n.yml`. Zero new JavaScript; tokens-only CSS; validator guards pin the four published constants to public state. The chart is a non-interactive `<figure>` (no hover/click detail), so the table is the detail + a11y + no-JS/no-SVG fallback.

**Tech Stack:** Jekyll (Liquid), inline SVG, hand-written CSS design tokens, Ruby validator (`scripts/validate_site.rb`). No build step, no JS framework.

**Branch:** `design/constant-time-visualizer` (already exists, holds the spec commit). All work lands here; Frank merges the PR.

**Verification commands (run from repo root, the macOS UTF-8 prefix is required):**
- Build: `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bundle exec jekyll build`
- Validate: `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb` → prints `Site validation passed`

---

## Authoritative public data (from gm-crypto-rs `SECURITY.md` @ v0.16.0 — do NOT change these numbers)

| target | `|τ|` | meaning |
|---|---|---|
| `ct_sign` | 0.0044 | SM2 sign, class-split by private key `d` |
| `ct_sign_k_class` | 0.0708 | SM2 sign, class-split by nonce `k` magnitude |
| `ct_fn_invert` | 0.0071 | direct `Fn::invert` diagnostic |
| `ct_fp_invert` | 0.0063 | direct `Fp::invert` diagnostic |

Gate constants: PR gate `0.20`; `ct_sign_k_class` nightly `0.25`; invert-diagnostics sentinel `0.55`; `negative_control` must exceed `1.0`. Caught leak: `crypto-bigint 0.6` `ConstMontyForm::invert` before `≈0.70` → after `≈0.006`. These four `|τ|` are a **v0.2 "W0" 100K-sample snapshot on the pre-2026-05-12 runner** — present as a baseline snapshot with provenance, not "current gate readings."

---

## File Structure

- **Create `_data/dudect.yml`** — facts only (numbers + bilingual `desc`/`what`). One responsibility: the data.
- **Create `_includes/dudect-chart.html`** — renders the SVG figure + caption + table from the data + i18n. One responsibility: presentation markup.
- **Modify `_data/i18n.yml`** — add `dudect:` subtree (en+zh): titles, labels, caveat, table headers, status words.
- **Modify `projects/gm-crypto-rs.html`** and **`zh/projects/gm-crypto-rs.html`** — insert one include line in Evidence.
- **Modify `assets/css/style.css`** — `.dudect` component block, tokens only.
- **Modify `scripts/validate_site.rb`** — guards: data-file constants pinned, figure+table+source present on both pages, i18n parity, CSS present.

---

## Task 1: Create the dudect facts data file

**Files:**
- Create: `_data/dudect.yml`

- [ ] **Step 1: Write the data file**

Create `_data/dudect.yml` with exactly this content (numbers are load-bearing — they're guarded in Task 6):

```yaml
# Public dudect constant-time measurements for gm-crypto-rs.
# SOURCE OF TRUTH: gm-crypto-rs SECURITY.md @ the public v0.16.0 tag.
# Every number here must match that public file — scripts/validate_site.rb
# pins the four `tau` values + the leak before/after, so a silent drift
# fails CI. Do NOT add per-target values for the other 14 of 18 targets:
# they carry gate POLICY in SECURITY.md but no published per-target number,
# and inventing them would violate the site's auditability rule.
gate: 0.20            # PR-smoke blocking gate (|tau| < 0.20)
gate_nightly: 0.25    # ct_sign_k_class, nightly only
sentinel: 0.55        # invert-diagnostics gross-regression sentinel
control_floor: 1.0    # negative_control must exceed this to prove the detector fires
axis_max: 1.1
source_url: "https://github.com/frankxue831/gm-crypto-rs/blob/v0.16.0/SECURITY.md"
# The four publicly-measured values (v0.2 "W0" harness, 100K samples,
# pre-2026-05-12 runner image). A baseline snapshot, not a live gate reading.
measured:
  - target: "ct_sign"
    tau: 0.0044
    desc:
      en: "SM2 sign, split by private key d"
      zh: "SM2 签名，按私钥 d 分类"
  - target: "ct_sign_k_class"
    tau: 0.0708
    desc:
      en: "SM2 sign, split by nonce k magnitude"
      zh: "SM2 签名，按随机数 k 的量级分类"
  - target: "ct_fn_invert"
    tau: 0.0071
    desc:
      en: "Direct Fn::invert diagnostic"
      zh: "Fn::invert 直接诊断"
  - target: "ct_fp_invert"
    tau: 0.0063
    desc:
      en: "Direct Fp::invert diagnostic"
      zh: "Fp::invert 直接诊断"
leak:
  before: 0.70
  after: 0.006
  what:
    en: "crypto-bigint 0.6 ConstMontyForm::invert"
    zh: "crypto-bigint 0.6 的 ConstMontyForm::invert"
```

- [ ] **Step 2: Verify it parses**

Run: `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby -ryaml -e 'd=YAML.load_file("_data/dudect.yml"); raise "bad" unless d["measured"].length==4 && d["gate"]==0.20 && d["leak"]["before"]==0.70; puts "OK: #{d["measured"].map{|m| m["tau"]}.inspect}"'`
Expected: `OK: [0.0044, 0.0708, 0.0071, 0.0063]`

- [ ] **Step 3: Commit**

```bash
git add _data/dudect.yml
git commit -m "data: public dudect constant-time facts for the visualizer

Sourced from gm-crypto-rs SECURITY.md @ v0.16.0. Four measured |tau|
values + the caught-leak before/after + gate constants. Facts only.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Add the bilingual i18n strings

**Files:**
- Modify: `_data/i18n.yml` (add `dudect:` under both `en:` and `zh:`)

- [ ] **Step 1: Add the EN subtree**

In `_data/i18n.yml`, the `en:` block ends just before the top-level `zh:` line. Its last sub-key is `notes:` (with `all`/`read_more`/`none`). Add a `dudect:` sub-key immediately after the `en:` `notes:` block (2-space indent, matching siblings), before `zh:`:

```yaml
  dudect:
    title: "Constant-time, measured"
    intro: "Each secret-touching path is timed against the |τ| gate. Low |τ| = no leak detected under the budget; the gate fails the build if a path crosses it."
    axis_label: "|τ| (timing-leak statistic)"
    gate_label: "PR gate |τ| < 0.20"
    control_label: "negative_control — must fire here (proof the detector isn't blind)"
    landscape_heading: "The gate landscape"
    leak_heading: "The leak it caught"
    leak_label: "crypto-bigint 0.6 → 0.7.3: a real invert leak, caught and fixed"
    context: "4 of 18 real targets shown with published values; every real target gates under 0.20."
    caveat: "dudect reports detection events — a low |τ| means no leak was detected under the budget given, not that none exists."
    provenance: "Measured: v0.2 W0 harness, 100K samples (pre-2026-05-12 runner). The two invert diagnostics later moved to telemetry + a |τ| ≥ 0.55 sentinel."
    source: "Source: gm-crypto-rs SECURITY.md @ v0.16.0"
    table_caption: "Published dudect measurements (gm-crypto-rs @ v0.16.0)"
    col_target: "Target"
    col_measures: "What it measures"
    col_tau: "|τ|"
    col_gate: "Gate"
    col_status: "Status"
    status_pass: "under gate"
    status_fire: "must fire"
    leak_before_row: "before (crypto-bigint 0.6)"
    leak_after_row: "after (0.7.3 upgrade)"
```

- [ ] **Step 2: Add the ZH subtree**

The `zh:` block is the last top-level block (ends at end of file with `notes:`). Add a `dudect:` sub-key after the `zh:` `notes:` block (2-space indent):

```yaml
  dudect:
    title: "把常量时间测出来"
    intro: "每条涉密路径都对着 |τ| 门禁计时。|τ| 低，表示在该预算下没测到泄漏；一旦某条路径越过门禁，构建就失败。"
    axis_label: "|τ|（时序泄漏统计量）"
    gate_label: "PR 门禁 |τ| < 0.20"
    control_label: "negative_control —— 必须在这里触发（证明检测器不是瞎的）"
    landscape_heading: "门禁全景"
    leak_heading: "它抓到的那次泄漏"
    leak_label: "crypto-bigint 0.6 → 0.7.3：一次真实的 invert 泄漏，被抓到并修掉"
    context: "18 条真实路径中有 4 条带公开数值；每条真实路径都压在 0.20 以下。"
    caveat: "dudect 报的是检测事件 —— |τ| 低只说明在给定预算下没测到泄漏，并不等于不存在。"
    provenance: "测量环境：v0.2 W0 harness，100K 采样（2026-05-12 之前的 runner）。两个 invert 诊断后来转为遥测 + |τ| ≥ 0.55 的兜底哨兵。"
    source: "来源：gm-crypto-rs SECURITY.md @ v0.16.0"
    table_caption: "公开的 dudect 测量值（gm-crypto-rs @ v0.16.0）"
    col_target: "目标"
    col_measures: "测的是什么"
    col_tau: "|τ|"
    col_gate: "门禁"
    col_status: "状态"
    status_pass: "在门禁内"
    status_fire: "必须触发"
    leak_before_row: "修复前（crypto-bigint 0.6）"
    leak_after_row: "修复后（升级到 0.7.3）"
```

- [ ] **Step 3: Verify both parse and are parallel**

Run: `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby -ryaml -e 'd=YAML.load_file("_data/i18n.yml"); en=d["en"]["dudect"].keys.sort; zh=d["zh"]["dudect"].keys.sort; raise "desync: #{(en-zh)|(zh-en)}" unless en==zh; puts "OK #{en.length} keys, parallel"'`
Expected: `OK 22 keys, parallel`

- [ ] **Step 4: Commit**

```bash
git add _data/i18n.yml
git commit -m "i18n: dudect visualizer strings (en+zh)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Build the SVG-chart include

**Files:**
- Create: `_includes/dudect-chart.html`

This include computes SVG x-coordinates in Liquid (`x = margin_l + tau/axis_max * plot_w`) so the chart is server-rendered (no JS). The viewBox is `0 0 720 300`. Layout: left margin 40, right margin 30, plot width 650; axis baseline at y=210; gate line full height; measured points as a clustered row near the axis; the leak arrow as a second row at y=120.

- [ ] **Step 1: Write the include**

Create `_includes/dudect-chart.html` with exactly this content:

```liquid
{%- comment -%}
  Constant-time visualizer. Server-rendered inline SVG (no JS) + an always-
  visible data table that carries the same numbers (the a11y / no-SVG / JS-off
  fallback). All numbers come from _data/dudect.yml (pinned to public v0.16.0
  state by scripts/validate_site.rb). Strings from i18n.yml dudect subtree.
  Non-interactive figure: no hover/click targets, so no WCAG 2.5.8 concern.
{%- endcomment -%}
{%- assign d = site.data.dudect -%}
{%- assign t = site.data.i18n[page.lang].dudect -%}
{%- assign W = 720 -%}
{%- assign H = 300 -%}
{%- assign ml = 40 -%}
{%- assign mr = 30 -%}
{%- assign plotw = 650 -%}
{%- assign axis_y = 210 -%}
{%- assign leak_y = 120 -%}
{%- comment -%} helper: x for a given tau = ml + tau/axis_max * plotw {%- endcomment -%}
{%- assign gate_x = d.gate | times: 1.0 | divided_by: d.axis_max | times: plotw | plus: ml -%}
{%- assign sentinel_x = d.sentinel | divided_by: d.axis_max | times: plotw | plus: ml -%}
{%- assign control_x = d.control_floor | divided_by: d.axis_max | times: plotw | plus: ml -%}
{%- assign before_x = d.leak.before | divided_by: d.axis_max | times: plotw | plus: ml -%}
{%- assign after_x = d.leak.after | divided_by: d.axis_max | times: plotw | plus: ml -%}
<figure class="dudect reveal" aria-labelledby="dudect-cap">
  <figcaption id="dudect-cap" class="dudect__title">{{ t.title | escape }}</figcaption>
  <p class="dudect__intro">{{ t.intro | escape }}</p>
  <svg class="dudect__chart" viewBox="0 0 {{ W }} {{ H }}" role="img"
       aria-label="{{ t.title | escape }}. {{ t.context | escape }}"
       xmlns="http://www.w3.org/2000/svg">
    <!-- axis baseline -->
    <line class="dudect__axis" x1="{{ ml }}" y1="{{ axis_y }}" x2="{{ W | minus: mr }}" y2="{{ axis_y }}"/>
    <text class="dudect__axis-label" x="{{ ml }}" y="{{ H | minus: 12 }}">{{ t.axis_label | escape }}</text>
    <!-- axis ticks: 0, gate, sentinel, control -->
    <g class="dudect__ticks">
      <text x="{{ ml }}" y="{{ axis_y | plus: 20 }}" text-anchor="middle">0</text>
      <text x="{{ sentinel_x }}" y="{{ axis_y | plus: 20 }}" text-anchor="middle">0.55</text>
      <text x="{{ control_x }}" y="{{ axis_y | plus: 20 }}" text-anchor="middle">1.0</text>
    </g>
    <!-- gate line -->
    <line class="dudect__gate" x1="{{ gate_x }}" y1="40" x2="{{ gate_x }}" y2="{{ axis_y }}"/>
    <text class="dudect__gate-label" x="{{ gate_x | plus: 6 }}" y="52">{{ t.gate_label | escape }}</text>
    <!-- sentinel marker (subtle) -->
    <line class="dudect__sentinel" x1="{{ sentinel_x }}" y1="{{ axis_y | minus: 30 }}" x2="{{ sentinel_x }}" y2="{{ axis_y }}"/>
    <!-- negative_control zone past 1.0 -->
    <rect class="dudect__control" x="{{ control_x }}" y="{{ axis_y | minus: 40 }}" width="{{ W | minus: mr | minus: control_x }}" height="40"/>
    <text class="dudect__control-label" x="{{ control_x }}" y="{{ axis_y | minus: 48 }}">{{ t.control_label | escape }}</text>
    <!-- Row A: the four measured points, clustered near zero, on the axis -->
    <g class="dudect__points">
      {%- for m in d.measured -%}
      {%- assign px = m.tau | divided_by: d.axis_max | times: plotw | plus: ml -%}
      <circle class="dudect__pt" cx="{{ px }}" cy="{{ axis_y }}" r="4"/>
      {%- endfor -%}
    </g>
    <text class="dudect__cluster-label" x="{{ ml }}" y="{{ axis_y | minus: 14 }}">{{ d.measured.size }}× ct_* &lt; 0.20</text>
    <!-- Row B: the caught leak — arrow from before (right, danger) to after (left, ok) -->
    <g class="dudect__leak">
      <text class="dudect__leak-heading" x="{{ ml }}" y="{{ leak_y | minus: 24 }}">{{ t.leak_heading | escape }}</text>
      <line class="dudect__leak-arrow" x1="{{ before_x }}" y1="{{ leak_y }}" x2="{{ after_x | plus: 10 }}" y2="{{ leak_y }}" marker-end="url(#dudect-arrow)"/>
      <circle class="dudect__leak-before" cx="{{ before_x }}" cy="{{ leak_y }}" r="5"/>
      <text class="dudect__leak-before-label" x="{{ before_x }}" y="{{ leak_y | minus: 10 }}" text-anchor="middle">≈{{ d.leak.before }}</text>
      <circle class="dudect__leak-after" cx="{{ after_x }}" cy="{{ leak_y }}" r="5"/>
      <text class="dudect__leak-after-label" x="{{ after_x }}" y="{{ leak_y | plus: 22 }}" text-anchor="middle">≈{{ d.leak.after }}</text>
    </g>
    <defs>
      <marker id="dudect-arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
        <path d="M0,0 L10,5 L0,10 z" class="dudect__arrowhead"/>
      </marker>
    </defs>
  </svg>
  <p class="dudect__caveat">{{ t.caveat | escape }}</p>
  <table class="dudect__table">
    <caption>{{ t.table_caption | escape }}</caption>
    <thead>
      <tr>
        <th scope="col">{{ t.col_target | escape }}</th>
        <th scope="col">{{ t.col_measures | escape }}</th>
        <th scope="col">{{ t.col_tau | escape }}</th>
        <th scope="col">{{ t.col_gate | escape }}</th>
        <th scope="col">{{ t.col_status | escape }}</th>
      </tr>
    </thead>
    <tbody>
      {%- for m in d.measured -%}
      <tr>
        <td><code>{{ m.target }}</code></td>
        <td>{{ m.desc[page.lang] | default: m.desc.en | escape }}</td>
        <td>{{ m.tau }}</td>
        <td>&lt; {{ d.gate }}</td>
        <td>{{ t.status_pass | escape }}</td>
      </tr>
      {%- endfor -%}
      <tr>
        <td><code>negative_control</code></td>
        <td>{{ t.control_label | escape }}</td>
        <td>&gt; {{ d.control_floor }}</td>
        <td>&gt; {{ d.control_floor }}</td>
        <td>{{ t.status_fire | escape }}</td>
      </tr>
      <tr>
        <td><code>{{ d.leak.what[page.lang] | default: d.leak.what.en | escape }}</code></td>
        <td>{{ t.leak_before_row | escape }}</td>
        <td>≈{{ d.leak.before }}</td>
        <td>&lt; {{ d.gate }}</td>
        <td>{{ t.status_fire | escape }}</td>
      </tr>
      <tr>
        <td><code>{{ d.leak.what[page.lang] | default: d.leak.what.en | escape }}</code></td>
        <td>{{ t.leak_after_row | escape }}</td>
        <td>≈{{ d.leak.after }}</td>
        <td>&lt; {{ d.gate }}</td>
        <td>{{ t.status_pass | escape }}</td>
      </tr>
    </tbody>
  </table>
  <p class="dudect__provenance">{{ t.provenance | escape }}
    <a href="{{ d.source_url }}" rel="noopener noreferrer">{{ t.source | escape }} ↗</a>
  </p>
</figure>
```

- [ ] **Step 2: Commit (renders in Task 4)**

```bash
git add _includes/dudect-chart.html
git commit -m "feat: dudect-chart include — server-rendered SVG + data table

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Wire the include into both gm-crypto pages

**Files:**
- Modify: `projects/gm-crypto-rs.html` (after the Evidence `<p>`, before `<details class="drawer">`)
- Modify: `zh/projects/gm-crypto-rs.html` (same position)

- [ ] **Step 1: Insert into the EN page**

In `projects/gm-crypto-rs.html`, find the end of the Evidence paragraph and the drawer that follows (currently lines ~146–148):

```html
            reference, and the runnable demo.
        </p>
        <details class="drawer">
```

Replace with:

```html
            reference, and the runnable demo.
        </p>
        {% include dudect-chart.html %}
        <details class="drawer">
```

- [ ] **Step 2: Insert into the ZH page**

In `zh/projects/gm-crypto-rs.html`, find the Evidence paragraph end and the drawer (around line 136–138). The paragraph ends `...也都在。</p>` and is followed by `<details class="drawer">`. Insert the same include line between them:

```html
        </p>
        {% include dudect-chart.html %}
        <details class="drawer">
```

(Match the exact closing `</p>` of the Evidence paragraph that precedes `<details class="drawer">` — there is only one `<details class="drawer">` in the file, so this anchor is unique.)

- [ ] **Step 3: Build and confirm both render**

Run: `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bundle exec jekyll build`
Then: `grep -c 'class="dudect' _site/projects/gm-crypto-rs/index.html _site/zh/projects/gm-crypto-rs/index.html`
Expected: each file reports a non-zero count (the `<figure class="dudect ...">` plus `dudect__*` elements).

Then confirm the four tau values landed in the EN table:
Run: `grep -oE '0\.(0044|0708|0071|0063)' _site/projects/gm-crypto-rs/index.html | sort -u | tr '\n' ' '`
Expected: `0.0044 0.0063 0.0071 0.0708`

- [ ] **Step 4: Confirm no <h2> entered the figure (contents-rail safety)**

Run: `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby -e 'h=File.read("_site/projects/gm-crypto-rs/index.html"); puts(h.match?(/<figure class="dudect.*?<h2/m) ? "BAD: h2 in figure" : "OK: no h2 in figure")'`
Expected: `OK: no h2 in figure`

- [ ] **Step 5: Commit**

```bash
git add projects/gm-crypto-rs.html zh/projects/gm-crypto-rs.html
git commit -m "feat: embed constant-time visualizer in gm-crypto Evidence (en+zh)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Style the visualizer (tokens only)

**Files:**
- Modify: `assets/css/style.css` (append a `.dudect` block at end of file, matching the Phase-1 append style)

- [ ] **Step 1: Append the CSS block**

Append to the end of `assets/css/style.css`:

```css

/* =========================================================
   Constant-time visualizer (Phase 2). Server-rendered inline SVG +
   data table. Tokens only; dark theme adapts via --bg-sunk/--rule/--fg
   overrides. Status hues reinforce position+text, never sole signal.
   ========================================================= */
.dudect {
    margin: var(--space-6) 0 var(--space-8);
    padding: var(--space-5);
    border: 1px solid var(--rule);
    border-radius: 4px;
    background: var(--bg-sunk);
}
.dudect__title {
    font-family: var(--mono);
    font-size: var(--text-xs);
    letter-spacing: 0.04em;
    text-transform: uppercase;
    color: var(--fg-subtle);
    margin: 0 0 var(--space-2);
}
.dudect__intro {
    font-family: var(--sans);
    font-size: var(--text-sm);
    color: var(--fg-muted);
    margin: 0 0 var(--space-4);
    max-width: var(--maxw-reading, 42rem);
}
.dudect__chart {
    width: 100%;
    height: auto;
    overflow: visible;
}
/* SVG strokes/fills via tokens. font-size in SVG text is in user units. */
.dudect__axis { stroke: var(--rule); stroke-width: 1.5; }
.dudect__axis-label,
.dudect__ticks text { font-family: var(--mono); font-size: 11px; fill: var(--fg-subtle); }
.dudect__gate { stroke: var(--accent); stroke-width: 1.5; stroke-dasharray: 4 3; }
.dudect__gate-label { font-family: var(--mono); font-size: 11px; fill: var(--accent); }
.dudect__sentinel { stroke: var(--fg-subtle); stroke-width: 1; stroke-dasharray: 2 3; }
.dudect__control { fill: var(--danger); opacity: 0.10; }
.dudect__control-label,
.dudect__cluster-label { font-family: var(--mono); font-size: 11px; fill: var(--fg-muted); }
.dudect__pt { fill: var(--status-released); }
.dudect__leak-heading { font-family: var(--mono); font-size: 11px; fill: var(--fg-subtle); text-transform: uppercase; letter-spacing: 0.04em; }
.dudect__leak-arrow { stroke: var(--fg-muted); stroke-width: 1.5; }
.dudect__arrowhead { fill: var(--fg-muted); }
.dudect__leak-before { fill: var(--danger); }
.dudect__leak-after { fill: var(--status-released); }
.dudect__leak-before-label,
.dudect__leak-after-label { font-family: var(--mono); font-size: 12px; fill: var(--fg); }
.dudect__caveat {
    font-family: var(--sans);
    font-size: var(--text-sm);
    color: var(--fg-muted);
    font-style: italic;
    margin: var(--space-3) 0 var(--space-4);
}
.dudect__table {
    width: 100%;
    border-collapse: collapse;
    font-family: var(--sans);
    font-size: var(--text-sm);
    margin: 0 0 var(--space-3);
}
.dudect__table caption {
    text-align: left;
    font-family: var(--mono);
    font-size: var(--text-xs);
    letter-spacing: 0.04em;
    text-transform: uppercase;
    color: var(--fg-subtle);
    margin-bottom: var(--space-2);
}
.dudect__table th,
.dudect__table td {
    text-align: left;
    padding: var(--space-2) var(--space-3);
    border-bottom: 1px solid var(--rule);
    vertical-align: top;
}
.dudect__table th { color: var(--fg-subtle); font-weight: 600; }
.dudect__table code { font-family: var(--mono); font-size: var(--text-xs); }
.dudect__provenance {
    font-family: var(--sans);
    font-size: var(--text-xs);
    color: var(--fg-subtle);
    margin: 0;
}
/* Reduced-motion: the figure carries `reveal`; the global reveal/motion
   gate + the prefers-reduced-motion reset already neutralise its animation.
   No bespoke motion here, so nothing extra to disable. */
@media (max-width: 759px) {
    .dudect { padding: var(--space-4); }
    .dudect__table { font-size: var(--text-xs); }
    .dudect__table th, .dudect__table td { padding: var(--space-1) var(--space-2); }
}
```

- [ ] **Step 2: Build and verify brace balance + presence**

Run: `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bundle exec jekyll build && grep -c '.dudect__chart' _site/assets/css/style.css`
Expected: build succeeds; count ≥ 1.

- [ ] **Step 3: Commit**

```bash
git add assets/css/style.css
git commit -m "style: paper-and-ink CSS for the constant-time visualizer (tokens only)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: Validator guards (pin the public constants) + teeth-test

**Files:**
- Modify: `scripts/validate_site.rb`

The guards live next to the Phase-1 gm-crypto native-interactivity guards. Add a dudect block: (a) data-file constants pinned to public values; (b) figure + table + source link present on both built pages; (c) i18n parity; (d) CSS present.

- [ ] **Step 1: Add the data-constants + i18n-parity guard**

In `scripts/validate_site.rb`, after the glossary i18n-parity block (the `%w[en zh].each` loop that checks `glossary.#{term}` and `details.earlier_releases`), add:

```ruby
# --- Constant-time visualizer: pin the published dudect facts to public state ---
# The four |tau| values, the gate, and the caught-leak before/after MUST equal
# the values published in gm-crypto-rs SECURITY.md @ v0.16.0. A silent drift
# here would misrepresent public release state — fail CI instead.
dudect_path = ROOT.join("_data/dudect.yml")
if !dudect_path.exist?
  record(failures, "_data/dudect.yml: missing (constant-time visualizer data)")
else
  dd = YAML.load_file(dudect_path)
  expected_tau = { "ct_sign" => 0.0044, "ct_sign_k_class" => 0.0708,
                   "ct_fn_invert" => 0.0071, "ct_fp_invert" => 0.0063 }
  measured = (dd["measured"] || []).each_with_object({}) { |m, h| h[m["target"]] = m["tau"] }
  expected_tau.each do |target, tau|
    got = measured[target]
    record(failures, "_data/dudect.yml: #{target} |tau| is #{got.inspect}, expected #{tau} (public v0.16.0)") unless got == tau
  end
  record(failures, "_data/dudect.yml: gate must be 0.2 (public)") unless dd["gate"] == 0.20
  record(failures, "_data/dudect.yml: leak.before must be 0.7 (public)") unless dd.dig("leak", "before") == 0.70
  record(failures, "_data/dudect.yml: leak.after must be 0.006 (public)") unless dd.dig("leak", "after") == 0.006
  record(failures, "_data/dudect.yml: must NOT publish more than 4 per-target values (others are unpublished)") if (dd["measured"] || []).length != 4
  record(failures, "_data/dudect.yml: source_url must point at the public v0.16.0 tag") unless dd["source_url"].to_s.include?("v0.16.0")
end

# dudect i18n parity: every required key present + non-empty in both languages.
%w[en zh].each do |lang|
  %w[title intro axis_label gate_label control_label caveat provenance source
     table_caption col_target col_measures col_tau col_gate col_status
     status_pass status_fire].each do |key|
    record(failures, "i18n.yml: missing #{lang}.dudect.#{key}") if i18n.dig(lang, "dudect", key).to_s.empty?
  end
end
```

- [ ] **Step 2: Add the rendered-page + CSS guards**

Find the Phase-1 block that iterates the gm-crypto built pages checking `popovertarget="gloss-` and `<details`. Extend that same loop body (the `%w[projects/gm-crypto-rs/index.html zh/projects/gm-crypto-rs/index.html].each`) by adding these three lines inside it, after the existing `record(...)` calls:

```ruby
  record(failures, "#{relative}: missing constant-time visualizer figure (class=\"dudect\")") unless html.include?('class="dudect')
  record(failures, "#{relative}: visualizer missing data-table fallback (.dudect__table)") unless html.include?("dudect__table")
  record(failures, "#{relative}: visualizer missing public source link (v0.16.0)") unless html.include?("v0.16.0")
```

- [ ] **Step 3: Add the CSS-present guard**

In the CSS-checks block (where `@view-transition`, `.gloss-term`, `.gloss-def` are asserted), add one line:

```ruby
  record(failures, "style.css: missing .dudect visualizer styles") unless css.include?(".dudect__chart")
```

- [ ] **Step 4: Build, then run the validator — expect PASS**

Run: `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bundle exec jekyll build && LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb`
Expected: `Site validation passed`

- [ ] **Step 5: Teeth-test each new guard (break → fail → restore)**

For each, make the break, rebuild if it's a page/CSS guard, run the validator, confirm it FAILS with the expected message, then restore. Use this scripted check:

```bash
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby - <<'RUBY'
require 'fileutils'
def val; `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb 2>&1`; end
def build; `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bundle exec jekyll build 2>&1`; end
checks = []
# 1. data constant pin
f = "_data/dudect.yml"; s = File.read(f); FileUtils.cp(f, f+".bak")
File.write(f, s.sub("tau: 0.0044", "tau: 0.5"))
checks << ["tau-pin", val.include?("expected 0.0044")]
FileUtils.mv(f+".bak", f)
# 2. i18n parity
f = "_data/i18n.yml"; s = File.read(f); FileUtils.cp(f, f+".bak")
File.write(f, s.sub('caveat: "dudect reports', 'xaveat: "dudect reports'))
checks << ["i18n-parity", val.include?("missing en.dudect.caveat")]
FileUtils.mv(f+".bak", f)
# 3 + 4. page figure/table guards (operate on built _site, no rebuild needed)
f = "_site/projects/gm-crypto-rs/index.html"; s = File.read(f); FileUtils.cp(f, f+".bak")
File.write(f, s.gsub('class="dudect', 'class="xudect').gsub("dudect__table", "xudect__table"))
o = val; checks << ["page-figure", o.include?("missing constant-time visualizer figure")]
checks << ["page-table", o.include?("missing data-table fallback")]
FileUtils.mv(f+".bak", f)
# 5. CSS present
f = "_site/assets/css/style.css"; s = File.read(f); FileUtils.cp(f, f+".bak")
File.write(f, s.sub(".dudect__chart", ".xudect__chart"))
checks << ["css-present", val.include?("missing .dudect visualizer styles")]
FileUtils.mv(f+".bak", f)
checks.each { |n, ok| puts "#{ok ? 'PASS' : 'FAIL'}  #{n}" }
puts (checks.all? { |_, ok| ok } ? "ALL GUARDS FIRE" : "SOME GUARD DID NOT FIRE")
RUBY
```
Expected: every line `PASS`, final `ALL GUARDS FIRE`.

- [ ] **Step 6: Rebuild clean + final validate**

Run: `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bundle exec jekyll build && LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb`
Expected: `Site validation passed`

- [ ] **Step 7: Commit**

```bash
git add scripts/validate_site.rb
git commit -m "validator: pin dudect visualizer to public v0.16.0 state + presence guards

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: Browser verification (EN+ZH × light/dark, JS-off, no new JS)

**Files:** none (verification only)

- [ ] **Step 1: Confirm no new JS file was added**

Run: `git diff --stat main..HEAD -- assets/js/ | tail -1`
Expected: empty output (no JS files changed). Also: `ls assets/js/*.js | wc -l` → still `6`.

- [ ] **Step 2: Serve and screenshot via chrome-devtools MCP**

Start: `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bundle exec jekyll serve --port 4000 --detach` then verify `curl -s -o /dev/null -w "%{http_code}" http://localhost:4000/projects/gm-crypto-rs/` returns `200`.

Using chrome-devtools MCP, for each of the 4 combinations (EN/ZH × light/dark — set theme via `document.documentElement.setAttribute('data-theme', ...)`):
- Navigate to the page, scroll the `.dudect` figure into view.
- Assert in-page (`evaluate_script`): `document.querySelectorAll('.dudect__pt').length === 4`; the gate line x is left of every point's cx; `.dudect__table tbody tr` count === 6 (4 measured + control + 2 leak rows); `getComputedStyle(document.querySelector('.dudect')).backgroundColor` differs between light and dark.
- Screenshot each; eyeball: gate line + four green points clustered left, red control zone right, before/after arrow crossing the gate, CJK renders in ZH.

- [ ] **Step 3: Confirm JS-off render**

In chrome-devtools, disable JavaScript (or fetch the static `_site` file) and confirm the `.dudect__chart` SVG and `.dudect__table` are both present and the numbers are visible. The figure is server-rendered, so it must look identical minus the optional reveal animation.

- [ ] **Step 4: Reduced-motion**

Emulate `prefers-reduced-motion: reduce`; reload; confirm no animation plays and the figure is fully visible (the `reveal` class must not leave it hidden — the global gate handles this).

- [ ] **Step 5: Stop the server**

Run: `pkill -f "jekyll serve"`

No commit (verification only). If any assertion fails, fix the relevant include/CSS task and re-verify before proceeding.

---

## Task 8: External prose review (codex + grok) + apply real fixes

**Files:** `_data/dudect.yml`, `_data/i18n.yml` (only if a real fix is warranted)

- [ ] **Step 1: Run both reviews**

Write the visualizer's user-facing strings (the i18n `dudect` EN+ZH subtrees + the `_data/dudect.yml` `desc`/`what`) into a review prompt that states the authoritative facts (the four `|τ|`, the gate constants, the caught-leak, "detection not proof") and asks for: (a) accuracy vs public SECURITY.md; (b) EN precision / no-overclaim — the caveat must NOT imply a guarantee; (c) ZH native quality (商用密码/杂凑/分组密码 vocabulary, no 翻译腔). Run:
- `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 codex exec -s read-only --skip-git-repo-check "<prompt>" < /dev/null`
- `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 grok -p "<prompt>"`

- [ ] **Step 2: Judge findings (verify, don't blind-apply)**

Use the receiving-code-review discipline: accept only genuine accuracy errors, overclaims, or translationese; reject nitpicks and anything that breaks EN↔ZH parity or contradicts the public source. For any accepted fix, edit the string in `i18n.yml` or `dudect.yml`, rebuild, re-validate (the constant pins must still pass), and confirm parity.

- [ ] **Step 3: Commit any fixes**

```bash
git add _data/i18n.yml _data/dudect.yml
git commit -m "content: apply codex+grok fixes to visualizer copy (en+zh)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```
(Skip if no fixes were warranted; note that in the PR body.)

---

## Task 9: Open the PR (Frank merges)

**Files:** none

- [ ] **Step 1: Final build + validate**

Run: `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bundle exec jekyll build && LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb`
Expected: `Site validation passed`.

- [ ] **Step 2: Push the branch**

Run: `git push -u origin design/constant-time-visualizer`

- [ ] **Step 3: Open the PR**

Use `gh pr create --base main --head design/constant-time-visualizer` with a title like "Phase 2: constant-time visualizer (honest |τ|-vs-gate, zero new JS)" and a body covering: what it is; the honesty constraints (only 4 published values, W0-snapshot provenance, no fabricated dots, "detection not proof" caveat, the validator pin); zero new JS; a11y (table fallback, no sub-24px targets); EN+ZH; the before/after screenshots; and the note that the four values are pinned to public v0.16.0 state. End with the 🤖 Generated-with line. **Do not merge — Frank merges.**

- [ ] **Step 4: Report CI status**

After ~20s, run `gh pr checks <num>` and `gh pr view <num> --json mergeable,state` and report green/mergeable to the user.

---

## Self-Review (completed during planning)

- **Spec coverage:** data file (T1) ✓, i18n (T2) ✓, SVG+table include (T3) ✓, page wiring EN+ZH (T4) ✓, tokens-only CSS (T5) ✓, validator pin + presence + parity + teeth-test (T6) ✓, browser/JS-off/reduced-motion verify (T7) ✓, codex+grok review (T8) ✓, PR-no-merge (T9) ✓. Honesty constraints (only 4 points, no fabricated dots, W0 provenance, "detection not proof" caveat) are encoded in T1 comments, T3 context text + caveat, and T6 pin. Zero-new-JS asserted in T7.
- **Placeholder scan:** none — every code/string/command is concrete.
- **Type/name consistency:** `_data/dudect.yml` keys (`measured[].target/tau/desc`, `leak.before/after/what`, `gate`, `source_url`) are used identically in T3 include, T6 guard, and T7 assertions. i18n `dudect.*` key set is identical across T2 (definition), T3 (use), T6 (parity guard, 16 required keys ⊆ the 22 defined). SVG class names (`dudect__chart`, `dudect__pt`, `dudect__table`) match across T3/T5/T6/T7.
