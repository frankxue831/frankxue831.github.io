# Content Expression Design (Release Split, Notes Reframe, Entry Altitude)

Created: 2026-08-05
Status: Approved for implementation planning

## Purpose

The site's evidence discipline is its strongest asset — pinned-tag deep links
to exact lines, `Cost:` on every decision, `What it isn't` on every project,
the dudect caveat kept in the harness author's own words. This spec does not
touch that discipline. It fixes three ways the *expression* of that material
works against it.

The 2026-08-05 content review found:

1. **The gm-crypto-rs case study is 42% changelog.** The version grid between
   `Evidence` and `Next` is 1,147 of the page's 2,758 words (identical 42%
   share on the ZH mirror). The `<details>` drawer hides only v0.6–v0.13;
   v0.14 through v1.11 sit fully expanded at 60–130 words each. The page's
   argument — *verify continuously, don't assert once* — is separated from its
   conclusion by fifteen screens of release minutiae, on the one page a
   crates.io / docs.rs visitor lands on first.
2. **The notes index tells readers not to read it.** `notes.html` ledes with
   "Nothing polished — just things worth writing down," above six pieces that
   are the strongest writing on the site. `constant-time-warrant` in
   particular carries an argument, a turn, and a generalizable conclusion —
   and sits at home-page section (04), two-of-six shown.
3. **The entry points sit above the reader's altitude, and the evidence
   asymmetry is stated three times before any work appears.** The hero lede is
   a category list plus a methodology claim; `about.html` compresses four
   projects into one 90-word four-semicolon sentence. The "only gm-crypto-rs
   is independently verifiable" disclosure appears at `index.html:66`,
   `projects.html:22`, and `about.html:56` — all before the reader has seen a
   project. Said once it reads as rigor; said three times at full weight it
   reads as anxiety, and uniform hedging stops carrying signal.

Audience, confirmed during design: people evaluating judgment (hiring /
collaboration), engineers deciding whether to depend on the crates, and Frank
writing to think. Explicitly **not** scoped as a Chinese-market portfolio —
ZH keeps full claims-parity but does not drive framing.

## Stage 1 — Split the gm-crypto-rs release history

### New pages

- `projects/gm-crypto-rs-releases.html` → permalink `/projects/gm-crypto-rs/releases/`,
  `lang: en`, `alternate: /zh/projects/gm-crypto-rs/releases/`
- `zh/projects/gm-crypto-rs-releases.html` → permalink `/zh/projects/gm-crypto-rs/releases/`,
  `lang: zh`, `alternate: /projects/gm-crypto-rs/releases/`

These are **release-history pages, not case studies** — the six-section
`case_study` skeleton does not apply and they are not added to that hash.
Page header follows the existing `page-header` pattern with the
`(03)  Work / Detail` eyebrow; body is the version grid plus a back-link to
the case study.

### What moves

Only the **Evidence-section** release material moves: the
`<details class="drawer">` block (v0.6.0 – v0.13.0) and the immediately
following `<dl class="version-grid">` (v0.14.0 – v1.11.0). Both locales.

The `<dl class="version-grid">` under `<h2>Next</h2>` is a *different* list
and **stays on the case-study page** — it is the forward-looking statement,
not history. This is easy to get wrong: `zh/projects/gm-crypto-rs.html` has
three `version-grid` elements (lines 217, 244, 298) and only the first two
move.

Ordering on the new page is **newest-first**. The current drawer runs
oldest-first, which is backwards for a changelog and is corrected in the move.
The `Not published` entries (v0.14, 0.17–0.23, v1.5, v1.10) keep their framing
verbatim — they carry the release-discipline argument and are the most
interesting rows on the page.

The `details.earlier_releases` i18n key survives: the drawer moves onto the
releases page rather than disappearing, so the `validate_site.rb:732` guard
stays valid and both locale strings are unchanged.

### What stays on the case study

A compact **Release line** block under `Evidence`, replacing what left:

- current published version and date (`v1.11.0`, 2026-08-01)
- the count of cycles that merged unpublished
- the one-line rule: a cycle that changes no output bytes merges unpublished
- the existing link to the `releases-that-change-nothing` note (unchanged)
- a link out to the full release history

The existing `{% include dudect-chart.html %}` stays where it is. The
`install` block, the audit-notes lists, and every pinned-tag evidence link are
untouched.

Expected result: `projects/gm-crypto-rs.html` drops from 2,758 words to
roughly 1,650 (1,611 after the cut, plus the Release line block) — about a
40% reduction — and `Evidence → Next → What it isn't` reads as one movement.

### Validator changes

- Add `core_pages` hreflang entries for `projects/gm-crypto-rs/releases/index.html`
  and `zh/projects/gm-crypto-rs/releases/index.html`, following the existing
  three-alternate pattern (`zh-CN`, `en`, `x-default` → the EN URL).
- Retarget the gm-crypto-rs `version_before` guard from `v1.2.0` to `v1.11.0`
  in both locale entries. The guard's intent — release state stated under
  Evidence, before `Next` — is preserved by the Release line block; the
  version token it pins on just becomes the current one.
- Do **not** add the new pages to the hardcoded `project_pages` list
  (`validate_site.rb:188`). That list carries three separate requirements —
  `SoftwareSourceCode` JSON-LD, a `project-summary` include, and a
  `data-toc-label` body attribute — none of which a release-history page
  needs. Leaving the list at its current eight entries is deliberate.
- `private_source_pattern` (`validate_site.rb:326`) forbids only
  `repolens-rs` / `ghrunners` links, so linking
  `github.com/frankxue831/gm-crypto-rs` from the releases pages is fine.
- The internal-link sweep resolves every internal target, so the case study's
  new link to `/projects/gm-crypto-rs/releases/` and the back-links from the
  releases pages are covered automatically once both pages build.

## Stage 2 — Notes reframe

- **Index lede** (`notes.html`, `zh/notes.html`): "Nothing polished" is
  removed. The replacement states what the notes are — working a specific
  problem through in public, each tied to a decision in the work — without
  overclaiming. No self-deprecation, no promotion.
- **Start-here cue**: the notes index points a first-time reader at
  `constant-time-warrant` as the representative piece. Rendered as prose in
  the lede, not a new component.
- **Home page**: `limit: 2` → `limit: 3` in `index.html` and `zh/index.html`.
  Section heading "Latest notes." sharpened to say what the notes are about.
  The `(04)` numbering and section order are unchanged — no renumbering, no
  ghost-num churn.
- New i18n keys only if the start-here cue needs one; prefer inline prose,
  consistent with the existing convention that prose lives in page templates.

## Stage 3 — Entry altitude and disclosure consolidation

- **Hero lede** (`index.html:22` + ZH): currently a category list plus a
  methodology claim. Rewritten so the first beat is one sentence a
  non-specialist can hold, with the methodology claim as the second beat
  rather than the whole sentence.
- **About** (`about.html:30` + ZH): the 90-word four-semicolon sentence
  breaks into shorter units so each project registers individually.
- **Disclosure consolidation**: the evidence-asymmetry statement stays **once
  at full weight**, in the hero proof panel where the project claims first
  appear. `projects.html:22` reduces to a short pointer; `about.html:56`
  folds to a clause. Nothing is softened, hedged away, or removed — the
  same fact is stated once well instead of three times at diminishing
  weight. No validator guard covers these three instances (confirmed by
  grep), so this is an editorial change with no harness impact.

## Cross-Cutting Constraints

- **Claims parity, native voice.** Every change lands on the EN page and its
  ZH mirror in the same commit. Disclosures, hedges, numbers, and framing
  stance match exactly; register stays natively Chinese. Per the CLAUDE.md
  2026-08 audit rule, avoid future-promising hedges (暂时 / 尚未) where EN
  states present fact.
- **Source-of-truth rule holds.** No version numbers, release claims, or
  shipped-feature statements change in this work. The release split *moves*
  copy; it does not restate it. `ghrunners`, `repolens-rs`, and
  `explainer-engine` keep their private/local framing and gain no source
  links.
- **No design-system change.** No new tokens, no new colors, no new
  components, no CSS beyond what the releases page needs from existing
  classes (`page-header`, `version-grid`, `drawer`, `project-detail__links`).
- **CSP unchanged.** No new JS, no inline scripts, no inline styles, no
  external origins. Nothing here touches the pinned inline-script hashes.
- **Validation.** `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby
  scripts/validate_site.rb` must pass after each stage, on top of
  `jekyll build`.

## Shipping

Three commits in stage order, each independently useful and revertible:

1. Release-history split (+ validator changes) — the structural change,
   highest risk, goes first.
2. Notes reframe.
3. Entry altitude + disclosure consolidation.

This spec rides with commit 1.

## Non-Goals

- No reordering or renumbering of home-page sections.
- No changes to the `case_study` six-section skeleton or its per-page
  honest-status phrase guards.
- No new projects, no new notes, no changes to `_data/projects.yml` facts.
- No filter/sort/search UI on any list (per existing convention).
- No ZH-first reframing — ZH mirrors EN, it does not lead.
- No voice de-templating sweep. Differentiating the four descriptions each
  project receives across hero → home note → index note → detail lede, and
  varying where hedges land, was considered and deferred: it is an editing
  problem, and editing is easier once the structure is right. Candidate for a
  follow-up spec after these three stages land.
