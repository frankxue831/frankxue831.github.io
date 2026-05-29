# Keyboard-focus parity for interactive affordances

Date: 2026-05-29
Status: shipped-pending (implementation + review, then PR)
Scope: `assets/css/style.css` only (no markup/JS/content change)

## Why

The site responds richly to the **mouse** on its primary interactive elements,
but keyboard users get only the generic focus outline. The hover affordances —
the work-list row indent + accent title, the hero-proof row accent title, the
CTA background fill + arrow nudge — are keyed on `:hover` with no
`:focus-visible` counterpart.

The pattern to fix against already exists in the codebase: the nav links pair
`:hover` with `:focus-visible` (`.primary-nav__link:hover,
.primary-nav__link:focus-visible`), as do the theme toggle, the install button,
and the contents-rail links. The rich content affordances simply weren't given
the same treatment. This is the last interactiveness gap: **the keyboard gets
the same feedback as the mouse.**

A real accessibility + polish win, not decoration — and it reuses the existing
visual vocabulary, so nothing new is introduced.

## The gap (audited)

| Element | `:hover` does | `:focus-visible` today |
|---------|---------------|------------------------|
| `.work-list__row` (via `.work-list__item:hover`) | indent + title → accent | — (outline only) |
| `.hero-proof__row` | title → accent | — |
| `.hero__cta` | bg/colour + arrow nudge (4px) | — |
| `.btn` | bg → accent + arrow nudge (3px) | — |
| `.preview__link` | colour + border → accent | — |

Already correct (left untouched): nav links, theme toggle, install copy
button, TOC links. Plain text-link colour hovers (`.prose a`, footer, etc.)
keep relying on the global `:focus-visible { outline }` — adequate for inline
links, and adding per-link colour parity would be churn for no real gain.

## Approach

In-place selector grouping — extend each existing hover rule to also match
`:focus-visible`, matching the nav pattern. No duplicated declarations, no new
block. Two subjects differ between hover and focus and so are grouped
explicitly:

- The work-list affordance is keyed on the **item** for hover but the focusable
  element is the **row** (`<a class="work-list__row">`):
  ```css
  .work-list__item:hover .work-list__row,
  .work-list__row:focus-visible { padding-left: var(--space-3); }

  .work-list__item:hover .work-list__title,
  .work-list__row:focus-visible .work-list__title { color: var(--accent); }
  ```
  The mobile reset (`padding-left: 0`) is grouped the same way.
- Same-element affordances (`.hero__cta`, `.btn`, `.preview__link`,
  `.hero-proof__row …`) just add `, …:focus-visible` to the selector.

`:focus-visible` (not `:focus`) so the affordance shows for keyboard navigation
but not on mouse click — matching the intent of the hover states. The global
`:focus-visible { outline }` still applies on top, so focus remains clearly
indicated; the affordance is additive.

## Safety

- **Reduced motion:** the arrow-nudge / indent transitions already fall under
  the global `prefers-reduced-motion` reset (transition-duration ~0), so the
  focus state snaps rather than animates — no new motion introduced.
- **Tokens only:** every value reused (`--accent`, `--bg`, `--space-3`) — no new
  colours.
- **Dark / print:** inherits; nothing theme-specific added.

## Validator checks

- `.work-list__row:focus-visible` present (row indent/accent parity).
- `.hero__cta:focus-visible` and `.btn:focus-visible` present (CTA parity).

Teeth-tested (broken once) before shipping. The checks assert the parity
selectors exist so a future edit that drops them is caught.

## Out of scope (YAGNI)

- Per-link `:focus-visible` colour on inline prose/footer links (outline covers
  them).
- Any markup or JS change.
- New focus styles beyond mirroring existing hovers.
