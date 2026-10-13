# Site Content Truth and Bilingual Evidence Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Correct every actionable factual, release-evidence, terminology, disclosure, and EN/ZH parity issue in the 2026-08-03 Notion review while closing stale or invalid content observations with evidence instead of manufacturing content.

**Architecture:** Treat public immutable releases as the authority for public claims, encode durable facts in the existing Jekyll source/data, and add narrow validator guards for values that can silently drift. English and Chinese are edited as paired claim surfaces. The workstream changes content and content validation only; interactive behavior and metadata schema remain for later workstreams.

**Tech Stack:** Jekyll, Liquid/HTML, Markdown, YAML, WebVTT, Ruby validation, `rg`, Git, public GitHub/crates.io evidence, and the connected Notion issue database.

## Global Constraints

- Create branch `codex/site-review-content-truth` from clean `main` at `d0004a4`, or from the then-current clean `main` after confirming that the design assumptions still hold.
- Use superpowers:test-driven-development for every validator-backed change: add a focused failing assertion, run it to observe the intended failure, make the smallest content change, and rerun it.
- Public authority order is: immutable tag, crates.io publication metadata, public `origin/main` for explicitly current snapshots, generated site, then Notion observation.
- Preserve the four verified `gm-crypto-rs v1.11.0` anchors: `cipher.rs#L627`, `Cargo.toml#L177`, `timing_leaks.rs#L167`, and `README.md#L76`. Change only the displaced workflow anchor from line 166 to line 169.
- EN/ZH parity means equal facts, hedges, numbers, release status, source visibility, and evidence limits. Chinese should be native prose rather than a literal translation.
- Do not add public source links to private projects, revive the absent extraction-trigger note, invent exact private line/run evidence, widen CSP, change page layout behavior, or introduce a framework.
- Do not edit `_includes/nav.html`, JavaScript behavior, structured-data types, manifest/icon assets, preload routing, or 404 robots metadata in this workstream.
- Use `fixed-mid-session` only for demonstrated source fixes and `wontfix` for stale/invalid/intentional rows. Do not edit the 72 `info` rows.
- Run commands from `/Users/fengxiang/Desktop/agent_workspace/frankxue831.github.io`.

---

### Task 1: Add regression guards for the release and architecture facts

**Files:**
- Modify: `scripts/validate_site.rb`
- Test: `scripts/validate_site.rb`

**Interfaces:**
- Consumes: source pages, `_data/dudect.yml`, `_data/i18n.yml`, and generated `_site` HTML.
- Produces: targeted failures for the stale facts repaired in Tasks 2–5.

- [ ] **Step 1: Confirm branch and baseline**

Run:

```bash
git status --short --branch
bundle exec jekyll doctor
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
ruby scripts/check_release_drift.rb
```

Expected: clean content branch; doctor, build, validator, and release-drift checker all pass before adding new assertions.

- [ ] **Step 2: Add exact release-history assertions**

In `scripts/validate_site.rb`, add a `release_history_expected` map used against both `projects/gm-crypto-rs-releases.html` and `zh/projects/gm-crypto-rs-releases.html`:

```ruby
release_history_expected = {
  "v0.15.0" => "2026-05-27",
  "v0.10.0" => "2026-05-22",
  "v0.9.0"  => "2026-05-20",
  "v0.8.0"  => "2026-05-17",
  "v0.7.0"  => "2026-05-15"
}.freeze
```

For each locale source, assert that every version and date occur in the same release-history row and add a validation error if an old date remains. Do not make the validator fetch the network.

- [ ] **Step 3: Add durable source-contract assertions**

Add checks that fail unless all of these are true:

```text
projects/gm-crypto-rs.html and zh/projects/gm-crypto-rs.html contain =1.11.0
both pages link dudect-pr.yml#L169 and do not link dudect-pr.yml#L166
both pages link constant-time-warrant, constant-time-ci-gate, byte-identity, and unsafe-opt-in
_data/dudect.yml contains numeric gate 0.20 and sentinel 0.55 plus display strings 0.20 and 0.55
_includes/dudect-chart.html uses status_caught for the historical before row and status_fire only for negative_control
assets/video/harness-field-explainer.en.vtt contains “The load-bearing line”
CLAUDE.md does not say that v0.8 AEAD support is next
```

Keep errors itemized by source path so a future drift points at the broken contract.

- [ ] **Step 4: Add rejected-phrase assertions**

Add a compact source scan that rejects these stale or misleading fragments:

```ruby
rejected_content = {
  "Colophon" => ["six focused files", "roughly 500 lines"],
  "gm demo" => ["=1.9.0", "hash, sign, and verify"],
  "RepoLens" => ["Planned until"],
  "warrant telemetry" => ["proves constant-time", "证明了常量时间"],
  "notes scope" => ["Rust, cryptography, CI, and tooling."]
}.freeze
```

Implement the scan over the named source files only; do not globally ban ordinary words such as `planned`, `hash`, or `Rust`.

- [ ] **Step 5: Run the new validator and observe failure**

Run:

```bash
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
```

Expected: failure messages name the old release dates, `=1.9.0`, workflow line 166, stale architecture copy, missing dudect display/status keys, and the old VTT sentence. If an assertion passes unexpectedly, inspect the current source and narrow the guard rather than weakening it.

- [ ] **Step 6: Commit the red tests**

Run:

```bash
git diff --check
git add scripts/validate_site.rb
git commit -m "test: guard reviewed site content facts"
```

---

### Task 2: Correct the gm-crypto demo, audit links, release dates, and case-study wording

**Files:**
- Modify: `projects/gm-crypto-rs.html`
- Modify: `zh/projects/gm-crypto-rs.html`
- Modify: `projects/gm-crypto-rs-releases.html`
- Modify: `zh/projects/gm-crypto-rs-releases.html`
- Test: `scripts/validate_site.rb`

**Interfaces:**
- Publishes: the current demo version/capability boundary and immutable release evidence.
- Links: `gm-crypto-rs` tag `v1.11.0` and the paired explanatory notes.

- [ ] **Step 1: Verify the five immutable evidence anchors before editing**

Open the public `v1.11.0` files and verify:

```text
src/core/cipher.rs#L627                    ct_eq comparison
Cargo.toml#L177                            unsafe_code = "forbid"
tests/timing_leaks.rs#L167                 fn negative_control
.github/workflows/dudect-pr.yml#L169       Parse and gate
README.md#L76                              does not prove constant-time
```

Also verify the public demo `Cargo.toml` contains `gmcrypto-core = "=1.11.0"`. Stop if a public source no longer matches; do not copy Notion's suggested line blindly.

- [ ] **Step 2: Rewrite the EN demo paragraph**

In `projects/gm-crypto-rs.html`, replace the old narrow demo sentence with this claim boundary:

```html
The published <code>gm-crypto-rs-demo</code> is a consumer and smoke-test tour of representative crate capabilities, including hashing, signing and verification, encryption and decryption, key exchange, and encoding flows. Its dependency is pinned to <code>gmcrypto-core = "=1.11.0"</code> so the demo and this evidence snapshot refer to the same release.
```

Do not describe the examples as exhaustive conformance coverage.

- [ ] **Step 3: Rewrite the ZH demo paragraph and FFI term**

Use this paired wording in `zh/projects/gm-crypto-rs.html`:

```html
已发布的 <code>gm-crypto-rs-demo</code> 是面向使用者的示例与冒烟测试导览，覆盖散列、签名与验签、加解密、密钥交换和编码等代表性能力。它把依赖固定为 <code>gmcrypto-core = "=1.11.0"</code>，使示例与本页证据快照对应同一版本。
```

Where the page uses `入口点` for an FFI API boundary, replace it with `FFI 入口` or `FFI 接口` according to the sentence; use `FFI 入口` for the case-study label.

- [ ] **Step 4: Correct only the displaced workflow anchor**

In both locale case-study pages, change:

```text
.github/workflows/dudect-pr.yml#L166
```

to:

```text
.github/workflows/dudect-pr.yml#L169
```

Leave the four already-correct anchors unchanged.

- [ ] **Step 5: Calibrate the comparison and gated-path language**

Replace the categorical EN statement `Secret-dependent comparison is constant-time` with:

```html
Secret-derived equality uses the crate's constant-time comparison path; the linked source shows that implementation choice, while the dudect evidence below remains empirical rather than a proof.
```

Use the paired ZH wording:

```html
涉密数据的相等判断走库里的常量时间比较路径；链接源码能核对这一实现选择，下面的 dudect 结果仍是经验性证据，不是证明。
```

Normalize the gated-path list so every item is a full sentence with a terminal period in EN and `。` in ZH.

- [ ] **Step 6: Add the two missing note cross-links**

In the case-study notes/evidence section in both locales, add links to:

```text
/notes/byte-identity/       /zh/notes/byte-identity/
/notes/unsafe-opt-in/       /zh/notes/unsafe-opt-in/
```

Use the existing `relative_url` pattern and link text `Byte identity as an interop test` / `把字节一致性当作互操作测试`, and `Unsafe as an explicit opt-in` / `把 unsafe 变成显式选择`.

- [ ] **Step 7: Correct the five release dates in both locales**

In `projects/gm-crypto-rs-releases.html` and `zh/projects/gm-crypto-rs-releases.html`, replace only the date cells/strings for these releases:

```text
v0.15.0  2026-05-27
v0.10.0  2026-05-22
v0.9.0   2026-05-20
v0.8.0   2026-05-17
v0.7.0   2026-05-15
```

Keep version order, descriptions, and all other release dates unchanged.

- [ ] **Step 8: Run the focused checks**

Run:

```bash
rg -n "=1\.9\.0|dudect-pr\.yml#L166|Secret-dependent comparison is constant-time|入口点" projects/gm-crypto-rs.html zh/projects/gm-crypto-rs.html
rg -n "=1\.11\.0|dudect-pr\.yml#L169|byte-identity|unsafe-opt-in" projects/gm-crypto-rs.html zh/projects/gm-crypto-rs.html
rg -n "2026-05-27|2026-05-22|2026-05-20|2026-05-17|2026-05-15" projects/gm-crypto-rs-releases.html zh/projects/gm-crypto-rs-releases.html
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
```

Expected: the first search exits 1; the second finds paired EN/ZH facts; the validator remains red only for later tasks.

- [ ] **Step 9: Commit the gm case-study corrections**

Run:

```bash
git diff --check
git add projects/gm-crypto-rs.html zh/projects/gm-crypto-rs.html projects/gm-crypto-rs-releases.html zh/projects/gm-crypto-rs-releases.html
git commit -m "fix: align gm crypto evidence with public releases"
```

---

### Task 3: Separate dudect policy, historical detection, and proof language

**Files:**
- Modify: `_data/dudect.yml`
- Modify: `_data/i18n.yml`
- Modify: `_includes/dudect-chart.html`
- Modify: `_notes/constant-time-warrant.md`
- Modify: `_notes/constant-time-warrant.zh.md`
- Modify: `_notes/constant-time-ci-gate.md`
- Modify: `_notes/constant-time-ci-gate.zh.md`
- Modify: `assets/video/harness-field-explainer.en.vtt`
- Test: `scripts/validate_site.rb`

**Interfaces:**
- `_data/dudect.yml` keeps numeric policy values for plotting and adds exact display strings for prose/table output.
- `_data/i18n.yml` exposes separate `status_fire` and `status_caught` semantics.

- [ ] **Step 1: Add display-safe threshold strings**

Immediately after the numeric keys in `_data/dudect.yml`, add:

```yaml
gate_display: "0.20"
sentinel_display: "0.55"
```

Keep `gate: 0.20` and `sentinel: 0.55` numeric so Liquid arithmetic continues to work.

- [ ] **Step 2: Add a caught-leak status in both locales**

Under each locale's `dudect` map in `_data/i18n.yml`, retain `status_fire` for `negative_control` and add:

```yaml
# EN
status_caught: "Over gate — caught"

# ZH
status_caught: "超过门槛——已捕获"
```

Do not reuse `must fire` / `必须触发` for the historical real leak.

- [ ] **Step 3: Render exact display thresholds and distinct statuses**

In `_includes/dudect-chart.html`:

- render `d.sentinel_display` in sentinel policy cells;
- render `d.gate_display` in blocking-gate cells and the historical rows;
- keep the SVG arithmetic on numeric `d.gate` and `d.sentinel`;
- render `t.status_fire` only in the `negative_control` row;
- render `t.status_caught` in the historical `leak.before` row;
- keep `t.status_pass` in the fixed `leak.after` row.

Wrap no table markup here; horizontal scrolling belongs to the accessibility workstream.

- [ ] **Step 4: Calibrate the EN/ZH visualizer introduction**

Set the EN introduction to:

```yaml
intro: "Published measurements and current policy share one view: observed values are evidence from a named run, while the gate and sentinel are enforcement thresholds rather than proof."
```

Set the ZH introduction to:

```yaml
intro: "这张图把已发布测量值与当前策略放在一起：观测值来自一轮明确的运行，门槛与哨兵值是执行策略，不是证明。"
```

- [ ] **Step 5: Align warrant telemetry claims**

In both constant-time warrant notes, describe the chart as evidence that the detector caught a deliberately preserved negative control and a historical regression. State explicitly that passing observations do not prove constant-time behavior. Preserve all exact public measurements.

Required EN sentence:

```markdown
The telemetry shows that the harness can catch its deliberate negative control and records one historical regression it caught; low observed values support the implementation claim but do not prove constant-time behavior.
```

Required ZH sentence:

```markdown
这组遥测说明检测器能抓住故意保留的负对照，也记录了一次它抓到的历史回归；较低的观测值能支持实现说法，却不能证明代码是常量时间的。
```

- [ ] **Step 6: Make the ZH CI-gate excerpt match its body**

In `_notes/constant-time-ci-gate.zh.md`, set front-matter `description` to a concise copy of the body's actual claim boundary:

```yaml
description: "一条可信的常量时间 CI 门，不只要在正常路径上通过，还要让负对照故意触发，并把测量值、阈值和证据边界一起公开。"
```

Ensure the EN note uses the same three facts: normal path, deliberate negative control, and published measurement/threshold boundary.

- [ ] **Step 7: Correct the WebVTT sentence without changing timing**

In `assets/video/harness-field-explainer.en.vtt`, replace only the cue text:

```text
The line that carries the page is the verification line.
```

with:

```text
The load-bearing line on the page is the verification line.
```

Do not change cue timestamps or the video asset.

- [ ] **Step 8: Run focused and rendered checks**

Run:

```bash
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
rg -n "0\.20|0\.55|Over gate|must fire" _site/projects/gm-crypto-rs/index.html
rg -n "0\.20|0\.55|超过门槛|必须触发" _site/zh/projects/gm-crypto-rs/index.html
rg -n "The load-bearing line" assets/video/harness-field-explainer.en.vtt
```

Expected: only `negative_control` carries must-fire language; the historical before row carries caught language; exact trailing zeroes render in both locales; validator remains red only for later tasks.

- [ ] **Step 9: Commit the evidence-semantics correction**

Run:

```bash
git diff --check
git add _data/dudect.yml _data/i18n.yml _includes/dudect-chart.html _notes/constant-time-warrant.md _notes/constant-time-warrant.zh.md _notes/constant-time-ci-gate.md _notes/constant-time-ci-gate.zh.md assets/video/harness-field-explainer.en.vtt
git commit -m "fix: distinguish dudect evidence from gate policy"
```

---

### Task 4: Update architecture, identity, release-authority, and privacy documentation

**Files:**
- Modify: `CLAUDE.md`
- Modify: `README.md`
- Modify: `colophon.html`
- Modify: `zh/colophon.html`
- Modify: `about.html`
- Modify: `zh/about.html`
- Test: `scripts/validate_site.rb`

**Interfaces:**
- Documents: current JavaScript inventory, shipped cryptographic milestone, contributor identity, public release authority, and localStorage use.

- [ ] **Step 1: Replace the stale JavaScript inventory**

In `CLAUDE.md`, `README.md`, and both Colophon pages where the architecture count appears, state:

```text
seven focused JavaScript files, approximately 570 lines in total
```

For Chinese use:

```text
7 个职责集中的 JavaScript 文件，合计约 570 行
```

Name the seven files when the surrounding section is an inventory: `contents.js`, `copy.js`, `decrypt.js`, `locale-404.js`, `main.js`, `reveal.js`, and `theme.js`.

- [ ] **Step 2: Replace the stale AEAD roadmap statement**

In `CLAUDE.md`, replace any statement that v0.8 AEAD support is next with:

```markdown
`gm-crypto-rs` v1.11 is the current published evidence snapshot used by the site; AEAD support is shipped. Future roadmap statements must be sourced from the public repository rather than inferred from this site's older release narrative.
```

- [ ] **Step 3: Document the release-date authority rule**

Add this rule beside the existing evidence/release guidance in `CLAUDE.md`:

```markdown
For a public release date, prefer crates.io publication metadata when the page means publication, and the immutable annotated tagger timestamp when the page means the signed/tagged release. Record which meaning the page uses; do not substitute a mutable commit date or a review observation.
```

- [ ] **Step 4: Align the public identity line**

In `README.md`, replace `Rust engineer` with `software engineer, mostly in Rust`. Preserve the existing note that the site includes work beyond Rust.

- [ ] **Step 5: Clarify localStorage privacy disclosure**

In both Colophon pages, state that the theme preference is stored under `frankxue.theme` in browser `localStorage`, remains on the device, is not transmitted by the site, and can be cleared through browser site-data controls. Use this EN sentence:

```html
The theme choice is stored locally in your browser under <code>frankxue.theme</code>; this site does not transmit it, and clearing site data removes it.
```

Use this ZH sentence:

```html
主题选择以 <code>frankxue.theme</code> 保存在浏览器本地；本站不会传输它，清除站点数据即可移除。
```

- [ ] **Step 6: Strengthen About parity without overclaiming**

In the EN and ZH About pages, add the same build-gate fact to the public `gm-crypto-rs` description:

```text
EN: The core group fails the build when it crosses the published gate.
ZH: 核心目标一旦越过公开门槛，构建就会失败。
```

Keep the measured-versus-proven limitation intact.

- [ ] **Step 7: Recount and verify**

Run:

```bash
wc -l assets/js/*.js
rg -n "six focused|roughly 500|v0\.8.*next|Rust engineer|frankxue\.theme|seven focused|570" CLAUDE.md README.md colophon.html zh/colophon.html
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
```

Expected: the seven-file count is visible, rejected architecture/roadmap strings are gone, privacy disclosure is paired, and validator remains red only for remaining content tasks.

- [ ] **Step 8: Commit the documentation corrections**

Run:

```bash
git diff --check
git add CLAUDE.md README.md colophon.html zh/colophon.html about.html zh/about.html
git commit -m "docs: align site architecture and evidence guidance"
```

---

### Task 5: Repair bilingual entry points, project disclosures, and editorial terminology

**Files:**
- Modify: `_data/i18n.yml`
- Modify: `about.html`
- Modify: `zh/about.html`
- Modify: `contact.html`
- Modify: `zh/contact.html`
- Modify: `index.html`
- Modify: `zh/index.html`
- Modify: `projects.html`
- Modify: `zh/projects.html`
- Modify: `notes.html`
- Modify: `zh/notes.html`
- Modify: `_notes/starting-a-notebook.md`
- Modify: `_notes/starting-a-notebook.zh.md`
- Modify: `projects/repolens-rs.html`
- Modify: `zh/projects/repolens-rs.html`
- Modify: `projects/gm-crypto-rs.html`
- Modify: `zh/projects/gm-crypto-rs.html`
- Test: `scripts/validate_site.rb`

**Interfaces:**
- Publishes: concise entry-point copy and consistent public/private status boundaries.
- Preserves: shorter home-card altitude versus project-index detail.

- [ ] **Step 1: Normalize localized identity/tagline facts**

In `_data/i18n.yml`, set the EN and ZH home identity to the same boundary:

```yaml
# EN
tagline: "Software engineer, mostly in Rust. I publish selected work with its status, evidence, and limits visible."
short_tagline: "Software engineer, mostly in Rust"

# ZH
tagline: "软件工程师，主要使用 Rust。我会公开一部分作品，并把状态、证据和限制写在明面上。"
short_tagline: "软件工程师，主要使用 Rust"
```

The missing terminal punctuation in `short_tagline` also prepares the metadata workstream; do not change title assembly here.

- [ ] **Step 2: Give About and Contact accurate EN descriptions**

Set `about.html` front-matter description to:

```yaml
description: "How I work, what I optimize for, and how I present evidence and limitations across public and private projects."
```

Set `contact.html` front-matter description to:

```yaml
description: "Ways to contact Frank Xue, with response expectations and links to public work."
```

Write native ZH counterparts with the same facts; do not copy the global site description into either page.

- [ ] **Step 3: Make the home CTA use destination vocabulary**

In `index.html`, change `Review selected work` to `View selected work`. In `zh/index.html`, use `查看精选作品`. Keep the destination and visual treatment unchanged.

- [ ] **Step 4: Normalize private-source disclosures**

For every private/local home and project-index card, use one of these exact status patterns:

```text
EN: Private project — no public source link.
EN: Local prototype — no public source link.
ZH: 私有项目——暂无公开源码链接。
ZH: 本地原型——暂无公开源码链接。
```

Retain project-specific status facts, but do not imply that a missing link is an omission or promise publication.

- [ ] **Step 5: Complete the RepoLens sentence**

Replace the English fragment beginning `Planned until` with:

```text
Planned work remains uncommitted until it is tied to a public milestone.
```

Use the paired ZH sentence:

```text
后续工作在绑定公开里程碑之前，不写成已承诺计划。
```

- [ ] **Step 6: Clarify the ZH ghrunners source/status sentence**

Replace the template fragment `源码目前{{ status }}` with a grammatical sentence that preserves the data value:

```liquid
当前状态：{{ status }}。这是私有项目，暂无公开源码链接。
```

Do not expose or fabricate a repository URL.

- [ ] **Step 7: Broaden the Notes description and lede**

Use this EN front-matter description in `notes.html`:

```yaml
description: "Working notes on software engineering: evidence, interfaces, reliability, cryptography, CI, and the choices behind shipped systems."
```

Use this EN lede:

```html
These are working notes on how software claims become inspectable: through interfaces, tests, release evidence, operational limits, and the choices behind shipped systems.
```

Use a native ZH description and lede with the same scope; do not reduce the page to a fixed technology list.

- [ ] **Step 8: Calibrate the notebook ordering claim**

In both `starting-a-notebook` notes, replace `strongest first` / `最强的放在最前面` with the more accurate rule:

```text
EN: Put the most decision-relevant evidence first, then make its limits easy to find.
ZH: 先放最影响判断的证据，再让它的边界也容易找到。
```

- [ ] **Step 9: Repair remaining terminology and discoverability**

Apply these bounded changes in the page that owns each observation:

1. Define FIPS as `U.S. Federal Information Processing Standards` on first EN use and `美国联邦信息处理标准（FIPS）` on first ZH use.
2. Add a visible `LICENSE` link to the public `gm-crypto-rs` repository's immutable `v1.11.0/LICENSE` file near licensing prose.
3. Change the home footer/link `See all writing` to `Browse all notes`; use `浏览全部笔记` in ZH.
4. Keep the three-of-four `mostly in Rust` framing; do not expand it into a language inventory.
5. Keep home project cards shorter than project-index cards while retaining project status and source visibility.

- [ ] **Step 10: Run the focused residue/parity checks**

Run:

```bash
rg -n "Review selected work|See all writing|Planned until|源码目前|strongest first|最强的放在最前面|Rust, cryptography, CI, and tooling" . --glob '!_site/**' --glob '!docs/**'
rg -n "View selected work|查看精选作品|Browse all notes|浏览全部笔记|no public source link|暂无公开源码链接|decision-relevant|最影响判断" index.html zh/index.html projects.html zh/projects.html notes.html zh/notes.html _notes/starting-a-notebook.md _notes/starting-a-notebook.zh.md
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
```

Expected: rejected text is absent; paired replacements are present; every new validator assertion is green.

- [ ] **Step 11: Inspect the generated EN/ZH surfaces**

Inspect generated extracts for:

```text
_site/index.html and _site/zh/index.html
_site/about/index.html and _site/zh/about/index.html
_site/contact/index.html and _site/zh/contact/index.html
_site/projects/index.html and _site/zh/projects/index.html
_site/notes/index.html and _site/zh/notes/index.html
```

Confirm HTML escaping, links, status disclosures, and claim parity. No page may gain a public source link for a private project.

- [ ] **Step 12: Commit the paired editorial corrections**

Run:

```bash
git diff --check
git add _data/i18n.yml about.html zh/about.html contact.html zh/contact.html index.html zh/index.html projects.html zh/projects.html notes.html zh/notes.html _notes/starting-a-notebook.md _notes/starting-a-notebook.zh.md projects/repolens-rs.html zh/projects/repolens-rs.html projects/gm-crypto-rs.html zh/projects/gm-crypto-rs.html
git commit -m "fix: align bilingual entry points and disclosures"
```

Before committing, inspect `git diff --cached --stat` and confirm every staged file is listed in this task.

---

### Task 6: Run the full content-truth verification gate

**Files:**
- Verify: all files changed in Tasks 1–5
- Verify: generated `_site/`

**Interfaces:**
- Produces: the commit SHA and evidence package required before Notion resolution.

- [ ] **Step 1: Run source hygiene and exact residue checks**

Run:

```bash
git diff main...HEAD --check
rg -n "=1\.9\.0|dudect-pr\.yml#L166|six focused files|roughly 500 lines|Planned until|The line that carries the page|Secret-dependent comparison is constant-time" . --glob '!_site/**' --glob '!docs/superpowers/**'
```

Expected: no matches.

- [ ] **Step 2: Run every repository verification command**

Run:

```bash
bundle exec jekyll doctor
JEKYLL_ENV=production bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
ruby scripts/check_release_drift.rb
```

Expected: every command exits 0; validator prints `Site validation passed`; release drift reports no mismatch.

- [ ] **Step 3: Verify generated links locally**

The site validator's `generated_target_for` pass checks every generated internal `<a>` and `<link>` target. Review the validator output from Step 2 and confirm it contains no `broken internal link`, `invalid internal href`, or `internal link escapes _site` failure. Then run the focused fragment/source search:

```bash
rg -n 'href="[^"]*(byte-identity|unsafe-opt-in|LICENSE|dudect-pr\.yml#L169)' _site/projects/gm-crypto-rs/index.html _site/zh/projects/gm-crypto-rs/index.html
```

Expected: paired note links, the immutable LICENSE link, and workflow line 169 render; the validator reports no missing local target.

- [ ] **Step 4: Review the complete workstream diff**

Run:

```bash
git log --oneline main..HEAD
git diff --stat main...HEAD
git diff main...HEAD -- scripts/validate_site.rb _data/dudect.yml _data/i18n.yml CLAUDE.md README.md
git status --short
```

Confirm the workstream contains only content, data, WebVTT, and validation changes. The worktree must be clean. Record `git rev-parse HEAD` for the Notion resolution.

---

### Task 7: Resolve the content rows in Notion

**Files:**
- No repository files modified

**Interfaces:**
- Updates database: `Site review issues — 2026-08-03 continuous`.
- Uses exact issue-title search within the `frankxue.dev — personal site` project rather than assuming cached row state.

- [ ] **Step 1: Re-fetch the content rows by exact title and severity**

Fetch every `major`, `minor`, and `nit` row mapped to Workstream T in the approved design. Confirm each row is still open, belongs to the target project, and describes the same acceptance condition. Do not fetch or mutate the 72 `info` rows.

- [ ] **Step 2: Resolve the implemented rows**

Run `date -u '+%Y-%m-%dT%H:%M:%SZ'` and `git rev-parse HEAD`. For each implemented row, append five lines: `Resolution — ` followed by the actual UTC output; `Disposition: fixed in ` followed by the actual commit SHA; `Changed surfaces: ` followed by the exact repository paths for that row; `Evidence: ` followed by the public tag/crates.io URL for a public fact or the generated EN/ZH path pair for site copy; and `Verification: Jekyll doctor, production build, site validator, release-drift checker, and local-link check all passed.`

Set status to `fixed-mid-session`. Grouped code changes may share a commit, but every row must name its own changed surfaces and acceptance evidence.

- [ ] **Step 3: Resolve the three extraction-trigger observations as stale/unshipped**

For `missing ZH mirror`, `broken description`, and the ZH translated-quote observation, start the resolution with `Resolution — ` plus the actual UTC output from Step 2, then append these two literal lines:

```text
Disposition: wontfix because this described an unshipped branch artifact, not the current site.
Evidence: the extraction-trigger source is absent from current main, /notes/extraction-trigger/ returns 404, and no production navigation or feed links to it. Recreating the abandoned note would add unsupported content rather than repair production.
```

Set status to `wontfix`.

- [ ] **Step 4: Resolve the invalid deep-link observation**

For the row claiming `timing_leaks.rs#L167` and `README.md#L76` drifted, start the resolution with `Resolution — ` plus the actual UTC output, then append:

```text
Disposition: wontfix; direct inspection of immutable gm-crypto-rs v1.11.0 shows timing_leaks.rs#L167 lands on fn negative_control and README.md#L76 lands on the does-not-prove-constant-time caveat. No source edit is warranted.
```

Set status to `wontfix`.

- [ ] **Step 5: Resolve the four intentional/invalid content nits**

Use `wontfix` with these exact rationales:

```text
Home/project density: intentional altitude compression; both surfaces retain status and source visibility.
Mostly in Rust: accurate three-of-four summary, not a claim that every project is Rust.
External Markdown rel: links do not use target=_blank, so no opener is created and noopener is unnecessary.
Sitemap lastmod: optional metadata; manually maintained dates would create a less reliable signal than omission.
```

- [ ] **Step 6: Audit the database mutations**

Re-fetch every updated row and verify its status, appended resolution, exact commit/evidence reference, and project relation. Confirm that no `info` row changed and that no unresolved Workstream T action row remains.
