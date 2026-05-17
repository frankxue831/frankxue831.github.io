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
