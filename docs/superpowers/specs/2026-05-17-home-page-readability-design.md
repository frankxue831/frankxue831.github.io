# Home Page Readability Refresh Design

Date: 2026-05-17

## Context

The current home page is visually distinctive, but too many reading surfaces use the display serif treatment. Body copy, metadata, project rows, and calls to action all compete with the large hero type, which makes the page harder to scan. The user asked to redesign the home page with fonts that are easier to read.

During visual review, Option A was selected: keep serif type for expressive display moments and use a clearer sans-serif stack for body and interface reading.

## Goals

- Improve readability on the English and Chinese home pages.
- Preserve the existing paper-and-ink identity instead of replacing the site with a generic portfolio look.
- Make the first screen communicate Frank's work more directly.
- Keep project facts sourced from `_data/projects.yml`.
- Avoid new release, source, or availability claims.

## Non-Goals

- No project-detail content rewrite.
- No new blog, notes, contact, or email feature.
- No new JavaScript behavior.
- No new image or illustration system.
- No dependency-heavy design system.

## Design Direction

Use a hybrid type system:

- Serif remains for the site mark, hero title, and selected section headings.
- Sans-serif becomes the default body/interface stack for paragraphs, nav, buttons, metadata, preview blocks, and project row supporting text.
- Mono stays for compact technical labels only, with reduced letter spacing where it currently hurts legibility.
- Chinese pages keep locale-specific line-height improvements and should not rely on italic emphasis.

The home page should feel quieter and more readable, with a smaller hero, clearer lede, and denser project section.

## Home Page Structure

The English and Chinese home pages keep the same section order:

1. Hero
2. About preview
3. Selected work
4. Contact preview

The hero copy becomes more concrete:

- English direction: "Building reliable tools for code, crypto, and agents."
- Chinese direction should mirror the meaning naturally rather than translate word-for-word.

The hero metadata remains, but should read as compact facts rather than a decorative code block. The project section continues to loop over `site.data.projects`.

## CSS Architecture

All implementation should stay in `assets/css/style.css` and the two home pages:

- Update type tokens near `:root` so `--sans` is a true readable sans stack.
- Keep `--serif` and `--mono` available for identity and technical labels.
- Add or adjust home-page-specific selectors for hero, preview, and work-list readability.
- Avoid inline styles on home pages.
- Keep responsive behavior explicit for mobile widths.

If global typography token changes affect other pages, those effects are acceptable only when they improve readability without changing page structure. Any page-specific regressions found during verification should be fixed in the stylesheet, not by adding one-off inline styles.

## Data Flow

Jekyll renders the pages statically:

- `index.html` uses English copy and `project.detail_url`.
- `zh/index.html` uses Chinese copy and `project.zh_detail_url`.
- `_data/projects.yml` remains the source for project titles, years, tags, and detail URLs.

No new data files or includes are required.

## Accessibility and Readability

- Body copy should use comfortable line-height and max-width constraints.
- Text must not overlap or rely on viewport-width font scaling.
- Buttons and links should remain keyboard focusable.
- Contrast should stay within the existing palette and remain readable on the paper background.
- Reduced-motion behavior should continue to work for the hero reveal animation.

## Verification

Run these checks before completion:

- `bundle exec jekyll doctor`
- `bundle exec jekyll build`
- Inspect generated `_site/index.html` and `_site/zh/index.html` for expected copy and project links.
- Use the browser to visually verify desktop and mobile home-page layouts.
- Confirm `_site/docs/superpowers` is still excluded.
- Confirm no project GitHub/source links were introduced for private or unavailable projects.

## Acceptance Criteria

- Home page body and supporting text are visibly easier to read than the current mostly-serif version.
- English and Chinese home pages remain structurally parallel.
- The hero communicates the site purpose without requiring the user to scroll.
- The selected work list is scannable on desktop and mobile.
- Project facts and links still come from `_data/projects.yml`.

## Addendum (2026-06-11)

Clarification recorded during a design review: "project row supporting text"
in the sans-serif list above means the row's interface text — tags, status
pill, release, year. The prose note under each row (`.work-list__note`) has
been `var(--serif)` since the version of this spec shipped (PR #4) and stays
serif by design: it is a short reading passage, not row metadata. Two
adjustments from the same review: the note no longer drops to `--text-sm` on
mobile (14px Garamond was the smallest reading text on the site; it now stays
at `--text-base`), and display headings (`.hero__title`, `.section__title`,
`.page-header__title`) gained `text-wrap: balance` as a progressive
enhancement on Latin pages only — Chromium's balancer mishandles mixed
CJK/Latin display lines (it can open a line with a fullwidth comma), so
ZH pages keep native wrapping via a `body.lang-zh` override.

## Addendum (2026-06-12) — long-form reading sizes

A reader-comfort review (measurement + deep research pass) found the
long-form pages — about, project details, notes — uncomfortable on
desktop, and traced it to three causes:

1. **Apparent size, not nominal size.** EB Garamond's x-height is
   ~0.435 of its em (measured 7.29px at 18px), below even Times' 0.447.
   The 18px long-form body therefore rendered lowercase *smaller* than
   the site's own 16px sans UI text, sitting at roughly the 0.2°
   x-height visual angle that vision science identifies as the critical
   print size floor (Legge & Bigelow, *Journal of Vision* 2011) — fluent
   but with no comfort margin.
2. **Measure.** 605px columns gave ~78 characters per line. Screen
   studies (Dyson & Kipping 1998; Dyson & Haselgrove 2001) show long
   lines are not slower, but ~55 cpl wins comprehension and readers
   consistently *prefer* moderate lines; 78 was above that band.
3. **ZH leading.** W3C clreq puts comfortable Han body leading at
   1.5–2.0; the shared 1.6 sat on that floor, and the existing
   `body.lang-zh` 1.75 override list was missing the detail-page and
   note selectors entirely.

Decisions (all tokens-only):

- Long-form serif body (`.prose p`, `.project-detail p`, `.project-detail
  li`, `.note li`) moves `--text-lg` → `--text-xl` (18px → 20px). At
  20px, EB Garamond's x-height (8.10px) matches an 18px system sans
  (8.08px) — the apparent size of mainstream long-form practice.
- Reading measure on `.prose` / `.project-detail` is unified at `36rem`
  (≈576px → ~66 cpl at the new size), inside the preferred 55–70 band.
- Every long-form ZH surface now gets `line-height: 1.75`; EN keeps its
  existing 1.55–1.65 values, which are mid-range for Latin.
- Headings were deliberately **not** changed: the research pass found no
  surviving empirical basis to pass or fail the 12px mono eyebrows or
  the title scale (both candidate heading-benchmark claims failed
  adversarial verification). Any future heading rebalance is a design
  judgment, not a readability correction.

Home-page sizes (hero, work-list, previews) are untouched — this
addendum governs the long-form reading surfaces only.
