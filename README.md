# frankxue.dev

Personal site for **Frank Xue** — a Rust engineer working on cryptography, agent
tooling, and CLIs. A bilingual (English / 中文), hand-built Jekyll site deployed on
GitHub Pages at **[www.frankxue.dev](https://www.frankxue.dev)**.

No framework, no CSS preprocessor, no build step beyond Jekyll. The aesthetic is
"Codex — paper & ink": a light, monograph-feel layout that also ships a dark theme.

## Highlights

- **Bilingual, one-for-one.** English pages live at the root; Chinese mirrors live
  under `/zh/`. Every page cross-links its counterpart and emits `hreflang` tags;
  UI strings are centralized in `_data/i18n.yml`, never hardcoded.
- **Light / dark theme.** Three-state toggle (light · dark · auto) that persists a
  preference and follows the OS when set to auto, with a pre-paint script to avoid
  a flash of the wrong theme.
- **Progressive enhancement.** A handful of small vanilla JS files in `assets/js/`
  (~500 lines total) add scroll reveals, a decrypt-on-reveal effect, a contents
  rail with scroll-spy, a copy-to-clipboard install button, and the mobile nav.
  Every page works with JavaScript disabled, and all motion respects
  `prefers-reduced-motion`.
- **Self-hosted fonts, zero third-party requests.** EB Garamond and IBM Plex Mono
  (both OFL) are served from `assets/fonts/`; CJK falls back to the reader's system
  serif/sans. No Google Fonts, no external runtime dependencies.
- **Security-conscious.** A Content-Security-Policy and `referrer-policy` are set
  via `<meta>` (the most GitHub Pages allows), with defense-in-depth escaping in
  the templates.
- **Project portfolio + writing.** Featured projects render from a single
  source-of-truth data file with deeper detail pages; a bilingual Writing/Notes
  section publishes an Atom feed at `/feed.xml`.

## Local development

Prerequisites: Ruby 3.x, Bundler, Git.

```bash
bundle install                # one-time, installs the github-pages gem
bundle exec jekyll serve      # http://localhost:4000, watches + rebuilds
```

Build the production output (what GitHub Pages produces) into `_site/`:

```bash
bundle exec jekyll build
```

Run the validator — the de-facto test harness for this repo. It checks metadata,
hreflang/i18n parity, security headers, and asset integrity against the built
`_site/`. CI runs it on every push and pull request.

```bash
# The LC_ALL/LANG prefix is required on macOS so the script reads UTF-8 cleanly.
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
```

## Project structure

```
index.html  about.html  projects.html  contact.html  notes.html   # EN pages (root)
zh/                                                                # ZH mirrors, same filenames
projects/<slug>.html  zh/projects/<slug>.html                      # project detail pages
_data/projects.yml                                                 # source of truth for project facts
_data/i18n.yml                                                     # all bilingual UI strings
_includes/  _layouts/                                              # head, nav, footer, single layout
_notes/                                                            # Writing/Notes collection (bilingual)
assets/css/style.css                                               # one hand-written stylesheet, design tokens
assets/js/                                                         # progressive-enhancement scripts
assets/fonts/                                                      # self-hosted woff2 + OFL licenses
scripts/validate_site.rb                                           # post-build validator (run in CI)
```

The plugin set is `github-pages` (umbrella), `jekyll-feed`, `jekyll-seo-tag`, and
`jekyll-sitemap`. Deeper architecture and contribution conventions live in
[`CLAUDE.md`](CLAUDE.md).

## Deployment

Pushing to `main` deploys automatically via GitHub Pages. The custom domain is
configured through the `CNAME` file with HTTPS enabled in the Pages settings.

## License

Site code is released under the [Apache License 2.0](LICENSE). The bundled fonts
are licensed separately under the SIL Open Font License (see
`assets/fonts/OFL-EBGaramond.txt` and `assets/fonts/OFL-IBMPlexMono.txt`).

---

**Live site:** [www.frankxue.dev](https://www.frankxue.dev) · **GitHub:**
[@frankxue831](https://github.com/frankxue831)
