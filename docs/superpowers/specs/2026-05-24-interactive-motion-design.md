# Interactive motion: home-hero "decrypt" + site-wide scroll reveal

- **Date:** 2026-05-24
- **Status:** Approved (design), hardened after critical codex review — ready for implementation plan
- **Surface:** `frankxue831.github.io` (frankxue.dev), Jekyll static site
- **References:** Apple + Anthropic — restraint everywhere, one moment of obvious craft

## Goal

Make the site feel more alive on arrival without breaking its "Codex — paper & ink"
monograph restraint. Two layers:

1. **One signature moment** — the home hero title arrives *decrypted*: scrambled cipher
   glyphs resolve into the real headline. On-brand for a cryptographer; the single highlight.
2. **A quiet base** — content below the fold fades and rises gently as it enters the
   viewport, site-wide. Felt more than seen.

**Non-negotiable invariants** (these drove the post-review rewrite):
- The real, correct text is always in the DOM and in the accessibility tree (SEO + a11y).
- No layout shift / reflow at any frame.
- Everything **fails open**: JS off, script load failure, missing APIs, reduced-motion,
  print, and bfcache restores all resolve to *visible, correct, static* content.

## Locked decisions (from brainstorm)

| Decision | Choice |
| --- | --- |
| Ambition level | **B — restraint + one signature moment** |
| Signature | **Decrypt on arrival** of the home hero title |
| EN scramble | Latin/hex **cipher glyphs** → resolves to English |
| ZH scramble | **Cipher glyphs → 汉字** (same pool; resolves *into* the real Chinese) |
| Decrypt surface | **Home hero only** (`/` and `/zh/`). Inner-page titles do NOT decrypt. |
| Decrypt frequency | **Every fresh home load.** Skipped on bfcache back/forward restore (see C1.7). |
| Base polish | **Scroll-reveal site-wide** |
| Tech | **Vanilla JS, zero deps, no build step** |

## Scope

**In scope:** home hero decrypt (EN + ZH); site-wide scroll-reveal; full fail-open behavior.

**Out of scope (YAGNI):** cursor trails / easter eggs / pointer fields (level "C");
page-transition animations; sound; theme toggles; new hover states.

---

## Component 1 — Hero decrypt

### C1.1 DOM model (the key change from review)
- The `<h1 class="hero__title">` is **server-rendered with the real text** (plain lead +
  nested `<em>` accent), exactly as today — so SEO and no-JS get the real headline.
- JS **locks the accessible name**: it sets `aria-label` on the `<h1>` to the real,
  whitespace-normalized title and marks all animated descendants `aria-hidden="true"`, so
  assistive tech always reads the real headline, never cipher noise. (This is codex's
  sanctioned "stable accessible name + aria-hidden character spans" fix.)
- The scramble runs **in place** (no separate overlay): JS rewraps the title's graphemes
  into `inline-block` **cells** and animates their text. Because the cells ARE the `<h1>`'s
  own layout, wrapping is inherently identical to the final title.
- Resting state: cells hold the real graphemes — visually identical to today's title.

### C1.2 No reflow — pinned-width cells + word grouping
- **During the scramble**, each cell's width is **pinned to its real glyph's advance**, so
  swapping in a random glyph never changes width → no reflow (CLS = 0). The pin is
  **released when the animation settles** (see C1.5), so the final title is natural-width
  and responsive.
- **Line-break behavior is preserved:** consecutive Latin graphemes are grouped into a
  `white-space:nowrap` "word" wrapper (words never break mid-word; break only at spaces, as
  normal text). CJK graphemes are standalone cells that may break per character (normal CJK
  wrapping). Spaces are real break opportunities. The EN title (Latin words) and ZH title
  (CJK) each therefore wrap exactly as the final text.
- Cells preserve the `<em>` segment boundary; accent-segment cells inherit the em's indigo.

### C1.3 Glyph pool
`0 1 2 3 4 5 6 7 8 9 A B C D E F / \ { } [ ] # * + = $ % @ ?`
(no `<`, `>`, `&` — never enter `innerHTML`; prefer building cells with `textContent`).

### C1.4 Timing
- ~1s total, brisk: characters resolve **left → right**, glyphs re-roll on a short interval,
  settle by ~900–1100ms. Tunable constants in `decrypt.js`. No looping.

### C1.5 Font handling & responsiveness (no gate, no fixed final widths)
- Do **not** gate the start on `document.fonts.ready` — waiting would show the real title
  first, then scramble (the effect playing backwards). Build the cells and scramble
  **immediately** so the real title is never shown in final form first.
- Pin each cell's width to its real glyph's advance **only for the scramble** (so random
  glyphs don't reflow), then **release the pins on settle** (`style.width = ''`). The
  settled title therefore has natural widths: it renders correctly across web-font swaps
  with **no re-measure**, and stays **responsive** to the `clamp()` / mobile media-query
  title sizing — no clipping or gaps after a resize or orientation change.

### C1.6 Accessibility / SEO
- Accessible name = `aria-label` on the `<h1>` (the real title); animated cells are
  `aria-hidden`. Screen readers read the label, never cipher noise. No focus on the title;
  no `aria-live`.
- `prefers-reduced-motion: reduce` → set the `aria-label`, then **no cell rewrap, no
  scramble**; the real `<h1>` is left untouched and shown instantly (checked in JS via
  `matchMedia`, not only CSS).
- No-JS → real title shown (server-rendered resting state). Cells + `aria-label` only ever
  exist when JS runs.

### C1.7 Run frequency / bfcache
- Runs on every **fresh** home load (the chosen behavior).
- Lifecycle handlers are registered **before any async work**: on `pagehide` and on
  `pageshow` with `event.persisted === true` (bfcache restore) the decrypt **settles to the
  final title and cancels** — it never resumes or replays a mid-flight scramble. (Replaying
  on "back" delays comprehension and isn't "opening the page".)

### C1.8 Text capture / segmentation
- Read each segment's text with **whitespace normalized** (collapse the template's newlines
  and indentation; trim). Preserve the `<em>` boundary as two ordered segments.
- Iterate by **grapheme** (use `Intl.Segmenter` where available; fall back to
  `Array.from(str)` for code points) so the cell model is robust for CJK and future input.

### C1.9 Scoping
- Guard on element presence: run only if `document.querySelector('.hero__title')` exists
  (only the two home pages have `.hero`). No-op everywhere else.

---

## Component 2 — Scroll reveal (quiet base)

### C2.1 Enable gate (fail-open)
- A tiny **inline head script** adds the `motion` class to `<html>` **before paint** only
  when ALL are true: not `prefers-reduced-motion`, AND `'IntersectionObserver' in window`,
  AND `'fonts' in document` is not required here (reveal doesn't need fonts). If any fails,
  `.motion` is never added → `.reveal` has no hidden state → content is visible/static.
- **Watchdog:** the inline script also sets a timeout (e.g. 3s). If `reveal.js` hasn't
  signalled "ready" (e.g. set `document.documentElement.dataset.revealReady`), the watchdog
  **removes `.motion`**, revealing everything. Covers a failed/blocked `reveal.js` load.

### C2.2 CSS model
- `.motion .reveal { opacity: 0; transform: translateY(12px); }`
- `.motion .reveal.is-revealed { opacity: 1; transform: none; }` (transition via existing
  `--dur` / `--ease`). **Only `opacity` + `transform`** animate — no layout shift.
- `.motion .reveal:focus-within { opacity: 1; transform: none; }` — a keyboard user tabbing
  into a not-yet-revealed island reveals it immediately (no invisible focus targets).
- `@media print { .reveal { opacity: 1 !important; transform: none !important; } }`.

### C2.3 Targets — template-declared, never nested, never JS-tagged
- The `reveal` class is added **in templates/includes only** (declarative), so the start
  state is correct at first paint and JS never causes content to appear-then-hide.
- **One reveal level per content island — no nesting.** Concretely:
  - Pages whose body is prose/sections: put `reveal` on each `.section` / `.page-header`.
  - Where a `.work-list` is the island (home work section, projects index): put `reveal`
    on the `.work-list__item`s for a capped stagger, and **not** on their wrapping section.
- Final selector/class placement confirmed in the implementation plan, honoring "no nesting."

### C2.4 Initial viewport / bfcache / fast scroll
- Before (or at) observer setup, **synchronously mark every target already in or above the
  viewport as `.is-revealed`** so above-the-fold content is never hidden waiting on the
  deferred callback, and fast scrolls can't outrun it.
- Handle `pageshow` (incl. `persisted`): ensure all currently-visible targets are revealed.
- Observer is one-shot per element (unobserve after reveal). Threshold ≈ 0.12 with a small
  bottom root-margin.

### C2.5 Hero interaction
- The home hero keeps its existing `rise` entrance; the hero is **not** a reveal target
  (no double-animation). Reveal is strictly below-the-fold content.

---

## Architecture & files

- `assets/js/main.js` — **unchanged** (mobile nav only).
- `assets/js/reveal.js` — **new.** IntersectionObserver reveal + initial/bfcache sync +
  sets `revealReady` for the watchdog. Site-wide. Small IIFE.
- `assets/js/decrypt.js` — **new.** Home-hero overlay decrypt (C1). Guards on `.hero__title`.
- `_includes/head.html` — **new inline script:** the `.motion` enable-gate + fail-open
  watchdog (C2.1). See "CSP note" below.
- `_layouts/default.html` — add `defer` `<script>` for `reveal.js` and `decrypt.js`.
- `assets/css/style.css` — add `.reveal` / `.is-revealed` / `:focus-within` / `@media print`
  rules and the hero decrypt **cell** styles (`.hero-cell`, `.hero-word`); reuse `:root` tokens.
- Templates that gain a `reveal` class on targets (per C2.3): `_includes` partial(s) and/or
  `index.html`, `zh/index.html`, `about.html`, `projects.html`, `contact.html`,
  project-detail pages and ZH mirrors. Bilingual mirror invariant preserved.

**CSP note (P3):** the site has no CSP today, so the inline gate works as-is. To stay
CSP-ready, the implementation will keep the inline script **byte-stable** and documented so
a `script-src` hash can be added later, or move it to a tiny same-origin blocking script
placed before the stylesheet. Decision recorded; not blocking.

## Performance
- Decrypt: one overlay updated on a short interval for ~1s, then stopped and removed — no
  lingering timers, no rAF loop left running.
- Reveal: `IntersectionObserver` (no scroll listeners); per-element disconnect after reveal.
- Animate only `transform` + `opacity`. Two small same-origin JS files; no third-party deps.

## Verification
- `bundle exec jekyll build` clean; `scripts/validate_site.rb` passes (no email /
  private-source surfaces touched).
- `codex review --uncommitted` before commit; no blocking findings.
- Manual matrix:
  - Home **EN** + **ZH**: decrypt plays once, **no reflow/jiggle**, settles to the exact
    correct title (accent indigo).
  - **No layout shift** measured (title box stable; no CLS).
  - `prefers-reduced-motion` → instant static titles + instant reveal.
  - **JS disabled** → all text visible, nothing hidden.
  - **Simulated `reveal.js` load failure / no IntersectionObserver** → watchdog reveals all.
  - Back/forward (bfcache) → no decrypt replay; content visible.
  - **Keyboard tab** through a page → never focuses an invisible element.
  - **Print preview** → all content visible.
  - Mobile nav still works (main.js untouched); no console errors.

## Decisions deferred to the plan (non-blocking)
- Exact reveal selector list + stagger cap (honoring C2.3 no-nesting).
- Final decrypt timing constants and cell-measurement method (canvas `measureText` vs
  per-cell `getBoundingClientRect`).
- Whether the inline gate stays inline (hash-documented) or becomes a tiny blocking file.
