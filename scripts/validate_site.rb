#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "json"
require "pathname"
require "set"
require "uri"
require "yaml"

# Read everything as UTF-8 regardless of the caller's locale. The site has CJK
# content; under an ASCII locale Pathname#read would raise "invalid byte
# sequence in US-ASCII" and abort before any check runs. Binary reads
# (PNG header via binread) are unaffected. Makes the validator self-contained.
Encoding.default_external = Encoding::UTF_8

ROOT = Pathname.new(__dir__).parent
SITE = ROOT.join("_site")
HOST = "www.frankxue.dev"
BASE_URL = "https://#{HOST}"
PROJECTS = YAML.load_file(ROOT.join("_data/projects.yml"))

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

def expected_url_for(relative)
  path = relative.sub(/index\.html\z/, "")
  "#{BASE_URL}/#{path}"
end

def alternate_pairs(html)
  html.scan(%r{<link rel="alternate" hreflang="([^"]+)" href="([^"]+)">}).map do |hreflang, href|
    [hreflang, href]
  end.to_set
end

def internal_href?(href)
  href.start_with?("/") ||
    href.start_with?("#{BASE_URL}/") ||
    href.start_with?("https://#{HOST}/") ||
    href.start_with?("http://#{HOST}/") ||
    !href.match?(%r{\A[a-z][a-z0-9+.-]*:}i)
end

def generated_target_for(href)
  return nil if href.empty? || href.start_with?("#", "mailto:", "tel:")

  uri = URI.parse(href)
  return nil if uri.scheme && !%w[http https].include?(uri.scheme)
  return nil if uri.host && uri.host != HOST

  path = uri.path
  path = "/" if path.empty?

  relative = if path.end_with?("/")
    path == "/" ? "index.html" : "#{path.delete_prefix("/")}index.html"
  else
    path.delete_prefix("/")
  end

  target_path = SITE.join(relative).cleanpath
  site_root = SITE.cleanpath.to_s
  return :outside_site unless target_path.to_s == site_root || target_path.to_s.start_with?("#{site_root}/")

  relative
rescue URI::InvalidURIError
  internal_href?(href) ? :invalid_internal_href : nil
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
  SITE.join("docs/superpowers"),
  SITE.join("scripts")
].each do |path|
  record(failures, "Excluded path was generated: #{path.relative_path_from(SITE)}") if path.exist?
end

core_pages = {
  "index.html" => {
    alternates: [
      { hreflang: "en", href: "#{BASE_URL}/" },
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/" },
      { hreflang: "x-default", href: "#{BASE_URL}/" }
    ]
  },
  "zh/index.html" => {
    alternates: [
      { hreflang: "en", href: "#{BASE_URL}/" },
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/" },
      { hreflang: "x-default", href: "#{BASE_URL}/" }
    ]
  },
  "about/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/about/" },
      { hreflang: "en", href: "#{BASE_URL}/about/" }
    ]
  },
  "zh/about/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/about/" },
      { hreflang: "en", href: "#{BASE_URL}/about/" }
    ]
  },
  "projects/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/projects/" },
      { hreflang: "en", href: "#{BASE_URL}/projects/" }
    ]
  },
  "zh/projects/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/projects/" },
      { hreflang: "en", href: "#{BASE_URL}/projects/" }
    ]
  },
  "contact/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/contact/" },
      { hreflang: "en", href: "#{BASE_URL}/contact/" }
    ]
  },
  "zh/contact/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/contact/" },
      { hreflang: "en", href: "#{BASE_URL}/contact/" }
    ]
  },
  "notes/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/notes/" },
      { hreflang: "en", href: "#{BASE_URL}/notes/" }
    ]
  },
  "zh/notes/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/notes/" },
      { hreflang: "en", href: "#{BASE_URL}/notes/" }
    ]
  }
}

project_pages = %w[
  projects/gm-crypto-rs/index.html
  projects/repolens-rs/index.html
  projects/ghrunners/index.html
  zh/projects/gm-crypto-rs/index.html
  zh/projects/repolens-rs/index.html
  zh/projects/ghrunners/index.html
]

# Individual notes (collection docs). Run through the same per-page SEO loop.
note_pages = %w[
  notes/starting-a-notebook/index.html
  zh/notes/starting-a-notebook/index.html
]

public_release_labels = PROJECTS.select { |project| project["release_source"] == "public_tag" }.map { |project| project["release"] }
private_release_labels = PROJECTS.reject { |project| project["release_source"] == "public_tag" }.map { |project| project["release"] }.compact
home_pages = %w[index.html zh/index.html]

(core_pages.keys + project_pages + note_pages).each do |relative|
  path = SITE.join(relative)
  html = read_file(path, failures)
  next if html.empty?

  expected_canonical = expected_url_for(relative)
  canonical_pattern = %r{<link rel="canonical" href="#{Regexp.escape(expected_canonical)}"\s*/?>}
  record(failures, "#{relative}: missing canonical URL #{expected_canonical}") unless html.match?(canonical_pattern)
  record(failures, "#{relative}: missing meta description") unless html.match?(%r{<meta name="description" content="[^"]+"})
  record(failures, "#{relative}: missing Open Graph title") unless html.match?(%r{<meta property="og:title" content="[^"]+"})
  record(failures, "#{relative}: missing Open Graph description") unless html.match?(%r{<meta property="og:description" content="[^"]+"})
  # Share card must be a raster PNG — SVG og:images do not render in
  # link previews on iMessage, Slack, X, LinkedIn, WhatsApp, or Discord.
  record(failures, "#{relative}: missing PNG Open Graph image") unless html.match?(%r{<meta property="og:image" content="#{Regexp.escape(BASE_URL)}/assets/img/social-card\.png"})
  record(failures, "#{relative}: og:image must not be an SVG (link previews won't render it)") if html.match?(%r{<meta property="og:image" content="[^"]+\.svg"})
  record(failures, "#{relative}: missing apple-touch-icon") unless html.match?(%r{<link rel="apple-touch-icon"[^>]*href="/assets/img/apple-touch-icon\.png"})
  record(failures, "#{relative}: missing web manifest link") unless html.include?(%(<link rel="manifest" href="/site.webmanifest">))

  docs = json_ld_documents(html, failures, relative)
  graph_types = docs.flat_map { |doc| Array(doc["@graph"]).map { |node| node["@type"] } }
  record(failures, "#{relative}: missing WebPage JSON-LD") unless graph_types.include?("WebPage")
  record(failures, "#{relative}: missing Person JSON-LD") unless graph_types.include?("Person")
  record(failures, "#{relative}: missing WebSite JSON-LD") unless graph_types.include?("WebSite")
end

core_pages.each do |relative, config|
  html = read_file(SITE.join(relative), failures)
  expected_pairs = config[:alternates].map { |alternate| [alternate[:hreflang], alternate[:href]] }.to_set
  actual_pairs = alternate_pairs(html)
  unless actual_pairs == expected_pairs
    record(failures, "#{relative}: alternate set mismatch expected #{expected_pairs.to_a.inspect} got #{actual_pairs.to_a.inspect}")
  end
end

project_pages.each do |relative|
  html = read_file(SITE.join(relative), failures)
  docs = json_ld_documents(html, failures, relative)
  graph_types = docs.flat_map { |doc| Array(doc["@graph"]).map { |node| node["@type"] } }
  record(failures, "#{relative}: missing SoftwareSourceCode JSON-LD") unless graph_types.include?("SoftwareSourceCode")
  record(failures, "#{relative}: missing project summary") unless html.include?(%(class="project-summary"))
end

home_pages.each do |relative|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?

  record(failures, "#{relative}: missing hero proof ledger") unless html.include?(%(class="hero-proof"))
  public_release_labels.each do |release|
    record(failures, "#{relative}: missing public release label #{release}") unless html.include?(release)
  end
  private_release_labels.each do |release|
    record(failures, "#{relative}: exposes private or local release label #{release}") if html.include?(release)
  end
end

internal_targets = Set.new
Pathname.glob(SITE.join("**/*.html").to_s).each do |path|
  html = path.read
  html.scan(%r{<(?:a|link)\b[^>]+\bhref=(['"])(.*?)\1}i).each do |match|
    href = CGI.unescapeHTML(match[1])
    source = path.relative_path_from(SITE).to_s
    target = generated_target_for(href)
    if target == :outside_site
      record(failures, "#{source}: internal link escapes _site: #{href}")
    elsif target == :invalid_internal_href
      record(failures, "#{source}: invalid internal href: #{href}")
    elsif target
      internal_targets << [source, target]
    end
  end
end

internal_targets.each do |source, target|
  next if SITE.join(target).exist?

  record(failures, "#{source}: broken internal link to #{target}")
end

# Private/unreachable source repos that must never be linked publicly.
# `gm-crypto-rs` went public (repo + crate + demo all visitor-reachable), so it
# is no longer forbidden — only the still-private repos are. The trailing
# (?![\w-]) word-boundary keeps these from prefix-matching a future public
# `<name>-demo`/`-foo` sibling.
private_source_pattern = %r{github\.com/frankxue831/(repolens-rs|ghrunners)(?![\w-])}
Pathname.glob(SITE.join("**/*.html").to_s).each do |path|
  html = path.read
  if html.match?(/mailto:/i) || html.match?(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i)
    record(failures, "#{path.relative_path_from(SITE)}: exposes public email")
  end
  if html.match?(private_source_pattern)
    record(failures, "#{path.relative_path_from(SITE)}: exposes private or unavailable GitHub source link")
  end
end

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
{ "index.html" => "auditable tools", "zh/index.html" => "可审计" }.each do |relative, needle|
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

# --- Share/icon assets (product polish layer) ---
# The referenced share card, favicons, touch icon, and manifest must
# actually be generated, and the social card must be the right dimensions.
%w[
  assets/img/social-card.png
  assets/img/apple-touch-icon.png
  assets/img/icon-192.png
  assets/img/icon-512.png
  assets/img/favicon-32.png
  assets/img/favicon-16.png
  site.webmanifest
].each do |rel|
  record(failures, "Missing share/icon asset: #{rel}") unless SITE.join(rel).exist?
end

card = SITE.join("assets/img/social-card.png")
if card.exist?
  # PNG IHDR: width/height are big-endian uint32 at byte offsets 16 and 20.
  header = card.binread(24)
  if header && header.byteslice(0, 8) == "\x89PNG\r\n\x1a\n".b
    width = header.byteslice(16, 4).unpack1("N")
    height = header.byteslice(20, 4).unpack1("N")
    unless width == 1200 && height == 630
      record(failures, "social-card.png must be 1200x630 (Open Graph), got #{width}x#{height}")
    end
  else
    record(failures, "social-card.png is not a valid PNG")
  end
end

manifest = SITE.join("site.webmanifest")
if manifest.exist?
  begin
    data = JSON.parse(manifest.read)
    record(failures, "site.webmanifest: missing name") unless data["name"].to_s != ""
    icons = Array(data["icons"])
    record(failures, "site.webmanifest: needs 192px and 512px icons") unless
      icons.any? { |i| i["sizes"] == "192x192" } && icons.any? { |i| i["sizes"] == "512x512" }
    icons.each do |icon|
      src = icon["src"].to_s.sub(%r{\A/}, "")
      record(failures, "site.webmanifest: icon missing on disk: #{icon["src"]}") unless src.empty? || SITE.join(src).exist?
    end
  rescue JSON::ParserError => error
    record(failures, "site.webmanifest: invalid JSON (#{error.message})")
  end
end

# --- Light/dark theme toggle ---
# theme.js must ship, and every page must (1) carry the pre-paint script that
# applies data-theme before first paint (no FOUC), (2) link theme.js, (3) carry
# both media-queried theme-color metas (light + dark), and (4) include the
# theme toggle button. The dark token block must exist in the CSS.
record(failures, "Missing theme script: assets/js/theme.js") unless SITE.join("assets/js/theme.js").exist?

css_path = SITE.join("assets/css/style.css")
if css_path.exist?
  css = css_path.read
  record(failures, "style.css: missing [data-theme=\"dark\"] token block") unless css.include?(%([data-theme="dark"]))
  # Fail-open: a dark-OS reader with JS disabled / pre-paint script throwing
  # must still see dark — needs the @media (prefers-color-scheme: dark) +
  # :not([data-theme]) fallback that mirrors the dark tokens.
  unless css.match?(/@media\s*\(prefers-color-scheme:\s*dark\)[^{]*\{\s*:root:not\(\[data-theme\]\)/)
    record(failures, "style.css: missing no-JS dark fallback (@media prefers-color-scheme + :root:not([data-theme]))")
  end
end

Pathname.glob(SITE.join("**/*.html").to_s).each do |path|
  html = path.read
  source = path.relative_path_from(SITE).to_s
  record(failures, "#{source}: missing theme.js include") unless html.include?("/assets/js/theme.js")
  record(failures, "#{source}: missing pre-paint theme gate") unless html.include?("frankxue.theme")
  record(failures, "#{source}: missing light theme-color meta") unless
    html.match?(%r{<meta name="theme-color" content="#f5f1e8" media="\(prefers-color-scheme: light\)">})
  record(failures, "#{source}: missing dark theme-color meta") unless
    html.match?(%r{<meta name="theme-color" content="#1a1814" media="\(prefers-color-scheme: dark\)">})
  record(failures, "#{source}: missing theme toggle button") unless html.include?(%(class="theme-toggle"))
  # The theme gate must run before the motion gate so a stored dark choice
  # is applied before motion classes / reveal hidden-state paint.
  theme_at = html.index("frankxue.theme")
  motion_at = html.index("classList.add('motion')")
  if theme_at && motion_at && theme_at > motion_at
    record(failures, "#{source}: theme gate must precede motion gate (FOUC risk)")
  end
end

# --- Contents rail ("On this page") scroll-spy ---
# contents.js must ship and load site-wide (it self-guards to detail pages).
# The CSS must carry the rail styles, the sticky-header scroll-margin, and the
# print rule that drops the rail. The bilingual label must exist in i18n and be
# emitted as data-toc-label on the detail-page bodies the rail attaches to.
record(failures, "Missing contents script: assets/js/contents.js") unless SITE.join("assets/js/contents.js").exist?

Pathname.glob(SITE.join("**/*.html").to_s).each do |path|
  html = path.read
  source = path.relative_path_from(SITE).to_s
  record(failures, "#{source}: missing contents.js include") unless html.include?("/assets/js/contents.js")
end

if css_path.exist?
  css = css_path.read
  record(failures, "style.css: missing contents-rail grid (.section.has-toc)") unless css.include?(".section.has-toc")
  record(failures, "style.css: missing contents-rail link style (.toc__link)") unless css.include?(".toc__link")
  record(failures, "style.css: missing scroll-margin-top on detail headings") unless
    css.match?(/\.project-detail h2\s*\{[^}]*scroll-margin-top/)
  record(failures, "style.css: missing print rule hiding the contents rail") unless
    css.match?(/@media print\s*\{\s*\.toc\s*\{\s*display:\s*none/)
end

i18n = YAML.load_file(ROOT.join("_data/i18n.yml"))
%w[en zh].each do |lang|
  label = i18n.dig(lang, "toc", "label").to_s
  record(failures, "i18n.yml: missing #{lang}.toc.label") if label.empty?
end

# Detail-page bodies must carry the localized rail label for contents.js to read.
project_pages.each do |relative|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  record(failures, "#{relative}: missing data-toc-label on body") unless
    html.match?(/<body[^>]*\sdata-toc-label="[^"]+"/)
end

# --- Smooth theme-toggle transition ---
# theme.js adds a transient `theme-anim` class for an explicit switch; the CSS
# must carry the scoped colour transition and its reduced-motion null-out.
if css_path.exist?
  css = css_path.read
  record(failures, "style.css: missing theme-anim transition block") unless
    css.match?(/html\.theme-anim[^{]*\{[^}]*transition:[^}]*background-color/m)
  record(failures, "style.css: missing reduced-motion theme-anim null-out") unless
    css.match?(/prefers-reduced-motion:\s*reduce\)\s*\{[^}]*\.theme-anim[^}]*transition:\s*none/m)
end
record(failures, "theme.js: missing theme-anim hook") unless
  SITE.join("assets/js/theme.js").read.include?("theme-anim")

# --- Copy-to-clipboard install command (gm-crypto-rs only) ---
# copy.js must ship and load site-wide. The gm-crypto-rs pages (EN + ZH) must
# carry the install block; the private/local projects must NOT — only the
# public crate gets an install command (source-of-truth boundary).
record(failures, "Missing copy script: assets/js/copy.js") unless SITE.join("assets/js/copy.js").exist?

Pathname.glob(SITE.join("**/*.html").to_s).each do |path|
  html = path.read
  source = path.relative_path_from(SITE).to_s
  record(failures, "#{source}: missing copy.js include") unless html.include?("/assets/js/copy.js")
end

%w[projects/gm-crypto-rs/index.html zh/projects/gm-crypto-rs/index.html].each do |relative|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  record(failures, "#{relative}: missing install command") unless html.include?("cargo add gmcrypto-core")
  record(failures, "#{relative}: missing copy button") unless html.include?(%(data-copy-target="install-cmd"))
end

# --- Project case-study structure (per 2026-05-30-project-case-study spec) ---
# Each featured page is a six-section case study with an anti-relabeling
# discipline: section shape + order, a per-decision cost cue (every decision
# names a tradeoff), and no overclaims. gm-crypto-rs (public) additionally checks
# the dudect caveat, the version history living under Evidence, and its public
# source link. The private siblings instead carry load-bearing honest-status
# phrases as regression guards, and must NOT show a public source link (already
# enforced by private_source_pattern above). Headings match built HTML
# (note the `&amp;` entity).
case_study = {
  "projects/gm-crypto-rs/index.html" => {
    headings: ["<h2>What it is</h2>", "<h2>The problem</h2>",
               "<h2>Constraints &amp; key decisions</h2>", "<h2>Evidence</h2>",
               "<h2>Next</h2>", "<h2>What it isn't</h2>"],
    cost: "Cost:", overclaims: %w[production-ready guaranteed secure],
    caveat: "detection events", version_before: ["<h2>Next</h2>", "v0.16.0"],
    source_link: %(github.com/frankxue831/gm-crypto-rs")
  },
  "zh/projects/gm-crypto-rs/index.html" => {
    headings: ["<h2>是什么</h2>", "<h2>要解决的问题</h2>", "<h2>约束与关键决策</h2>",
               "<h2>证据</h2>", "<h2>下一步</h2>", "<h2>它不是什么</h2>"],
    cost: "代价：", overclaims: ["生产就绪", "保证安全", "绝对常量时间"],
    caveat: "检测事件", version_before: ["<h2>下一步</h2>", "v0.16.0"],
    source_link: %(github.com/frankxue831/gm-crypto-rs")
  },
  "projects/repolens-rs/index.html" => {
    headings: ["<h2>What it is</h2>", "<h2>The problem</h2>",
               "<h2>Constraints &amp; key decisions</h2>", "<h2>Evidence</h2>",
               "<h2>Next</h2>", "<h2>What it isn't</h2>"],
    cost: "Cost:", overclaims: %w[production-ready guaranteed secure],
    must_include: ["warnings-only", "not the typed graph", "scaffolding"]
  },
  "zh/projects/repolens-rs/index.html" => {
    headings: ["<h2>是什么</h2>", "<h2>要解决的问题</h2>", "<h2>约束与关键决策</h2>",
               "<h2>证据</h2>", "<h2>下一步</h2>", "<h2>它不是什么</h2>"],
    cost: "代价：", overclaims: ["生产就绪", "保证安全"],
    must_include: ["只给 warning", "不是那张类型化记忆图", "脚手架"]
  }
}
case_study.each do |relative, spec|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?

  # All six headings present, in order.
  positions = spec[:headings].map { |h| [h, html.index(h)] }
  missing = positions.select { |_, i| i.nil? }.map(&:first)
  record(failures, "#{relative}: missing case-study heading(s): #{missing.join(', ')}") unless missing.empty?
  if missing.empty?
    idxs = positions.map(&:last)
    record(failures, "#{relative}: case-study headings out of order") unless idxs == idxs.sort
  end

  # Every decision must name a tradeoff: at least four visible cost cues.
  cost_count = html.scan(spec[:cost]).length
  record(failures, "#{relative}: only #{cost_count} #{spec[:cost].inspect} cost cues (need >= 4, one per decision)") if cost_count < 4

  # No overclaims (whole-word for the ASCII set).
  spec[:overclaims].each do |word|
    pattern = word.match?(/\A[\x00-\x7F]+\z/) ? /\b#{Regexp.escape(word)}\b/ : /#{Regexp.escape(word)}/
    record(failures, "#{relative}: overclaim #{word.inspect} present") if html.match?(pattern)
  end

  # Load-bearing phrases that must survive a rewrite (private honest-status guards).
  # Normalize whitespace first so a phrase wrapped across source lines still matches.
  normalized = html.gsub(/\s+/, " ")
  Array(spec[:must_include]).each do |phrase|
    record(failures, "#{relative}: required phrase #{phrase.inspect} missing") unless normalized.include?(phrase)
  end

  # gm-crypto-only: the dudect non-proof caveat survives the reframe.
  if spec[:caveat]
    record(failures, "#{relative}: dudect detection-event caveat missing") unless html.include?(spec[:caveat])
  end

  # gm-crypto-only: version history lives under Evidence (release token appears
  # before the Next heading, and the version-grid precedes it).
  if spec[:version_before]
    next_h2, version = spec[:version_before]
    next_i = html.index(next_h2)
    grid_i = html.index("version-grid")
    record(failures, "#{relative}: version-grid not before Next (history must live under Evidence)") if grid_i && next_i && grid_i >= next_i
    record(failures, "#{relative}: release #{version} missing from Evidence (before Next)") unless next_i && (html.index(version) || 1 << 60) < next_i
  end

  # gm-crypto-only: the now-public source link must be present.
  if spec[:source_link]
    record(failures, "#{relative}: missing public source link") unless html.include?(spec[:source_link])
  end
end

%w[
  projects/repolens-rs/index.html projects/ghrunners/index.html
  zh/projects/repolens-rs/index.html zh/projects/ghrunners/index.html
].each do |relative|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  # Key on the install-block markers, not the bare "cargo add" string, so a
  # private page that merely mentions the command in prose can't false-trip
  # this guard — only an actual install block is forbidden.
  if html.include?(%(class="install")) || html.include?("data-copy-target")
    record(failures, "#{relative}: private/local project must not show an install block")
  end
end

%w[en zh].each do |lang|
  %w[label copy copied aria].each do |key|
    record(failures, "i18n.yml: missing #{lang}.install.#{key}") if i18n.dig(lang, "install", key).to_s.empty?
  end
end

if css_path.exist? && !css_path.read.include?(".install__copy")
  record(failures, "style.css: missing .install copy-button styles")
end

# --- Keyboard-focus parity for interactive affordances ---
# The rich hover affordances must have :focus-visible counterparts so keyboard
# users get the same feedback as the mouse (matching the nav-link pattern).
if css_path.exist?
  css = css_path.read
  {
    ".work-list__row:focus-visible"  => "work-list row focus parity",
    ".hero__cta:focus-visible"       => "hero CTA focus parity",
    ".btn:focus-visible"             => "button focus parity"
  }.each do |selector, label|
    record(failures, "style.css: missing #{label} (#{selector})") unless css.include?(selector)
  end
end

# --- Writing/Notes section ---
# The collection feed must be non-empty (it was empty before — no _posts), the
# notes index must list notes, each note page must carry both-language
# hreflang, and the i18n strings must exist.
feed = read_file(SITE.join("feed.xml"), failures)
record(failures, "feed.xml: no <entry> (notes feed is empty)") unless feed.include?("<entry")

%w[notes/index.html zh/notes/index.html].each do |relative|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  record(failures, "#{relative}: notes index lists no notes") unless html.include?(%(class="work-list__item))
end

note_pages.each do |relative|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  record(failures, "#{relative}: missing en hreflang alternate") unless html.match?(%r{<link rel="alternate" hreflang="en" href="#{Regexp.escape(BASE_URL)}/notes/[^"]+">})
  record(failures, "#{relative}: missing zh-CN hreflang alternate") unless html.match?(%r{<link rel="alternate" hreflang="zh-CN" href="#{Regexp.escape(BASE_URL)}/zh/notes/[^"]+">})
end

i18n = YAML.load_file(ROOT.join("_data/i18n.yml"))
%w[en zh].each do |lang|
  record(failures, "i18n.yml: missing #{lang}.nav.writing") if i18n.dig(lang, "nav", "writing").to_s.empty?
  %w[all read_more none].each do |key|
    record(failures, "i18n.yml: missing #{lang}.notes.#{key}") if i18n.dig(lang, "notes", key).to_s.empty?
  end
end

# --- WCAG AA contrast guard ---
# --fg-subtle styles normal-size meta text (eyebrows, section numbers, tags,
# years), so it must clear 4.5:1 on --bg in BOTH themes. Regression guard for
# the a11y fix (was 2.42:1 light / 3.06:1 dark). Parses the token values from
# the :root and [data-theme="dark"] blocks and computes the WCAG ratio.
if css_path.exist?
  css = css_path.read
  lin = ->(c) { c /= 255.0; c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055)**2.4 }
  lum = ->(hex) { r, g, b = hex.delete("#").scan(/../).map { |x| x.to_i(16) }; 0.2126 * lin.(r) + 0.7152 * lin.(g) + 0.0722 * lin.(b) }
  ratio = ->(a, b) { l1 = lum.(a); l2 = lum.(b); ([l1, l2].max + 0.05) / ([l1, l2].min + 0.05) }
  hex_in = ->(block, var) { block && block[/--#{var}:\s*(#[0-9a-fA-F]{6})/, 1] }
  {
    "light" => css[/:root\s*\{(.*?)\n\}/m, 1],
    "dark"  => css[/\[data-theme="dark"\]\s*\{(.*?)\n\}/m, 1]
  }.each do |theme, block|
    bg = hex_in.(block, "bg")
    # Tokens used as normal-size text → must clear AA 4.5:1 on --bg.
    # (--status-released is also used as text in .install__copy.is-copied.)
    %w[fg-subtle status-released].each do |var|
      fg = hex_in.(block, var)
      if bg && fg
        r = ratio.(fg, bg)
        record(failures, "style.css: #{theme} --#{var} #{fg} on --bg #{bg} = #{r.round(2)}:1, below WCAG AA 4.5:1") if r < 4.5
      else
        record(failures, "style.css: could not extract #{theme} --bg/--#{var} for contrast check")
      end
    end
  end
end

# --- Self-hosted fonts: no third-party Google origin (privacy) ---
# Fonts are served from this origin; no page may reach fonts.googleapis.com /
# fonts.gstatic.com. The self-hosted @font-face must be present with
# font-display: swap, every woff2 the CSS references must exist on disk, each
# preloaded font link must resolve, and --serif must keep a system CJK serif
# (Noto Serif SC is no longer downloaded, so CJK display relies on the fallback).
Pathname.glob(SITE.join("**/*.html").to_s).each do |path|
  html = path.read
  if html.match?(%r{fonts\.(?:googleapis|gstatic)\.com})
    record(failures, "#{path.relative_path_from(SITE)}: references Google Fonts (fonts.googleapis/gstatic.com) — fonts must be self-hosted")
  end
end

if css_path.exist?
  css = css_path.read
  record(failures, "style.css: missing @font-face (self-hosted fonts)") unless css.include?("@font-face")
  record(failures, "style.css: missing font-display: swap on self-hosted fonts") unless css.match?(/font-display:\s*swap/)
  font_srcs = css.scan(%r{url\(['"]?(/assets/fonts/[^'")]+\.woff2)['"]?\)}).flatten.uniq
  record(failures, "style.css: no /assets/fonts/*.woff2 @font-face src found") if font_srcs.empty?
  font_srcs.each do |src|
    record(failures, "style.css: @font-face src missing on disk: #{src}") unless SITE.join(src.sub(%r{\A/}, "")).exist?
  end
  serif = css[/--serif:\s*([^;]+);/, 1]
  unless serif && serif.match?(/Songti SC|STSong|SimSun|Noto Serif SC/)
    record(failures, "style.css: --serif lost its system CJK serif fallback")
  end
end

Pathname.glob(SITE.join("**/*.html").to_s).each do |path|
  html = path.read
  html.scan(/<link\b[^>]*\bas="font"[^>]*>/i).each do |tag|
    next unless tag.include?('rel="preload"')
    href = tag[/href="([^"]+)"/, 1]
    next unless href
    rel = href.sub(%r{\Ahttps?://[^/]+}, "").sub(%r{\A/}, "")
    record(failures, "#{path.relative_path_from(SITE)}: preload font missing on disk: #{href}") unless SITE.join(rel).exist?
  end
end

# --- Security hardening: CSP, referrer policy, no inline styles, JSON-LD safety ---
require "digest"

# The CSP script-src must pin the sha256 of each inline pre-paint gate script.
# Recompute them from the built output: if a gate script is edited without
# updating the hash in head.html, this fails (self-guarding). The gates are the
# only attribute-less <script> blocks (JSON-LD has type=, others have src=).
sample = read_file(SITE.join("index.html"), failures)
unless sample.empty?
  gate_scripts = sample.scan(%r{<script>(.*?)</script>}m).flatten
  record(failures, "head: expected 2 inline gate scripts, found #{gate_scripts.length}") unless gate_scripts.length == 2
  csp = sample[/content="(default-src[^"]*)"/, 1].to_s
  record(failures, "head: missing/!malformed CSP meta (no default-src)") if csp.empty?
  gate_scripts.each_with_index do |body, i|
    digest = Digest::SHA256.base64digest(body)
    record(failures, "CSP: script-src missing 'sha256-#{digest}' for inline gate script ##{i + 1}") unless csp.include?("sha256-#{digest}")
  end
end

# Every page must carry the CSP + referrer metas, no inline style attributes
# (strict style-src), and no </script breakout inside JSON-LD.
Pathname.glob(SITE.join("**/*.html").to_s).each do |path|
  html = path.read
  source = path.relative_path_from(SITE).to_s
  record(failures, "#{source}: missing Content-Security-Policy meta") unless html.include?(%(http-equiv="Content-Security-Policy"))
  record(failures, "#{source}: missing referrer policy meta") unless html.include?(%(name="referrer"))
  record(failures, "#{source}: inline style= attribute (breaks strict style-src CSP)") if html.match?(/\sstyle="/)
  # JSON-LD breakout guard: the content up to the FIRST </script> (what the
  # browser treats as the script body) must be valid, complete JSON. A value
  # containing </script> closes the element early and truncates it, so the
  # parse fails. The template \u-escapes <,>,& so this cannot happen in normal
  # output — this check makes a regression impossible to ship.
  html.scan(%r{<script type="application/ld\+json">\s*(.*?)\s*</script>}m).flatten.each do |ld|
    begin
      JSON.parse(ld)
    rescue JSON::ParserError
      record(failures, "#{source}: JSON-LD does not parse up to first </script> (possible breakout)")
    end
  end
end

# Project URLs come from a data file; require https (no javascript:/data: scheme).
PROJECTS.each do |project|
  %w[repo_url crate_url docs_url].each do |key|
    url = project[key].to_s
    next if url.empty?
    record(failures, "projects.yml: #{project["slug"]} #{key} is not https: #{url}") unless url.start_with?("https://")
  end
end

if failures.empty?
  puts "Site validation passed"
else
  warn failures.join("\n")
  warn "Hint: run `bundle exec jekyll build` before validation; `jekyll serve` can leave localhost URLs in _site."
  exit 1
end
