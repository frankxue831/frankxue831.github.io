# Chinese Prose Audit Batch 2 Design

## Context

The 2026-08-08 production audit confirmed that the bilingual routes changed by
PR #83 render cleanly on desktop and mobile: one `h1` per page, correct language
metadata, no broken images, no horizontal overflow, and no browser console
warnings or errors. The remaining Notion backlog is not a fresh defect list. All
98 open `nit` rows come from the 2026-08-06 Chinese prose readthrough, and the
set includes duplicates, intentional voice choices, and issues whose suggested
fixes would flatten the site's tone.

The approved approach is a thematic, high-confidence batch. It corrects hard
translations, ambiguous technical wording, unexplained English jargon, and
cross-page terminology drift without turning the site's Chinese into neutral
documentation prose.

## Goal

Close 26 selected Notion rows across seven Chinese pages by making 21 concrete
prose corrections and marking five duplicate rows as duplicates. Preserve every
technical fact, version, release date, publication boundary, snapshot label,
source link, and evidence claim.

## Non-goals

- Do not change DNS, deployment configuration, CSS, JavaScript, layout, or
  navigation behavior.
- Do not fix the mobile menu's small background sliver in this batch. Record it
  as a new open `nit` from the production audit.
- Do not sweep all 98 open `nit` rows.
- Do not translate stable code identifiers, CLI command names, crate names,
  protocol names, standards, or public API symbols.
- Do not remove purposeful first-person phrasing or colloquial emphasis merely
  because it differs from the English sentence structure.
- Do not change English pages.

## Editorial rules

1. Prefer idiomatic engineering Chinese over word-for-word calques.
2. On first use, explain a project-specific English term in Chinese; later uses
   may keep the stable English identifier when it is part of the product model.
3. Preserve the distinction between evidence, measurement, design intent, and
   proof. No rewrite may strengthen a claim.
4. Keep private/public status and release state exactly as currently stated.
5. Keep the site's compact, direct voice. Do not replace a vivid phrase unless
   it causes ambiguity, an incorrect technical reading, or an unexplained jargon
   jump.

## Files and exact rewrite directions

### `zh/projects/explainer-engine.html`

- First `beat` occurrence becomes `beat（镜头段落）`; the later occurrence
  becomes `镜头段落类型`.
- `被渲染进了画面` becomes `直接显示在画面中`.
- Both `披露装置` / `披露标记` references become `常设出处标记` / `出处标记`,
  preserving the sentence about pixels spent on provenance rather than polish.
- `输出上的任何差异都能追回输入上的差异` becomes
  `任何输出差异都能追溯到输入差异`.

Selected Notion rows:

| Row ID | Issue | Disposition |
| --- | --- | --- |
| `3b4a01fccd2b814eba37fc88b982cae3` | `beat` has no Chinese gloss | fixed |
| `3b4a01fccd2b814db478db5465b6d88d` | passive `被渲染进了画面` | fixed |
| `3b4a01fccd2b81c3ab48d90dceed9ee2` | `disclosure furniture` rendered as `披露装置` | fixed; canonical row |
| `3b4a01fccd2b8168b07cc9d6aeea6212` | duplicate `披露装置` finding | duplicate of canonical row |
| `3b4a01fccd2b819d98ebefcab0708b2b` | awkward `追回输入上的差异` | fixed |

### `zh/projects/ghrunners.html`

- `summary_outcome` becomes
  `类型化检查结果与受控操作，都基于同一份权威的 launchd 状态。`
- The first product-model use becomes `control 子命令（verb）`; later prose uses
  `子命令` rather than bare `verb`.
- `更深的 GitHub API 接入` becomes `更深的 GitHub API 信息补全` so the next
  step describes enrichment rather than a new integration boundary.

Selected Notion rows:

| Row ID | Issue | Disposition |
| --- | --- | --- |
| `3b4a01fccd2b8131a481d001e832bd8d` | summary uses drifting `落在…上` | fixed |
| `3b4a01fccd2b81f7a5b6d93b8d81061c` | bare CLI `verb` | fixed; canonical row |
| `3b4a01fccd2b8191bc18d1ed58c43623` | duplicate CLI `verb` finding | duplicate of canonical row |
| `3b4a01fccd2b81118ec0c85fb145e217` | `API enrichment` narrowed to `API 接入` | fixed; canonical row |
| `3b4a01fccd2b81628bd3f64ff42b7d1e` | duplicate `API 接入` finding | duplicate of canonical row |

### `zh/projects/gm-crypto-rs-releases.html`

- `增量、可选` becomes `非破坏式新增、需显式启用`.
- `固有 AEAD 路径` becomes `既有 AEAD 路径`.
- `薄壳不加密码学` becomes `包装层不引入新的密码逻辑`.
- `字节幂等` becomes `字节级幂等检查`, followed by a short clarification that
  the same bytes remain stable through the tested transformation.
- `原始 Name（名称）衔接` becomes `证书原始 Name 字段的衔接`.
- `中间 CA 资格` becomes `中间证书必须具备 CA 资格`.
- `逐字节进、逐字节出` becomes `以字节串为输入和输出`.

Selected Notion rows:

| Row ID | Issue | Disposition |
| --- | --- | --- |
| `3b4a01fccd2b8164b31cee3610e5f3fe` | `additive, opt-in` compressed to `增量、可选` | fixed |
| `3b4a01fccd2b816b93fbca512a66b776` | `inherent AEAD` rendered as `固有 AEAD` | fixed; canonical row |
| `3b4a01fccd2b8130ba6aee8472c1815e` | duplicate `固有 AEAD` finding | duplicate of canonical row |
| `3b4a01fccd2b816e80daed9991c3c6ba` | `薄壳不加密码学` over-compresses the claim | fixed |
| `3b4a01fccd2b81469979e32492d7ad92` | `字节幂等` lacks a gloss | fixed |
| `3b4a01fccd2b8102af8fc36f1e829ea6` | raw `Name` transition is unclear | fixed |
| `3b4a01fccd2b8112a5a4c76d73233b2e` | `中间 CA 资格` is underspecified | fixed |
| `3b4a01fccd2b81aa9adbee8d8c67eba0` | `byte-in/byte-out` translated mechanically | fixed |

### `zh/projects/gm-crypto-rs.html`

- The decision heading becomes `核心禁止 unsafe，SIMD 单独按需开。` This makes
  the memory-safety boundary explicit and avoids reading `safe core` as a broad
  cryptographic-security guarantee.
- `工作量等于翻倍` becomes `每种模式的测试和维护面都翻倍`, matching the
  English claim about owned surface rather than promising an exact labor ratio.

Selected Notion rows:

| Row ID | Issue | Disposition |
| --- | --- | --- |
| `3b4a01fccd2b813c907ac591fdc6f9a4` | `安全的核心` is technically ambiguous | fixed; canonical row |
| `3b4a01fccd2b811aa6fdce140a00c658` | duplicate `safe core` finding | duplicate of canonical row |
| `3b4a01fccd2b8195aa51f0f85414d252` | `C ABI doubles the surface` rendered as exact labor | fixed |

### `zh/projects/repolens-rs.html`

- In the pack contents, `profile` becomes `仓库画像（profile）`.
- In the MCP tool list, `wiki` becomes `知识库（wiki）`.
- `自用（dogfood）评估契约` becomes `项目自用的评估契约`.

Selected Notion rows:

| Row ID | Issue | Disposition |
| --- | --- | --- |
| `3b4a01fccd2b81e3a289fe11929c79a5` | `profile` / `wiki` left unexplained | fixed |
| `3b4a01fccd2b814daa9ccbdca63f9c9d` | `dogfood eval` left as mixed jargon | fixed |

### `zh/about.html`

- `dudect 泄漏 harness` becomes `dudect 泄漏回归 harness`, matching the
  evidence terminology used on the project page without strengthening the
  measurement claim.

Selected Notion row:

| Row ID | Issue | Disposition |
| --- | --- | --- |
| `3b4a01fccd2b81c8b228f4100a9e5c59` | About drops `回归` from the harness name | fixed |

### `zh/colophon.html`

- `零件保持得少` becomes `组成很精简`.
- `基于设计 token 的样式表` becomes
  `基于一套设计变量（design tokens）的样式表`.

Selected Notion rows:

| Row ID | Issue | Disposition |
| --- | --- | --- |
| `3b4a01fccd2b818596b1d2b7a2f1ab7c` | `moving parts` translated mechanically | fixed |
| `3b4a01fccd2b8104b068f3fb60d59ce2` | `design tokens` left as mixed jargon | fixed |

## Production-audit record

Create one new Notion row after the content edits are validated:

- **Name:** `mobile nav：展开面板底部露出正文窄条`
- **Location:** `mobile primary navigation / assets/css/style.css`
- **Pass:** `2026-08-08 production UX audit`
- **Severity:** `nit`
- **Status:** `open`
- **Body:** At a 390 × 844 viewport, the expanded mobile navigation leaves a
  narrow strip of page content visible at the bottom. The menu remains usable,
  its links are exposed semantically, and `aria-expanded` updates correctly;
  this is a visual containment issue, not a navigation blocker. It is excluded
  from the prose batch because fixing it requires a separate CSS/interaction
  decision.

## Notion closure rules

After the repository changes pass all validation:

1. Append `## Resolution — 2026-08-08` to each of the 21 canonical fixed rows,
   naming the final replacement and the file changed.
2. Set those 21 rows to `fixed-mid-session`.
3. Append a short duplicate note to each of the five duplicate rows, link or
   name its canonical row ID, and set status to `duplicate`.
4. Do not change any of the other open `nit`, `info`, or DNS rows.
5. Create the production-audit mobile-navigation row exactly as specified above.

## Validation design

### RED: residue checks before editing

Run a targeted `rg` command over the seven files and confirm that it finds the
phrases this batch intends to remove:

```sh
rg -n '被渲染进了画面|披露装置|追回输入上的差异|每个 verb|控制 verb|GitHub API 接入|增量、可选|固有 AEAD|薄壳不加密码学|字节幂等|原始 Name（名称）衔接|中间 CA 资格|逐字节进、逐字节出|安全的核心，SIMD|工作量等于翻倍|dogfood|dudect 泄漏 harness|零件保持得少|设计 token' \
  zh/projects/explainer-engine.html \
  zh/projects/ghrunners.html \
  zh/projects/gm-crypto-rs-releases.html \
  zh/projects/gm-crypto-rs.html \
  zh/projects/repolens-rs.html \
  zh/about.html \
  zh/colophon.html
```

The command must return matches before edits. That proves the residue check can
detect the current problems.

### GREEN: residue and site checks after editing

1. Re-run the same `rg` command; it must return no matches.
2. Run `git diff --check`.
3. Run `bundle exec jekyll doctor`.
4. Run `bundle exec jekyll build`.
5. Run `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb`.
6. Inspect the rendered Chinese routes for the seven changed files at desktop
   and 390 × 844 mobile width. Confirm no text overlap, clipping, new horizontal
   overflow, broken images, or missing navigation.
7. Confirm that versions, dates, status labels, snapshot labels, and outbound
   evidence URLs are unchanged in the diff.

## Delivery

The implementation should use one focused content branch. Commit logical file
groups separately, update Notion only after the repository validation is green,
then run the full validation suite again before publishing a draft pull request.

