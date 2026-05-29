# Copy-to-clipboard install command (gm-crypto-rs)

Date: 2026-05-29
Status: shipped-pending (implementation + codex review, then PR)
Scope: the gm-crypto-rs detail page only (`projects/gm-crypto-rs.html` EN +
`zh/projects/gm-crypto-rs.html` ZH)

## Why

This continues the interactiveness arc — after motion (decrypt/reveal), control
(theme), and navigation (contents rail), the next useful layer is a **utility
action**. The single most useful action on a Rust crate's page is *install it*.

`gm-crypto-rs` is the one project with a **public, installable crate**
(`gmcrypto-core` on crates.io). Today the page links to crates.io but never
shows the install line. A copy-to-clipboard install command turns "go find the
crate" into one click — genuinely useful, interactive, and on-brand (mono,
terminal feel).

### Source-of-truth boundary (critical)

Only gm-crypto-rs gets this block. `repolens-rs` and `ghrunners` are
**private/local** with no public crate — they must **not** show an install
command. This is enforced by a validator check, not just convention.

The command is version-agnostic — `cargo add gmcrypto-core`, never a pinned
version — so it stays correct as the crate publishes new releases (no stale
version claim, consistent with the portfolio source-of-truth rule).

## Placement

Immediately after the `{% include project-summary.html %}` block and before the
first `<h2>What it is</h2>`. The reading flow becomes: summary facts → *here's
how to get it* → prose. High enough to be discoverable; not bolted onto the end.

It lives in the two gm-crypto-rs page templates directly (not the shared
`project-summary.html` include), so the other projects never render it.

## Structure (server-rendered, progressive)

```html
<div class="install">
  <span class="install__label">Install</span>
  <div class="install__row">
    <code class="install__cmd" id="install-cmd">cargo add gmcrypto-core</code>
    <button type="button" class="install__copy"
            data-copy-target="install-cmd"
            data-label-copy="Copy" data-label-done="Copied"
            aria-label="Copy install command">
      <span class="install__copy-text" aria-hidden="true">Copy</span>
    </button>
  </div>
  <span class="install__status" role="status" aria-live="polite"></span>
</div>
```

- The command is **real text** in `<code>` — visible, selectable, and copyable
  by hand even with no JS. Pure progressive enhancement.
- All visible/aria strings come from i18n (see below).
- The visible button text is `aria-hidden` and flips Copy→Copied for sighted
  users; the button's accessible name stays the stable `aria-label`, so the
  flip doesn't spam screen readers.
- A visually-hidden `role="status" aria-live="polite"` region announces
  "Copied" once per copy for screen-reader users.

## Behavior — copy.js

A small site-wide script binds every `[data-copy-target]` button (self-guards
to no-op when none exist):

1. On click, read `textContent` of the referenced element.
2. `await navigator.clipboard.writeText(text)`.
3. On success: flip the visible label to the `data-label-done` value, set the
   `.install__status` live region to the same, add `.is-copied`; revert the
   label + clear the status after ~1.6s (timer reset on rapid re-clicks).
4. On failure / no Clipboard API: fall back to selecting the command text
   (range selection) so the reader can press ⌘/Ctrl-C. Never throws.

## Fail-safe matrix

| Condition | Result |
|-----------|--------|
| JS disabled / throws | Copy button hidden via `html.no-js .install__copy` (the head pre-paint script drops `no-js` when JS runs). Command text still visible + selectable. |
| Clipboard API absent / blocked (insecure context, permissions) | Catch → select the command text for manual copy. |
| Reduced motion | Feedback is a text/colour swap, no motion. |
| Dark theme | Inherits via tokens. |
| Print | Command prints (it's content); the button is hidden. |
| Other projects (repolens-rs, ghrunners) | No install block at all. |

## i18n

Add an `install` block to `_data/i18n.yml`:

| key      | en       | zh       |
|----------|----------|----------|
| `label`  | Install  | 安装      |
| `copy`   | Copy     | 复制      |
| `copied` | Copied   | 已复制    |
| `aria`   | Copy install command | 复制安装命令 |

Rendered into the page templates with `{{ site.data.i18n[page.lang].install.* }}`.

## Styling (tokens only)

- `.install` — a compact bordered block; `--rule` border, `--bg-sunk` field for
  the command, mono type. Sits between the summary and the prose with the same
  vertical rhythm as `.project-summary`.
- `.install__cmd` — mono, `--fg`, selectable.
- `.install__copy` — small mono button, `--fg-muted` → `--fg`/`--accent` on
  hover/focus; `.is-copied` uses `--status-released` (green) for the confirmed
  state. No new colour values.
- `html.no-js .install__copy { display: none }`. `@media print` hides the button.

## Files

| File | Change |
|------|--------|
| `assets/js/copy.js` | **new** — clipboard + feedback + fallback |
| `_layouts/default.html` | load `copy.js` |
| `projects/gm-crypto-rs.html` | install block (EN) |
| `zh/projects/gm-crypto-rs.html` | install block (ZH) |
| `assets/css/style.css` | `.install` styles |
| `_data/i18n.yml` | `install.*` en/zh |
| `scripts/validate_site.rb` | regression checks |

## Validator checks (regression)

- `copy.js` ships and loads site-wide.
- gm-crypto-rs EN + ZH pages contain `cargo add gmcrypto-core` and a
  `data-copy-target` button.
- **repolens-rs and ghrunners (EN + ZH) contain NO install block** — guards the
  source-of-truth boundary.
- `install.{label,copy,copied,aria}` present in i18n for en + zh.
- CSS contains `.install` styles.

Each new check teeth-tested (broken once) before shipping.

## Out of scope (YAGNI)

- Copy buttons on arbitrary inline `<code>` (noisy; only the install line earns
  one).
- A package-manager switcher (Cargo.toml vs `cargo add`) — one canonical line.
- Install blocks on private projects (explicitly forbidden).
