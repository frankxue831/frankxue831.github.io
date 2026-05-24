# Interactive Motion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a once-on-open "decrypt" of the home hero title and a quiet site-wide scroll-reveal, in zero-dependency vanilla JS, with no layout shift and full fail-open behavior.

**Architecture:** Three small additions — an inline `<head>` enable-gate (sets a `motion` flag before paint), `reveal.js` (IntersectionObserver fade/rise of `.reveal` elements), and `decrypt.js` (in-place, fixed-width-cell scramble of the home `.hero__title`). CSS keys the hidden states on `.motion` so no-JS / reduced-motion / unsupported browsers see correct static content. The real title text always stays in the DOM; `decrypt.js` locks the accessible name via `aria-label` and marks animated cells `aria-hidden`.

**Tech Stack:** Jekyll (GitHub Pages), hand-written CSS with `:root` tokens, vanilla ES (no build/bundler), Ruby validator (`scripts/validate_site.rb`).

**Spec:** `docs/superpowers/specs/2026-05-24-interactive-motion-design.md`

**Branch:** `design/interactive-motion` (already created, based on merged `main`).

> **Testing note (repo reality):** This site has **no JS test runner and no build step** by design (see `CLAUDE.md`). Verification therefore uses (a) `bundle exec jekyll build` must be clean, (b) `scripts/validate_site.rb` static regression checks (extended in Task 7), and (c) a scripted **browser verification matrix** (Task 8) run via DevTools console snippets (or a browser MCP). Strict red-green TDD is adapted to this: each task ends with a concrete, observable check.

---

## File Structure

| File | Responsibility | Action |
| --- | --- | --- |
| `assets/css/style.css` | reveal states + decrypt cell styles | Modify (append two blocks) |
| `_includes/head.html` | inline motion enable-gate + watchdog | Modify (prepend script) |
| `assets/js/reveal.js` | scroll-reveal observer (site-wide) | Create |
| `assets/js/decrypt.js` | home hero decrypt (home only) | Create |
| `_layouts/default.html` | load the two new scripts (`defer`) | Modify |
| `index.html`, `zh/index.html` | declare `.reveal` on about/contact sections + work-list items | Modify |
| `about.html`, `zh/about.html`, `contact.html`, `zh/contact.html` | declare `.reveal` on the content section | Modify |
| `projects.html`, `zh/projects.html` | declare `.reveal` on work-list items (NOT the section) | Modify |
| `projects/*.html`, `zh/projects/*.html` (6 files) | declare `.reveal` on the content section | Modify |
| `scripts/validate_site.rb` | regression checks for the above | Modify |

`main.js` is **not touched** (stays mobile-nav only).

---

## Task 1: Reveal CSS

**Files:**
- Modify: `assets/css/style.css` (append near the other animation rules; end of file is fine)

- [ ] **Step 1: Append the reveal CSS block**

Add to the end of `assets/css/style.css`:

```css

/* ============================================================
   Scroll reveal — gated by the `motion` flag set in <head>.
   Without `.motion` (no-JS, reduced-motion, or unsupported),
   `.reveal` has no hidden state, so content is visible + static.
   ============================================================ */
.motion .reveal {
    opacity: 0;
    transform: translateY(12px);
    transition: opacity var(--dur-slow) var(--ease),
                transform var(--dur-slow) var(--ease);
}
.motion .reveal.is-revealed,
.motion .reveal:focus-within {
    opacity: 1;
    transform: none;
}

/* Capped stagger for work-list rows (one reveal level — items only) */
.motion .work-list__item.reveal:nth-child(2) { transition-delay: 80ms; }
.motion .work-list__item.reveal:nth-child(3) { transition-delay: 160ms; }
.motion .work-list__item.reveal:nth-child(4) { transition-delay: 240ms; }

@media print {
    .reveal { opacity: 1 !important; transform: none !important; }
}
```

- [ ] **Step 2: Build and confirm clean**

Run: `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bundle exec jekyll build`
Expected: build completes, no errors. (No visible change yet — nothing has `.reveal` and `.motion` isn't set.)

- [ ] **Step 3: Commit**

```bash
git add assets/css/style.css
git commit -m "feat(motion): reveal CSS states (gated on .motion)"
```

---

## Task 2: Inline motion enable-gate + watchdog

**Files:**
- Modify: `_includes/head.html` (add as the FIRST thing inside the include, so it runs before paint)

- [ ] **Step 1: Prepend the gate script**

Insert at the very top of `_includes/head.html` (before any other tags):

```html
<script>
  /* Motion enable-gate — runs before paint, no external deps.
     Adds `motion` to <html> ONLY when motion is allowed AND the reveal
     observer is supported, so the CSS hidden-state for `.reveal` applies
     before first paint (no FOUC). Fails open on any error. A watchdog
     strips `motion` if reveal.js never signals ready (blocked/failed load),
     so content can never stay stuck hidden. */
  (function () {
    try {
      var el = document.documentElement;
      var mq = window.matchMedia;
      var reduce = mq && mq('(prefers-reduced-motion: reduce)').matches;
      if (!reduce && 'IntersectionObserver' in window) {
        el.classList.add('motion');
        window.setTimeout(function () {
          if (el.getAttribute('data-reveal-ready') !== 'true') {
            el.classList.remove('motion');
          }
        }, 3000);
      }
    } catch (e) { /* fail open: no motion class => content visible */ }
  })();
</script>
```

- [ ] **Step 2: Build**

Run: `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bundle exec jekyll build`
Expected: clean. Built pages now contain the inline script. Still no visible change (no `.reveal` elements yet; watchdog will strip `.motion` after 3s harmlessly).

- [ ] **Step 3: Verify the gate is present in output**

Run: `grep -c "classList.add('motion')" _site/index.html _site/zh/index.html`
Expected: `1` for each.

- [ ] **Step 4: Commit**

```bash
git add _includes/head.html
git commit -m "feat(motion): inline enable-gate + fail-open watchdog"
```

---

## Task 3: reveal.js + wire it in

**Files:**
- Create: `assets/js/reveal.js`
- Modify: `_layouts/default.html` (add a `defer` script tag next to `main.js`)

- [ ] **Step 1: Create `assets/js/reveal.js`**

```js
/* Scroll-reveal: fades/rises .reveal elements as they enter the viewport.
   Active only when <html> has `motion` (set by the head gate). Fail-open. */
(() => {
  const root = document.documentElement;
  if (!root.classList.contains('motion')) return;        // gate disabled -> visible
  if (!('IntersectionObserver' in window)) {              // belt-and-suspenders
    root.classList.remove('motion');
    return;
  }

  const targets = Array.from(document.querySelectorAll('.reveal'));
  const reveal = (el) => el.classList.add('is-revealed');

  // Reveal anything already in/above the viewport now, so above-the-fold
  // content is never left hidden waiting on the async observer callback.
  const vh = window.innerHeight || root.clientHeight;
  targets.forEach((el) => {
    if (el.getBoundingClientRect().top < vh * 0.9) reveal(el);
  });

  const io = new IntersectionObserver((entries, obs) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        reveal(entry.target);
        obs.unobserve(entry.target);
      }
    });
  }, { threshold: 0.12, rootMargin: '0px 0px -8% 0px' });

  targets.forEach((el) => {
    if (!el.classList.contains('is-revealed')) io.observe(el);
  });

  // bfcache restore -> ensure everything visible (no animation needed).
  window.addEventListener('pageshow', (e) => {
    if (e.persisted) targets.forEach(reveal);
  });

  // Signal the head watchdog so it doesn't strip `motion`.
  root.setAttribute('data-reveal-ready', 'true');
})();
```

- [ ] **Step 2: Wire it into the layout**

In `_layouts/default.html`, find the existing line:

```html
    <script src="{{ '/assets/js/main.js' | relative_url }}" defer></script>
```

Add immediately below it:

```html
    <script src="{{ '/assets/js/reveal.js' | relative_url }}" defer></script>
```

- [ ] **Step 3: Build**

Run: `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bundle exec jekyll build`
Expected: clean; `_site/assets/js/reveal.js` exists.

- [ ] **Step 4: Verify reference + file**

Run: `test -f _site/assets/js/reveal.js && grep -c "assets/js/reveal.js" _site/index.html`
Expected: prints `1`.

- [ ] **Step 5: Commit**

```bash
git add assets/js/reveal.js _layouts/default.html
git commit -m "feat(motion): reveal.js observer + layout wiring"
```

---

## Task 4: Declare `.reveal` targets in templates

One reveal level per island, never nested. **Do NOT add `.reveal` to the home `work-h` section or to the projects-index `.section`** (their work-list *items* get it instead).

**Files & exact edits:**

- [ ] **Step 1: `index.html` — about + contact sections, work-list item**

Change:
```html
<section class="section wrap" aria-labelledby="about-h">
```
to:
```html
<section class="section wrap reveal" aria-labelledby="about-h">
```

Change:
```html
<section class="section wrap" aria-labelledby="contact-h">
```
to:
```html
<section class="section wrap reveal" aria-labelledby="contact-h">
```

Change (leave the `work-h` section UNCHANGED):
```html
        <li class="work-list__item">
```
to:
```html
        <li class="work-list__item reveal">
```

- [ ] **Step 2: `zh/index.html` — identical three edits** (about-h section, contact-h section, `work-list__item`). The `work-h` section stays unchanged.

- [ ] **Step 3: `projects.html` — work-list item only**

Change:
```html
        <li class="work-list__item">
```
to:
```html
        <li class="work-list__item reveal">
```
(Leave `<section class="section wrap">` unchanged.)

- [ ] **Step 4: `zh/projects.html` — same single edit** as Step 3.

- [ ] **Step 5: Content sections get `.reveal`** — in each of these files change the single `<section class="section wrap">` to `<section class="section wrap reveal">`:
  - `about.html`
  - `zh/about.html`
  - `contact.html`
  - `zh/contact.html`
  - `projects/gm-crypto-rs.html`
  - `projects/repolens-rs.html`
  - `projects/ghrunners.html`
  - `zh/projects/gm-crypto-rs.html`
  - `zh/projects/repolens-rs.html`
  - `zh/projects/ghrunners.html`

  > ⚠️ `projects.html` and `zh/projects.html` also contain `<section class="section wrap">` — do **not** change those (handled in Steps 3–4). Edit the listed files only.

- [ ] **Step 6: Build**

Run: `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bundle exec jekyll build`
Expected: clean.

- [ ] **Step 7: Verify counts**

Run:
```bash
grep -c 'class="section wrap reveal"' _site/about/index.html _site/contact/index.html _site/projects/gm-crypto-rs/index.html
grep -c 'class="work-list__item reveal"' _site/index.html _site/projects/index.html
grep -c 'class="section wrap" aria-labelledby="work-h"' _site/index.html
```
Expected: first command `1` per file; second `1` per file; third `1` (work section unchanged — no nesting).

- [ ] **Step 8: Commit**

```bash
git add index.html zh/index.html projects.html zh/projects.html about.html zh/about.html contact.html zh/contact.html projects/ zh/projects/
git commit -m "feat(motion): declare scroll-reveal targets (no nesting)"
```

---

## Task 5: Decrypt cell CSS

**Files:**
- Modify: `assets/css/style.css` (append)

- [ ] **Step 1: Append the decrypt cell block**

Add to the end of `assets/css/style.css`:

```css

/* ============================================================
   Hero decrypt cells (built in place by decrypt.js).
   Widths are locked inline by JS to each glyph's final advance;
   overflow:hidden keeps a wider random glyph from overlapping
   its neighbour (no reflow, ever). Accent cells inherit the
   <em> indigo. Only present while JS runs.
   ============================================================ */
.hero-word { white-space: nowrap; }
.hero-cell {
    display: inline-block;
    overflow: hidden;
    text-align: center;
    white-space: pre;          /* keep space cells from collapsing */
    vertical-align: baseline;
}
```

- [ ] **Step 2: Build**

Run: `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bundle exec jekyll build`
Expected: clean (no visible change yet — no cells exist until decrypt.js runs).

- [ ] **Step 3: Commit**

```bash
git add assets/css/style.css
git commit -m "feat(motion): hero decrypt cell styles"
```

---

## Task 6: decrypt.js + wire it in

**Files:**
- Create: `assets/js/decrypt.js`
- Modify: `_layouts/default.html` (add a second `defer` script)

- [ ] **Step 1: Create `assets/js/decrypt.js`**

```js
/* Home hero "decrypt": the title arrives as cipher glyphs that resolve into the
   real headline. In place, reflow-free (fixed-width cells), a11y-safe (stable
   aria-label + aria-hidden cells), reduced-motion / no-JS / bfcache safe. */
(() => {
  const title = document.querySelector('.hero__title');
  if (!title) return; // home only (only the home hero uses .hero__title)

  const GLYPHS = '0123456789ABCDEF/\\{}[]#*+=$%@?';
  const rnd = () => GLYPHS[(Math.random() * GLYPHS.length) | 0];

  const toGraphemes = (str) => {
    if (window.Intl && Intl.Segmenter) {
      return Array.from(
        new Intl.Segmenter(undefined, { granularity: 'grapheme' }).segment(str),
        (s) => s.segment
      );
    }
    return Array.from(str);
  };
  // CJK ranges (incl. CJK punctuation + fullwidth forms) break per character.
  const isCJK = (ch) =>
    /[　-〿㐀-鿿豈-﫿＀-￯]/.test(ch);

  // 1) Read real text segments (preserve the <em> boundary), normalize whitespace.
  const segments = [];
  title.childNodes.forEach((node) => {
    if (node.nodeType === Node.TEXT_NODE) {
      const t = node.textContent.replace(/\s+/g, ' ').trim();
      if (t) segments.push({ node, text: t, accent: false });
    } else if (node.nodeType === Node.ELEMENT_NODE) {
      const t = node.textContent.replace(/\s+/g, ' ').trim();
      segments.push({ node, text: t, accent: node.tagName === 'EM' });
    }
  });
  if (!segments.length) return;

  // 2) Lock the accessible name (independent of whether we animate).
  title.setAttribute('aria-label', segments.map((s) => s.text).join(' '));

  // 3) Reduced motion -> leave the real title untouched. Done.
  const mq = window.matchMedia;
  if (mq && mq('(prefers-reduced-motion: reduce)').matches) return;

  const cells = []; // { span, real }

  const buildSegment = (seg) => {
    const frag = document.createDocumentFragment();
    let word = null;
    toGraphemes(seg.text).forEach((g) => {
      if (g === ' ') { frag.appendChild(document.createTextNode(' ')); word = null; return; }
      const cell = document.createElement('span');
      cell.className = 'hero-cell';
      cell.setAttribute('aria-hidden', 'true');
      cell.textContent = g;
      cells.push({ span: cell, real: g });
      if (isCJK(g)) {
        frag.appendChild(cell);          // CJK: standalone, breaks per char
        word = null;
      } else {
        if (!word) {                     // Latin: group into a nowrap word
          word = document.createElement('span');
          word.className = 'hero-word';
          word.setAttribute('aria-hidden', 'true');
          frag.appendChild(word);
        }
        word.appendChild(cell);
      }
    });
    if (seg.node.nodeType === Node.TEXT_NODE) {
      const holder = document.createElement('span');
      holder.setAttribute('aria-hidden', 'true');
      holder.appendChild(frag);
      title.replaceChild(holder, seg.node);
    } else {
      seg.node.setAttribute('aria-hidden', 'true');
      seg.node.textContent = '';
      seg.node.appendChild(frag);
    }
  };

  const animate = () => {
    segments.forEach(buildSegment);
    // Lock each cell width to its natural (final-glyph) advance -> swaps never reflow.
    cells.forEach((c) => { c.span.style.width = c.span.getBoundingClientRect().width + 'px'; });
    // Resolve left -> right.
    const total = cells.length;
    let frame = 0;
    const tick = () => {
      const resolved = (frame / 2) | 0;
      for (let i = 0; i < total; i++) {
        cells[i].span.textContent = i < resolved ? cells[i].real : rnd();
      }
      frame++;
      if (resolved < total) window.setTimeout(tick, 45);
      else cells.forEach((c) => { c.span.textContent = c.real; }); // settle exact
    };
    tick();
  };

  // 4) Start after fonts are ready (correct width measurement). If fonts take
  //    longer than 800ms, SKIP the animation and leave the real title (fail open).
  let settled = false;
  if (document.fonts && document.fonts.ready) {
    const timer = window.setTimeout(() => { settled = true; /* skip: real title stays */ }, 800);
    document.fonts.ready.then(() => {
      if (settled) return;
      settled = true;
      window.clearTimeout(timer);
      animate();
    });
  } else {
    animate();
  }
  // bfcache: this module's JS state persists on restore, so `settled` stays true
  // and the decrypt does not replay. Fresh navigations re-run the module.
})();
```

- [ ] **Step 2: Wire it into the layout**

In `_layouts/default.html`, below the `reveal.js` line you added in Task 3, add:

```html
    <script src="{{ '/assets/js/decrypt.js' | relative_url }}" defer></script>
```

- [ ] **Step 3: Build**

Run: `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bundle exec jekyll build`
Expected: clean; `_site/assets/js/decrypt.js` exists.

- [ ] **Step 4: Verify reference + file + real title still in HTML**

Run:
```bash
test -f _site/assets/js/decrypt.js && grep -c "assets/js/decrypt.js" _site/index.html
grep -c "auditable tools" _site/index.html
grep -c "更清楚的工具" _site/zh/index.html
```
Expected: `1`, `1`, `1` — the decrypt is JS-only; the server-rendered real title remains in the HTML.

- [ ] **Step 5: Commit**

```bash
git add assets/js/decrypt.js _layouts/default.html
git commit -m "feat(motion): hero decrypt (in-place, reflow-free, a11y-safe)"
```

---

## Task 7: Regression checks in the validator

**Files:**
- Modify: `scripts/validate_site.rb` (insert a block immediately BEFORE the final `if failures.empty?`)

- [ ] **Step 1: Insert the motion regression block**

In `scripts/validate_site.rb`, directly above this existing line:

```ruby
if failures.empty?
```

insert:

```ruby
# --- Interactive motion (decrypt + scroll reveal) regression checks ---
%w[assets/js/reveal.js assets/js/decrypt.js].each do |rel|
  record(failures, "Missing motion script: #{rel}") unless SITE.join(rel).exist?
end

Pathname.glob(SITE.join("**/*.html").to_s).each do |path|
  html = path.read
  source = path.relative_path_from(SITE).to_s
  record(failures, "#{source}: missing reveal.js include") unless html.include?("/assets/js/reveal.js")
  record(failures, "#{source}: missing decrypt.js include") unless html.include?("/assets/js/decrypt.js")
  record(failures, "#{source}: missing inline motion gate") unless html.include?("classList.add('motion')")
end

# Home heroes must keep their real, server-rendered title (decrypt is JS-only).
{ "index.html" => "auditable tools", "zh/index.html" => "更清楚的工具" }.each do |relative, needle|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  record(failures, "#{relative}: hero title lost real text (#{needle.inspect})") unless html.include?(needle)
  record(failures, "#{relative}: hero__title missing") unless html.include?(%(class="hero__title"))
end

# Reveal targets must be template-declared (no FOUC), one level only.
%w[
  about/index.html zh/about/index.html
  contact/index.html zh/contact/index.html
  projects/gm-crypto-rs/index.html projects/repolens-rs/index.html projects/ghrunners/index.html
  zh/projects/gm-crypto-rs/index.html zh/projects/repolens-rs/index.html zh/projects/ghrunners/index.html
].each do |relative|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  record(failures, "#{relative}: missing reveal section") unless html.include?(%(class="section wrap reveal"))
end

%w[index.html zh/index.html projects/index.html zh/projects/index.html].each do |relative|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  record(failures, "#{relative}: work-list items missing reveal class") unless html.include?(%(class="work-list__item reveal"))
end

# No nesting: the home work section must NOT also carry reveal.
%w[index.html zh/index.html].each do |relative|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  if html.include?(%(class="section wrap reveal" aria-labelledby="work-h"))
    record(failures, "#{relative}: work section is nested reveal (should be items only)")
  end
end
```

- [ ] **Step 2: Run the validator (build first)**

Run:
```bash
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
```
Expected: `Site validation passed`. (If any new check fails, fix the corresponding template/JS from Tasks 3–6, not the check.)

- [ ] **Step 3: Commit**

```bash
git add scripts/validate_site.rb
git commit -m "test(motion): validator regression checks for reveal + decrypt"
```

---

## Task 8: Full verification matrix, codex review, PR

**Files:** none (verification + ship).

- [ ] **Step 1: Serve locally**

Run:
```bash
export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
pkill -f 'jekyll serve' 2>/dev/null; sleep 1
nohup ruby vendor/bundle/bin/bundle _2.4.22_ exec jekyll serve --livereload --host 127.0.0.1 --port 4000 > /tmp/jekyll-serve.log 2>&1 &
sleep 6 && curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:4000/zh/
```
Expected: `200`.

- [ ] **Step 2: Decrypt — visual + no-reflow (EN and ZH)**

Open `http://127.0.0.1:4000/` and `http://127.0.0.1:4000/zh/`. In DevTools console, before reload, paste this to assert the title box does not change size during the animation:

```js
const h = document.querySelector('.hero__title');
const b0 = h.getBoundingClientRect();
let maxDW = 0, maxDH = 0;
const id = setInterval(() => {
  const b = h.getBoundingClientRect();
  maxDW = Math.max(maxDW, Math.abs(b.width - b0.width));
  maxDH = Math.max(maxDH, Math.abs(b.height - b0.height));
}, 16);
setTimeout(() => { clearInterval(id); console.log('max ΔW', maxDW.toFixed(2), 'max ΔH', maxDH.toFixed(2)); }, 1500);
```
Expected: both deltas ≈ `0` (sub-pixel). Visually: glyphs scramble then resolve left→right in ~1s; **no jiggle/reflow**; accent clause settles indigo; final text exactly matches the EN / ZH headline.

- [ ] **Step 3: Decrypt — accessibility**

In console after the animation settles:
```js
const h = document.querySelector('.hero__title');
console.log('aria-label:', h.getAttribute('aria-label'));
console.log('all cells aria-hidden:', [...h.querySelectorAll('.hero-cell')].every(c => c.getAttribute('aria-hidden') === 'true'));
```
Expected: `aria-label` is the full real title; cells all `aria-hidden` → screen readers read the label, never glyphs.

- [ ] **Step 4: Reduced motion**

Emulate: DevTools → Rendering → "Emulate CSS prefers-reduced-motion: reduce", then hard-reload `/`.
Expected: title appears **instantly**, no scramble; reveal content visible & static; `document.querySelector('.hero__title').getAttribute('aria-label')` is still set.

- [ ] **Step 5: Scroll reveal + focus**

Reload `/about/` and scroll: the content section fades/rises in once. On `/projects/`, the work-list rows stagger in. Tab through a long page with keyboard before scrolling — focus must never land on an invisible element (the `:focus-within` rule reveals on focus). No layout shift.

- [ ] **Step 6: Fail-open checks**

  - Disable JS (DevTools → Settings → Debugger → Disable JavaScript) and reload `/about/`, `/`: **all content visible**, real title shown, nothing stuck hidden.
  - Re-enable JS. Simulate a missing observer: console `window.IntersectionObserver = undefined;` then reload — content still visible (gate/ watchdog fail open).
  - Back/forward (navigate away then Back): decrypt does **not** replay (bfcache); content visible.

- [ ] **Step 7: Print**

DevTools → print preview (or Cmd/Ctrl+P) on `/about/`: all content visible (no hidden reveal blocks).

- [ ] **Step 8: No console errors / nav intact**

Confirm zero console errors across `/`, `/zh/`, `/about/`, `/projects/`, `/contact/`, a detail page. Mobile-nav toggle still works (resize narrow, open/close).

- [ ] **Step 9: Stop the server**

Run: `pkill -f 'jekyll serve'`

- [ ] **Step 10: codex review (pre-PR gate)**

Run: `codex review --uncommitted` (commit any final tweaks first so the tree is clean, or review the branch). Address any P0–P2 findings; re-verify.

- [ ] **Step 11: Open the PR (do NOT merge)**

```bash
git push -u origin design/interactive-motion
gh pr create --base main --head design/interactive-motion \
  --title "Interactive motion: hero decrypt + scroll reveal" \
  --body "Implements docs/superpowers/specs/2026-05-24-interactive-motion-design.md and docs/superpowers/plans/2026-05-24-interactive-motion.md. Vanilla JS, zero deps, no build. Real title always in DOM + a11y tree; fail-open (no-JS/reduced-motion/unsupported/bfcache/print all resolve to static visible content); CLS = 0 (fixed-width cells). validate_site.rb extended + passing."
```
Leave merging to the user.

---

## Self-Review

**Spec coverage:**
- C1.1/C1.2 in-place fixed-width cells, word grouping, aria-label → Task 5 (CSS) + Task 6 (decrypt.js). ✓
- C1.3 glyph pool → Task 6 `GLYPHS`. ✓
- C1.4 ~1s left→right → Task 6 `tick`/45ms. ✓
- C1.5 fonts.ready + 800ms skip → Task 6 Step 1 (fonts block). ✓
- C1.6 a11y (aria-label + aria-hidden, reduced-motion, no-JS) → Task 6 + Task 8 Steps 3–4, 6. ✓
- C1.7 every fresh load, skip bfcache → Task 6 (persisted state) + Task 8 Step 6. ✓
- C1.8 whitespace-normalize + grapheme → Task 6 (`replace(/\s+/`, `toGraphemes`). ✓
- C1.9 guard on `.hero__title` → Task 6 line 1. ✓
- C2.1 enable-gate + watchdog → Task 2. ✓
- C2.2 CSS hidden/revealed/:focus-within/print → Task 1. ✓
- C2.3 template-declared, no nesting → Task 4 + validator Task 7. ✓
- C2.4 initial viewport / bfcache / fast scroll → Task 3 reveal.js. ✓
- C2.5 hero not a reveal target → Task 4 (work/hero untouched). ✓
- Architecture/files → File Structure table + Tasks. ✓
- Verification matrix → Task 8. ✓

**Placeholder scan:** none — all code is complete; no TBD/TODO. ✓

**Type/name consistency:** `motion` class, `is-revealed`, `data-reveal-ready`, `.reveal`, `.hero-cell`, `.hero-word`, `aria-label`, `aria-hidden` used identically across head gate, reveal.js, decrypt.js, CSS, and validator. ✓
