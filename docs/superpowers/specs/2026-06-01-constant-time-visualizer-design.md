# Constant-time visualizer — design

**Date:** 2026-06-01
**Status:** approved (brainstorm), pending spec review
**Scope:** Phase 2 of the interactivity roadmap — the signature piece. One PR.

## Context

The deep-research pass on interactivity concluded the site's highest-leverage
move is **explanatory** interactivity that makes the technical depth legible —
and named the constant-time visualizer as the signature opportunity, *with* an
explicit anti-pattern: never invent or mislead with data, because the site's
whole thesis is auditability / truth-seeking. Phase 1 (View Transitions, popover
glossary, audit drawer) shipped in PR #38. This is Phase 2.

The goal: make "constant-time, **verified**" legible at a glance on the
gm-crypto-rs page — turning the abstract claim into a picture a visitor
immediately grasps, sourced entirely from public, tagged release state.

### The honesty constraint that drives the form

The authoritative public data (gm-crypto-rs `SECURITY.md` + README +
`docs/v0.5-dudect-recalibration.md`, all present at the **v0.16.0** tag) is
**scalar `|τ|` per path against a gate** — NOT raw timing-sample distributions.
So a "two overlapping timing histograms" visual would require fabricating sample
data, which the auditability thesis forbids. The honest — and more compelling —
shape is a **`|τ|` number line against the 0.20 gate**.

What is actually published (and may be shown):
- **Four measured `|τ|` values** (v0.2 "W0" harness, 100K samples):
  `ct_sign` = 0.0044, `ct_fp_invert` = 0.0063, `ct_fn_invert` = 0.0071,
  `ct_sign_k_class` = 0.0708.
- **The caught leak (before/after):** the v0.1-era `crypto-bigint 0.6`
  `ConstMontyForm::invert` leak measured `|τ| ≈ 0.70` in isolation → after the
  `crypto-bigint 0.6 → 0.7.3` upgrade, both invert diagnostics measured
  `|τ| ≈ 0.006` (two orders of magnitude under the gate).
- **The gate structure:** most real targets gate at `|τ| < 0.20`;
  `negative_control` must gate the *opposite* way (`|τ| > 1.0` **must** fire, to
  prove the detector isn't blind); `ct_sign_k_class` nightly-only at `0.25`; the
  two invert diagnostics moved to telemetry + a `|τ| ≥ 0.55` gross-regression
  sentinel after the 2026-05-12 runner recalibration.
- **The surface size:** 18 real `ct_*` targets + the `negative_control`.

What is NOT published (and must NOT be invented):
- Per-target measured `|τ|` for the other **14 of 18** targets (they carry gate
  *policy* in `SECURITY.md`, but no published per-target number). The chart plots
  ONLY the four measured points; "18 targets" is conveyed as context text, never
  as 14 fabricated dots.
- The four W0 values were measured on the **pre-2026-05-12 runner image**; the
  same doc records the two invert diagnostics later drifting to `[0.29–0.40]` on
  the current shared runner (the reason they moved to telemetry + the 0.55
  sentinel). The visual therefore presents the four as a **W0 baseline
  snapshot** with that provenance — never as "today's live gate readings."

## What we're building

A server-rendered (Liquid → inline SVG) **`|τ|` number line** embedded in the
*Evidence* section of the gm-crypto-rs page (EN + ZH), plus an always-visible
data table beneath it that carries the same numbers and doubles as the
accessibility / no-SVG / JS-off fallback. **Zero new JavaScript.**

### Visual: one linear `|τ|` axis (0 → ~1.1), two annotated rows

- **Axis:** linear (deliberately — not log: linear honestly shows the real paths
  clustered in the noise near zero with vast headroom to the gate, and the
  caught-leak arrow visibly crossing the gate). Ticks at 0, 0.20 (gate), 0.55
  (sentinel), 1.0 (negative-control floor).
- **Gate line** at 0.20: a labeled vertical rule ("PR gate `|τ| < 0.20`").
- **Row A — the gate landscape:** the four measured points plotted near zero,
  each a labelled marker (`ct_sign` etc.); a `negative_control` zone past 1.0
  labelled "must fire here — proof the detector isn't blind"; context text
  "4 of 18 targets shown with published values; all real targets gate < 0.20."
- **Row B — the leak it caught:** a left-pointing arrow from `≈0.70` (right of
  the gate, drawn in the `--danger` hue) sweeping across the gate to `≈0.006`
  (left, `--status-released`), labelled
  "`crypto-bigint 0.6 → 0.7.3`: a real `invert` leak, caught and fixed."
- **Caption (verbatim caveat):** "dudect reports *detection events* — a low
  `|τ|` means no leak was detected under the budget given, not that none exists."
- **Provenance line:** "Measured: v0.2 W0 harness, 100K samples (pre-2026-05-12
  runner). Source: gm-crypto-rs `SECURITY.md` @ v0.16.0" → links to the public
  repo. A second clause notes the invert diagnostics' later drift → telemetry +
  0.55 sentinel, so the snapshot is never mistaken for the current gate.

### Data table (always visible, beneath the chart)

Columns: target · what it measures · `|τ|` · gate · status. Rows = the four
measured targets + `negative_control` (shown as ">1.0, must fire") + the
before/after leak as two rows. This table IS the auditable artifact and the
a11y / no-SVG / JS-off fallback. No data lives only in the SVG.

## Architecture (no-build, zero new JS)

Three new/changed units, each single-purpose:

1. **`_data/dudect.yml`** — the facts only (no prose styling). Schema:
   ```yaml
   gate:        0.20      # PR-smoke blocking gate
   gate_nightly: 0.25     # ct_sign_k_class nightly
   sentinel:    0.55      # invert-diagnostics gross-regression
   control_floor: 1.0     # negative_control must exceed
   axis_max:    1.1
   source_url:  "https://github.com/frankxue831/gm-crypto-rs/blob/v0.16.0/SECURITY.md"
   measured:                # the four published W0 values
     - { target: ct_sign,         tau: 0.0044, desc: { en: "...", zh: "..." } }
     - { target: ct_sign_k_class, tau: 0.0708, desc: { en: "...", zh: "..." } }
     - { target: ct_fn_invert,    tau: 0.0071, desc: { en: "...", zh: "..." } }
     - { target: ct_fp_invert,    tau: 0.0063, desc: { en: "...", zh: "..." } }
   leak:                    # the caught before/after
     before: 0.70
     after:  0.006
     what:   { en: "crypto-bigint 0.6 ConstMontyForm::invert", zh: "..." }
   ```
   Mirrors the existing `_data/projects.yml` bilingual-subkey convention. Numbers
   are language-neutral; only `desc`/`what` are bilingual. (The `"..."` above are
   schema illustration; the actual short descriptions are authored at
   implementation time and reviewed by codex/grok with the rest of the prose.)

2. **`_includes/dudect-chart.html`** — renders the inline SVG **server-side**
   with Liquid. Coordinate math in Liquid filters
   (`x = tau | times: scale | plus: margin`), so the chart is fully present with
   JS off. Reuses the site's `currentColor` + design-token SVG convention
   (same approach as the nav/theme icons). Emits: `<figure>` →
   `<svg role="img" aria-label="{i18n summary}">` (axis, gate line, the four
   points, the negative-control zone, the before/after arrow) → `<figcaption>`
   (caveat + provenance) → the data `<table>`. All strings via
   `site.data.i18n[page.lang].dudect`.

3. **Page edits** — insert `{% include dudect-chart.html %}` into the *Evidence*
   section of `projects/gm-crypto-rs.html` and `zh/projects/gm-crypto-rs.html`,
   after the dudect prose paragraph, before the `version-grid`. Must not disturb
   the six case-study `<h2>`s, their order, the `version-grid`-before-`Next`
   guard, or the contents-rail (`<figure>` carries no `<h2>`).

4. **`_data/i18n.yml`** — new `dudect:` subtree (en + zh): chart title, axis
   label, gate/sentinel/control labels, the two row headings, the caveat
   sentence, provenance template, table column headers, status words
   (pass/fail/"must fire").

5. **`assets/css/style.css`** — a `.dudect` component block, tokens only
   (`--bg-sunk`, `--rule`, `--accent`, `--danger`, `--status-released`,
   `--fg-muted`, `--mono`, `--space-*`). Chart + table styling matched to the
   "paper & ink" `.install` / `.version-grid` look. The status hues are AA-
   verified and used ONLY as reinforcement to position+text, never as the sole
   signal. Dark mode adapts via existing token overrides.

### Optional motion (still zero new JS)

The before/after arrow MAY get a one-time draw-in by adding `reveal`/`.reveal`
to the figure so the existing `reveal.js` `motion` gate animates it on scroll;
static otherwise. Gated by `prefers-reduced-motion` (already handled globally).
No new script. If it complicates the SVG, ship static — the data is the point.

## Accessibility (WCAG 2.2 AA)

- SVG is `role="img"` with a concise summarizing `aria-label`; the adjacent
  `<table>` carries the full semantics for assistive tech and for JS/SVG-off.
- **No sub-24px interactive targets** — there is no hover/click detail layer;
  all detail lives in the always-visible table. This sidesteps SC 2.5.8 (target
  size) entirely. The visualizer is non-interactive by design (it's a figure,
  not a control), which is the right call for a minimalist, auditable artifact.
- Pass/fail is encoded by **position relative to the gate line + text labels**,
  never color alone. Color is reinforcement only.
- AA contrast re-checked in both themes (validator already asserts the relevant
  tokens; re-verify the chart text/marks).
- `prefers-reduced-motion` removes the optional arrow animation.

## Bilingual

- All chart/table/caption strings in `i18n.yml` `dudect:` (parity-checked, same
  mechanism as the glossary). Per-target `desc` + leak `what` in `_data/dudect.yml`.
- Numbers/units language-neutral; CJK in SVG `<text>` renders via the page font
  stack — browser-verified EN + ZH.

## Performance

- Server-rendered SVG → negligible payload, no runtime cost, no INP impact (no
  new JS). CLS-safe: the SVG has explicit `viewBox` + width/height so it reserves
  layout space.

## Error handling / fallbacks

- JS off → chart (server-rendered SVG) + table both fully present.
- SVG unsupported / images-off → the `<table>` carries every number.
- A future data edit that desyncs from public state is caught by a validator
  guard pinning the four `|τ|` constants (see below).

## Validator guards (all teeth-tested: break → fail → restore)

Add to `scripts/validate_site.rb`:
- `_data/dudect.yml` exists and parses; the four measured `|τ|` values equal the
  published constants `{0.0044, 0.0063, 0.0071, 0.0708}`, and `leak.before/after`
  equal `{0.70, 0.006}` — **pins the chart to public v0.16.0 state** (the
  auditability guard; a silent drift fails CI).
- gm-crypto EN + ZH built pages contain the chart figure
  (`class="dudect"`) and the data `<table>` (so the a11y fallback can't be
  dropped) and the source-attribution link.
- `i18n.yml` `dudect:` parity: every required key present + non-empty in en + zh.
- `.dudect` CSS present.
- Does NOT disturb existing case-study guards (re-run full suite green).

## Verification

1. `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bundle exec jekyll build` clean.
2. `… ruby scripts/validate_site.rb` passes; teeth-test each new guard.
3. Confirm **no new JS file**; existing 6 JS files unchanged.
4. Browser (jekyll serve + chrome-devtools), EN + ZH × light + dark: chart
   renders, gate line + four points + negative-control zone + before/after arrow
   correct; table matches; CJK renders; toggle reduced-motion (arrow static);
   disable JS → chart + table still present; check CLS (no reflow).
5. Cross-check every number against public `SECURITY.md` @ v0.16.0; codex + grok
   review the visualizer's prose/labels (EN precision + ZH native quality +
   no-overclaim + the "detection not proof" caveat intact).
6. Branch off main; PR with before/after screenshots + the zero-new-JS note +
   the public-source provenance. **Frank reviews & merges.**

## Out of scope (later)

- Live in-browser timing (coarsened browser timers mislead — against the thesis).
- A standalone explorable note (this is the inline Evidence version; a richer
  note could link to it later).
- Per-target values for the other 14 targets (not published; would be fabrication).
- Animating the four points / interactive hover detail (table is the detail layer).
