# Visual Evolution Design (Figures, Editorial Dose, Second-Design Dark)

Created: 2026-06-11
Status: Approved for implementation planning

## Purpose

Move the site from disciplined to designed without changing its identity.
The 2026-06-11 design discussion found four gaps: the site is all type with
no graphic matter (the dudect chart is the only figure on the site — and the
most memorable element on it); page rhythm is flat, with every section at the
same middle register; the work-list rows looked under-rewarded (corrected
below); and dark mode reads as a value inversion rather than a second design.

Frank approved a blended direction: the figure system as the spine, a
measured dose of editorial drama, and a dark/detail finishing pass — staged
in that order, each shipping as its own PR inside the existing token system,
CSP envelope, and bilingual structure.

**Correction recorded during design:** the work-list hover reward already
shipped (`assets/css/style.css` — `.work-list__item:hover .work-list__row`
applies the elevated tint, 2px inset accent rail, accent title, with
`:focus-visible` parity). Stage 3 therefore covers what does *not* exist:
hero-proof row parity and the dark pass. Do not re-flag the work-list hover
as missing in future critiques.

## Stage 1 — Figure System (the spine)

A reusable monograph-figure pattern, then three figures.

### Markup pattern

```html
<figure class="fig">
    {% include figures/<name>.svg %}
    <figcaption class="fig__cap">fig. 3.1 — crate &amp; C ABI surface</figcaption>
</figure>
```

- `.fig` carries a strong hairline top rule (`1px solid var(--fg)`) and
  spacing; `.fig__cap` is mono, `--text-sm`, `--fg-muted` — a compact
  technical label, consistent with the type-system spec.
- ZH caption prefix is `图 3.1 —`. Captions are prose and live inline in
  each language's page, like all other project prose.
- Numbering is **per page** in document order, prefixed by the page's
  section number. All project detail pages sit in "(03) Work", so each page
  runs fig. 3.1, fig. 3.2, … independently. Pages never cross-reference
  each other's figures, so sibling pages reusing "3.1" is acceptable. On
  the gm-crypto-rs pages the new crate-graph figure precedes the dudect
  chart, which therefore takes fig. 3.2.

### Drawings

- One SVG per figure in `_includes/figures/<name>.svg`, included by both the
  EN page and its ZH mirror — single source per drawing.
- Inline SVG styled **only by classes defined in `style.css`**, using
  existing tokens: strokes `var(--fg)`, box fills `var(--bg-sunk)`, secondary
  strokes `var(--rule)`, labels `var(--mono)`. No `style=""` attributes —
  the CSP is `style-src 'self'` (presentation attributes like
  `stroke-width` are fine; colors go through classes so dark mode adapts
  automatically).
- Text labels inside drawings stay locale-neutral (crate names, `launchd`,
  API names). Anything that needs prose belongs in the caption. If a future
  figure genuinely needs translated labels, resolve them from a `figures:`
  subtree in `_data/i18n.yml` — escape hatch only, not the default.
- Accessibility: each SVG gets `role="img"` with `<title>` (and `<desc>`
  when the structure isn't obvious); the visible caption complements, not
  replaces, the accessible name. Label text must stay legible at rendered
  size (no sub-11px effective type).

### The first three figures

1. **gm-crypto-rs** — crate & C ABI surface: `sm2` / `sm3` / `sm4` modules
   feeding `gmcrypto-core`, feeding `gmcrypto-ffi` (C ABI, 72 entry
   points). Verify the entry-point count against the public v1.2.0 docs
   before drawing — source-of-truth rule applies to figures exactly as it
   does to prose.
2. **RepoLens** — repository → structured context + typed, decaying memory
   → 26 MCP tools → agent session.
3. **ghrunners** — launchd, process tree, log tails, GitHub API converging
   into typed findings, then guarded launchd control.

The existing dudect chart joins the numbering system as fig. 3.2 on the
gm-crypto-rs pages via a caption prefix only — its data, `_data/dudect.yml`
values, and validator pins are untouched, and the caption must keep the
pinned `@ v1.2.0` version token.

The home page deliberately gets **no** figure; the home-page readability
spec (2026-05-17) stays intact.

## Stage 2 — Editorial Dose (measured)

- **Ghost numerals.** An `aria-hidden="true"` span inside the section head /
  page header renders the section number as an oversized ghost:
  `var(--serif)` italic, `clamp(72px, 12vw, 128px)`, color from a new token
  `--ghost-ink` (light: `rgba(26, 24, 20, 0.07)`; dark:
  `rgba(237, 228, 204, 0.05)`). Absolutely positioned behind the head
  (head gets `position: relative`), `pointer-events: none`, no layout
  shift, no motion (nothing for `prefers-reduced-motion` to gate).
- **Where:** the four home-page section heads and the four top-level page
  headers (About, Work, Writing, Contact), EN and ZH. Project detail
  pages, the colophon, and 404 stay quiet.
- **Double rule.** The same heads get the monograph rule: `2px solid
  var(--fg)` over `1px solid var(--rule)` with a small gap.
- Pure CSS plus one decorative span per head. No JS.

## Stage 3 — Second-Design Dark + Reward Parity

- **Hero-proof parity.** Proof-ledger rows currently change only title
  color on hover; bring them to the work-list standard (elevated tint,
  2px inset accent rail, `:focus-visible` parity), respecting their
  tighter geometry.
- **Dark pass principle:** in dark, surfaces are warm-elevated
  (`--bg-elevated`) and accents are moonlit (`--accent` #9bb4ff family) —
  never a plain value flip. Applied deliberately to an enumerated list:
  hero-proof panel, dudect chart, install block, status pills, the audit
  drawer. Examples: accent hairlines where light mode uses plain rules on
  these panels; release numerals in accent.
- Tokens only. `--ghost-ink` (Stage 2) is the only planned new token; any
  further additions need a reason recorded in the PR.
- Stage 1 figures inherit the dark treatment automatically via tokens.

## Cross-Cutting Constraints

- **CSP unchanged:** no new JS files, no inline scripts, no inline style
  attributes, no external origins. Everything here is CSS, markup, and
  inline SVG.
- **Bilingual parity:** every change lands on the EN page and its ZH mirror
  in the same PR, per CLAUDE.md.
- **Tokens only:** no new color literals outside the `:root` /
  `[data-theme="dark"]` blocks.
- **Type system respected:** ghost numerals are display serif; figure
  captions are mono technical labels — both consistent with the
  2026-05-17 type spec.
- **Validation:** `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby
  scripts/validate_site.rb` must pass at every stage. The dudect caption
  edit must keep its pinned version token. A figure EN/ZH parity guard in
  the validator is optional follow-up, not required.

## Shipping

Three PRs in stage order — figures, editorial dose, dark pass — each
independently useful and revertible. This spec rides with the Stage 1 PR.

## Non-Goals

- No figure on the home page.
- No new fonts, no external assets, no analytics.
- No JS interactivity and no changes to the six existing JS files.
- No layout-grid redesign; the page structure and content are unchanged.
- No filter/sort UI on the work list (per existing convention).
