# Site Accessibility and Progressive Enhancement Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the mobile navigation, copy command, theme state, case-study navigation, dudect table, print output, and touch targets robust for keyboard, assistive-technology, no-JavaScript, and narrow-screen use.

**Architecture:** Preserve the existing server-rendered HTML and no-JS navigation as the baseline, then layer small same-origin enhancements on top. Mobile menu state is centralized in `main.js`; localized accessible strings remain in `_data/i18n.yml`; stable section anchors are rendered in source; CSS owns target size, scrolling, supported font weights, and print-only suppression. No modal semantics or new dependency is introduced.

**Tech Stack:** Liquid/HTML, YAML i18n data, vanilla JavaScript, CSS, Ruby post-build validation, Jekyll, keyboard/browser inspection, and the connected Notion issue database.

## Global Constraints

- Create branch `codex/site-review-accessibility` from the accepted content-truth result after Workstream T is merged or explicitly rebased. Re-run the baseline before editing.
- Use superpowers:test-driven-development: add a failing static or behavior check before each implementation change and observe the expected failure.
- Preserve the no-JavaScript path: the navigation remains visible and usable, the install command remains selectable, content remains visible, and no CSS rule depends on JavaScript for basic reading.
- The navigation is not a modal dialog. Do not add `role="dialog"`, `aria-modal`, a focus-trap dependency, or a framework. Express state with `aria-expanded`, `aria-controls`, focus placement, inert background content, and deterministic dismissal.
- Do not widen CSP, add inline event handlers, add remote dependencies, change factual copy, or change JSON-LD/SEO behavior.
- Every EN string added to `_data/i18n.yml` needs a native ZH counterpart with the same state/meaning.
- Use source-rendered IDs for all eight case-study pages. JavaScript may consume them but must never be the only source of anchors.
- Use `fixed-mid-session` only after static validation and browser acceptance are green. Do not edit the 72 `info` rows.
- Run commands from `/Users/fengxiang/Desktop/agent_workspace/frankxue831.github.io`.

---

### Task 1: Add failing accessibility contract checks

**Files:**
- Modify: `scripts/validate_site.rb`
- Test: `scripts/validate_site.rb`

**Interfaces:**
- Reads source HTML, i18n, JavaScript, CSS, and generated page pairs.
- Produces precise failures for the behavior and markup implemented in Tasks 2–5.

- [ ] **Step 1: Confirm the accepted upstream baseline**

Run:

```bash
git status --short --branch
bundle exec jekyll doctor
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
```

Expected: clean accessibility branch and a green baseline.

- [ ] **Step 2: Extend i18n key validation**

Require these non-empty keys for both `en` and `zh`:

```text
nav.menu
nav.skip
theme.aria_template
install.copy
install.copied
install.aria
install.copied_aria
install.manual
install.manual_aria
dudect.table_scroll_label
```

Also assert that both theme templates contain all three placeholders: `{current}`, `{effective}`, and `{next}`.

- [ ] **Step 3: Add source-behavior checks for mobile nav and copy feedback**

Read `assets/js/main.js` and fail unless it contains all of these contracts:

```text
querySelectorAll('footer')
the #main element
the inert property or inert attribute
focus of the first primary-nav link on open
Escape dismissal with toggle focus restoration
pointerdown backdrop dismissal
desktop media-query cleanup
```

Read `assets/js/copy.js` and fail unless success and failure both update visible text, `aria-label`, and the live status; require `data-label-manual`, `data-aria-copy`, `data-aria-done`, and `data-aria-manual` in each generated gm install control.

- [ ] **Step 4: Replace brittle case-study heading checks with ID-aware checks**

Replace exact strings such as `<h2>What it is</h2>` with an expected list of `[id, text]` pairs:

```ruby
en_case_study_headings = [
  ["what-it-is", "What it is"],
  ["problem", "The problem"],
  ["decisions", "Constraints &amp; key decisions"],
  ["evidence", "Evidence"],
  ["next", "Next"],
  ["limits", "What it isn't"]
].freeze

zh_case_study_headings = [
  ["what-it-is", "是什么"],
  ["problem", "要解决的问题"],
  ["decisions", "约束与关键决策"],
  ["evidence", "证据"],
  ["next", "下一步"],
  ["limits", "它不是什么"]
].freeze
```

Extract generated headings with:

```ruby
actual = html.scan(%r{<h2 id="([^"]+)">(.*?)</h2>}m).map do |id, text|
  [id, text.gsub(/\s+/, " ").strip]
end
```

Assert exact order, IDs, and visible labels for all four EN and four ZH case-study pages. Update any `version_before` boundary to look for `<h2 id="next">`.

- [ ] **Step 5: Add CSS/source checks for the remaining observations**

Require:

```text
.hero-proof__title uses font-weight: 600 and never 650
.install__copy has min-block-size: 44px or min-height: 44px
.dudect__table-scroll has overflow-x: auto
print CSS hides .nav-toggle, .primary-nav__item--theme, and .primary-nav__item--switch
_includes/dudect-chart.html wraps the table in .dudect__table-scroll with tabindex="0" and a localized aria-label
assets/js/contents.js retains its early h.id branch
```

- [ ] **Step 6: Run the validator and observe the intended failures**

Run:

```bash
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
```

Expected: failures name missing i18n keys, mobile inert/backdrop behavior, copy state attributes, static heading IDs, table wrapper, target size, print controls, and font weight.

- [ ] **Step 7: Commit the red checks**

Run:

```bash
git diff --check
git add scripts/validate_site.rb
git commit -m "test: define accessibility remediation contracts"
```

---

### Task 2: Contain mobile navigation focus and implement backdrop dismissal

**Files:**
- Modify: `assets/js/main.js`
- Verify: `_includes/nav.html`
- Verify: `_layouts/default.html`
- Test: `scripts/validate_site.rb`

**Interfaces:**
- Inputs: `.nav-toggle`, `#primary-nav`, `#main`, all `footer` elements, and the `(min-width: 760px)` media query.
- State: `aria-expanded`, `body.is-nav-open`, and background `inert`.

- [ ] **Step 1: Replace the one-bit `setOpen` function with explicit open/close state**

Implement this state model in `assets/js/main.js`:

```javascript
const main = document.getElementById('main');
const footers = Array.from(document.querySelectorAll('footer'));
const backgrounds = [main, ...footers].filter(Boolean);
const firstNavLink = nav.querySelector('.primary-nav__link');

const setBackgroundInert = (inert) => {
  backgrounds.forEach((element) => { element.inert = inert; });
};

const setOpen = (open, { restoreFocus = false, moveFocus = false } = {}) => {
  toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
  document.body.classList.toggle('is-nav-open', open);
  setBackgroundInert(open);
  if (open && moveFocus && firstNavLink) {
    window.requestAnimationFrame(() => firstNavLink.focus());
  } else if (!open && restoreFocus) {
    toggle.focus();
  }
};
```

Do not set `inert` on the header or navigation.

- [ ] **Step 2: Define every transition explicitly**

Use these closure/focus rules:

```text
toggle opens: move focus to first nav link
toggle closes: leave focus on the toggle
nav link click: close without restoring focus because navigation is starting
Escape: close and restore focus to toggle
body-overlay pointerdown: close and restore focus to toggle
desktop media change: close, clear inert, do not move focus to a hidden mobile toggle
```

The toggle handler should call:

```javascript
const open = toggle.getAttribute('aria-expanded') !== 'true';
setOpen(open, { moveFocus: open });
```

- [ ] **Step 3: Use the existing body pseudo-element as the backdrop hit target**

Because the overlay is `body.is-nav-open::after`, add:

```javascript
document.addEventListener('pointerdown', (event) => {
  if (toggle.getAttribute('aria-expanded') === 'true' && event.target === document.body) {
    setOpen(false, { restoreFocus: true });
  }
});
```

Do not insert a second backdrop element. Confirm in the browser that pointer events on the existing pseudo-element report `document.body`; if a target browser does not, revise the CSS to use one explicit same-header sibling backdrop and update the validator in the same commit.

- [ ] **Step 4: Make cleanup idempotent**

Ensure `setOpen(false)` always clears `inert`, even when the body class or ARIA state was already out of sync. Add a `pageshow` listener that calls desktop synchronization so bfcache restore cannot leave the page inert.

- [ ] **Step 5: Run static checks and a no-JS source review**

Run:

```bash
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
rg -n "inert|pointerdown|firstNavLink|restoreFocus|matchMedia" assets/js/main.js
```

Expected: navigation behavior checks pass; validator remains red for later tasks. Confirm no source HTML adds `inert` at build time.

- [ ] **Step 6: Commit mobile containment**

Run:

```bash
git diff --check
git add assets/js/main.js
git commit -m "fix: contain focus within open mobile navigation"
```

---

### Task 3: Localize navigation chrome and make theme state meaningful

**Files:**
- Modify: `_data/i18n.yml`
- Modify: `_includes/nav.html`
- Modify: `404.html`
- Modify: `assets/js/theme.js`
- Test: `scripts/validate_site.rb`

**Interfaces:**
- `_data/i18n.yml` is the sole source of Menu/Skip/theme-state strings.
- `locale-404.js` continues consuming 404 `data-*` values without new hardcoded labels.

- [ ] **Step 1: Add shared Menu and Skip labels**

Under each locale's `nav` map, add:

```yaml
# EN
menu: "Menu"
skip: "Skip to content"

# ZH
menu: "菜单"
skip: "跳到正文"
```

- [ ] **Step 2: Consume the shared labels in the nav include and 404 data**

In `_includes/nav.html`, replace both language conditionals with:

```liquid
<a class="skip-link" href="#main">{{ t.nav.skip | escape }}</a>
```

and:

```liquid
aria-label="{{ t.nav.menu | escape }}"
```

In `404.html`, replace the four literal values with:

```liquid
data-skip-en="{{ en.nav.skip | escape }}"
data-skip-zh="{{ zh.nav.skip | escape }}"
data-menu-en="{{ en.nav.menu | escape }}"
data-menu-zh="{{ zh.nav.menu | escape }}"
```

- [ ] **Step 3: Expand the theme announcement template**

Use these templates:

```yaml
# EN
aria_template: "Theme preference: {current}. Current appearance: {effective}. Switch to {next}."

# ZH
aria_template: "主题偏好：{current}。当前显示：{effective}。切换到{next}。"
```

The existing state labels (`Auto`, `Light`, `Dark` / `跟随系统`, `浅色`, `深色`) remain the substitution vocabulary.

- [ ] **Step 4: Substitute effective appearance in `theme.js`**

In `apply(pref)`, build the accessible name with all three substitutions:

```javascript
ariaTemplate
  .replace('{current}', state[pref])
  .replace('{effective}', state[effective])
  .replace('{next}', state[next])
```

Keep the stored preference, effective `data-theme`, and theme-color logic unchanged.

- [ ] **Step 5: Build and inspect both locale outputs**

Run:

```bash
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
rg -n "Skip to content|Menu|Theme preference" _site/index.html
rg -n "跳到正文|菜单|主题偏好" _site/zh/index.html
rg -n "data-skip-en|data-skip-zh|data-menu-en|data-menu-zh" _site/404.html
```

Expected: strings come from i18n, placeholders are absent from generated accessible labels after JavaScript runs, and validator remains red only for later tasks.

- [ ] **Step 6: Commit localized state communication**

Run:

```bash
git diff --check
git add _data/i18n.yml _includes/nav.html 404.html assets/js/theme.js
git commit -m "fix: localize navigation and clarify theme state"
```

---

### Task 4: Make copy success and failure fully perceivable

**Files:**
- Modify: `_data/i18n.yml`
- Modify: `projects/gm-crypto-rs.html`
- Modify: `zh/projects/gm-crypto-rs.html`
- Modify: `assets/js/copy.js`
- Modify: `assets/css/style.css`
- Test: `scripts/validate_site.rb`

**Interfaces:**
- Button data attributes carry localized idle/success/manual labels.
- `.install__status[role=status]` announces state without stealing focus.

- [ ] **Step 1: Add complete install-control strings**

Under `install`, add:

```yaml
# EN
copied_aria: "Install command copied"
manual: "Copy manually"
manual_aria: "Command selected. Copy manually."

# ZH
copied_aria: "安装命令已复制"
manual: "手动复制"
manual_aria: "命令已选中，请手动复制。"
```

Retain `aria: "Copy install command"` / `aria: "复制安装命令"` as the idle accessible name.

- [ ] **Step 2: Expose every state to JavaScript**

On both install buttons add:

```liquid
data-label-manual="{{ inst.manual | escape }}"
data-aria-copy="{{ inst.aria | escape }}"
data-aria-done="{{ inst.copied_aria | escape }}"
data-aria-manual="{{ inst.manual_aria | escape }}"
```

Keep the initial `aria-label="{{ inst.aria | escape }}"` and existing live region.

- [ ] **Step 3: Refactor copy feedback into one state function**

In `assets/js/copy.js`, read all four data-backed state values and implement:

```javascript
const setState = ({ label, aria, announcement, copied = false }) => {
  if (textSpan) textSpan.textContent = label;
  btn.setAttribute('aria-label', aria);
  if (status) status.textContent = announcement;
  btn.classList.toggle('is-copied', copied);
};

const reset = () => setState({
  label: copyLabel,
  aria: copyAria,
  announcement: ''
});
```

Success calls `setState` with `doneLabel`, `doneAria`, and `copied: true`, then resets after 1600 ms.

- [ ] **Step 4: Announce the fallback instead of silently selecting**

Implement one `showManual` function that calls `selectText(target)`, then sets visible text, accessible name, and live announcement to the manual state, and resets after 3000 ms. Use it for both missing Clipboard API and rejected `writeText` promises.

Do not report `Copied` after a failed write.

- [ ] **Step 5: Guarantee the minimum touch target**

In `.install__copy`, add:

```css
min-block-size: 44px;
display: inline-flex;
align-items: center;
justify-content: center;
```

Keep the existing border, type, hover/focus, no-JS hiding, and print hiding.

- [ ] **Step 6: Build and run focused static checks**

Run:

```bash
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
rg -n "data-label-manual|data-aria-copy|data-aria-done|data-aria-manual" _site/projects/gm-crypto-rs/index.html _site/zh/projects/gm-crypto-rs/index.html
rg -n "setState|showManual|aria-label|writeText" assets/js/copy.js
```

Expected: copy/i18n/target-size checks pass; validator remains red only for Task 5 items.

- [ ] **Step 7: Commit copy-state accessibility**

Run:

```bash
git diff --check
git add _data/i18n.yml projects/gm-crypto-rs.html zh/projects/gm-crypto-rs.html assets/js/copy.js assets/css/style.css
git commit -m "fix: announce copy success and fallback states"
```

---

### Task 5: Render stable section anchors and repair responsive/print styles

**Files:**
- Modify: `projects/gm-crypto-rs.html`
- Modify: `projects/repolens-rs.html`
- Modify: `projects/ghrunners.html`
- Modify: `projects/explainer-engine.html`
- Modify: `zh/projects/gm-crypto-rs.html`
- Modify: `zh/projects/repolens-rs.html`
- Modify: `zh/projects/ghrunners.html`
- Modify: `zh/projects/explainer-engine.html`
- Modify: `_includes/dudect-chart.html`
- Modify: `_data/i18n.yml`
- Modify: `assets/css/style.css`
- Verify: `assets/js/contents.js`
- Test: `scripts/validate_site.rb`

**Interfaces:**
- Exposes the same fragment IDs across EN/ZH case-study counterparts.
- Makes the dudect table a named keyboard-scrollable region without changing its data.

- [ ] **Step 1: Add the six stable IDs to all eight case studies**

Use this exact mapping in every EN/ZH pair:

```text
What it is / 是什么                              id="what-it-is"
The problem / 要解决的问题                      id="problem"
Constraints & key decisions / 约束与关键决策    id="decisions"
Evidence / 证据                                  id="evidence"
Next / 下一步                                    id="next"
What it isn't / 它不是什么                      id="limits"
```

Example:

```html
<h2 id="evidence">Evidence</h2>
<h2 id="evidence">证据</h2>
```

Do not derive Chinese IDs from CJK text; paired stable IDs make locale switching and external fragments predictable.

- [ ] **Step 2: Confirm `contents.js` preserves source IDs**

Retain this early branch unchanged:

```javascript
if (h.id) { used.add(h.id); return h.id; }
```

Do not delete the slugging fallback because future non-case-study detail pages may still rely on progressive enhancement.

- [ ] **Step 3: Wrap the dudect table in a localized scroll region**

Add to both locale `dudect` maps:

```yaml
# EN
table_scroll_label: "Constant-time measurement table; scroll horizontally when needed"

# ZH
table_scroll_label: "常量时间测量表；空间不足时可横向滚动"
```

Insert the opening wrapper immediately before `<table class="dudect__table">`:

```liquid
<div class="dudect__table-scroll" tabindex="0" role="region"
     aria-label="{{ t.table_scroll_label | escape }}">
```

Keep the table and every existing child unchanged, then insert `</div>` immediately after the table's closing `</table>`.

- [ ] **Step 4: Add narrow-screen table behavior**

Add:

```css
.dudect__table-scroll {
    max-width: 100%;
    overflow-x: auto;
    overscroll-behavior-inline: contain;
}
.dudect__table-scroll:focus-visible {
    outline: 2px solid var(--accent);
    outline-offset: 2px;
}
.dudect__table {
    min-width: 640px;
}
```

Keep page-level horizontal overflow absent; only the named wrapper may scroll.

- [ ] **Step 5: Use a supported proof-title weight**

Change `.hero-proof__title` from `font-weight: 650` to `font-weight: 600`. Do not add or synthesize a 650 font file.

- [ ] **Step 6: Hide interactive-only chrome in print**

Add one consolidated print rule:

```css
@media print {
    .nav-toggle,
    .primary-nav__item--theme,
    .primary-nav__item--switch {
        display: none !important;
    }
}
```

Retain the existing print rules for `.install__copy`, `.toc`, and `.reveal`.

- [ ] **Step 7: Build and run the complete static validator**

Run:

```bash
bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
rg -n '<h2 id="(what-it-is|problem|decisions|evidence|next|limits)">' _site/projects/*/index.html _site/zh/projects/*/index.html
```

Expected: every validation check passes and every case-study page has exactly the six IDs in order.

- [ ] **Step 8: Commit stable anchors and responsive styles**

Run:

```bash
git diff --check
git add projects/gm-crypto-rs.html projects/repolens-rs.html projects/ghrunners.html projects/explainer-engine.html zh/projects/gm-crypto-rs.html zh/projects/repolens-rs.html zh/projects/ghrunners.html zh/projects/explainer-engine.html _includes/dudect-chart.html _data/i18n.yml assets/css/style.css
git commit -m "fix: stabilize case study navigation and responsive controls"
```

---

### Task 6: Run browser, no-JS, print, and full-branch verification

**Files:**
- Verify: all files changed in Tasks 1–5
- Verify: generated `_site/`

**Interfaces:**
- Produces the acceptance record and commit SHA required before Notion updates.

- [ ] **Step 1: Start the local production-like server**

Run:

```bash
JEKYLL_ENV=production bundle exec jekyll serve --host 127.0.0.1 --port 4000
```

Use the in-app browser at `http://127.0.0.1:4000/`. Keep the terminal session available for console/server errors.

- [ ] **Step 2: Test the 390×844 EN and ZH mobile menu**

On `/` and `/zh/` at 390×844:

1. Focus the menu toggle and press Enter; first nav link receives focus.
2. Press Tab through nav links, language switch, and theme control; focus never reaches `main` or footer while open.
3. Press Escape; menu closes, `inert` is cleared, and focus returns to the toggle.
4. Reopen and click/tap the opaque backdrop; the same close/restore behavior occurs.
5. Reopen and activate a nav link; navigation proceeds and the destination is not inert.
6. Resize past 760px while open; menu state and every inert flag clear.
7. Confirm no page-level horizontal scrollbar appears.

- [ ] **Step 3: Test copy success and failure**

On both gm case-study locales:

1. Successful copy changes visible text, accessible name, and live status, then resets.
2. Block/override Clipboard API in DevTools and retry; the command becomes selected, visible text says manual copy, the accessible name/live status announce the manual action, and `Copied` never appears.
3. At 390px, the control is at least 44 CSS pixels high and does not clip the command.

- [ ] **Step 4: Test theme announcements**

With OS appearance light and preference Auto, inspect the theme button name. It must report preference Auto, current appearance Light, and the next preference. Repeat on dark OS and in ZH. Cycle all three preferences and confirm each accessible name matches visible/effective state.

- [ ] **Step 5: Test table scrolling, anchors, no-JS, and print**

1. At 390px, tab to the dudect table region and scroll it horizontally without moving the whole page.
2. Load `#evidence` and `#limits` directly on an EN and ZH case study; the correct heading is targeted before JavaScript runs.
3. Disable JavaScript and reload home, gm case study, and 404; content and navigation remain usable and the install command is selectable.
4. Open print preview for home and a case study; menu toggle, theme control, language switch, copy button, and contents rail do not print.

- [ ] **Step 6: Run the complete repository gate**

Stop the server, then run:

```bash
git diff main...HEAD --check
bundle exec jekyll doctor
JEKYLL_ENV=production bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
ruby scripts/check_release_drift.rb
git status --short
```

Expected: all commands pass and the worktree is clean. Record `git rev-parse HEAD` plus the browser matrix results.

---

### Task 7: Resolve the accessibility rows in Notion

**Files:**
- No repository files modified

**Interfaces:**
- Updates database: `Site review issues — 2026-08-03 continuous`.

- [ ] **Step 1: Re-fetch the Workstream A rows**

Fetch the open rows for mobile nav focus containment, Menu/Skip localization, print controls, hero proof font weight, theme accessible name, dudect horizontal scrolling, static case-study IDs, copy success state, copy failure feedback, backdrop dismissal, and the 44px install target. Confirm each still belongs to the target project and has not changed scope.

- [ ] **Step 2: Resolve every demonstrated implementation row**

Run `date -u '+%Y-%m-%dT%H:%M:%SZ'` and `git rev-parse HEAD`. For each row, append five lines: `Resolution — ` followed by the actual UTC output; `Disposition: fixed in ` followed by the actual commit SHA; `Changed surfaces: ` followed by the exact paths for that row; `Static verification: production build and site validator passed.`; and `Behavior verification: ` followed by the relevant EN/ZH viewport, keyboard, no-JS, failure-path, fragment, or print result from Task 6.

Set status to `fixed-mid-session` only when the row's specific browser acceptance result is present.

- [ ] **Step 3: Resolve the mobile-theme-location nit as intentional**

For the observation that the theme toggle is inside the mobile menu, start with `Resolution — ` followed by the actual UTC output, then append:

```text
Disposition: wontfix. The theme control remains intentionally inside compact mobile navigation, where it is keyboard reachable and now participates in the contained focus order. Moving it would duplicate controls without improving access.
```

Set status to `wontfix`.

- [ ] **Step 4: Audit the database changes**

Re-fetch every updated Workstream A row. Confirm the resolution evidence, status, and project relation, and confirm no `info`, content-truth, metadata, or hosting row was changed.
