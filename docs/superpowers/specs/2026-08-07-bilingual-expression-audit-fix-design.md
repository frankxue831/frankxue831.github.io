# Bilingual Expression Audit Fix Design

Created: 2026-08-07
Status: Approved for implementation planning

## Purpose

The 2026-08-07 full bilingual readthrough found seventeen open expression
issues that are still present on `main` at `ba3f39f`: five `minor` issues and
twelve `nit` issues, including one previously filed home-page CTA issue that
was reopened after re-verification. This design fixes that bounded set before
the older residual nit inventory.

The repair preserves the site's editorial contract: public claims must remain
calibrated to evidence that a reader can actually inspect; private projects
must not borrow public authority; and the Chinese copy should sound native
without changing the English claim boundary.

## Scope Boundary

This batch includes exactly the seventeen open rows assigned to the
`2026-08-07 full bilingual expression audit` pass, including the reopened home
CTA row:

- five claim, evidence, or grammatical-category issues marked `minor`;
- twelve bounded wording, tense, terminology, subtitle, and accessible-name
  issues marked `nit`.

The batch excludes:

- the 98 older residual nits covered by the post-PR-82 plan;
- the apex-DNS `major` issue;
- all `info` inventory rows;
- unrelated rewriting, layout work, CSS, JavaScript, CSP, navigation, or
  project-fact changes.

## Editorial Rules

1. **Claim parity, not literal translation.** English and Chinese must assert
   the same facts, limitations, and degree of certainty. Chinese sentence
   structure may differ where that produces natural prose.
2. **Separate visible evidence from private verification.** A rendered video
   can show that the artifact and disclosure markers exist. It cannot let an
   external reader independently verify a private source line or a private
   gate run.
3. **Name what evidence supports.** Evidence of a maintainer's calibration is
   not additional evidence that code has constant-time behavior.
4. **No invented facts.** Do not add version numbers, tags, commits, source
   URLs, test results, or release claims.
5. **Terms of record remain stable.** Existing intentional terms such as
   `受控`, `单次运行`, and literal identifiers remain unchanged unless the
   affected phrase itself is one of the seventeen issues.

## Change Set 1 — Claims and Evidence Boundaries

This is the highest-risk group and lands first.

### Constant-time warrant note

Files: `_notes/constant-time-warrant.md` and
`_notes/constant-time-warrant.zh.md`.

- Replace the unsupported "Every crypto library" universal in the body and
  matching metadata with a scoped statement that constant-time claims are
  common in cryptographic libraries.
- Reframe "exactly two things" in the body and description as the two
  artifacts this essay uses to transfer warrant, not a
  necessity-and-sufficiency claim.
- Replace "evidence in itself" with an explicit distinction: volunteering a
  limitation is evidence of the maintainer's calibration, not evidence that
  the code is constant-time.
- Make the English closing idiomatic while preserving the comparison with the
  video's production cost. The Chinese closing already expresses that
  comparison naturally and changes only if parity requires it.

### Explainer Engine evidence

Files: `projects/explainer-engine.html` and
`zh/projects/explainer-engine.html`.

- Keep the checkable facts: the clip is a real rendered artifact, and the
  `simplified` and `verified @ commit` markers are visible.
- State plainly that the cited private source line and private gate result are
  not independently checkable today. If the source is later published, the
  cited line could become externally checkable; the historical gate result
  would still require public run evidence. Do not promise publication.
- Do not add a source link or imply a publication date.

### Byte-identity note

File: `_notes/byte-identity.zh.md`.

- Rewrite the opening question to: `它产出的字节，是否与可信参考实现在相同输入、相同规则下产出的字节完全一致。`
  This compares outputs under the same conditions rather than comparing an
  implementation directly with bytes.

## Change Set 2 — Native Wording and Page Microcopy

- `_notes/starting-a-notebook.zh.md`: replace `最吃紧的几篇` with
  `最扎实的几篇`, and replace the apparent typo `私下游记` with
  `先留在私人笔记里就够`.
- `_notes/unsafe-opt-in.zh.md`: replace concealment language (`藏在`) with
  placement behind an explicit feature, and make the same-crate alternative
  explicitly mean keeping those paths outside the default build.
- `404.html`: use `你要找的页面可能已经移动，也可能从来就不存在。总之，不在这里。`
  so the Chinese subject is the missing page rather than the link.
- `index.html` and `zh/index.html`: use `How to get in touch` and `怎么联系`
  for the contact CTA. These labels point to the existing contact explanation
  without implying that additional channels exist.
- `projects.html`: use `Private/local today — source not public.` for
  ghrunners instead of interpolating the slash-style status label into
  ungrammatical prose.
- `zh/projects/explainer-engine.html`: rewrite the `Next` research question as
  `一个概念有多少内容能做成动画讲出来，同时仍可按源码核对。`

## Change Set 3 — Subtitles and Accessible Text

- `assets/video/harness-field-explainer.en.vtt`: change `Constraint blocks bad
  action.` to the grammatical generic plural `Constraint blocks bad actions.`
  so it matches the other generic force definitions.
- `zh/projects/ghrunners.html` and
  `_includes/figures/ghrunners-evidence.zh.svg`: replace `受控的控制动作` with
  `受控操作` in both the visible decision heading and the SVG accessible
  title. The two surfaces must remain identical in terminology.

No timing, cue boundaries, SVG geometry, styling, or animation changes are in
scope.

## Change Set 4 — Historical Tense and Proper Names

### v1.10 history

File: `projects/gm-crypto-rs-releases.html`.

- Change the completed v1.10 assurance-cycle sentence to past tense and avoid
  the awkward singular possessive: no runtime output of any published crate
  changed, so crates.io skipped 1.10.0.
- Preserve every release fact and the statement that the changes shipped with
  1.11.0.

### GmSSL casing

Apply one public-copy rule across the affected English and Chinese notes,
front matter, case study, and release-history pages:

- use `GmSSL` for the named project or implementation in prose and metadata;
- retain lowercase `gmssl` only inside literal commands, executable names, or
  identifiers such as `interop-gmssl`, formatted as code where appropriate;
- do not mechanically rewrite repository documentation or historical spec
  documents outside the public site content tree.

The implementation plan must enumerate every lowercase public-content match
before editing, classify it as proper name or literal identifier, and leave no
unclassified match.

## Validation and Failure Handling

Validation runs after each change set and once across the complete batch:

1. Search for every exact rejected phrase and confirm it has no unintended
   public-content residue.
2. Search case-insensitively for `gmssl`; classify every remaining lowercase
   occurrence as a literal identifier or command.
3. Run `jekyll doctor`.
4. Run `bundle exec jekyll build`.
5. Run `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb`.
6. Inspect the rendered English and Chinese extracts for every changed page,
   including the VTT cue and SVG accessible title.

If an existing validator pins a rejected phrase or encodes the old claim
boundary, update only that targeted assertion and add a regression guard for
the corrected boundary. A validator failure unrelated to this batch is
reported and investigated; it is not silenced.

If a proposed wording changes a technical claim, creates EN/ZH asymmetry, or
requires an unverifiable fact, the affected Notion issue remains open until a
calibrated replacement is chosen. Passing the build alone is not sufficient.

## Notion Resolution Flow

The issue database is updated only after the final batch verification passes.
Each resolution must identify its corresponding source change:

- mark each of the seventeen rows `fixed-mid-session`;
- append the final old-to-new wording and repository evidence;
- do not create replacement or duplicate issue rows;
- do not change the status of the older residual nits, DNS issue, or info
  inventory rows.

## Shipping

Implementation stays on one branch and uses four independently reviewable
content commits in the change-set order above. This approved design is a
documentation-only commit made before implementation planning; the subsequent
implementation plan is committed separately after user review.

The four content commits are intentionally risk-ordered:

1. claims and evidence boundaries;
2. native wording and page microcopy;
3. subtitles and accessible text;
4. historical tense and proper names.

Notion status changes happen only after the final repository verification so
the issue database never claims a fix that the branch has not demonstrated.

## Acceptance Criteria

- All five scoped `minor` rows and twelve scoped `nit` rows have source-level
  fixes and Notion resolution evidence.
- English and Chinese retain equal claim boundaries and explicit limitations.
- No private repository URL or invented release evidence appears in generated
  HTML.
- Every public prose reference to the named implementation uses `GmSSL`; every
  remaining lowercase match is a deliberate literal identifier or command.
- Rejected phrases are absent from source and generated output, except where a
  historical issue record necessarily quotes them.
- Jekyll doctor, the full build, and `scripts/validate_site.rb` pass.
- The 98 older residual nits remain out of this batch.
