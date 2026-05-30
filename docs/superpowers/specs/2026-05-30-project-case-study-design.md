# Project Case-Study Structure Design

Created: 2026-05-30
Status: Approved for implementation planning

## Purpose

Deepen `gm-crypto-rs` from a polished, dense project page into a credible
engineering **case study** — one that shows judgment (the *why* and the *cost*
behind the work), not just an inventory of features. Establish a reusable
case-study shape that the two private siblings (`repolens-rs`, `ghrunners`) can
adopt later, and that degrades gracefully when a project has little publicly
verifiable evidence.

This extends — does not replace — the content model in
`2026-05-16-portfolio-project-depth-design.md`. Every source-of-truth and
editorial rule from that spec still holds; this spec evolves the *section shape*
for the flagship project and codifies the rationale-extraction discipline.

### Why now

An external review (Codex) found that the project pages "explain *what* exists
but not the problem, constraints, tradeoffs, or evidence of impact." A second
opinion (Grok) recommended reframing the existing material under case-study
headings rather than expanding with new artifacts, because that path (a) stays
faithful to the site's short, honest, technical voice, and (b) degrades
gracefully for the private siblings, which have no public benchmarks or
external validation to point at.

## Scope

Included (this round):

- Rewrite `projects/gm-crypto-rs.html` (EN) and `zh/projects/gm-crypto-rs.html`
  (ZH) into the canonical case-study shape below.
- Keep `_data/projects.yml`, `index.html`, `projects.html`, and the ZH mirrors
  consistent with the rewritten detail page (no contradictions in the short
  summaries). No data-model schema change is expected.
- Add validator coverage that locks the new structure where it is cheap and
  deterministic to do so (see Testing).

Excluded (explicitly deferred, NOT this round):

- Rewriting `repolens-rs` or `ghrunners`. This spec defines the shape they will
  later adopt, but applying it needs private facts only the author holds and is
  a separate effort.
- Any new visual component, color, or layout change. Reuse existing
  `prose` / `version-grid` / `project-summary` styling.
- Concrete performance numbers. Evidence stays correctness- and
  safety-focused (qualitative). A single throughput line MAY be added later
  *only* if a reproducible benchmark figure exists; absent that, omit it.
- Contact form / public email restoration; blog/notes changes.

## The canonical case-study shape

Six content sections, in order. Section titles may be localized; the order is
fixed so the two languages stay mirrored and the shape reads the same across
projects.

1. **What it is** — one or two sentences of orientation. Identity, not history.
2. **The problem** — the gap that justifies the work. What was missing or
   unsatisfying in the existing landscape that made this worth building.
3. **Constraints & key decisions** — the heart. The conditions that shaped the
   design, then the non-obvious choices made in response, **each paired with its
   cost or tradeoff**. This is where judgment is visible.
4. **Evidence** — what actually backs the claims: verification, interoperability,
   sustained delivery. For public projects this cites public artifacts; for
   private projects it cites internal harnesses and surfaces, clearly labeled as
   private-snapshot.
5. **Next** — candidate or planned scope, never promoted to shipped.
6. **What it isn't** — boundaries and scoping disclaimers, plus any
   non-affiliation note.

Followed by the existing links block.

### Anti-relabeling rule (the load-bearing editorial constraint)

The single biggest risk of this reframe is *performative relabeling*: putting
the same sentences under sexier headings, which reads as worse than the current
honest page. To prevent it:

- Every reframed section must add real rationale or constraint that the current
  page leaves implicit. A heading rename with no new "why" is a defect.
- "Constraints & key decisions" must state, for each decision, *what forced it*
  and *what it costs*. A decision with no tradeoff is a feature, not a decision —
  move it to Evidence or cut it.
- If a section cannot be filled with genuine rationale for a given project, the
  section is omitted for that project rather than padded. (Relevant to the
  private siblings later, not to `gm-crypto-rs`.)

## gm-crypto-rs content mapping

Source material already exists on the current page; this is a redistribution and
compression, not a rewrite from zero. Net length should stay close to current.

- **What it is** — keep the current opener: pure-Rust SM2/SM3/SM4 SDK,
  `no_std + alloc`, wasm-capable, RustCrypto-trait fits, runnable demo.
- **The problem** — make explicit what is currently implied only by "What's
  different": Rust SM implementations *aim* for constant-time secret-dependent
  operations, but design intent is asserted once and can silently regress; and
  the target combination (no_std, C-FFI consumers across several languages,
  byte-level GB/T conformance, interop with gmssl/OpenSSL) is unusual. The page
  should say why that combination motivated a from-scratch SDK with continuous
  verification.
- **Constraints & key decisions** — reframe "What's different" plus the safety
  bullets as decisions with costs:
  - *Continuous leak-regression gate over one-time review.* A `dudect-bencher`
    harness exercises the secret-touching paths every CI run; a core set is
    gated at `|τ| < 0.20` and fails the build on regression. Cost: CI budget,
    and a split between gated paths and telemetry-only paths. Keep the honest
    caveat verbatim in spirit — the harness reports *detection events*; a low
    `|τ|` means no leak was detected under the budget, not that none exists.
  - *`#![forbid(unsafe_code)]` in the core, SIMD `unsafe` quarantined* to a
    sibling crate behind an opt-in feature. Cost: SIMD is not the default; the
    default path is the safe linear-scan S-box.
  - *Constant-time-designed arithmetic* via `subtle` + `crypto-bigint`, secret
    material zeroized on drop. Cost: not constant-time on CPUs with
    data-dependent multiply latency (already disclosed under boundaries).
  - *Throughput-then-API sequencing.* The version arc was deliberately ordered:
    land the bitsliced SIMD S-box and CBC-decrypt fanout first, then expose
    user-callable cipher modes and AEAD on top. Present as a sequencing
    decision, not a bare changelog.
- **Evidence** — what backs the claims: byte-identical output against the KAT
  suite, gmssl 3.1.1 interop, and OpenSSL `SM4-XTS` (`xts_standard=GB`); the
  in-CI `|τ|` gates; `#![forbid(unsafe_code)]`; the public crate
  (`gmcrypto-core`), `docs.rs`, and the runnable demo repo. The existing
  `version-grid` definition list stays here as evidence of sustained,
  dated delivery rather than as its own "What is shipped" section.
- **Next** — keep the candidate-scope list (AEAD `aead 0.6` trait fit parked on
  upstream rc, AVX-512 `sbox_x64`, streaming/incremental CCM).
- **What it isn't** — keep the current boundaries list and the non-affiliation
  paragraph unchanged.

## Source of truth

Re-verify at implementation time rather than trusting any snapshot. The current
page already describes `v0.6 → v0.12` as shipped, the `gmcrypto-core` crate and
the `gm-crypto-rs-demo` repo as public, and the `gm-crypto-rs` GitHub repo as
not visitor-public (no source link). Before changing any version, feature, or
release claim, confirm:

```sh
git -C ../gm-crypto-rs ls-remote --tags origin
curl -sI -L https://crates.io/crates/gmcrypto-core
curl -sI -L https://github.com/frankxue831/gm-crypto-rs        # still 404 to visitors?
```

Use the latest **public** release as the shipped baseline. Any newer untagged
local work appears only under **Next**. Do not add a `gm-crypto-rs` GitHub
source link while the repository returns 404 to unauthenticated visitors.

## Editorial rules (carried from the portfolio spec, reaffirmed)

- Keep the short, honest, technical voice. Reframing must not inflate tone.
- EN and ZH pages are equivalent in meaning, not literal translations, and carry
  the same shipped/next/boundary split, release label, and links.
- Scoped language for security claims: `constant-time-designed`, "guarded by a
  detectable-leak regression harness." No `production-ready`, `secure`,
  `guaranteed`, or absolute `constant-time`.
- State that `dudect-bencher` detects timing-leak *events* and does not prove the
  absence of leaks.
- Public links only. No `gm-crypto-rs` / `repolens-rs` / `ghrunners` GitHub
  source links while their repos are not visitor-public. No `mailto:` / email.

## Constraints honored (current site invariants)

The rewrite must not break what the validator and design system already enforce:

- The detail page keeps its `<section class="section wrap reveal">` wrapper
  (scroll-reveal regression check).
- The copy-to-clipboard install block (`cargo add gmcrypto-core`) stays on both
  the EN and ZH `gm-crypto-rs` pages.
- Headings remain `<h2>` so the contents-rail scroll-spy picks them up; more
  well-named sections improve the rail. `scroll-margin-top` on detail headings is
  already in `style.css`.
- No private/unreachable GitHub source links; no exposed email.
- Tokens only; no inline colors or new components.

## Data flow

`_data/projects.yml` continues to provide repeated facts (status, release label,
tags, links) to the home and index pages. The detail page provides narrative and
rationale. The short home/index summaries for `gm-crypto-rs` must not contradict
the rewritten detail page; adjust their one-line copy if the framing shifts.

## Testing / verification

1. `bundle exec jekyll doctor` and
   `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bundle exec jekyll build`.
2. `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb` →
   "Site validation passed". Teeth-test any new check (break → confirm fail →
   restore).
3. Generated pages exist: `_site/projects/gm-crypto-rs/index.html` and
   `_site/zh/projects/gm-crypto-rs/index.html`.
4. New validator coverage (cheap, deterministic only):
   - Both `gm-crypto-rs` pages contain the case-study section headings in order
     (EN heading set and the ZH heading set, each matched against its page).
   - The `dudect` detection-event caveat phrase is still present (the honest
     "detects events, not absence" language must survive the rewrite).
   - No overclaim words appear on the `gm-crypto-rs` pages, matched as whole
     words: `production-ready`, `guaranteed`, `secure`. (Do NOT regex
     `constant-time` — the page legitimately uses `constant-time-designed` and
     `constant-time GHASH`; the absolute-`constant-time` ban is an editorial /
     review rule, not an automated one, to avoid false positives.)
   - Existing structural checks (reveal wrapper, install block, no private
     source link) still pass.
5. Browser (jekyll serve + chrome-devtools MCP): EN and ZH `gm-crypto-rs` pages,
   light + dark. Contents rail lists the new sections; install copy button works;
   no console errors.
6. Independent subagent diff review against this spec, then push and open a PR
   for the author to merge.

## Acceptance criteria

- `projects/gm-crypto-rs.html` and `zh/projects/gm-crypto-rs.html` follow the
  six-section canonical shape in order, with localized titles.
- Each of "The problem" and "Constraints & key decisions" adds genuine rationale
  the previous page only implied — no section is a bare rename (anti-relabeling
  rule).
- Every decision in "Constraints & key decisions" names a cost or tradeoff.
- The page stays close to its current length; voice unchanged.
- All source-of-truth, editorial, and site-invariant constraints above hold;
  the full Testing list passes, including the new validator checks.
- Home and index summaries for `gm-crypto-rs` do not contradict the detail page.
- The canonical shape and anti-relabeling rule are documented here clearly enough
  that `repolens-rs` and `ghrunners` can adopt them later without re-deriving the
  design.

## Open risks

- **Performative relabeling.** Mitigated by the anti-relabeling rule and the
  per-decision tradeoff requirement; the diff review must check that each
  reframed section earns its heading.
- **Length creep.** Going from five to six sections risks bloat. Mitigation:
  compress the changelog prose into Evidence and keep new prose tight; the
  acceptance criterion is "close to current length."
- **Sibling degradation unproven.** The shape is designed to degrade for private
  projects, but that is only validated when `repolens-rs` / `ghrunners` adopt it
  later. If it does not fit them, revise the shape before forcing it on.

## Implementation refinements (2026-05-30, post-review)

Codex and Grok reviewed this spec; source-of-truth was re-verified in plan mode.
The following refinements were folded into the implementation (the user chose the
all-in-one scope and the explicit cost cue):

- **Source-of-truth update.** `gm-crypto-rs` is now a **public** repo
  (`gh repo view` → `PUBLIC`; unauthenticated `200`). Latest public tag and the
  published `gmcrypto-core` version are **v0.16.0**, not v0.12.0. `v0.14.0` was
  deliberately **never published** — a `cargo-fuzz` parser-fuzzing sweep (16
  targets, zero crashes) that changed no output bytes, so crates.io goes
  `0.13.0 → 0.15.0`. Releases follow a **core-in-vN / FFI-in-vN+1** cadence.
  Consequences: the page links its public **Source**; `_data/projects.yml` sets
  `repo_url` + `public_source: true` + `release: v0.16.0`; the validator's
  `private_source_pattern` drops `gm-crypto-rs` (keeps `repolens-rs|ghrunners`).
- **Anti-relabeling gate = a decision/rationale matrix authored first** (both
  reviewers' #1 fix): `forced-by → decision → cost → evidence`, kept in the PR
  description and signed off by human + subagent review before the rule is
  claimed satisfied.
- **Explicit cost cue.** Each decision ends with a visible `Cost:` (EN) / `代价：`
  (ZH) lead-in; the validator counts `>= 4` per page (one per decision) — the
  machine-checkable half of the anti-relabeling rule.
- **Fixed ZH headings** (deterministic checks): `是什么` · `要解决的问题` ·
  `约束与关键决策` · `证据` · `下一步` · `它不是什么`.
- **New validator checks** (all teeth-tested) on both `gm-crypto-rs` pages: the
  six headings present and in order; `>= 4` cost cues; the dudect caveat phrase
  (`detection events` / `检测事件`) survives; the `version-grid` precedes the
  `Next`/`下一步` heading and `v0.16.0` appears before it (history lives under
  Evidence); the public source link is present; no overclaims (EN whole-word
  `production-ready|guaranteed|secure`; ZH `生产就绪|保证安全|绝对常量时间`,
  without flagging the legitimate `按常量时间设计`).
- **i18n.** Added `project_summary.source` (`en: Source` / `zh: 源码`) so the
  shared summary include renders a localized source link instead of a hardcoded
  English string.
