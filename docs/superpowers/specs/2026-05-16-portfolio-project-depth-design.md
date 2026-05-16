# Portfolio Project Depth Design

Created: 2026-05-16
Status: Approved for implementation planning

## Purpose

Make the portfolio section credible and current without changing the site's
visual identity. The work should raise the three featured projects to a
comparable level of detail while keeping every public claim tied to a verified
source of truth and never presenting private source as visitor-inspectable.

## Source Of Truth

The site must describe verified release or snapshot state, not untagged local
branch state, and it must distinguish visitor-public source from authenticated
private source. Before implementation, re-verify each project instead of
trusting the snapshot below:

```sh
git -C ../gm-crypto-rs ls-remote --tags origin
git -C ../gm-crypto-rs ls-remote origin HEAD refs/heads/main
curl -I -L https://github.com/frankxue831/gm-crypto-rs
git -C ../repolens-rs ls-remote --tags origin
git -C ../repolens-rs ls-remote origin HEAD refs/heads/main
curl -I -L https://github.com/frankxue831/repolens-rs
git -C ../ghrunners tag --sort=-creatordate
git ls-remote https://github.com/frankxue831/ghrunners.git HEAD refs/heads/main refs/heads/master
```

Discovery snapshot on 2026-05-16:

- `gm-crypto-rs`: latest public tag is `v0.7.0`; public `origin/main` points at
  the same commit, but unauthenticated visitor access to
  `https://github.com/frankxue831/gm-crypto-rs` returns HTTP 404 from this
  environment. Use the public release/crate/docs facts, but omit the GitHub
  source link and set `public_source: false` unless visitor web access becomes
  reachable at implementation time. If a newer public tag exists at
  implementation time, use the newer public tag. Any untagged `v0.8` work may
  appear only as next work around AEAD, SM4-GCM, and SM4-CCM.
- `repolens-rs`: authenticated `origin/main` exists and carries current private
  CLI/MCP surfaces, but unauthenticated visitor access to
  `https://github.com/frankxue831/repolens-rs` returns HTTP 404. Treat it as
  private pre-release source: label the site status as `Private pre-release`,
  cite the authenticated `origin/main` short SHA, use `private_main`, omit
  `repo_url`, and do not show a public source link unless the repository is
  visitor-public at implementation time. Do not call it a `v0.1` release.
- `ghrunners`: local tags include `v0.1.0` and `v0.1.1`, but its GitHub
  repository is not publicly reachable from this environment. If it remains
  private at implementation time, describe it as a local/private tagged tool
  using the latest local tag and omit a public source link.

## Scope

Included:

- Refresh `gm-crypto-rs` copy around the latest public tag verified at
  implementation time.
- Add English and Chinese detail pages for `RepoLens`.
- Add English and Chinese detail pages for `ghrunners`.
- Update `index.html`, `zh/index.html`, `projects.html`, and
  `zh/projects.html` so their summaries do not contradict the detail pages.
- Add a small metadata file for repeated project facts.

Excluded:

- Contact form or public email restoration.
- Blog or notes system.
- Visual redesign.
- Claims based only on untagged local branches.

## Architecture

Keep the existing Jekyll structure and static bilingual page approach.

Add `_data/projects.yml` for repeated metadata only. Field meanings:

- `slug`: stable URL/data key, e.g. `gm-crypto-rs`.
- `title`: display title.
- `years`: display year range, e.g. `2025 — now`.
- `tags`: array of display technology tags, not VCS tags.
- `status`: one of `released`, `public-pre-release`,
  `private-pre-release`, or `private-local`.
- `release`: display release label or snapshot label, e.g. `v0.7.0`,
  `origin/main @ afd7a6b`, or `local tag v0.1.1`.
- `release_source`: one of `public_tag`, `public_main`, `private_main`, or
  `local_tag`.
- `repo_url`: public source URL, or omitted/null when visitors cannot inspect
  the source.
- `crate_url`: public crate/package URL, or omitted/null.
- `docs_url`: public documentation URL, or omitted/null.
- `detail_url`: English detail page URL.
- `zh_detail_url`: Chinese detail page URL.
- `public_source`: boolean; `true` only when visitors can inspect the source.

Example shape:

```yaml
- slug: gm-crypto-rs
  title: gm-crypto-rs
  years: "2025 — now"
  tags: ["Rust", "Cryptography", "no_std"]
  status: released
  release: v0.7.0
  release_source: public_tag
  repo_url:
  crate_url: https://crates.io/crates/gmcrypto-core
  docs_url: https://docs.rs/gmcrypto-core
  detail_url: /projects/gm-crypto-rs/
  zh_detail_url: /zh/projects/gm-crypto-rs/
  public_source: false

- slug: repolens-rs
  title: RepoLens
  years: "2025 — now"
  tags: ["Rust", "MCP", "Agent tooling"]
  status: private-pre-release
  release: "origin/main @ afd7a6b"
  release_source: private_main
  repo_url:
  crate_url:
  docs_url:
  detail_url: /projects/repolens-rs/
  zh_detail_url: /zh/projects/repolens-rs/
  public_source: false

- slug: ghrunners
  title: ghrunners
  years: "2026"
  tags: ["Rust", "CLI", "macOS"]
  status: private-local
  release: "local tag v0.1.1"
  release_source: local_tag
  repo_url:
  crate_url:
  docs_url:
  detail_url: /projects/ghrunners/
  zh_detail_url: /zh/projects/ghrunners/
  public_source: false
```

Use a 7-character short SHA for public-main snapshot labels unless the codebase
already establishes a longer local convention.

Add detail pages:

- `projects/repolens-rs.html`
- `projects/ghrunners.html`
- `zh/projects/repolens-rs.html`
- `zh/projects/ghrunners.html`

Likely touched support files:

- `_data/projects.yml`
- `_data/i18n.yml` if shared labels such as status/source/link labels are
  introduced in includes.
- `index.html`
- `zh/index.html`
- `projects.html`
- `zh/projects.html`

Long-form project copy stays in the page files. Metadata can drive repeated
facts in home and project lists, but it should not force generated detail
pages or over-template the writing.

## Content Model

Each detail page should use the same editorial shape:

1. What it is.
2. What is shipped, or current private/local snapshot for non-public projects.
3. What is different about it.
4. What it is not.
5. Links.

Project-specific emphasis:

- `gm-crypto-rs`: pure-Rust SM2/SM3/SM4 SDK, latest public tag verified at
  implementation time, SM4-CTR and public batch APIs when backed by that tag,
  constant-time-designed secret paths, and in-CI `dudect-bencher`
  leak-regression gates.
- `RepoLens`: agent-facing repository packs, MCP tools, typed decaying memory,
  current private-snapshot CLI/MCP surfaces from authenticated private `origin/main`,
  status labeled `Private pre-release`, no public source link while the visitor
  GitHub URL returns 404, and clear boundaries between private-snapshot and planned
  memory-safety work.
- `ghrunners`: one-shot read-only macOS GitHub Actions runner observability,
  typed findings, partial output as a deliberate design, and no public source
  link until the repository is reachable.

## Editorial Rules

- Keep the current short, honest, technical voice.
- English and Chinese pages should be equivalent in meaning, not literal
  translations.
- Use scoped language for security-sensitive claims. Prefer
  `constant-time-designed` and `guarded by a detectable-leak regression
  harness` over absolute claims.
- State that `dudect-bencher` detects timing-leak events and does not prove the
  absence of leaks.
- Do not use broad claims such as `production-ready`, `secure`, `guaranteed`,
  or absolute `constant-time`.
- Use public links only. Omit `repolens-rs` and `ghrunners` GitHub links until
  each repo is publicly reachable by visitors.
- Detail pages should contain the five editorial sections from the Content
  Model in the same order. Section titles may be localized.

## Data Flow

`_data/projects.yml` provides stable repeated facts to `index.html`,
`zh/index.html`, `projects.html`, and `zh/projects.html`. Detail pages provide
narrative and source-specific nuance.

The site should avoid duplicating status strings by hand where metadata is
enough, especially for release labels, public-source availability, tags, and
detail links.

## Testing

Implementation should verify:

- `bundle exec jekyll doctor`
- `bundle exec jekyll build`
- English and Chinese detail pages are generated.
- Home and project-index links resolve to the intended pages.
- `_site/projects/repolens-rs/index.html`,
  `_site/projects/ghrunners/index.html`,
  `_site/zh/projects/repolens-rs/index.html`, and
  `_site/zh/projects/ghrunners/index.html` exist after build.
- No public page links to unreachable private GitHub URLs:
  `! rg -n "github\\.com/frankxue831/(gm-crypto-rs|ghrunners|repolens-rs)" _site`.
- Security-sensitive overclaims are absent from project pages:
  `! rg -n "\\b(production-ready|guaranteed|secure)\\b" _site/projects _site/zh/projects`.
- `gm-crypto-rs` next-version language is explicitly labeled as next/planned
  work. If terms such as `v0.8`, `AEAD`, `SM4-GCM`, or `SM4-CCM` appear in the
  generated `gm-crypto-rs` pages, they must appear only in a section titled
  `Next` or its Chinese equivalent. Use `Next` for English and `下一步` for
  Chinese so the rule is deterministic during review.

## Acceptance Criteria

- `/projects/` presents all three projects at a comparable level of credibility.
- `gm-crypto-rs` reflects the latest public tag verified at implementation
  time, with newer untagged work only as next/planned work.
- `RepoLens` has English and Chinese detail pages with private-snapshot/planned
  boundaries kept explicit and status labeled `Private pre-release` unless a
  visitor-public repository or public release tag exists by implementation
  time.
- `ghrunners` has English and Chinese detail pages, no broken public GitHub
  link, and status marked as local/private using the latest local tag unless
  the repository is public by implementation time.
- All English and Chinese detail pages contain the five editorial sections from
  the Content Model in order, with localized section titles allowed.
- Home and project-index summaries use `_data/projects.yml` for repeated facts
  and do not contradict the detail pages.
- English and Chinese pages carry the same shipped/current/planned boundary, release
  label, public-source status, and links.
- All Testing checks pass, including `bundle exec jekyll doctor`,
  `bundle exec jekyll build`, generated-page existence checks, unreachable-link
  checks, overclaim checks, and the `Next`/`下一步` content placement check.

## Open Risk

`ghrunners` is less publicly verifiable until the repository is public. Its
detail page must be clear that the project is local/private right now, and it
must avoid implying that visitors can inspect the source.

`gm-crypto-rs` may ship another public tag before implementation starts. The
implementation must re-run the source-of-truth check rather than treating this
spec's discovery snapshot as current. If the GitHub web URL still returns 404
for unauthenticated visitors, the detail pages must omit the source link even
when the release tag and crate/docs pages are public.

`RepoLens` is visible through authenticated git but not visitor-public GitHub
access. The implementation must use the `Private pre-release` label, omit
`repo_url`, and avoid public source links unless the repository is visitor-public
before implementation.
