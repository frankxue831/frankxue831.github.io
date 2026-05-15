# Portfolio Project Depth Design

Created: 2026-05-16
Status: Approved for implementation planning

## Purpose

Make the portfolio section credible and current without changing the site's
visual identity. The work should raise the three featured projects to a
comparable level of detail while keeping every public claim tied to a public
or tagged source of truth.

## Source Of Truth

The site must describe public/tagged release state, not untagged local branch
state.

- `gm-crypto-rs` uses public `origin/main` and tag `v0.7.0` as the shipped
  source. The site may mention `v0.8` only as next work around AEAD,
  SM4-GCM, and SM4-CCM.
- `repolens-rs` uses public `origin/main` plus public milestone tags. The site
  should not call it a `v0.1` release. It should describe shipped CLI/MCP
  surfaces and keep planned memory-safety work explicit.
- `ghrunners` has local tags `v0.1.0` and `v0.1.1`, but its GitHub repository
  is not publicly reachable from this environment. The site should describe it
  as a local/private tagged `v0.1.1` tool and omit a public source link until
  the repository is reachable.

## Scope

Included:

- Refresh `gm-crypto-rs` copy around public `v0.7.0`.
- Add English and Chinese detail pages for `RepoLens`.
- Add English and Chinese detail pages for `ghrunners`.
- Update home and project-index summaries so they match the detail pages.
- Add a small metadata file for repeated project facts.

Excluded:

- Contact form or public email restoration.
- Blog or notes system.
- Visual redesign.
- Claims based only on untagged local branches.

## Architecture

Keep the existing Jekyll structure and static bilingual page approach.

Add `_data/projects.yml` for repeated metadata only:

- `slug`
- `title`
- `years`
- `tags`
- `status`
- `release`
- `repo_url`
- `crate_url`
- `docs_url`
- `detail_url`
- `zh_detail_url`
- `public_source`

Add detail pages:

- `projects/repolens-rs.html`
- `projects/ghrunners.html`
- `zh/projects/repolens-rs.html`
- `zh/projects/ghrunners.html`

Long-form project copy stays in the page files. Metadata can drive repeated
facts in home and project lists, but it should not force generated detail
pages or over-template the writing.

## Content Model

Each detail page should use the same editorial shape:

1. What it is.
2. What is shipped.
3. What is different about it.
4. What it is not.
5. Links.

Project-specific emphasis:

- `gm-crypto-rs`: pure-Rust SM2/SM3/SM4 SDK, public `v0.7.0`, SM4-CTR and
  public batch APIs, constant-time-designed secret paths, and in-CI
  `dudect-bencher` leak-regression gates.
- `RepoLens`: agent-facing repository packs, MCP tools, typed decaying memory,
  shipped workspace CLI surfaces, and clear boundaries between shipped and
  planned memory-safety work.
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
- Use public links only. Omit `ghrunners` GitHub links until the repo is
  publicly reachable.

## Data Flow

`_data/projects.yml` provides stable repeated facts to the home page and
project index. Detail pages provide narrative and source-specific nuance.

The site should avoid duplicating status strings by hand where metadata is
enough, especially for release labels, public-source availability, tags, and
detail links.

## Testing

Implementation should verify:

- `bundle exec jekyll doctor`
- `bundle exec jekyll build`
- English and Chinese detail pages are generated.
- Home and project-index links resolve to the intended pages.
- No public page links to an unreachable `ghrunners` GitHub URL.
- `gm-crypto-rs` shipped language does not describe untagged `v0.8` work as
  released.

## Acceptance Criteria

- `/projects/` presents all three projects at a comparable level of credibility.
- `gm-crypto-rs` reflects public `v0.7.0`, with `v0.8` only as next work.
- `RepoLens` has English and Chinese detail pages with shipped/planned
  boundaries kept explicit.
- `ghrunners` has English and Chinese detail pages, no broken public GitHub
  link, and status marked as local/private tagged `v0.1.1`.
- Home page summaries match the project pages.
- English and Chinese pages have matching meaning.
- `bundle exec jekyll doctor` and `bundle exec jekyll build` pass.

## Open Risk

`ghrunners` is less publicly verifiable until the repository is public. Its
detail page must be clear that the project is local/private right now, and it
must avoid implying that visitors can inspect the source.
