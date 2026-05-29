# Smooth theme-toggle transition

Date: 2026-05-29
Status: shipped-pending (implementation + review, then PR)
Scope: `assets/js/theme.js` + `assets/css/style.css` (no markup/content change)

## Why

The light/dark toggle currently **snaps** every colour at once. A brief,
reduced-motion-aware crossfade scoped to the switch makes the control feel
finished and intentional — recognized product-level polish on the existing
theme feature. This is polish-tier (the high-value interactiveness gaps are
already shipped), kept deliberately restrained.

## Behaviour

When the effective theme changes **after initial load** — a user toggle, or an
OS change while in `auto` — the page briefly transitions its colour properties
(~`--dur`, 320ms) instead of snapping. The transition is enabled only for the
duration of the switch, then removed, so it never affects ordinary interactions
(hover, the decrypt animation, etc.) and never flashes on first paint.

## How

### JS (`theme.js`)

- `beginThemeAnim()`: if `prefers-reduced-motion: reduce` (checked **live** each
  call), return immediately — no class, instant switch. Otherwise add
  `theme-anim` to `<html>`, force a reflow (`void el.offsetWidth`) so the
  transition property is committed before the value change, and remove the
  class after ~380ms (slightly longer than `--dur`); the removal timer is
  reset on rapid re-toggles so the class never sticks.
- It is called **only** from the toggle click handler and the matchMedia
  `change` handler (OS change while in auto), each time just before `apply()`.
  The initial `apply(currentPref)` on load runs before the handlers are wired
  and never calls it — so the first paint never animates (no flash). No
  `firstApplyDone` flag is needed; the call-ordering guarantees it.
- The pre-paint script in `head.html` is untouched — it sets the initial theme
  before first paint with no transition.

### CSS (`style.css`)

```css
/* Only present for the ~320ms of a theme switch. Scoped to colour properties
   so a brief override of other transitions is invisible (nothing else is
   animating during an isolated toggle). */
html.theme-anim,
html.theme-anim *,
html.theme-anim *::before,
html.theme-anim *::after {
    transition: background-color var(--dur) var(--ease),
                color var(--dur) var(--ease),
                border-color var(--dur) var(--ease),
                fill var(--dur) var(--ease) !important;
}
@media (prefers-reduced-motion: reduce) {
    html.theme-anim,
    html.theme-anim *,
    html.theme-anim *::before,
    html.theme-anim *::after { transition: none !important; }
}
```

The universal selector + `!important` is acceptable because the class lives for
only ~320ms during an infrequent, isolated action; the JS also skips it under
reduced motion (CSS guard is belt-and-suspenders). `.grain` (a `fixed` overlay)
uses no transitioned colour, so it's unaffected.

## Fail-safe matrix

| Condition | Result |
|-----------|--------|
| Initial load / pre-paint | No transition (firstApplyDone false / inline script untouched) — no flash. |
| `prefers-reduced-motion` | Instant switch (JS skips the class; CSS nulls it too). |
| JS disabled | No toggle at all; theme is whatever the CSS `@media` fallback resolves — no transition needed. |
| Rapid re-toggle | Timer reset; class removed once after the last switch. |
| Print | Unaffected (print resets tokens; no `theme-anim` in print context). |

## Validator checks

- CSS contains the `html.theme-anim` transition block.
- CSS contains the reduced-motion `theme-anim` null-out.
- `theme.js` references `theme-anim`.

Teeth-tested before shipping.

## Out of scope (YAGNI)

- Transitioning `transform`/`opacity` (nothing else animates during a toggle).
- A per-element curated transition list (the scoped universal rule is simpler
  and the override window is invisible).
- View Transitions API (progressive-enhancement nicety, heavier; not worth it
  for a colour crossfade).
