# Site Quality Foundation Design

Date: 2026-05-19

## Context

The home-page readability refresh is merged, and the project pages now carry
enough detail to support a credibility-focused site. The next highest-return
work is not another visual redesign. It is a quality foundation that makes the
site easier to trust, easier to share, and harder to break during future content
updates.

Baseline verification also found a current `origin/main` build failure:
`bundle exec jekyll build` tries to render `CLAUDE.md` and fails because the
file contains a literal Liquid example. The root cause is that `_config.yml`
applies a default layout to all root-path files, so the Markdown guidance file
is treated as site content. This foundation pass should fix that before adding
new quality checks.

## Goals

- Restore a clean Jekyll build from current `origin/main`.
- Improve search and social previews with complete, page-specific metadata.
- Add structured data that identifies Frank, the website, and the featured
  software/project pages without making unsupported claims.
- Improve project-detail scanability near the top of each page.
- Add repeatable quality checks that catch broken builds, malformed generated
  output, and obvious metadata regressions before merge.
- Preserve the existing bilingual structure and the recently merged readable
  visual direction.

## Non-Goals

- No new visual theme or home-page redesign.
- No blog, notes, newsletter, analytics, comments, or contact-form changes.
- No new project release claims unless they are verified from public/tagged
  sources at implementation time.
- No large framework, JavaScript build step, or client-side rendering.
- No public email restoration.

## Design Direction

Treat the site as a static professional profile with three quality layers:

1. **Build hygiene:** non-site support files such as `CLAUDE.md` should never be
   rendered into `_site`, and build checks should fail clearly when they regress.
2. **Discoverability:** every public page should have accurate title,
   description, canonical URL, language alternates, and social-card metadata.
3. **Credibility:** project pages should expose key facts quickly before the
   long narrative sections, and structured data should describe those facts in a
   machine-readable way.

This should feel like infrastructure polish, not a new product surface.

## Metadata Model

Keep using `jekyll-seo-tag` as the base SEO generator, but give it better page
data:

- Keep `_config.yml` as the source for site-level title, author, URL, and
  default description.
- Add or normalize page-level `description` front matter where pages currently
  have weak or generic descriptions.
- Add a default social preview image path in site config backed by a new static
  `assets/img/social-card.svg` asset.
- Keep canonical URLs generated from `site.url`, `baseurl`, and page URL.
- Keep `hreflang` behavior in `_includes/head.html`, but ensure every bilingual
  page has a valid counterpart or intentionally hides the language switcher.

The social image must be simple, static, and lightweight. It should carry the
name "Frank Xue" and the site's technical identity without introducing stock
imagery or decorative complexity.

## Structured Data

Add JSON-LD through `_includes/structured-data.html`, then render it from
`_includes/head.html`.

The include must emit:

- `Person` for Frank Xue with name, URL, and GitHub profile.
- `WebSite` for `https://www.frankxue.dev`.
- `WebPage` for each rendered page with URL, name, description, language, and
  relationship to the website/person.
- `SoftwareSourceCode` or a conservative project-oriented schema only for
  project pages where the page facts are clear enough. Avoid source-code URLs
  for private or visitor-unreachable repositories.

Structured data must mirror visible page content. It must not add hidden claims
such as public source availability, certifications, security guarantees, or
production readiness.

## Project Page Scanability

Add a compact summary block near the top of each project detail page, after the
page lede and before long-form prose. The block should make each project
scannable in under 30 seconds:

- Role or ownership.
- Status and release label from `_data/projects.yml`.
- Stack or tags from `_data/projects.yml`.
- Public links that are already allowed by project metadata.
- One key outcome or differentiator written in page copy.

The summary block must be bilingual and structurally parallel across English and
Chinese pages. It should use existing CSS tokens and must not become a
decorative card nested inside another card.

## Quality Checks

Prefer lightweight checks that fit the current static-site repo:

- `bundle exec jekyll doctor`
- `bundle exec jekyll build`
- A generated-output check that ensures `_site/docs/superpowers` and
  `_site/CLAUDE.md` do not exist.
- `ruby scripts/validate_site.rb`, a small repository script that verifies
  generated internal links, core metadata, `hreflang` output, JSON-LD presence,
  and excluded non-site files.
- A GitHub Actions workflow at `.github/workflows/site.yml` that runs the same
  local validation path on pull requests and pushes to `main`.

Do not add a Node build pipeline for accessibility tooling in this pass. Browser
layout spot-checks remain manual verification for this PR.

## Data Flow

Jekyll continues to render static pages:

- `_config.yml` supplies site-level metadata and build excludes.
- Page front matter supplies per-page titles, descriptions, language, and
  alternate URLs.
- `_data/projects.yml` remains the source of truth for repeated project facts.
- `_includes/head.html` assembles SEO tags, language alternates, fonts, CSS, and
  structured data.
- Project detail pages render both narrative prose and the new summary block.

No collection migration or generated project-page system is required.

## Accessibility and Performance

- Metadata and structured data should not block rendering.
- Any social preview asset should be optimized and have stable dimensions.
- New project-summary UI should preserve readable line lengths, keyboard-visible
  links, and adequate contrast.
- Avoid adding third-party scripts.
- Keep web-font usage within the existing font strategy.

## Verification

Run these checks before completion:

- `bundle exec jekyll doctor`
- `bundle exec jekyll build`
- `test ! -e _site/CLAUDE.md`
- `test ! -d _site/docs/superpowers`
- Inspect generated core pages for expected title, description, canonical,
  Open Graph, and language alternate tags.
- Inspect generated project pages for JSON-LD and summary blocks.
- `ruby scripts/validate_site.rb`
- Inspect `.github/workflows/site.yml` for the same build and validation path.
- Use the browser to spot-check desktop and mobile layouts for home, about,
  project index, and one project detail page in both languages.

## Acceptance Criteria

- Current `origin/main` build failure is fixed by excluding or otherwise
  protecting non-site guidance files from Jekyll rendering.
- Every public page has useful generated metadata and does not rely on a generic
  site description when a page-specific description is available.
- Generated pages contain conservative JSON-LD that matches visible content.
- Project detail pages can be scanned quickly through a compact summary block.
- Private or unavailable repositories are not exposed as public source links in
  metadata, structured data, or visible page content.
- Build, generated-output, metadata, and link checks are repeatable locally and
  on GitHub pull requests.
