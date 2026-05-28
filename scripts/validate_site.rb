#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "json"
require "pathname"
require "set"
require "uri"
require "yaml"

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

public_release_labels = PROJECTS.select { |project| project["release_source"] == "public_tag" }.map { |project| project["release"] }
private_release_labels = PROJECTS.reject { |project| project["release_source"] == "public_tag" }.map { |project| project["release"] }.compact
home_pages = %w[index.html zh/index.html]

(core_pages.keys + project_pages).each do |relative|
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
# The trailing (?![\w-]) word-boundary keeps `gm-crypto-rs` from also
# matching the genuinely-public `gm-crypto-rs-demo` repo (a prefix match).
private_source_pattern = %r{github\.com/frankxue831/(gm-crypto-rs|repolens-rs|ghrunners)(?![\w-])}
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

if failures.empty?
  puts "Site validation passed"
else
  warn failures.join("\n")
  warn "Hint: run `bundle exec jekyll build` before validation; `jekyll serve` can leave localhost URLs in _site."
  exit 1
end
