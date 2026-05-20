# Site Quality Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a site quality foundation that restores the current Jekyll build, improves metadata and structured data, makes project pages easier to scan, and adds repeatable local and CI validation.

**Architecture:** Keep the site as a static Jekyll site. Use `_config.yml` and page front matter for metadata, add small includes for structured data and project summaries, add one lightweight Ruby validation script over `_site`, and wire the same checks into GitHub Actions.

**Tech Stack:** Jekyll 3.9 via `github-pages`, Liquid templates, YAML data files, vanilla CSS, Ruby standard library validation, GitHub Actions.

---

## File Structure

- Modify `_config.yml`: exclude `CLAUDE.md`, set a default social image, and keep existing Jekyll SEO behavior.
- Create `assets/img/social-card.svg`: static social preview asset referenced by page metadata.
- Create `_includes/structured-data.html`: emits conservative JSON-LD for `Person`, `WebSite`, `WebPage`, and project pages.
- Modify `_includes/head.html`: render the structured-data include after `{% seo %}`.
- Create `_includes/project-summary.html`: renders the reusable bilingual project fact block.
- Modify `_data/i18n.yml`: add English and Chinese labels used by the summary block.
- Modify `projects/*.html` and `zh/projects/*.html`: add `project_slug` front matter and include the summary block at the top of each project article.
- Modify `assets/css/style.css`: style `.project-summary` without changing the existing visual identity.
- Create `scripts/validate_site.rb`: validate generated metadata, structured data, internal links, and excluded files.
- Create `.github/workflows/site.yml`: run the same build and validation commands in CI.

## Task 1: Restore Build Baseline and Add Social Image Metadata

**Files:**
- Modify: `_config.yml`
- Create: `assets/img/social-card.svg`

- [ ] **Step 1: Reproduce the current build failure**

Run:

```bash
bundle exec jekyll build
```

Expected: FAIL with `Liquid Exception: Liquid syntax error ... CLAUDE.md`.

- [ ] **Step 2: Update `_config.yml`**

Change `_config.yml` so the existing defaults also set a site-wide image, and exclude `CLAUDE.md` from Jekyll rendering:

```yaml
defaults:
  - scope:
      path: ""
    values:
      layout: default
      image: /assets/img/social-card.svg

exclude:
  - .sass-cache/
  - .jekyll-cache/
  - docs/superpowers/
  - gemfiles/
  - Gemfile
  - Gemfile.lock
  - node_modules/
  - vendor/
  - README.md
  - CLAUDE.md
```

- [ ] **Step 3: Create `assets/img/social-card.svg`**

Create the directory `assets/img/` if it does not exist, then add this file:

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630" role="img" aria-labelledby="title desc">
  <title id="title">Frank Xue</title>
  <desc id="desc">Software engineer. Reliable tools for code, crypto, and agents.</desc>
  <rect width="1200" height="630" fill="#f5f1e8"/>
  <path d="M0 540h1200" stroke="#1e40af" stroke-width="4"/>
  <text x="96" y="190" fill="#1f2933" font-family="Georgia, 'Times New Roman', serif" font-size="92" font-weight="600">Frank Xue</text>
  <text x="96" y="280" fill="#1e40af" font-family="Arial, 'Helvetica Neue', sans-serif" font-size="38">Software engineer</text>
  <text x="96" y="356" fill="#3f4752" font-family="Arial, 'Helvetica Neue', sans-serif" font-size="44">Reliable tools for code, crypto, and agents.</text>
  <text x="96" y="500" fill="#7c6f63" font-family="Menlo, Consolas, monospace" font-size="26">frankxue.dev</text>
</svg>
```

- [ ] **Step 4: Verify the build baseline is restored**

Run:

```bash
bundle exec jekyll doctor
bundle exec jekyll build
test ! -e _site/CLAUDE.md
```

Expected: all commands exit 0, and `_site/CLAUDE.md` does not exist.

- [ ] **Step 5: Commit**

```bash
git add _config.yml assets/img/social-card.svg
git commit -m "fix: restore site build baseline"
```

## Task 2: Add Structured Data

**Files:**
- Create: `_includes/structured-data.html`
- Modify: `_includes/head.html`
- Modify: `projects/gm-crypto-rs.html`
- Modify: `projects/repolens-rs.html`
- Modify: `projects/ghrunners.html`
- Modify: `zh/projects/gm-crypto-rs.html`
- Modify: `zh/projects/repolens-rs.html`
- Modify: `zh/projects/ghrunners.html`

- [ ] **Step 1: Confirm structured data is currently absent**

Run:

```bash
bundle exec jekyll build
rg -n 'SoftwareSourceCode|#software' _site/projects/gm-crypto-rs/index.html
```

Expected: `rg` exits 1 because the existing `jekyll-seo-tag` output does not include project-specific software JSON-LD.

- [ ] **Step 2: Add `project_slug` front matter to each project detail page**

Add the matching slug to each project page front matter:

```yaml
project_slug: gm-crypto-rs
```

```yaml
project_slug: repolens-rs
```

```yaml
project_slug: ghrunners
```

Use the same slug in the English and Chinese page for that project.

- [ ] **Step 3: Create `_includes/structured-data.html`**

```liquid
{%- assign lang = page.lang | default: 'en' -%}
{%- assign page_description = page.description | default: site.description | strip_newlines | strip -%}
{%- assign page_title = page.title | default: site.title -%}
{%- assign page_url = page.url | absolute_url -%}
{%- assign site_url = '/' | absolute_url -%}
{%- assign person_id = site_url | append: '#person' -%}
{%- assign website_id = site_url | append: '#website' -%}
{%- assign webpage_id = page_url | append: '#webpage' -%}
{%- if page.project_slug -%}
  {%- assign project = site.data.projects | where: 'slug', page.project_slug | first -%}
{%- endif -%}
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Person",
      "@id": {{ person_id | jsonify }},
      "name": {{ site.author.name | default: site.title | jsonify }},
      "url": {{ site_url | jsonify }},
      "sameAs": [
        {{ 'https://github.com/' | append: site.github_username | jsonify }}
      ]
    },
    {
      "@type": "WebSite",
      "@id": {{ website_id | jsonify }},
      "url": {{ site_url | jsonify }},
      "name": {{ site.title | jsonify }},
      "description": {{ site.description | strip_newlines | strip | jsonify }},
      "inLanguage": {{ lang | jsonify }},
      "publisher": {
        "@id": {{ person_id | jsonify }}
      }
    },
    {
      "@type": "WebPage",
      "@id": {{ webpage_id | jsonify }},
      "url": {{ page_url | jsonify }},
      "name": {{ page_title | jsonify }},
      "description": {{ page_description | jsonify }},
      "inLanguage": {{ lang | jsonify }},
      "isPartOf": {
        "@id": {{ website_id | jsonify }}
      },
      "about": {
        "@id": {{ person_id | jsonify }}
      }
    }{% if project %},
    {
      "@type": "SoftwareSourceCode",
      "@id": {{ page_url | append: '#software' | jsonify }},
      "name": {{ project.title | jsonify }},
      "description": {{ page_description | jsonify }},
      "url": {{ page_url | jsonify }},
      "programmingLanguage": "Rust",
      "author": {
        "@id": {{ person_id | jsonify }}
      },
      "isPartOf": {
        "@id": {{ webpage_id | jsonify }}
      }{% if project.public_source and project.repo_url %},
      "codeRepository": {{ project.repo_url | jsonify }}{% endif %}{% if project.crate_url or project.docs_url %},
      "sameAs": [{% assign emitted_same_as = false %}{% if project.crate_url %}{{ project.crate_url | jsonify }}{% assign emitted_same_as = true %}{% endif %}{% if project.docs_url %}{% if emitted_same_as %}, {% endif %}{{ project.docs_url | jsonify }}{% endif %}]
      {% endif %}
    }{% endif %}
  ]
}
</script>
```

- [ ] **Step 4: Render structured data from `_includes/head.html`**

Add this immediately after `{% seo %}`:

```liquid
    {% include structured-data.html %}
```

- [ ] **Step 5: Verify JSON-LD renders and parses**

Run:

```bash
bundle exec jekyll build
ruby -rjson -e 'Dir["_site/**/*.html"].each { |f| File.read(f).scan(%r{<script type="application/ld\\+json">\\s*(.*?)\\s*</script>}m).each { |m| JSON.parse(m.first) } }'
rg -n 'SoftwareSourceCode|#person|#website' _site/index.html _site/projects/gm-crypto-rs/index.html _site/zh/projects/gm-crypto-rs/index.html
```

Expected: build exits 0, Ruby exits 0, and `rg` finds JSON-LD identifiers.

- [ ] **Step 6: Verify private repositories are not exposed as public source**

Run:

```bash
rg -n 'codeRepository|github\\.com/frankxue831/(gm-crypto-rs|repolens-rs|ghrunners)' _site/projects _site/zh/projects
```

Expected: `rg` exits 1 because `public_source: false` for all current project entries.

- [ ] **Step 7: Commit**

```bash
git add _includes/structured-data.html _includes/head.html projects/gm-crypto-rs.html projects/repolens-rs.html projects/ghrunners.html zh/projects/gm-crypto-rs.html zh/projects/repolens-rs.html zh/projects/ghrunners.html
git commit -m "feat: add conservative structured data"
```

## Task 3: Add Project Summary Blocks

**Files:**
- Create: `_includes/project-summary.html`
- Modify: `_data/i18n.yml`
- Modify: `assets/css/style.css`
- Modify: `projects/gm-crypto-rs.html`
- Modify: `projects/repolens-rs.html`
- Modify: `projects/ghrunners.html`
- Modify: `zh/projects/gm-crypto-rs.html`
- Modify: `zh/projects/repolens-rs.html`
- Modify: `zh/projects/ghrunners.html`

- [ ] **Step 1: Confirm project pages do not yet have summary blocks**

Run:

```bash
bundle exec jekyll build
rg -n 'project-summary|Project summary|项目摘要' _site/projects _site/zh/projects
```

Expected: `rg` exits 1.

- [ ] **Step 2: Add summary labels to `_data/i18n.yml`**

Add this under `en:`:

```yaml
  project_summary:
    aria: "Project summary"
    role: "Role"
    status: "Status"
    stack: "Stack"
    release: "Release"
    links: "Links"
    owner: "Personal project"
    key_outcome: "Key outcome"
```

Add this under `zh:`:

```yaml
  project_summary:
    aria: "项目摘要"
    role: "角色"
    status: "状态"
    stack: "技术"
    release: "版本"
    links: "链接"
    owner: "个人项目"
    key_outcome: "关键点"
```

- [ ] **Step 3: Create `_includes/project-summary.html`**

```liquid
{%- assign lang = page.lang | default: 'en' -%}
{%- assign labels = site.data.i18n[lang].project_summary -%}
{%- assign project = site.data.projects | where: 'slug', page.project_slug | first -%}
{%- if project -%}
  {%- assign tags = project.tags[lang] | default: project.tags.en -%}
  {%- assign status_label = project.status_label[lang] | default: project.status_label.en -%}
  <dl class="project-summary" aria-label="{{ labels.aria | escape }}">
    <div class="project-summary__item">
      <dt>{{ labels.role }}</dt>
      <dd>{{ labels.owner }}</dd>
    </div>
    <div class="project-summary__item">
      <dt>{{ labels.status }}</dt>
      <dd>{{ status_label }}</dd>
    </div>
    <div class="project-summary__item">
      <dt>{{ labels.release }}</dt>
      <dd>{{ project.release }}</dd>
    </div>
    {%- if page.summary_outcome -%}
      <div class="project-summary__item project-summary__item--wide">
        <dt>{{ labels.key_outcome }}</dt>
        <dd>{{ page.summary_outcome }}</dd>
      </div>
    {%- endif -%}
    <div class="project-summary__item project-summary__item--wide">
      <dt>{{ labels.stack }}</dt>
      <dd>
        {%- for tag in tags -%}
          <span>{{ tag }}</span>{% unless forloop.last %}<span aria-hidden="true">/</span>{% endunless %}
        {%- endfor -%}
      </dd>
    </div>
    {%- if project.crate_url or project.docs_url or project.repo_url -%}
      <div class="project-summary__item project-summary__item--wide">
        <dt>{{ labels.links }}</dt>
        <dd>
          {%- if project.repo_url and project.public_source -%}
            <a href="{{ project.repo_url }}" rel="noopener noreferrer">Source</a>
          {%- endif -%}
          {%- if project.crate_url -%}
            <a href="{{ project.crate_url }}" rel="noopener noreferrer">crates.io</a>
          {%- endif -%}
          {%- if project.docs_url -%}
            <a href="{{ project.docs_url }}" rel="noopener noreferrer">docs.rs</a>
          {%- endif -%}
        </dd>
      </div>
    {%- endif -%}
  </dl>
{%- endif -%}
```

- [ ] **Step 4: Insert the include into every project detail article**

Add `summary_outcome` front matter to each project page:

```yaml
summary_outcome: "In-CI leak-regression gates for secret-touching paths."
```

```yaml
summary_outcome: "Repository packs and typed memory help agents restart with grounded context."
```

```yaml
summary_outcome: "Read-only diagnostics surface runner state without hiding partial failures."
```

```yaml
summary_outcome: "用 CI 泄漏回归门控守住涉及秘密的关键路径。"
```

```yaml
summary_outcome: "仓库包和类型化记忆让 Agent 重启后仍能拿到有根据的上下文。"
```

```yaml
summary_outcome: "只读诊断暴露 runner 状态,同时保留局部失败的来源。"
```

Then insert the include immediately after `<article class="project-detail prose">` in each file:

```liquid
        {% include project-summary.html %}
```

Files:

```text
projects/gm-crypto-rs.html
projects/repolens-rs.html
projects/ghrunners.html
zh/projects/gm-crypto-rs.html
zh/projects/repolens-rs.html
zh/projects/ghrunners.html
```

- [ ] **Step 5: Add CSS for the summary block**

Add this in `assets/css/style.css` inside the `Project detail page` section, before `.project-detail h2`:

```css
.project-summary {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: var(--space-4) var(--space-6);
    margin: 0 0 var(--space-10);
    padding: var(--space-5) 0;
    border-top: 1px solid var(--rule);
    border-bottom: 1px solid var(--rule);
}
.project-summary__item {
    min-width: 0;
}
.project-summary__item--wide {
    grid-column: 1 / -1;
}
.project-summary dt {
    font-family: var(--mono);
    font-size: var(--text-xs);
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: var(--fg-subtle);
    margin-bottom: var(--space-2);
}
.project-summary dd {
    margin: 0;
    font-family: var(--sans);
    font-size: var(--text-sm);
    line-height: 1.5;
    color: var(--fg);
}
.project-summary dd span + span,
.project-summary dd a + a {
    margin-left: var(--space-2);
}
.project-summary a {
    color: var(--fg);
    border-bottom: 1px solid var(--accent);
}
.project-summary a:hover {
    color: var(--accent);
}
@media (max-width: 759px) {
    .project-summary {
        grid-template-columns: 1fr;
        margin-bottom: var(--space-8);
    }
    .project-summary__item--wide {
        grid-column: auto;
    }
}
```

- [ ] **Step 6: Verify summary output**

Run:

```bash
bundle exec jekyll build
rg -n 'project-summary|Project summary|项目摘要|local tag v0.1.1|origin/main @ afd7a6b|v0.7.0' _site/projects _site/zh/projects
```

Expected: `rg` finds the summary class, bilingual aria labels, and project release labels.

- [ ] **Step 7: Commit**

```bash
git add _includes/project-summary.html _data/i18n.yml assets/css/style.css projects/gm-crypto-rs.html projects/repolens-rs.html projects/ghrunners.html zh/projects/gm-crypto-rs.html zh/projects/repolens-rs.html zh/projects/ghrunners.html
git commit -m "feat: add project summary blocks"
```

## Task 4: Add Local Generated-Site Validation

**Files:**
- Create: `scripts/validate_site.rb`

- [ ] **Step 1: Confirm the validation command is absent**

Run:

```bash
ruby scripts/validate_site.rb
```

Expected: FAIL with `No such file or directory -- scripts/validate_site.rb`.

- [ ] **Step 2: Create `scripts/validate_site.rb`**

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "json"
require "pathname"
require "set"
require "uri"

ROOT = Pathname.new(__dir__).parent
SITE = ROOT.join("_site")
HOST = "www.frankxue.dev"
BASE_URL = "https://#{HOST}"

failures = []

def record(failures, message)
  failures << message
end

def read_file(path, failures)
  path.read
rescue Errno::ENOENT
  record(failures, "Missing generated file: #{path}")
  ""
end

def generated_target_for(href)
  return nil if href.empty? || href.start_with?("#", "mailto:", "tel:")

  uri = URI.parse(href)
  return nil if uri.scheme && !%w[http https].include?(uri.scheme)
  return nil if uri.host && uri.host != HOST

  path = uri.path
  path = "/" if path.empty?

  if path.end_with?("/")
    path == "/" ? "index.html" : "#{path.delete_prefix("/")}index.html"
  else
    path.delete_prefix("/")
  end
rescue URI::InvalidURIError
  nil
end

def json_ld_documents(html, failures, source)
  html.scan(%r{<script type="application/ld\+json">\s*(.*?)\s*</script>}m).map do |match|
    JSON.parse(CGI.unescapeHTML(match.first))
  rescue JSON::ParserError => error
    record(failures, "Invalid JSON-LD in #{source}: #{error.message}")
    nil
  end.compact
end

unless SITE.directory?
  record(failures, "Missing _site directory. Run bundle exec jekyll build first.")
end

[
  SITE.join("CLAUDE.md"),
  SITE.join("docs/superpowers")
].each do |path|
  record(failures, "Excluded path was generated: #{path.relative_path_from(SITE)}") if path.exist?
end

core_pages = {
  "index.html" => { alternates: ["#{BASE_URL}/zh/"] },
  "zh/index.html" => { alternates: ["#{BASE_URL}/"] },
  "about/index.html" => { alternates: ["#{BASE_URL}/zh/about/"] },
  "zh/about/index.html" => { alternates: ["#{BASE_URL}/about/"] },
  "projects/index.html" => { alternates: ["#{BASE_URL}/zh/projects/"] },
  "zh/projects/index.html" => { alternates: ["#{BASE_URL}/projects/"] },
  "contact/index.html" => { alternates: ["#{BASE_URL}/zh/contact/"] },
  "zh/contact/index.html" => { alternates: ["#{BASE_URL}/contact/"] }
}

project_pages = %w[
  projects/gm-crypto-rs/index.html
  projects/repolens-rs/index.html
  projects/ghrunners/index.html
  zh/projects/gm-crypto-rs/index.html
  zh/projects/repolens-rs/index.html
  zh/projects/ghrunners/index.html
]

(core_pages.keys + project_pages).each do |relative|
  path = SITE.join(relative)
  html = read_file(path, failures)
  next if html.empty?

  record(failures, "#{relative}: missing canonical URL") unless html.match?(%r{<link rel="canonical" href="#{Regexp.escape(BASE_URL)}/})
  record(failures, "#{relative}: missing meta description") unless html.match?(%r{<meta name="description" content="[^"]{20,}"})
  record(failures, "#{relative}: missing Open Graph title") unless html.match?(%r{<meta property="og:title" content="[^"]+"})
  record(failures, "#{relative}: missing Open Graph description") unless html.match?(%r{<meta property="og:description" content="[^"]+"})
  record(failures, "#{relative}: missing Open Graph image") unless html.match?(%r{<meta property="og:image" content="#{Regexp.escape(BASE_URL)}/assets/img/social-card\.svg"})

  docs = json_ld_documents(html, failures, relative)
  graph_types = docs.flat_map { |doc| Array(doc["@graph"]).map { |node| node["@type"] } }
  record(failures, "#{relative}: missing WebPage JSON-LD") unless graph_types.include?("WebPage")
  record(failures, "#{relative}: missing Person JSON-LD") unless graph_types.include?("Person")
  record(failures, "#{relative}: missing WebSite JSON-LD") unless graph_types.include?("WebSite")
end

core_pages.each do |relative, config|
  html = read_file(SITE.join(relative), failures)
  config[:alternates].each do |alternate|
    unless html.include?(%(<link rel="alternate")) && html.include?(%(href="#{alternate}"))
      record(failures, "#{relative}: missing alternate #{alternate}")
    end
  end
end

project_pages.each do |relative|
  html = read_file(SITE.join(relative), failures)
  docs = json_ld_documents(html, failures, relative)
  graph_types = docs.flat_map { |doc| Array(doc["@graph"]).map { |node| node["@type"] } }
  record(failures, "#{relative}: missing SoftwareSourceCode JSON-LD") unless graph_types.include?("SoftwareSourceCode")
  record(failures, "#{relative}: missing project summary") unless html.include?(%(class="project-summary"))
end

internal_targets = Set.new
Pathname.glob(SITE.join("**/*.html").to_s).each do |path|
  html = path.read
  html.scan(%r{<(?:a|link)\b[^>]+\bhref="([^"]+)"}i).each do |match|
    target = generated_target_for(CGI.unescapeHTML(match.first))
    internal_targets << [path.relative_path_from(SITE).to_s, target] if target
  end
end

internal_targets.each do |source, target|
  next if SITE.join(target).exist?

  record(failures, "#{source}: broken internal link to #{target}")
end

private_source_pattern = %r{github\.com/frankxue831/(gm-crypto-rs|repolens-rs|ghrunners)}
Pathname.glob(SITE.join("**/*.html").to_s).each do |path|
  html = path.read
  if html.match?(private_source_pattern)
    record(failures, "#{path.relative_path_from(SITE)}: exposes private or unavailable GitHub source link")
  end
end

if failures.empty?
  puts "Site validation passed"
else
  warn failures.join("\n")
  exit 1
end
```

- [ ] **Step 3: Build and verify the script passes**

Run:

```bash
bundle exec jekyll build
ruby scripts/validate_site.rb
```

Expected: build exits 0 and the script prints `Site validation passed`.

- [ ] **Step 4: Prove the script catches the `CLAUDE.md` regression**

Run:

```bash
mkdir -p _site
cp CLAUDE.md _site/CLAUDE.md
ruby scripts/validate_site.rb
rm _site/CLAUDE.md
```

Expected: validation fails while `_site/CLAUDE.md` exists with `Excluded path was generated: CLAUDE.md`, then the cleanup command removes the temporary file.

- [ ] **Step 5: Re-run validation after cleanup**

Run:

```bash
bundle exec jekyll build
ruby scripts/validate_site.rb
```

Expected: `Site validation passed`.

- [ ] **Step 6: Commit**

```bash
git add scripts/validate_site.rb
git commit -m "test: add generated site validation"
```

## Task 5: Add GitHub Actions Site Validation

**Files:**
- Create: `.github/workflows/site.yml`

- [ ] **Step 1: Confirm there is no site workflow**

Run:

```bash
test ! -e .github/workflows/site.yml
```

Expected: command exits 0.

- [ ] **Step 2: Create `.github/workflows/site.yml`**

```yaml
name: Site

on:
  pull_request:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.3"
          bundler-cache: true

      - name: Run Jekyll doctor
        run: bundle exec jekyll doctor

      - name: Build site
        run: bundle exec jekyll build

      - name: Validate generated site
        run: ruby scripts/validate_site.rb
```

- [ ] **Step 3: Verify workflow syntax is readable YAML**

Run:

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/site.yml"); puts "workflow yaml parsed"'
```

Expected: prints `workflow yaml parsed`.

- [ ] **Step 4: Run the same commands locally**

Run:

```bash
bundle exec jekyll doctor
bundle exec jekyll build
ruby scripts/validate_site.rb
```

Expected: all commands exit 0 and validation prints `Site validation passed`.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/site.yml
git commit -m "ci: validate generated site"
```

## Task 6: Final Verification and Visual Spot Check

**Files:**
- Verify all changed files from Tasks 1-5.

- [ ] **Step 1: Run complete local verification**

Run:

```bash
bundle exec jekyll doctor
bundle exec jekyll build
ruby scripts/validate_site.rb
test ! -e _site/CLAUDE.md
test ! -d _site/docs/superpowers
git diff --check origin/main...HEAD
```

Expected: all commands exit 0.

- [ ] **Step 2: Verify generated metadata and project summaries**

Run:

```bash
rg -n 'application/ld\\+json|SoftwareSourceCode|project-summary|og:image|canonical' _site/index.html _site/zh/index.html _site/projects/gm-crypto-rs/index.html _site/zh/projects/gm-crypto-rs/index.html
```

Expected: `rg` finds JSON-LD, project summary markup, Open Graph image, and canonical metadata.

- [ ] **Step 3: Verify unavailable private source links remain absent**

Run:

```bash
rg -n 'github\\.com/frankxue831/(gm-crypto-rs|repolens-rs|ghrunners)' _site
```

Expected: `rg` exits 1.

- [ ] **Step 4: Start the Jekyll server**

Run:

```bash
bundle exec jekyll serve --host 127.0.0.1 --port 4001
```

Expected: server starts at `http://127.0.0.1:4001/`.

- [ ] **Step 5: Browser spot-check layouts**

Use the in-app browser to inspect these pages at desktop and mobile widths:

```text
http://127.0.0.1:4001/
http://127.0.0.1:4001/zh/
http://127.0.0.1:4001/about/
http://127.0.0.1:4001/zh/about/
http://127.0.0.1:4001/projects/
http://127.0.0.1:4001/zh/projects/
http://127.0.0.1:4001/projects/gm-crypto-rs/
http://127.0.0.1:4001/zh/projects/gm-crypto-rs/
```

Expected: no horizontal overflow, no header overlap, project summary block is readable, and existing page rhythm remains intact.

- [ ] **Step 6: Stop the Jekyll server**

Stop the running `bundle exec jekyll serve` process with `Ctrl-C`.

- [ ] **Step 7: Final status check**

Run:

```bash
git status -sb
git log --oneline --decorate --max-count 8
```

Expected: branch is clean and shows the task commits on `codex/site-quality-foundation`.
