# Contents rail — scroll-spy section navigation (project detail pages)

Date: 2026-05-29
Status: shipped-pending (implementation + codex review, then PR)
Scope: project detail pages only (`projects/*.html` EN + `zh/projects/*.html` ZH)

## Why

The site already has two interactive layers: **motion** (hero decrypt, scroll
reveal) and **control** (light/dark/auto theme toggle). What it lacks is
**navigational interactivity** — feedback about *where you are* in a long
document and a fast way to jump around it.

The project detail pages are the only long-form reading surface, and they all
share an identical five-section spine:

> What it is · What is shipped / Current snapshot · What's different about it ·
> Next · What it isn't

That repeated structure across all six detail pages (3 EN + 3 ZH) makes a
contents rail a high-leverage, low-risk addition: one feature, six pages, zero
new per-page copy. A marginal contents rail is also quintessential
monograph/"Codex" furniture — it fits the paper-and-ink aesthetic rather than
fighting it.

The home and section pages are deliberately out of scope: they're short and
already richly interactive. Adding a rail there would be noise.

## What it is

A sticky **"On this page"** rail rendered in the right-margin whitespace of the
detail-page reading column. It:

1. lists the page's `<h2>` sections,
2. highlights the section you're currently reading (scroll-spy), and
3. jumps to a section on click.

It is built **entirely by JavaScript** from the existing heading structure —
no markup is added to any page template. If JS is off, the viewport is narrow,
or anything throws, the rail simply does not appear and the page reads exactly
as it does today. Pure progressive enhancement.

## Placement & responsive behavior

The detail page's reading section is:

```
<section class="section wrap reveal">
  <article class="project-detail prose"> … </article>   /* max-width: 64ch, left-aligned */
</section>
```

Inside the 1100px `.wrap`, the 64ch article leaves substantial right-margin
whitespace on wide viewports. That whitespace hosts the rail.

- **Wide (≥ 1024px):** JS adds `.has-toc` to the reading `.section`, turning it
  into a two-column grid — `[article 1fr] [rail auto]` with a column gap. The
  article keeps its 64ch cap and natural left position; the rail occupies the
  right column as `position: sticky`, offset below the sticky site header so it
  never slides under it. As you scroll the article, the rail stays pinned, then
  scrolls away naturally when the section ends.
- **Narrow (< 1024px):** the rail is `display: none` and the grid collapses to
  the original single-column block. The page is unchanged from today. A mobile
  contents affordance (e.g. a collapsible strip) is explicitly **out of scope**
  (YAGNI) — the pages are only five short sections and scroll fine on a phone.

Breakpoint rationale: at 1024px the content area (≈ 942px after gutters)
comfortably fits a 64ch article (~634px) + gap + a ~180px rail. Verified in
browser; tune if cramped.

## Structure (JS-built)

```html
<nav class="toc" aria-label="On this page">
  <p class="toc__label">On this page</p>
  <ol class="toc__list">
    <li class="toc__item">
      <a class="toc__link" href="#what-it-is">What it is</a>
    </li>
    …
  </ol>
</nav>
```

- Each `<h2>` gets a **stable, unique id**: reuse an existing `id` if present,
  else slugify the heading text (lowercase, non-alphanumerics → `-`, trim), and
  de-duplicate with a numeric suffix if a slug collides. CJK headings (the ZH
  pages) slugify to empty → fall back to `section-<n>`.
- The rail is inserted as the **last child** of the reading `.section` so it
  lands in the grid's right column.
- `aria-label` and the visible `.toc__label` come from i18n (see below).
- Ordered list (`<ol>`) because section order is meaningful.

## Scroll-spy

A `requestAnimationFrame`-throttled scroll handler computes the active heading:

> the **last** `<h2>` whose absolute document top is `≤ scrollY + threshold`,
> clamped to the first heading above that point and the last heading at the
> bottom of the page.

`threshold` ≈ sticky-header height + a small margin (~96px) so a section becomes
"current" as its heading reaches the top reading zone. The active link gets:

- `aria-current="true"` (removed from all others), and
- `.is-active` (accent text + a filled marker on the rail rule).

Recomputed on `load`, `scroll`, `resize`, and bfcache `pageshow`. No layout
thrash: reads are batched inside the rAF callback.

IntersectionObserver was considered but the "last heading above a threshold"
rule is more deterministic for the active-section semantics (IO's per-element
visibility makes "which one is current" ambiguous when several or none are on
screen). A scroll + rAF computation is ~20 lines and reliable.

## Navigation (clicks)

Plain `<a href="#id">` anchors. The stylesheet already sets
`html { scroll-behavior: smooth }` globally, and the existing
`prefers-reduced-motion` block already resets it to `auto`. So clicks
smooth-scroll natively and respect reduced motion **without any JS click
handler**. We only add `scroll-margin-top` to `.project-detail h2` so an
anchored/spied heading clears the sticky header.

## Styling (tokens only)

Paper-and-ink, restrained:

- `.toc` — mono, `--text-xs`/`--text-sm`, default `--fg-subtle`.
- A 1px `--rule` left border forms the rail; the active item shows a short
  `--accent` marker against that rule and `--fg`/`--accent` text.
- Generous line spacing; no boxes, no fills — it should read as a margin note,
  not a widget.

No new color values. **Dark theme** needs no extra rules — every value is a
token already remapped by `[data-theme="dark"]` and the no-JS dark fallback.
**Print:** `@media print` hides `.toc` and resets `.has-toc` to a single
column so the article prints full-width.

## i18n

Add a `toc` block to `_data/i18n.yml`:

| key       | en             | zh         |
|-----------|----------------|------------|
| `label`   | On this page   | 本页内容    |

The label is surfaced to JS via a `data-toc-label` attribute emitted on
`<body>` in `_layouts/default.html`, but **only** when `page.project_slug` is
set (i.e. detail pages), keeping `i18n.yml` the single source of truth and the
attribute off pages that don't need it. `contents.js` reads the attribute and
falls back to `"On this page"`.

## Fail-open matrix

| Condition                    | Result                                              |
|------------------------------|-----------------------------------------------------|
| JS disabled / throws         | No rail. Page identical to today. Headings still navigable via browser find. |
| Viewport < 1024px            | No rail. Single-column article.                     |
| `< 3` `<h2>` on the page     | No rail (not worth it).                             |
| Not a `.project-detail` page | Script no-ops (guard).                              |
| `prefers-reduced-motion`     | Anchor jumps are instant (CSS already handles it). Scroll-spy still tracks. |
| bfcache restore              | `pageshow` recomputes the active section.           |
| Dark / print                 | Inherits tokens; print hides the rail.              |

## Accessibility

- `<nav aria-label="On this page">` is a labelled navigation landmark.
- Active link carries `aria-current="true"`.
- Links are real anchors → keyboard focusable, work without JS pointer events.
- Color is never the only active signal: the active item also gets the marker +
  weight change, and `aria-current` exposes it to assistive tech.
- The rail is supplementary; the document's heading order is unchanged, so
  screen-reader heading navigation is unaffected.

## Files

| File | Change |
|------|--------|
| `assets/js/contents.js` | **new** — build rail + scroll-spy |
| `_layouts/default.html` | load `contents.js`; conditional `data-toc-label` on body |
| `assets/css/style.css` | `.toc` + `.has-toc` grid + h2 `scroll-margin-top` + print |
| `_data/i18n.yml` | `toc.label` en/zh |
| `scripts/validate_site.rb` | regression checks |

## Validator checks (regression)

- `contents.js` exists and is referenced in `default.html` (loads site-wide).
- CSS contains `.toc`, `.has-toc`, a `scroll-margin-top` on project-detail h2,
  and a print rule hiding `.toc`.
- `toc.label` present in i18n for both `en` and `zh`.
- Built detail pages (`_site/projects/*/index.html`) carry `data-toc-label`.

Each new check is teeth-tested (temporarily broken) to confirm it actually
fails before shipping.

## Out of scope (YAGNI)

- Mobile/narrow contents UI.
- Rails on home/about/projects-index/contact (short pages).
- Nested (h3) entries — detail pages only use h2.
- A separate reading-progress bar — the active-section highlight is the
  position signal; a second indicator would be redundant and bloggy.
