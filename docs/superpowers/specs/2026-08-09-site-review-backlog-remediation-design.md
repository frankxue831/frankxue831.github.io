# Site Review Backlog Remediation Program Design

Created: 2026-08-09  
Status: Approved in auto mode for implementation planning

## Purpose

The Notion database **Site review issues — 2026-08-03 continuous** currently
contains 137 open rows: 3 `major`, 13 `minor`, 49 `nit`, and 72 `info` rows.
This design turns the 65 non-info rows into a bounded remediation program.

The goal is not to make every row produce a code diff. The goal is to leave
every actionable row with an accurate disposition grounded in the current
`main` branch, the generated site, the live site, and public upstream sources.
Rows that are stale, already resolved, duplicated by a broader finding, or
technically invalid must be closed with evidence instead of prompting
unnecessary changes.

## Baseline and Sources of Truth

Baseline repository state:

- branch `main` at `d0004a4` (`fix: contain mobile nav and clear residual ZH nits (#85)`);
- clean worktree;
- `bundle exec jekyll doctor` passes;
- `bundle exec jekyll build` passes;
- `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb` passes.

Live checks on 2026-08-09 establish:

- strict HTTPS requests to `frankxue.dev` fail certificate-name validation;
- after bypassing that certificate error for diagnosis, apex root, `/projects/`,
  and `/zh/?from=apex` each redirect in one hop to the matching `www` path and
  return `200`;
- `https://www.frankxue.dev/404.html` returns `200`;
- `/notes/extraction-trigger/` returns `404` and the corresponding source files
  do not exist on `main`.

Authority order for disputed facts:

1. a public immutable release tag;
2. crates.io publication metadata for release dates and versions;
3. public `origin/main` for repositories intentionally described as snapshots;
4. the current site source and generated HTML;
5. the Notion observation and its suggested fix.

The Notion suggestion is never authoritative when it conflicts with a public
tag. For example, direct verification of `gm-crypto-rs` `v1.11.0` shows that
`cipher.rs#L627`, `Cargo.toml#L177`, `timing_leaks.rs#L167`, and
`README.md#L76` already land correctly. Only `dudect-pr.yml#L166` is displaced;
the `Parse and gate` step starts at line 169.

## Program Accounting

The 65 non-info rows divide as follows:

- **55 action rows:** one external DNS/TLS repair, eleven repository `minor`
  repairs, and forty-three repository `nit` repairs;
- **10 evidence-only dispositions:** one hosting row already resolved, three
  extraction-branch rows that no longer describe a shipped artifact, one
  incorrect deep-link row, and five intentional/invalid nits;
- **72 info rows:** checkpoints, positive controls, and session inventories;
  these are records rather than repair work and remain outside this program.

## Architecture

The remediation is split into four independently reviewable workstreams. Each
workstream gets its own implementation plan and may ship without the others.

1. **H — External hosting and TLS**
2. **T — Content truth and bilingual evidence**
3. **A — Accessibility and progressive enhancement**
4. **M — Metadata, performance, and PWA hygiene**

Each workstream consumes a row ledger containing the Notion URL, verified
current state, intended disposition, source files, and acceptance evidence.
Each produces one or more focused commits plus a verification record. Notion
status changes are downstream of verification, never a substitute for it.

The dependency order is `T → A → M` for repository work. Hosting is operationally
independent and may occur at any time, but its Notion row remains open until the
strict live checks pass. The order keeps factual copy changes separate from UI
behavior and prevents metadata tests from pinning text that is about to change.

## Workstream H — External Hosting and TLS

### Current state

The historical apex deep-path failure no longer reproduces behind the current
certificate: path and query are preserved in one redirect hop. The remaining
live defect is that the certificate presented for `frankxue.dev` does not cover
the apex hostname.

### Design

Keep `www.frankxue.dev` as the canonical Pages domain declared by `CNAME` and
remove the apex-only AWS detour. Configure the apex at the DNS provider with
the current GitHub Pages `A` and `AAAA` records (or an `ALIAS`/`ANAME` directly
to `frankxue831.github.io`), preserve the existing `www` CNAME, and let GitHub
Pages provision the certificate and canonical redirect. Remove conflicting
apex records before requesting/retrying certificate issuance.

No repository source change is expected. DNS values must be copied from the
current official GitHub Pages documentation at execution time; the design does
not treat an old issue-body value as permanent infrastructure configuration.

### Acceptance

- `curl -sSIL https://frankxue.dev/` succeeds without `-k`;
- apex certificate SANs cover `frankxue.dev`;
- `/`, `/projects/`, and `/zh/?from=apex` redirect once to the matching `www`
  path and query, then return `200`;
- HTTP apex requests redirect directly to canonical HTTPS;
- no apex path returns an AWS error page;
- the old deep-path row is resolved as already fixed; the TLS row is resolved
  only after the strict checks pass.

## Workstream T — Content Truth and Bilingual Evidence

### Responsibilities

This workstream owns facts, release evidence, bilingual claim parity, public
project status, editorial terminology, and documentation that guides future
agents. It does not change layout behavior, structured-data types, or hosting.

### High-priority repairs

- Update the `gm-crypto-rs-demo` pin to `1.11.0` and describe it as a published
  consumer/smoke-test tour with representative capabilities rather than a
  false `hash` / `sign` / `verify` upper bound.
- Re-check every `v1.11.0` evidence link. Preserve the four links that are
  already exact and change only `dudect-pr.yml#L166` to line 169.
- Correct the five release-history dates against public tagger/crates.io dates
  in both locales and document the authority rule in `CLAUDE.md`.
- Replace the RepoLens fragment with a complete English sentence and preserve
  the ZH claim boundary.
- Give the historical dudect leak row a distinct “over gate (caught)” status;
  keep “must fire” exclusively for `negative_control`.
- Correct the explainer VTT cue to “The load-bearing line …”.
- Update stale architecture copy: seven JavaScript files / approximately 570
  lines, the shipped v1.11 AEAD fit, and `software engineer, mostly Rust`.
- Repair the content-parity and terminology rows covering About, page
  descriptions, CTA vocabulary, project privacy disclosures, constant-time
  telemetry language, note cross-links, title/lede wording, LICENSE
  discoverability, and localStorage disclosure.

### Editorial boundaries

- Home-page summaries remain intentionally shorter than project-index
  summaries; they must preserve status/source disclosure but need not repeat
  tool counts or release-history pointers.
- “Mostly in Rust” remains accurate at three of four projects and stays.
- Note Markdown links continue to open in the same tab; `noopener` is not
  required without `target="_blank"`.
- Static pages remain timeless unless they have a meaningful content date;
  manual `lastmod` stamps that immediately become stale are not introduced.
- Extraction-trigger rows are resolved as unshipped/stale. The program does
  not revive an abandoned note merely to make its old branch pass validation.

### Validation

- exact rejected-phrase searches fail before edits and return no unintended
  matches after edits;
- both locale trees retain equal facts, hedges, numbers, and publication
  boundaries;
- every public version/date/line claim is checked against its named public
  source;
- Jekyll doctor, build, validator, and `scripts/check_release_drift.rb` pass;
- generated EN/ZH extracts are inspected for each changed surface.

## Workstream A — Accessibility and Progressive Enhancement

### Mobile navigation

When the mobile menu opens, set `inert` on `#main` and every footer while
leaving the header/nav interactive. Move focus into the first navigation link,
keep the existing Escape behavior, restore focus to the toggle when dismissal
does not navigate, and remove `inert` on every close path and desktop
breakpoint transition. Because this is a navigation region rather than a modal
dialog, do not invent `role="dialog"`; the behavior is expressed through
`aria-expanded`, `aria-controls`, focus placement, and inert background
content.

Close the menu when a pointer event lands on the body-backed overlay. Preserve
toggle, Escape, nav-link, and desktop-resize closure.

### Controls and responsive content

- Move Menu and Skip-to-content strings into `_data/i18n.yml` and make the
  shared 404 consume the same keys.
- Update copy-button visible text, accessible name, and live status together;
  on Clipboard API failure, select the command and announce an explicit
  manual-copy instruction. Restore the original name/status after the timer.
- Announce theme preference, effective appearance, and next mode so Auto on a
  light OS is not described as a meaningless “Switch to Light”.
- Give the install copy button a 44px minimum block size.
- Wrap the dudect table in a horizontally scrollable region.
- Add stable server-rendered IDs to all case-study `h2` headings and make
  `contents.js` preserve existing IDs.
- Hide menu, theme, and language-switch controls in print.
- Replace synthesized `font-weight: 650` with the supported `600` weight.

### Progressive-enhancement boundary

No framework, inline script, remote dependency, or CSP expansion is introduced.
Pages remain readable with JavaScript disabled. `inert` and richer copy/theme
feedback enhance supported browsers; the existing no-JS navigation and
selectable install command remain the baseline.

### Validation

- keyboard-only mobile flow cannot focus main/footer content while open;
- focus returns predictably on Escape and backdrop dismissal;
- backdrop, link, toggle, Escape, and breakpoint closure all clear `inert`;
- copy success and failure announce correct localized status;
- no-JS pages expose content and navigation;
- 390×844 EN/ZH checks show no clipping or new horizontal page overflow;
- print preview contains no interactive-only chrome;
- static validator guards the new IDs, i18n keys, wrapper, and target-size rule.

## Workstream M — Metadata, Performance, and PWA Hygiene

### Structured metadata

- Localize `WebSite.description` per page locale.
- Emit `SoftwareSourceCode` only when `project.public_source` is true; private
  project pages retain `WebPage` metadata without presenting inaccessible
  source as a public software artifact.
- Add `BlogPosting` JSON-LD for note pages with canonical URL, headline,
  description, `datePublished`, locale, author, and `isPartOf` links.
- Emit `og:locale:alternate` for bilingual page clusters and an explicit
  `twitter:description` from the same escaped page description.
- Add `robots: noindex, follow` to the shared 404 while retaining
  `sitemap: false`.
- Remove terminal punctuation from localized home-page `short_tagline` values.

### Resource loading and assets

- Keep `main.js`, `theme.js`, and `reveal.js` global.
- Load `decrypt.js` on EN/ZH home pages only.
- Load `contents.js` on the eight case-study pages only.
- Load `copy.js` on the EN/ZH gm-crypto case studies only.
- Make font preloads route-aware so a page preloads only faces used above the
  fold; update validator expectations from “site-wide” to positive and
  negative route assertions.
- Produce dedicated 192px and 512px maskable icons with verified safe-zone
  padding and declare them with `purpose: "maskable"`.
- Losslessly optimize the EN social card while preserving 1200×630 dimensions
  and pixel appearance; add a validator size ceiling that both locale cards
  satisfy.

### Validation

- parse every JSON-LD graph and assert locale/type/date rules;
- assert 404 robots metadata, OG alternates, Twitter description, and exactly
  one document title;
- assert scripts and font preloads are present only on intended routes;
- validate manifest icon purposes, dimensions, and disk paths;
- verify both social cards remain valid 1200×630 PNG files below the agreed
  size ceiling;
- browser network/console checks on home, case-study, note, and 404 routes show
  no unused preloads or missing assets.

## Row Ledger

### Major and minor rows

| Severity | Issue | Workstream / disposition |
| --- | --- | --- |
| major | Apex only redirects root; deep paths 404 | evidence-only: current live paths preserve path/query |
| major | extraction-trigger missing ZH mirror | stale/unshipped: resolve `wontfix` with `main` + production evidence |
| major | apex certificate SAN mismatch | H: external DNS/TLS repair |
| minor | Colophon JS count is stale | T: update EN/ZH + README/CLAUDE architecture copy |
| minor | demo capability description is too narrow | T: rewrite from public demo state |
| minor | RepoLens “Planned until …” fragment | T: complete sentence + parity check |
| minor | demo pin says 1.9.0 | T: update to 1.11.0 |
| minor | warrant L167/L76 deep links drifted | evidence-only: both anchors are correct at v1.11.0 |
| minor | gm-crypto evidence deep links drifted | T: change workflow 166→169; retain four verified links |
| minor | extraction description is broken | stale/unshipped: resolve with absent-source evidence |
| minor | CLAUDE says v0.8 AEAD is next | T: update shipped/next contract |
| minor | historical dudect leak says “must fire” | T: add caught-leak status |
| minor | five release-history dates differ | T: align EN/ZH to tagger/crates.io |
| minor | mobile nav does not contain focus | A: inert background + focus placement/restore |
| minor | `/404.html` is indexable `200` | M: 404-only `noindex, follow` |
| minor | explainer EN cue is unidiomatic | T: “The load-bearing line …” |

### Nit rows resolved by implementation

| Issue group | Workstream |
| --- | --- |
| About parity; EN About/Contact descriptions; notebook ordering claim | T |
| ZH FFI term; ZH tagline; ZH project status; certification gloss | T |
| Home CTA vocabulary and consistent private-source disclosures | T |
| EN/ZH warrant telemetry wording; CI-gate excerpt; README identity | T |
| dudect intro, threshold formatting, and project-note cross-links | T |
| localized page/notes wording, LICENSE link, localStorage disclosure | T |
| gated-path punctuation and constant-time evidence wording | T |
| private-project JSON-LD; localized WebSite description | M |
| title punctuation, OG locale alternate, notes BlogPosting metadata | M |
| Twitter description, 404 robots metadata | M |
| conditional scripts/preloads, maskable icons, social-card compression | M |
| Menu/Skip i18n; print chrome; supported hero-proof weight | A |
| theme accessible name; dudect scrolling; static case-study IDs | A |
| copy success/failure feedback, backdrop dismissal, 44px install target | A |
| notes description and lede broadened beyond a fixed technology list | T |

### Nit rows resolved without implementation

| Issue | Disposition |
| --- | --- |
| Home vs projects-index summary density | `wontfix`: explicit altitude compression; status/source remains load-bearing |
| “Outcomes, mostly in Rust” underweights Python | `wontfix`: accurate three-of-four framing |
| Markdown external links lack `noopener noreferrer` | `wontfix`: links do not use `_blank`, so no opener exists |
| Static/project sitemap URLs have no `lastmod` | `wontfix`: optional signal; manual dates would be misleading |
| ZH extraction says translated quotes are verbatim | stale/unshipped with the absent extraction note |
| Mobile theme toggle is inside the menu | `wontfix`: reachable, intentional compact navigation; focus containment is fixed separately |

## Notion Resolution Flow

1. Fetch the row again immediately before resolution.
2. Append a dated resolution containing the final disposition, changed files
   or live evidence, verification commands, and commit/production reference.
3. Use `fixed-mid-session` only for a demonstrated source or live fix.
4. Use `wontfix` for stale/unshipped, intentional, or invalid observations and
   explain why; do not disguise these as fixes.
5. Use `duplicate` only when a row truly adds no distinct acceptance condition.
6. Never update a workstream's rows if its required verification is red.
7. Do not modify the 72 `info` rows as part of repair execution.

## Failure Handling and Rollback

- If a row no longer reproduces, stop and re-triage it before editing.
- If a public source contradicts the proposed copy, the public source wins and
  the row remains open until a calibrated correction is designed.
- If a content change breaks EN/ZH parity, revert that task rather than merging
  a one-language intermediate state.
- If a JavaScript enhancement compromises the no-JS baseline or CSP, revert
  the enhancement; do not widen CSP to make it pass.
- If DNS access or authority is unavailable, keep the TLS row open and deliver
  the verified DNS record set and live acceptance commands without attempting
  an unauthorized infrastructure change.
- Commits stay workstream-scoped so any batch can be reverted without removing
  unrelated fixes.

## Shipping and Acceptance

Repository work ships as three branches/PRs in `T`, `A`, `M` order. Hosting is
a separately authorized operational change. Each repository branch must be
independently green and deployable.

The program is complete when:

- all 65 non-info rows have a verified action or evidence-only disposition;
- the 55 action rows have passed their workstream acceptance checks;
- the 10 evidence-only rows contain reproducible rationale;
- all Jekyll and validator checks pass after every repository workstream;
- no public claim exceeds its cited public source;
- EN/ZH claim parity, no-JS usability, CSP, and current design tokens remain intact;
- strict apex HTTPS and one-hop redirects pass before the TLS row closes;
- no `info` row is converted into repair work merely to reduce the open count.

## Sources

- [Site review issues — 2026-08-03 continuous](https://app.notion.com/p/62a7b6cb75024a658c0c1e2c614cac63?pvs=204)
- [frankxue.dev — personal site](https://app.notion.com/p/368a01fccd2b81baa3b2f34bea1f8cf4?pvs=204)
- [GitHub Pages: managing a custom domain](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site)
- [gm-crypto-rs v1.11.0](https://github.com/frankxue831/gm-crypto-rs/tree/v1.11.0)
- [gm-crypto-rs-demo main](https://github.com/frankxue831/gm-crypto-rs-demo)
