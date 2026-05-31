# ZH transcreation — design

**Date:** 2026-05-31
**Status:** in progress

## Problem

The Chinese pages were first written as faithful translations of the English, then
cleaned of sentence-level 翻译腔 (PR #32). They now read as grammatical Chinese — but
still *shaped* like the English: same sentence order, same density, same assumptions
about what needs explaining. A native reader stumbles where an English reader glides.

Frank's framing: **the Chinese does not have to mirror the English. A Chinese reader
should understand the content as immediately and fully as an English reader understands
the English.** The unit of equivalence is the reader's understanding, not the sentence.

## Principle (from research)

- **Functional / dynamic equivalence** (Nida) + **Skopos theory** (Nord): the target
  text must produce the same *effect/response* and serve the same *communicative
  function* as the source; target-culture functionality outranks source-text fidelity.
- **Gold standard:** the Chinese should read as if it were *originally authored in
  Chinese*, not translated.
- **Chinese runs ~40–50% shorter than English.** Break one long English sentence into
  several short Chinese ones; cut redundancy; don't pad to match English length.
- **Tone:** friendly, conversational, never talking down. This is a *personal* site, so
  keep `你` and a spoken register (not the corporate `您`).
- **Gloss for the audience:** an English security reader knows "constant-time /
  side-channel" cold; a general Chinese reader deserves the same instant grasp via a
  half-line gloss. Give the Chinese reader what *they* need, even if the English reader
  didn't need it.

## Method — tier by content type

| Tier | Content | Method | Freedom |
|---|---|---|---|
| A — Voice | hero title/lede/CTA, about bio, section teasers, contact, page ledes | **Transcreate** | recreate the personality natively; diverge fully from EN wording |
| B — Explanation | case-study prose (problem / decisions / evidence / next) | **Localize** | unpack, gloss terms, native flow, reorder for the CN reader, cut English-only asides; CN may be shorter |
| C — Facts | version grids, GB/T numbers, CLI flags, finding names, dates, code, release/status | **Translate faithfully** | accuracy locked — source-of-truth |

## Boundary (unchanged; validator-enforced)

- **Tier-C facts** stay accurate and consistent with the EN (source-of-truth rule).
- The **six case-study headings** (是什么 / 要解决的问题 / 约束与关键决策 / 证据 /
  下一步 / 它不是什么) and the per-decision **`代价：`** cue (≥4) stay — this is the
  case-study *design*, language-agnostic, not English-ness.
- Honest-status guards stay: gm-crypto `检测事件` + `这两个项目`; repolens
  `只给 warning` / `不是那张类型化记忆图` / `脚手架`; ghrunners `受控` / `v0.4.0`.
- hreflang parity: every ZH page keeps its `alternate` to the EN counterpart.

The ZH and EN therefore stop being line-comparable. Maintenance means keeping the two
in sync at the **claim** level, not the sentence level.

## Process (per page)

transcreate by tier → self-check vs this spec → **grok** native-style review →
`jekyll build` + `validate_site.rb` green (guards intact) → **Frank's sign-off** (the
authoritative native reader) → PR (Frank merges).

## Scope

All ZH pages: `zh/index`, `zh/about`, `zh/projects`, `zh/contact`, `zh/notes`, and the
three detail pages `zh/projects/{gm-crypto-rs,repolens-rs,ghrunners}`. Detail pages get
the most work (Tier-B heavy); prose pages get Tier-A voice polish. The EN pages are not
touched.

## References

- Nida, dynamic/functional equivalence (reader response).
- Reiss & Vermeer / Nord, Skopos theory (function over fidelity).
- Microsoft Simplified Chinese localization style guide (break long sentences; concise;
  friendly tone).
- 思果《翻译研究》, 余光中《怎样改进英式中文》, 阮一峰《中文技术文档写作规范》 (the
  sentence-level rubric from PR #32, still in force).
