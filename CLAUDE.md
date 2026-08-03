# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository

Personal site for Frank Xue at https://www.frankxue.dev — a Jekyll static site deployed via GitHub Pages (custom domain via `CNAME`). No JS framework and no build step beyond Jekyll; interactivity is a handful of small vanilla JS files in `assets/js/` (~500 lines total: mobile nav, scroll reveal, decrypt cells, theme toggle, contents rail, copy button) used purely as progressive enhancement — every page works with JavaScript disabled.

## Commands

```bash
bundle install                # one-time, installs github-pages gem
bundle exec jekyll serve      # http://localhost:4000, watches + rebuilds
bundle exec jekyll build      # writes _site/ (also what gh-pages produces)

# Post-build validator (the de-facto test harness; CI runs this on every push/PR).
# The LC_ALL/LANG prefix is required on macOS so the script reads UTF-8 cleanly.
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
```

No JS build and no unit-test or linter suite. The test harness is `scripts/validate_site.rb` — a post-build validator (metadata, hreflang/i18n parity, security headers, asset integrity) that CI runs after `jekyll doctor` and `jekyll build` on every push and PR (`.github/workflows/site.yml`). Deployment is automatic on push to `main`.

## Architecture

### Bilingual structure (EN at root, ZH under `/zh/`)

The site ships two parallel page trees that mirror each other one-for-one:

- English pages live at the repo root (`index.html`, `about.html`, `projects.html`, `contact.html`, `projects/<slug>.html`).
- Chinese pages live under `zh/` with the same filenames (`zh/index.html`, `zh/projects/<slug>.html`, …).

Every page **must** declare `lang: en` or `lang: zh` and an `alternate:` URL pointing to its counterpart in the other language in front matter — `_includes/head.html` uses `alternate` to emit `hreflang` SEO tags, and `_includes/nav.html` uses it to decide whether to show the language switcher. The locale roots `/` and `/zh/` are special-cased to always mirror each other, so they don't need `alternate`. Pages without a counterpart (e.g. `404.html`) intentionally omit `alternate` so the switcher hides rather than 404.

All UI strings (nav labels, footer text, language switcher) live in `_data/i18n.yml` keyed by `en` / `zh`. Includes resolve them with `site.data.i18n[page.lang]`. **Never** hardcode user-facing nav/footer strings in templates — add them to `i18n.yml`.

When adding a new page: create the EN version, then the ZH mirror under `zh/`, then cross-link them with `alternate:` in both directions.

### Layouts & includes

Only one real layout (`_layouts/default.html`); `_layouts/page.html` is a thin wrapper that delegates. Pages directly use `layout: default`. The `<body>` class encodes both the page slug (`page--<slug>`) and the locale (`lang-en` / `lang-zh`) so CSS can target either.

### Project detail pages

Each featured project has two HTML files: `projects/<slug>.html` (EN) and `zh/projects/<slug>.html` (ZH). Project copy is currently inlined into these pages — there is no collection or generator. The home page (`index.html`) and `projects.html` index repeat short summaries that must stay in sync with the detail pages.

All four detail pages follow the same six-section case-study skeleton, enforced per page (both locales) by `scripts/validate_site.rb`'s `case_study` hash: `What it is / The problem / Constraints & key decisions / Evidence / Next / What it isn't`, with at least four **Cost:** (`代价：`) trade-off cues and per-page honest-status phrase guards. A new project page must be added to that hash, or it silently escapes the discipline.

`_data/projects.yml` is the source of truth for project facts. It drives the work-list rendering on `index.html`, `projects.html`, `zh/index.html`, and `zh/projects.html` via `{% for project in site.data.projects %}`. Schema per entry: `slug`, `title`, bilingual `years.{en,zh}`, bilingual `tags.{en,zh}`, `status` + bilingual `status_label.{en,zh}`, `release`, `release_source` (`public_tag` / `public_main` / `private_main` / `local_tag`), bilingual `snapshot_label.{en,zh}` (every non-`public_tag` entry), `repo_url`, `crate_url`, `docs_url`, `detail_url`, `zh_detail_url`, `public_source` (boolean — controls whether templates may render a "Source" link; it does not imply a release). `project-summary.html` renders a **Release** row only for `public_tag`; every main-branch, private, or local working state renders a **Snapshot** row from `snapshot_label`. Prose lives in the page templates; the data file is facts only.

### Design system

`assets/css/style.css` is a single hand-written stylesheet (~1.2k lines, no preprocessor). Jekyll plugins are declared in the `Gemfile` `:jekyll_plugins` group: `github-pages` (umbrella), `jekyll-feed` (atom), `jekyll-seo-tag` (meta / OG / hreflang), `jekyll-sitemap`. All design tokens live in `:root` custom properties at the top: `--bg` / `--fg` / `--accent` for the paper-and-ink palette, `--serif` / `--sans` / `--mono` for typography, `--space-*` for the spacing scale.

**Type system (per `2026-05-17-home-page-readability-design.md`, shipped):** sans-serif (`--sans`: system stack) is the default for body, nav, buttons, metadata, preview blocks, and project-row interface text (tags, status, year). Serif (`--serif`: EB Garamond → Noto Serif SC fallback chain) is reserved for the site mark, hero title, selected section headings, and the short prose note under each work-list row (`.work-list__note` — intentional; see the spec's 2026-06-11 addendum). Mono (`--mono`: IBM Plex Mono) is for compact technical labels only. Do not expand serif coverage on the home page without checking the spec. CJK glyphs fall through automatically via the font-family chain — do not split into separate stacks per locale.

The aesthetic is "Codex — paper & ink" (light, monograph-feel). Keep new components consistent with the existing tokens; don't introduce new color values inline.

### Interactivity & the CSP envelope

Interactivity is progressive enhancement: every page must work with JavaScript disabled, and there is no build step or framework. `_includes/head.html` ships a strict Content-Security-Policy via `<meta>` — `script-src 'self'` plus the **pinned sha256 hashes of the two inline scripts** (the pre-paint theme resolver + the motion gate); `style-src 'self'` (no inline styles); `connect-src 'self'` (no external fetch — analytics, CDNs, and remote data are blocked); `img-src 'self' data:`. `scripts/validate_site.rb` recomputes and pins those inline-script hashes, so any change to an inline script must be re-pinned there or the validator fails.

When adding interactivity, reach for the lightest tool that fits, in this order:

1. **CSS only** — hover/affordance states, transitions, reveals (all gated by `prefers-reduced-motion`).
2. **Native HTML** — `<details>` (audit drawer), the Popover API (glossary), `@view-transition` (cross-document fade). Declarative, zero JS, no new CSP hash.
3. **A small vanilla-JS IIFE** in `assets/js/` — only when 1–2 can't do it. The six files are `main.js` (mobile nav), `reveal.js` (scroll reveal), `decrypt.js` (hero), `theme.js` (theme toggle), `contents.js` (contents rail), `copy.js` (install copy). External `.js` is governed by `script-src 'self'` and needs no hash.
4. **A new inline script** — last resort; add its sha256 to the CSP in `head.html` (the validator pins it).

External CDNs, web fonts, and analytics are out — fonts are self-hosted and `connect-src` is `'self'`.

## Content rules (from `docs/superpowers/specs/`)

Specs in `docs/superpowers/specs/` encode current design direction — read the most recent before substantive content or design changes:

- `2026-05-16-portfolio-project-depth-design.md` — project data model + the source-of-truth rule below.
- `2026-05-17-home-page-readability-design.md` — hybrid type system (sans for body, serif for display, mono for labels).

The portfolio spec defines a strict **source-of-truth** rule for project copy:

> The site must describe public/tagged release state, not untagged local branch state.

When editing project pages, version numbers, release notes, or shipped-feature claims:

- Tie every claim to a public release tag or public `origin/main`. Don't promote unreleased local work to "shipped."
- `gm-crypto-rs`: current shipped version is what's tagged at public `origin/main`; v0.8 AEAD work is "next," not shipped.
- `ghrunners`: repo is currently private/local-only — describe as local/private and **do not** add a public source link until the GitHub repo is reachable.

When the user asks to update a project page, verify the public release state (e.g. `git ls-remote --tags`, crates.io, the project's own repo) before changing version numbers or feature claims.

## Conventions to preserve

- Public email is intentionally omitted from the site (see comment in `_config.yml`). Don't add `mailto:` links or restore `email:` without an explicit ask — the config comment lists the touchpoints to update if it ever comes back.
- The footer / hero / contact templates assume the no-email state; check those four files together if the user does ask to restore it.
- `permalink: pretty` is set globally, so internal links should use trailing-slash paths (`/projects/gm-crypto-rs/`, not `.html`).
- `projects.html` is a deliberately unfiltered `{% for %}` list ("a short, honest list" at the current 4-project scale). Don't add filter/sort/search UI unless the list outgrows ~5 entries — and if it does, it must be progressive enhancement (works with JS off), tokens only, no framework.
- Terminal pages (`notes`, `contact`, `projects`) carry an onward `preview__link--section` CTA so reading doesn't dead-end — mirrors the home-page section CTAs. `scripts/validate_site.rb` guards presence on notes/contact; keep the pattern when editing these pages.
- **ZH parity rule (2026-08 audit): claims-parity, native voice.** Disclosures, hedges, limitations, numbers, and framing stance must match EN exactly; register and phrasing stay natively Chinese, and ZH may keep explanatory glosses EN doesn't need. The ZH terminology of record lives as a header comment in `_data/i18n.yml` — use it, and extend it when a new term starts recurring. Avoid future-promising hedges (暂时 / 尚未 / 等…再) where EN states present fact ("today").
