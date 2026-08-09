# Site Metadata, Performance, and PWA Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make locale, article, source-visibility, 404, social, script-loading, font-loading, and install metadata accurately reflect each route while reducing unused downloads and producing safe, reproducible PWA/share assets.

**Architecture:** Keep `jekyll-seo-tag` for its existing canonical/social baseline, retain `_includes/structured-data.html` as the single JSON-LD source, and add route-aware Liquid conditions in the shared head/layout. Metadata assertions are semantic: parse JSON-LD and manifest JSON, classify routes, and test positive plus negative cases. Asset generation is deterministic and committed; no runtime service or new browser dependency is introduced.

**Tech Stack:** Jekyll/Liquid, JSON-LD/Schema.org, Open Graph/Twitter metadata, Web App Manifest, vanilla JavaScript includes, Ruby validation, Python 3 with Pillow for deterministic PNG processing, browser network/console inspection, and the connected Notion issue database.

## Global Constraints

- Create branch `codex/site-review-metadata-performance` from the accepted accessibility result after Workstreams T and A are merged or explicitly rebased. Re-run the baseline before editing.
- Use superpowers:test-driven-development: introduce route- and schema-specific failing assertions before implementation, observe the expected failures, then make the smallest source change.
- Preserve the existing inline CSP hashes and same-origin policy. Do not add inline runtime JavaScript, remote fonts, analytics, a service worker, a framework, or a CSP exception.
- Keep `main.js`, `theme.js`, and `reveal.js` global. Keep server-rendered content and no-JS behavior unchanged while narrowing optional scripts.
- Emit `SoftwareSourceCode` only for a project whose `_data/projects.yml` row has `public_source: true`. A private project can still be a `WebPage`; inaccessible source is not public software metadata.
- Emit `BlogPosting` only for `_notes` collection documents, not the Notes index or release-history pages.
- Preserve exactly one document `<title>` and one JSON-LD script per page.
- PWA maskable icons must be separate files; do not relabel the current edge-reaching icons as maskable. Social-card optimization must be pixel-identical after decoding.
- Use `fixed-mid-session` only after production build, validator, asset checks, and browser network/console checks are green. Do not edit the 72 `info` rows.
- Run commands from `/Users/fengxiang/Desktop/agent_workspace/frankxue831.github.io`.

---

### Task 1: Add failing semantic metadata and route-loading checks

**Files:**
- Modify: `scripts/validate_site.rb`
- Test: `scripts/validate_site.rb`

**Interfaces:**
- Parses: generated HTML JSON-LD, head metadata, script/preload tags, Web App Manifest, and PNG headers.
- Produces: failures for Tasks 2–4 without network access.

- [ ] **Step 1: Confirm the accepted upstream baseline**

Run:

```bash
git status --short --branch
bundle exec jekyll doctor
JEKYLL_ENV=production bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
```

Expected: clean metadata branch and a green baseline.

- [ ] **Step 2: Add shared helpers for JSON-LD graph nodes**

Add:

```ruby
def json_ld_graph(html, failures, source)
  json_ld_documents(html, failures, source).flat_map { |document| Array(document["@graph"]) }
end

def graph_nodes_of_type(graph, type)
  graph.select { |node| node["@type"] == type }
end
```

Continue using JSON parsing rather than regex for semantic metadata.

- [ ] **Step 3: Add localized WebSite and public-source assertions**

For every core, project, and note page:

- assert exactly one `WebSite` node;
- assert its description equals `site.data.i18n[lang].meta.site_description` after build;
- assert every page has exactly one `WebPage` node.

For project pages, map the URL back to `PROJECTS` by slug and assert:

```text
public_source: true  -> exactly one SoftwareSourceCode with codeRepository
public_source: false -> zero SoftwareSourceCode nodes and no codeRepository
```

Do not treat `release_source: public_tag` as a substitute for `public_source`; test the field named by the schema contract.

- [ ] **Step 4: Add BlogPosting assertions for notes**

For every `note_pages` entry, require exactly one `BlogPosting` node with:

```text
@id ending #article
url equal to the canonical page URL
headline equal to the note title
non-empty description
datePublished equal to the note front-matter date in XML Schema format
inLanguage equal to en or zh-CN as appropriate
author @id ending #person
isPartOf @id ending #website
mainEntityOfPage @id ending #webpage
```

Assert that Notes index pages, project pages, release histories, and 404 contain no `BlogPosting` node.

- [ ] **Step 5: Add head-metadata assertions**

For every bilingual page cluster, require exactly one:

```text
meta[property="og:locale:alternate"] with zh_CN on EN and en_US on ZH
meta[name="twitter:description"] whose content equals the escaped page description
```

For `_site/404.html`, require exactly one `<meta name="robots" content="noindex, follow">` and no hreflang or OG locale alternate. Update home title expectations to:

```ruby
"index.html" => "Frank Xue | Software engineer, mostly in Rust"
"zh/index.html" => "Frank Xue | 软件工程师，主要使用 Rust"
```

Keep the existing exactly-one-title assertion.

- [ ] **Step 6: Replace site-wide optional-script assertions with a route matrix**

Define:

```ruby
global_scripts = %w[main.js theme.js reveal.js].freeze
home_only_scripts = %w[decrypt.js].freeze
case_study_scripts = %w[contents.js].freeze
gm_only_scripts = %w[copy.js].freeze
```

For every generated HTML file:

- require all three global scripts;
- require `decrypt.js` only on `index.html` and `zh/index.html`;
- require `contents.js` only on the eight `project_pages` entries;
- require `copy.js` only on the EN/ZH gm case studies;
- reject every optional script on all other routes, including 404 and release history.

Retain the existing inline motion/theme gate checks.

- [ ] **Step 7: Add home-only font-preload assertions**

The Notion observation reproduces on case-study routes while home was clean. Require both current font preloads on `index.html` and `zh/index.html`, and require zero `rel="preload" as="font"` tags on every other generated HTML page. Assert every retained preload still has `type="font/woff2"` and `crossorigin`.

- [ ] **Step 8: Add manifest safe-icon and social-card size checks**

Extend the asset list with:

```text
assets/img/icon-maskable-192.png
assets/img/icon-maskable-512.png
```

Parse `site.webmanifest` and require separate `purpose: "maskable"` entries for 192×192 and 512×512, while retaining the current ordinary icons. Validate dimensions from PNG IHDR and require both social cards to be 1200×630 and at most `175_000` bytes.

- [ ] **Step 9: Run the validator and observe the intended failures**

Run:

```bash
JEKYLL_ENV=production bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
```

Expected: failures name private `SoftwareSourceCode`, nonlocalized WebSite descriptions, missing BlogPosting/Twitter/OG/404 metadata, global optional scripts/preloads, missing maskable assets, and the EN card exceeding 175,000 bytes.

- [ ] **Step 10: Commit the red checks**

Run:

```bash
git diff --check
git add scripts/validate_site.rb
git commit -m "test: define route-aware metadata contracts"
```

---

### Task 2: Correct JSON-LD and per-route social metadata

**Files:**
- Modify: `_data/i18n.yml`
- Modify: `_includes/structured-data.html`
- Modify: `_includes/head.html`
- Modify: `404.html`
- Test: `scripts/validate_site.rb`

**Interfaces:**
- `_data/i18n.yml` owns localized site descriptions.
- `_includes/structured-data.html` remains the only JSON-LD script source.
- `_includes/head.html` adds metadata not emitted reliably by `jekyll-seo-tag`.

- [ ] **Step 1: Add localized site descriptions**

Under each locale add:

```yaml
# EN
meta:
  site_description: "Personal site of Frank Xue — software engineer. Notes and selected work."

# ZH
meta:
  site_description: "Frank Xue 的个人主页。软件工程师——笔记与精选作品，发布状态与限制写在明面上。"
```

Do not use the EN global `_config.yml` description for ZH JSON-LD.

- [ ] **Step 2: Localize the WebSite node**

At the top of `_includes/structured-data.html`, derive:

```liquid
{%- assign site_description = site.data.i18n[lang].meta.site_description | default: site.description | strip_newlines | strip -%}
```

Use `site_description` for the `WebSite.description`. Keep `WebSite.inLanguage` equal to `['en', 'zh-CN']` because it describes the bilingual site, not the current page.

- [ ] **Step 3: Gate SoftwareSourceCode on public source**

Change both the comma before and the node condition from `if project` to:

```liquid
{% if project and project.public_source %}
```

Within the public-only node, keep `codeRepository`, crates.io, and docs.rs logic. The three private project pages in each locale must emit no software node.

- [ ] **Step 4: Add a BlogPosting node for note documents**

After `WebPage`, conditionally emit this graph node when `page.collection == 'notes'`:

```liquid
{
  "@type": "BlogPosting",
  "@id": {{ page_url | append: '#article' | jsonify }},
  "url": {{ page_url | jsonify }},
  "headline": {{ page_title | jsonify }},
  "description": {{ page_description | jsonify }},
  "datePublished": {{ page.date | date_to_xmlschema | jsonify }},
  "inLanguage": {{ html_lang | jsonify }},
  "mainEntityOfPage": { "@id": {{ webpage_id | jsonify }} },
  "author": { "@id": {{ person_id | jsonify }} },
  "publisher": { "@id": {{ person_id | jsonify }} },
  "isPartOf": { "@id": {{ website_id | jsonify }} }
}
```

Preserve valid comma placement for all combinations: ordinary page, public project, private project, and note.

- [ ] **Step 5: Add explicit Twitter description and OG locale alternate**

Near the SEO capture in `_includes/head.html`, derive:

```liquid
{%- assign meta_description = page.description | default: site.description | strip_newlines | strip -%}
```

After the captured SEO metadata, emit:

```liquid
<meta name="twitter:description" content="{{ meta_description | escape }}">
```

For home pages or pages with `page.alternate`, emit exactly one:

```liquid
<meta property="og:locale:alternate" content="{% if lang == 'zh' %}en_US{% else %}zh_CN{% endif %}">
```

Do not emit it for 404 or any page without a counterpart.

- [ ] **Step 6: Mark the shared 404 as noindex**

Add `robots: noindex, follow` to `404.html` front matter, then render this optional front-matter value in `_includes/head.html`:

```liquid
{%- if page.robots -%}
<meta name="robots" content="{{ page.robots | escape }}">
{%- endif -%}
```

Retain `sitemap: false`, the bilingual recovery UI, no alternate/hreflang, and HTTP 200 behavior imposed by static hosting.

- [ ] **Step 7: Build, parse, and inspect representative graphs**

Run:

```bash
JEKYLL_ENV=production bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
ruby -rjson -e 'Dir["_site/**/*.html"].each { |p| File.read(p).scan(%r{<script type="application/ld\+json">\s*(.*?)\s*</script>}m).each { |m| JSON.parse(m.first); puts p } }'
rg -n "BlogPosting|SoftwareSourceCode|og:locale:alternate|twitter:description|noindex, follow" _site/notes/constant-time-warrant/index.html _site/zh/notes/constant-time-warrant/index.html _site/projects/gm-crypto-rs/index.html _site/projects/repolens-rs/index.html _site/404.html
```

Expected: JSON parsing succeeds; public gm has software metadata; RepoLens does not; both notes have BlogPosting; 404 has noindex; validator remains red only for later tasks.

- [ ] **Step 8: Commit semantic metadata corrections**

Run:

```bash
git diff --check
git add _data/i18n.yml _includes/structured-data.html _includes/head.html 404.html
git commit -m "fix: align localized and route-specific metadata"
```

---

### Task 3: Load optional scripts and font preloads only where they are useful

**Files:**
- Modify: `_layouts/default.html`
- Modify: `_includes/head.html`
- Modify: `scripts/validate_site.rb` only if a source-route classification discovered during implementation was omitted from Task 1
- Test: `scripts/validate_site.rb`

**Interfaces:**
- Global scripts: `main.js`, `theme.js`, `reveal.js`.
- Home enhancement: `decrypt.js`.
- Eight case studies: `contents.js`.
- EN/ZH gm case study: `copy.js`.
- EN/ZH home: two font preloads.

- [ ] **Step 1: Encode explicit script conditions in the layout**

Keep these three tags unconditional:

```liquid
<script src="{{ '/assets/js/main.js' | relative_url }}" defer></script>
<script src="{{ '/assets/js/theme.js' | relative_url }}" defer></script>
<script src="{{ '/assets/js/reveal.js' | relative_url }}" defer></script>
```

Replace the three optional tags with:

```liquid
{% if page.url == '/' or page.url == '/zh/' %}
<script src="{{ '/assets/js/decrypt.js' | relative_url }}" defer></script>
{% endif %}
{% if page.project_slug %}
<script src="{{ '/assets/js/contents.js' | relative_url }}" defer></script>
{% endif %}
{% if page.project_slug == 'gm-crypto-rs' %}
<script src="{{ '/assets/js/copy.js' | relative_url }}" defer></script>
{% endif %}
```

The release-history pages have no `project_slug`, so they receive neither case-study script.

- [ ] **Step 2: Make font preloads home-only**

Wrap both existing font preload tags in:

```liquid
{% if page.url == '/' or page.url == '/zh/' %}
<link rel="preload" as="font" type="font/woff2" crossorigin href="{{ '/assets/fonts/eb-garamond-latin.woff2' | relative_url }}">
<link rel="preload" as="font" type="font/woff2" crossorigin href="{{ '/assets/fonts/ibm-plex-mono-400-latin.woff2' | relative_url }}">
{% endif %}
```

Do not change `@font-face`; non-home routes still load the exact font files on demand. Do not replace the preloaded weights until a fresh performance trace demonstrates a better home critical path.

- [ ] **Step 3: Run the route matrix**

Run:

```bash
JEKYLL_ENV=production bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
for page in _site/index.html _site/zh/index.html _site/projects/gm-crypto-rs/index.html _site/projects/repolens-rs/index.html _site/notes/constant-time-warrant/index.html _site/404.html; do
  echo "$page"
  rg -o '/assets/js/[^" ]+|rel="preload" as="font"' "$page" || true
done
```

Expected:

```text
home: globals + decrypt; two font preloads
gm case study: globals + contents + copy; no font preload
other case study: globals + contents; no font preload
note and 404: globals only; no font preload
```

- [ ] **Step 4: Confirm progressive-enhancement fallbacks**

Inspect generated home title text, all case-study headings, and the gm install command. They must exist in server HTML without the optional scripts. The narrower loading policy may remove animation/copy/rail enhancement only from routes that never use it.

- [ ] **Step 5: Commit route-aware loading**

Run:

```bash
git diff --check
git add _layouts/default.html _includes/head.html scripts/validate_site.rb
git commit -m "perf: scope optional scripts and font preloads by route"
```

If `scripts/validate_site.rb` did not need a post-Task-1 correction, do not stage it again.

---

### Task 4: Produce reproducible maskable icons and losslessly optimize the EN social card

**Files:**
- Create: `scripts/build_maskable_icons.py`
- Create: `scripts/optimize_social_cards.py`
- Create: `assets/img/icon-maskable-192.png`
- Create: `assets/img/icon-maskable-512.png`
- Modify: `assets/img/social-card.png`
- Modify: `site.webmanifest`
- Test: `scripts/validate_site.rb`

**Interfaces:**
- Input icon: `assets/img/icon-512.png`.
- Input share card: `assets/img/social-card.png`.
- Output manifest icons: dedicated 192px and 512px maskable PNGs.
- Output share card: decoded pixels identical to the input, file size at most 175,000 bytes.

- [ ] **Step 1: Add the deterministic maskable-icon builder**

Create `scripts/build_maskable_icons.py` with this algorithm:

```python
#!/usr/bin/env python3
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/img/icon-512.png"
OUT_512 = ROOT / "assets/img/icon-maskable-512.png"
OUT_192 = ROOT / "assets/img/icon-maskable-192.png"

with Image.open(SOURCE) as opened:
    source = opened.convert("RGB")
if source.size != (512, 512):
    raise SystemExit(f"expected 512x512 source, got {source.size}")

background = source.getpixel((0, 0))
canvas = Image.new("RGB", (512, 512), background)
inner = source.resize((432, 432), Image.Resampling.LANCZOS)
canvas.paste(inner, (40, 40))
canvas.save(OUT_512, format="PNG", optimize=True, compress_level=9)
canvas.resize((192, 192), Image.Resampling.LANCZOS).save(
    OUT_192, format="PNG", optimize=True, compress_level=9
)

for path in (OUT_192, OUT_512):
    with Image.open(path) as opened:
        image = opened.convert("RGB")
    size = image.width
    if image.size != (size, size):
        raise SystemExit(f"{path}: icon is not square: {image.size}")
    bg = image.getpixel((0, 0))
    radius = size * 0.4
    foreground = (
        (x, y)
        for y in range(size)
        for x in range(size)
        if image.getpixel((x, y)) != bg
    )
    distances = [((x - size / 2) ** 2 + (y - size / 2) ** 2) ** 0.5 for x, y in foreground]
    if not distances or max(distances) > radius:
        raise SystemExit(f"{path}: foreground leaves the maskable safe circle")
    print(f"{path.relative_to(ROOT)}: {image.size}, safe")
```

This scales the complete existing canvas to 84.375%, preserving the mark and background while keeping non-background pixels—including Lanczos antialiasing at 192px—inside the maskable safe circle. The original mark reaches about 236px from center; 87.5% scaling was rejected by the builder because it left edge pixels outside the 40% safe radius.

- [ ] **Step 2: Build and visually inspect both icons**

Run:

```bash
python3 scripts/build_maskable_icons.py
file assets/img/icon-maskable-192.png assets/img/icon-maskable-512.png
```

Inspect both images at original detail. The italic `f`, blue color, paper background, centering, and antialiasing must match the ordinary icon; only the additional safe padding should differ.

- [ ] **Step 3: Add deterministic asset assertions to the validator**

In `scripts/validate_site.rb`, require both maskable assets, parse their PNG IHDR dimensions, and assert 192×192 and 512×512 respectively. Require `site.webmanifest` to reference those exact paths with `purpose: "maskable"`. The builder itself performs the decoded safe-circle assertion; rerunning the builder is part of the full verification gate.

Run this independent decoded-pixel check once after generation:

```bash
python3 - <<'PY'
from pathlib import Path
from PIL import Image
for path in map(Path, ["assets/img/icon-maskable-192.png", "assets/img/icon-maskable-512.png"]):
    image = Image.open(path).convert("RGB")
    size = image.width
    bg = image.getpixel((0, 0))
    radius = size * 0.4
    points = [(x, y) for y in range(size) for x in range(size) if image.getpixel((x, y)) != bg]
    assert points, f"{path}: no foreground pixels"
    assert max(((x - size / 2) ** 2 + (y - size / 2) ** 2) ** 0.5 for x, y in points) <= radius, f"{path}: foreground leaves safe circle"
    print(path, image.size, "safe")
PY
```

- [ ] **Step 4: Declare separate maskable icon entries**

Append to `site.webmanifest`:

```json
{ "src": "/assets/img/icon-maskable-192.png", "sizes": "192x192", "type": "image/png", "purpose": "maskable" },
{ "src": "/assets/img/icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
```

Keep the existing ordinary icon entries without a maskable purpose.

- [ ] **Step 5: Add the lossless social-card optimizer**

Create `scripts/optimize_social_cards.py` with the following complete implementation. It does not recompress the ZH card because it is already below the target and the row concerns EN.

```python
#!/usr/bin/env python3
from pathlib import Path
from tempfile import NamedTemporaryFile
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
CARD = ROOT / "assets/img/social-card.png"

before_bytes = CARD.stat().st_size
with Image.open(CARD) as opened:
    if opened.size != (1200, 630):
        raise SystemExit(f"expected 1200x630 card, got {opened.size}")
    baseline = opened.convert("RGBA")
    with NamedTemporaryFile(
        prefix="social-card-", suffix=".png", dir=CARD.parent, delete=False
    ) as temporary:
        temporary_path = Path(temporary.name)
    opened.save(temporary_path, format="PNG", optimize=True, compress_level=9)

try:
    with Image.open(temporary_path) as candidate_opened:
        candidate = candidate_opened.convert("RGBA")
    if candidate.size != baseline.size:
        raise SystemExit("optimized card changed dimensions")
    if ImageChops.difference(baseline, candidate).getbbox() is not None:
        raise SystemExit("optimized card changed decoded pixels")
    after_bytes = temporary_path.stat().st_size
    if after_bytes < before_bytes:
        temporary_path.replace(CARD)
        print(f"{CARD.relative_to(ROOT)}: {before_bytes} -> {after_bytes} bytes")
    else:
        temporary_path.unlink()
        print(f"{CARD.relative_to(ROOT)}: kept {before_bytes} bytes")
finally:
    if temporary_path.exists():
        temporary_path.unlink()
```

- [ ] **Step 6: Optimize and prove pixel identity**

Run:

```bash
cp assets/img/social-card.png /tmp/frankxue-social-card-before.png
python3 scripts/optimize_social_cards.py
python3 - <<'PY'
from PIL import Image, ImageChops
a = Image.open('/tmp/frankxue-social-card-before.png').convert('RGBA')
b = Image.open('assets/img/social-card.png').convert('RGBA')
assert a.size == b.size == (1200, 630)
assert ImageChops.difference(a, b).getbbox() is None
print('pixel-identical', b.size)
PY
wc -c assets/img/social-card.png assets/img/social-card.zh.png
```

Expected: pixel diff is empty and both cards are at most 175,000 bytes. A Pillow 12.2 diagnostic on the 2026-08-09 source reduced EN from 216,324 to 168,733 bytes without changing decoded pixels.

- [ ] **Step 7: Build and validate assets through the generated site**

Run:

```bash
JEKYLL_ENV=production bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
file _site/assets/img/icon-maskable-192.png _site/assets/img/icon-maskable-512.png _site/assets/img/social-card.png
```

Expected: manifest parses, all four ordinary/maskable icon paths exist at declared dimensions, social cards pass the ceiling, and the complete validator is green.

- [ ] **Step 8: Commit the asset improvements**

Run:

```bash
git diff --check
git add scripts/build_maskable_icons.py scripts/optimize_social_cards.py assets/img/icon-maskable-192.png assets/img/icon-maskable-512.png assets/img/social-card.png site.webmanifest
git commit -m "perf: add safe PWA icons and optimize share asset"
```

---

### Task 5: Run browser network, console, schema, and full-branch verification

**Files:**
- Verify: all files changed in Tasks 1–4
- Verify: generated `_site/`

**Interfaces:**
- Produces the acceptance record and commit SHA required before Notion updates.

- [ ] **Step 1: Run the complete static gate**

Run:

```bash
git diff main...HEAD --check
bundle exec jekyll doctor
JEKYLL_ENV=production bundle exec jekyll build
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb
ruby scripts/check_release_drift.rb
python3 scripts/build_maskable_icons.py
python3 scripts/optimize_social_cards.py
git status --short
```

Expected: all checks pass; the two generation scripts are idempotent; `git status --short` remains empty after rerunning them.

- [ ] **Step 2: Start a local server and inspect representative routes**

Run:

```bash
JEKYLL_ENV=production bundle exec jekyll serve --host 127.0.0.1 --port 4000
```

Inspect in the in-app browser:

```text
/
/zh/
/projects/gm-crypto-rs/
/projects/repolens-rs/
/notes/constant-time-warrant/
/zh/notes/constant-time-warrant/
/404.html
```

- [ ] **Step 3: Verify network and console behavior**

With cache disabled and a fresh reload:

1. Home loads global scripts plus `decrypt.js` and exactly two font preloads.
2. gm case study loads global scripts plus `contents.js` and `copy.js`, with no font-preload-unused warning.
3. RepoLens loads global scripts plus `contents.js`, not `copy.js` or `decrypt.js`, with no font-preload-unused warning.
4. Note and 404 load only global scripts.
5. Every requested asset returns 200 and the console has no error or preload warning.

- [ ] **Step 4: Inspect metadata using parsed DOM and JSON**

For the representative routes, confirm exactly one document title and JSON-LD script. Verify:

```text
ZH WebSite description is Chinese
public gm includes SoftwareSourceCode and codeRepository
private RepoLens includes WebPage but no SoftwareSourceCode
notes include BlogPosting with correct date/language/canonical IDs
bilingual pages include the opposite og:locale:alternate
all pages include explicit twitter:description
404 includes noindex, follow and no alternates
```

- [ ] **Step 5: Inspect PWA install presentation**

Open the manifest in browser application tooling. Confirm the ordinary icons remain available, the two new entries are recognized as maskable, and the mark remains fully visible in circle, rounded-square, and squircle previews.

- [ ] **Step 6: Record final branch evidence**

Stop the server and run:

```bash
git log --oneline main..HEAD
git diff --stat main...HEAD
git status --short
git rev-parse HEAD
```

Expected: focused metadata/performance commits, clean worktree, and a recorded final SHA.

---

### Task 6: Resolve the metadata, performance, and PWA rows in Notion

**Files:**
- No repository files modified

**Interfaces:**
- Updates database: `Site review issues — 2026-08-03 continuous`.

- [ ] **Step 1: Re-fetch the Workstream M rows**

Fetch the open rows for private-project JSON-LD, localized WebSite description, title punctuation, OG locale alternate, conditional scripts, maskable icons, Twitter description, font-preload warnings, BlogPosting JSON-LD, EN social-card size, and 404 robots metadata. Confirm each still belongs to the target project and has the same acceptance condition.

- [ ] **Step 2: Resolve implementation-backed rows**

Run `date -u '+%Y-%m-%dT%H:%M:%SZ'` and `git rev-parse HEAD`. For each row, append five lines: `Resolution — ` followed by the actual UTC output; `Disposition: fixed in ` followed by the actual commit SHA; `Changed surfaces: ` followed by the exact paths for that row; `Static verification: production build and semantic site validator passed.`; and `Runtime/asset verification: ` followed by the relevant schema parse, route network/console result, mask preview, or pixel-identical byte result from Task 5.

Set status to `fixed-mid-session` only when the row's exact acceptance result is included.

- [ ] **Step 3: Preserve title/description evidence per locale**

For the title punctuation and localized WebSite rows, include the exact final EN/ZH `<title>` or parsed `WebSite.description` values in the resolution. For BlogPosting, include one EN and one ZH parsed node summary with date and language.

- [ ] **Step 4: Audit the database changes**

Re-fetch every updated Workstream M row and verify status, appended resolution, commit, and evidence. Confirm no `info`, content, accessibility, or hosting row was changed.
