# Light/dark theme toggle

- **Date:** 2026-05-28
- **Surface:** `frankxue831.github.io` (frankxue.dev), Jekyll static site
- **Aesthetic anchor:** "Codex — paper & ink." Dark mode is *ink as paper*, not cold gray.

## Goal

Let the site adapt to a reader's light or dark preference — without losing its
monograph character or violating the editorial restraint. One quiet toggle in
the nav; everything else handled by the CSS token system and a pre-paint script.

## Invariants

- **No FOUC.** The correct theme is applied to `<html>` *before first paint*
  (inline head script). A reader on dark OS opening the site at night never sees
  a flash of paper.
- **`prefers-color-scheme` is the default.** No explicit choice ⇒ follow OS.
  Live: when the reader is in "auto" and toggles their OS, the page updates.
- **Fail-open.** JS off, blocked, or thrown ⇒ the CSS still resolves the right
  theme via `@media (prefers-color-scheme)`. Reader is never left dark-on-dark
  or light-on-light.
- **Accessibility tree is stable.** The toggle has a localized `aria-label`
  describing both current state and the next action; states announce on click.
- **Bilingual parity.** Toggle, state names, and `aria-label` are translated in
  `_data/i18n.yml` (EN + ZH).

## Locked decisions

| Decision | Choice |
| --- | --- |
| States | **Three: auto · light · dark.** Auto resolves at runtime. |
| Default | **Auto** (follows `prefers-color-scheme`). |
| Persistence | `localStorage["frankxue.theme"]` = `"light" \| "dark" \| "auto"` (or absent ⇒ auto). |
| Toggle UX | **Cycle on click:** auto → light → dark → auto. |
| Placement | **End of `.primary-nav`**, after the language switcher. Icon-only. |
| Pre-paint script | Inline in `<head>`, after `<meta charset>`. Sets `data-theme="light\|dark"` synchronously. |
| Live OS sync | `matchMedia('(prefers-color-scheme: dark)').addEventListener('change', …)` — re-resolves only when preference is `auto`. |
| `theme-color` meta | Two media-queried tags **+** JS updates on explicit override (so PWA chrome stays in sync). |
| Tech | Vanilla JS, no deps. Small IIFE. |

## Palette — "ink as paper"

Light theme is unchanged. Dark theme inverts the metaphor: the existing
ink color becomes the background; a warm parchment fg keeps the same family.
The indigo accent lifts for contrast on dark.

| Token | Light (unchanged) | Dark |
| --- | --- | --- |
| `--bg` | `#f5f1e8` (paper) | `#1a1814` (the existing `--fg`, inverted) |
| `--bg-elevated` | `#ece6d7` | `#23201a` |
| `--bg-sunk` | `#faf7f0` | `#13110d` |
| `--fg` | `#1a1814` | `#ede4cc` (warm parchment) |
| `--fg-muted` | `#6b6557` | `#a39880` |
| `--fg-subtle` | `#a39c8d` | `#6b6557` |
| `--rule` | `#d4cdb8` | `#2f2c25` |
| `--accent` | `#1e40af` (indigo) | `#9bb4ff` (lifted indigo) |
| `--accent-warm` | `#1e3a8a` | `#c2b8ff` |
| `--accent-cool` | `#3730a3` | `#7e93e6` |
| `--status-released` | `#15803d` | `#4ade80` |
| `--status-pre` | `#b45309` | `#f59e0b` |
| `--status-private` | `#8a8276` | `#8a8276` |
| `--danger` | `#b91c1c` | `#f87171` |

Grain texture (`.grain`): suppressed in dark — the paper-noise gesture doesn't
translate to ink; the eye reads it as banding rather than texture.

## CSS strategy

- Light tokens live in `:root` (already there — untouched).
- Dark overrides: a single `[data-theme="dark"] { … }` block.
- The pre-paint script *always* resolves `auto` to either `"light"` or
  `"dark"` and writes `data-theme="…"` — so the CSS only needs one explicit
  selector, never `:not(...)` chains.
- `@media print { :root, [data-theme="dark"] { … force light … } }` so printed
  output is always paper.

## Pre-paint script (head.html, after `<meta charset>`)

```js
(function () {
  try {
    var stored = localStorage.getItem('frankxue.theme');
    var pref = (stored === 'light' || stored === 'dark') ? stored : 'auto';
    var effective = pref;
    if (pref === 'auto') {
      effective = (window.matchMedia &&
        window.matchMedia('(prefers-color-scheme: dark)').matches) ? 'dark' : 'light';
    }
    document.documentElement.setAttribute('data-theme', effective);
  } catch (e) { /* fail open: CSS @media handles it */ }
})();
```

Runs before paint, fails open. Order in `<head>`: `<meta charset>`, theme gate,
motion gate, viewport.

## Toggle button

- Single `<button class="theme-toggle">` at the end of the primary nav.
- Icon-only (inline SVG). Three icons, swapped on state change:
  - `auto` → split sun/moon
  - `light` → sun
  - `dark` → moon
- `data-*` attributes carry the localized state names (Theme / Auto / Light /
  Dark, plus the bilingual aria templates) so `theme.js` builds aria-label
  without re-reading the DOM tree or duplicating strings.
- Initial server-rendered `aria-label` is the generic "Theme" so screen
  readers always have *something*; JS replaces it with the dynamic version on
  load and on each click.

## theme.js (defer, after main.js)

- On load: read pref, set `data-theme`, set button icon + aria-label, update
  `theme-color` meta if pref is explicit.
- On click: `pref = next(pref)`, persist (or clear, for `auto`), re-resolve,
  re-apply.
- On OS change (`matchMedia.change`): only act if `pref === 'auto'`.

## a11y

- `aria-label` describes current + next action, EN/ZH.
- Focus-visible inherits the site's global accent outline.
- No `aria-live` — the visual icon swap + new aria-label are enough; chatty
  live regions on every click are noisier than helpful.

## Fail-open matrix

- JS off → CSS `@media (prefers-color-scheme)` resolves correctly. Toggle
  invisible (we could hide it via `noscript`, but the simpler answer: button
  exists, click does nothing — and the rendered theme is correct).
  *Decision:* hide the toggle when JS is off using a small inline
  `noscript` override class, so we never present a non-functional control.
- localStorage blocked → behave as `auto`; toggle clicks update the in-memory
  preference but don't persist (the user sees the toggle work for the session).
- `matchMedia` missing → resolve to `light`.

## Verification

- `bundle exec jekyll build` clean; `scripts/validate_site.rb` passes.
- Manual matrix:
  - OS light + no localStorage → light renders, no flash, no console errors.
  - OS dark + no localStorage → dark renders, no flash, decrypt + reveal still play.
  - Toggle to dark on light OS → dark applied, persists across navigation + reload.
  - Toggle to light on dark OS → light applied, persists.
  - Toggle to auto → reverts to OS-tracking; changing OS theme updates page live.
  - JS disabled → CSS still resolves correctly; toggle hidden.
  - Reduced motion → theme switches instantly (no fade); decrypt obeys.
  - Print preview → always paper.
- `codex review --base origin/main` before commit; no blocking findings.

## Out of scope

- Animated theme transitions (cross-fade on switch). The instant switch is
  crisper and matches the site's restraint.
- Theme-aware social card / OG image (single English-card stays).
- Per-component dark-mode visual exceptions beyond the token swap (the design
  system was built on tokens; the swap should be near-complete on its own).
