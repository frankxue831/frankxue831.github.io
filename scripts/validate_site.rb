#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "date"
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
EXTERNAL_SUBSITE_PREFIX = "/gm-crypto-web/"
PROJECTS = YAML.load_file(ROOT.join("_data/projects.yml"))
I18N = YAML.load_file(ROOT.join("_data/i18n.yml"))

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
  # /gm-crypto-web/ is served by the separate frankxue831/gm-crypto-web Pages repo,
  # so it is not in this site's _site. Exact prefix only; QA checks it live by hand.
  return nil if path.start_with?(EXTERNAL_SUBSITE_PREFIX)

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

def json_ld_graph(html, failures, source)
  json_ld_documents(html, failures, source).flat_map { |document| Array(document["@graph"]) }
end

def graph_nodes_of_type(graph, type)
  graph.select { |node| node["@type"] == type }
end

def png_dimensions(path)
  header = path.binread(24)
  return nil unless header && header.byteslice(0, 8) == "\x89PNG\r\n\x1a\n".b

  [header.byteslice(16, 4).unpack1("N"), header.byteslice(20, 4).unpack1("N")]
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
      { hreflang: "en", href: "#{BASE_URL}/about/" },
      { hreflang: "x-default", href: "#{BASE_URL}/about/" }
    ]
  },
  "zh/about/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/about/" },
      { hreflang: "en", href: "#{BASE_URL}/about/" },
      { hreflang: "x-default", href: "#{BASE_URL}/about/" }
    ]
  },
  "projects/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/projects/" },
      { hreflang: "en", href: "#{BASE_URL}/projects/" },
      { hreflang: "x-default", href: "#{BASE_URL}/projects/" }
    ]
  },
  "zh/projects/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/projects/" },
      { hreflang: "en", href: "#{BASE_URL}/projects/" },
      { hreflang: "x-default", href: "#{BASE_URL}/projects/" }
    ]
  },
  "contact/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/contact/" },
      { hreflang: "en", href: "#{BASE_URL}/contact/" },
      { hreflang: "x-default", href: "#{BASE_URL}/contact/" }
    ]
  },
  "zh/contact/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/contact/" },
      { hreflang: "en", href: "#{BASE_URL}/contact/" },
      { hreflang: "x-default", href: "#{BASE_URL}/contact/" }
    ]
  },
  "notes/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/notes/" },
      { hreflang: "en", href: "#{BASE_URL}/notes/" },
      { hreflang: "x-default", href: "#{BASE_URL}/notes/" }
    ]
  },
  "zh/notes/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/notes/" },
      { hreflang: "en", href: "#{BASE_URL}/notes/" },
      { hreflang: "x-default", href: "#{BASE_URL}/notes/" }
    ]
  },
  "projects/gm-crypto-rs/releases/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/projects/gm-crypto-rs/releases/" },
      { hreflang: "en", href: "#{BASE_URL}/projects/gm-crypto-rs/releases/" },
      { hreflang: "x-default", href: "#{BASE_URL}/projects/gm-crypto-rs/releases/" }
    ]
  },
  "zh/projects/gm-crypto-rs/releases/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/projects/gm-crypto-rs/releases/" },
      { hreflang: "en", href: "#{BASE_URL}/projects/gm-crypto-rs/releases/" },
      { hreflang: "x-default", href: "#{BASE_URL}/projects/gm-crypto-rs/releases/" }
    ]
  },
  "colophon/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/colophon/" },
      { hreflang: "en", href: "#{BASE_URL}/colophon/" },
      { hreflang: "x-default", href: "#{BASE_URL}/colophon/" }
    ]
  },
  "zh/colophon/index.html" => {
    alternates: [
      { hreflang: "zh-CN", href: "#{BASE_URL}/zh/colophon/" },
      { hreflang: "en", href: "#{BASE_URL}/colophon/" },
      { hreflang: "x-default", href: "#{BASE_URL}/colophon/" }
    ]
  }
}

project_pages = %w[
  projects/gm-crypto-rs/index.html
  projects/repolens-rs/index.html
  projects/ghrunners/index.html
  projects/explainer-engine/index.html
  zh/projects/gm-crypto-rs/index.html
  zh/projects/repolens-rs/index.html
  zh/projects/ghrunners/index.html
  zh/projects/explainer-engine/index.html
]

# Individual notes (collection docs), discovered dynamically so adding a note
# never needs an edit here. Each note builds to <ns>/notes/<slug>/index.html;
# the notes index (notes/index.html) has no <slug> dir, so the glob skips it.
note_pages = (Dir.glob(SITE.join("notes/*/index.html").to_s) +
              Dir.glob(SITE.join("zh/notes/*/index.html").to_s))
  .map { |p| Pathname.new(p).relative_path_from(SITE).to_s }
  .sort

# Bilingual note parity: every EN note must have a ZH counterpart and vice versa.
en_note_slugs = Dir.glob(SITE.join("notes/*/index.html").to_s).map { |p| File.basename(File.dirname(p)) }.sort
zh_note_slugs = Dir.glob(SITE.join("zh/notes/*/index.html").to_s).map { |p| File.basename(File.dirname(p)) }.sort
(en_note_slugs - zh_note_slugs).each do |slug|
  record(failures, "notes: EN note '#{slug}/' has no ZH counterpart (zh/notes/#{slug}/)")
end
(zh_note_slugs - en_note_slugs).each do |slug|
  record(failures, "notes: ZH note '#{slug}/' has no EN counterpart (notes/#{slug}/)")
end

note_specs = {}
Pathname.glob(ROOT.join("_notes/*.md").to_s).each do |path|
  front_matter = path.read[/\A---\s*\n(.*?)\n---\s*\n/m, 1]
  next unless front_matter

  data = YAML.safe_load(front_matter, permitted_classes: [Date, Time], aliases: true)
  permalink = data["permalink"].to_s
  next if permalink.empty?

  relative = "#{permalink.delete_prefix('/')}index.html"
  note_specs[relative] = data
end

note_pages.each do |relative|
  html = read_file(SITE.join(relative), failures)
  graph = json_ld_graph(html, failures, relative)
  articles = graph_nodes_of_type(graph, "BlogPosting")
  spec = note_specs[relative]
  if spec.nil?
    record(failures, "#{relative}: missing source note front matter")
    next
  end

  unless articles.length == 1
    record(failures, "#{relative}: expected exactly one BlogPosting node, found #{articles.length}")
    next
  end

  article = articles.first
  page_url = expected_url_for(relative)
  lang = relative.start_with?("zh/") ? "zh-CN" : "en"
  expected_date = spec["date"].is_a?(Date) ? spec["date"] : Date.parse(spec["date"].to_s)
  published = article["datePublished"].to_s
  record(failures, "#{relative}: BlogPosting @id must end #article") unless article["@id"].to_s == "#{page_url}#article"
  record(failures, "#{relative}: BlogPosting url mismatch") unless article["url"] == page_url
  record(failures, "#{relative}: BlogPosting headline mismatch") unless article["headline"] == spec["title"]
  record(failures, "#{relative}: BlogPosting description missing") if article["description"].to_s.empty?
  unless published.match?(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:Z|[+-]\d{2}:\d{2})\z/) && Date.parse(published) == expected_date
    record(failures, "#{relative}: BlogPosting datePublished #{published.inspect} must be XML Schema date for #{expected_date}")
  end
  record(failures, "#{relative}: BlogPosting inLanguage must be #{lang}") unless article["inLanguage"] == lang
  record(failures, "#{relative}: BlogPosting author must reference #person") unless article.dig("author", "@id").to_s.end_with?("#person")
  record(failures, "#{relative}: BlogPosting isPartOf must reference #website") unless article.dig("isPartOf", "@id").to_s.end_with?("#website")
  record(failures, "#{relative}: BlogPosting mainEntityOfPage must reference #webpage") unless article.dig("mainEntityOfPage", "@id").to_s.end_with?("#webpage")
end

blogposting_negative_pages = %w[
  notes/index.html zh/notes/index.html
  projects/gm-crypto-rs/releases/index.html zh/projects/gm-crypto-rs/releases/index.html
  404.html
] + project_pages
blogposting_negative_pages.each do |relative|
  html = read_file(SITE.join(relative), failures)
  articles = graph_nodes_of_type(json_ld_graph(html, failures, relative), "BlogPosting")
  record(failures, "#{relative}: non-note route must not emit BlogPosting") unless articles.empty?
end

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
  # link previews on iMessage, Slack, X, LinkedIn, WhatsApp, or Discord —
  # and it must match the page's locale. A /zh/ URL shared with the English
  # card previews the Chinese tree as an English site, whatever the title says.
  expected_card = relative.start_with?("zh/") ? "social-card.zh.png" : "social-card.png"
  record(failures, "#{relative}: missing PNG Open Graph image (expected #{expected_card})") unless html.match?(%r{<meta property="og:image" content="#{Regexp.escape(BASE_URL)}/assets/img/#{Regexp.escape(expected_card)}"})
  record(failures, "#{relative}: missing og:image:alt") unless html.match?(%r{<meta property="og:image:alt" content="[^"]+"})
  # 2026-10-12 (PR 2): the share cards carry the home headline, so their alt
  # text must too. A headline change has to regenerate the cards
  # (scripts/build_social_card_{en,zh}.py) and update the alt in _config.yml and
  # the ZH notes' front matter, or this fails.
  expected_alt = relative.start_with?("zh/") ? "借助 AI，做有用的软件。" : "Building useful software with AI."
  card_alt = html[%r{<meta property="og:image:alt" content="([^"]+)"}, 1].to_s
  record(failures, "#{relative}: og:image:alt does not carry the current headline (#{expected_alt})") unless card_alt.include?(expected_alt)
  record(failures, "#{relative}: og:image must not be an SVG (link previews won't render it)") if html.match?(%r{<meta property="og:image" content="[^"]+\.svg"})
  record(failures, "#{relative}: missing apple-touch-icon") unless html.match?(%r{<link rel="apple-touch-icon"[^>]*href="/assets/img/apple-touch-icon\.png"})
  record(failures, "#{relative}: missing web manifest link") unless html.include?(%(<link rel="manifest" href="/site.webmanifest">))

  graph = json_ld_graph(html, failures, relative)
  webpage_nodes = graph_nodes_of_type(graph, "WebPage")
  website_nodes = graph_nodes_of_type(graph, "WebSite")
  person_nodes = graph_nodes_of_type(graph, "Person")
  record(failures, "#{relative}: expected exactly one WebPage JSON-LD node, found #{webpage_nodes.length}") unless webpage_nodes.length == 1
  record(failures, "#{relative}: expected exactly one Person JSON-LD node, found #{person_nodes.length}") unless person_nodes.length == 1
  record(failures, "#{relative}: expected exactly one WebSite JSON-LD node, found #{website_nodes.length}") unless website_nodes.length == 1

  lang = relative.start_with?("zh/") ? "zh" : "en"
  expected_site_description = I18N.dig(lang, "meta", "site_description").to_s
  if website_nodes.length == 1 && website_nodes.first["description"] != expected_site_description
    record(failures, "#{relative}: WebSite description must equal localized #{lang}.meta.site_description")
  end
  # 2026-10-12 (PR 2): About states "Fengxiang (Frank) Xue"; the Person node
  # carries the full name as alternateName while "Frank Xue" stays the name.
  if person_nodes.length == 1
    record(failures, "#{relative}: Person name must stay \"Frank Xue\"") unless person_nodes.first["name"] == "Frank Xue"
    record(failures, "#{relative}: Person alternateName must be \"Fengxiang Xue\"") unless person_nodes.first["alternateName"] == "Fengxiang Xue"
  end
end

core_pages.each do |relative, config|
  html = read_file(SITE.join(relative), failures)
  expected_pairs = config[:alternates].map { |alternate| [alternate[:hreflang], alternate[:href]] }.to_set
  actual_pairs = alternate_pairs(html)
  unless actual_pairs == expected_pairs
    record(failures, "#{relative}: alternate set mismatch expected #{expected_pairs.to_a.inspect} got #{actual_pairs.to_a.inspect}")
  end
end

(core_pages.keys + project_pages + note_pages).each do |relative|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?

  alternate_locales = html.scan(%r{<meta property="og:locale:alternate" content="([^"]+)">}).flatten
  expected_alternate = relative.start_with?("zh/") ? "en_US" : "zh_CN"
  unless alternate_locales == [expected_alternate]
    record(failures, "#{relative}: expected one og:locale:alternate #{expected_alternate}, got #{alternate_locales.inspect}")
  end

  descriptions = html.scan(%r{<meta name="description" content="([^"]*)"}).flatten
  twitter_descriptions = html.scan(%r{<meta name="twitter:description" content="([^"]*)"}).flatten
  unless twitter_descriptions.length == 1 && descriptions.length == 1 &&
         CGI.unescapeHTML(twitter_descriptions.first) == CGI.unescapeHTML(descriptions.first)
    record(failures, "#{relative}: twitter:description must occur once and equal the page description")
  end
end

not_found_html = read_file(SITE.join("404.html"), failures)
unless not_found_html.empty?
  robots = not_found_html.scan(%r{<meta name="robots" content="([^"]+)">}).flatten
  record(failures, "404.html: expected exactly one noindex, follow robots meta") unless robots == ["noindex, follow"]
  record(failures, "404.html: must not emit hreflang alternates") if not_found_html.include?(%(<link rel="alternate" hreflang=))
  record(failures, "404.html: must not emit og:locale:alternate") if not_found_html.include?(%(property="og:locale:alternate"))
end

project_pages.each do |relative|
  html = read_file(SITE.join(relative), failures)
  graph = json_ld_graph(html, failures, relative)
  software_nodes = graph_nodes_of_type(graph, "SoftwareSourceCode")
  slug = Pathname.new(relative).dirname.basename.to_s
  project = PROJECTS.find { |entry| entry["slug"] == slug }
  if project.nil?
    record(failures, "#{relative}: no matching project data row for #{slug}")
  elsif project["public_source"]
    record(failures, "#{relative}: expected exactly one public SoftwareSourceCode node, found #{software_nodes.length}") unless software_nodes.length == 1
    if software_nodes.length == 1 && software_nodes.first["codeRepository"].to_s.empty?
      record(failures, "#{relative}: public SoftwareSourceCode missing codeRepository")
    end
  else
    record(failures, "#{relative}: private project must not emit SoftwareSourceCode") unless software_nodes.empty?
    if graph.any? { |node| node.key?("codeRepository") }
      record(failures, "#{relative}: private project graph exposes codeRepository")
    end
  end
  record(failures, "#{relative}: missing project summary") unless html.include?(%(class="project-summary"))
end

# A public repository is not necessarily a published release: public_main is a
# visitor-reachable snapshot. Keep the summary label keyed to release state,
# not source visibility, so public pre-releases remain honestly labeled.
project_summary_source = read_file(ROOT.join("_includes/project-summary.html"), failures)
unless project_summary_source.include?("if project.release_source == 'public_tag'")
  record(failures, "project-summary.html: Release/Snapshot row must branch on release_source == public_tag")
end

allowed_release_sources = %w[public_tag public_main private_main local_tag]
PROJECTS.each do |project|
  source = project["release_source"]
  unless allowed_release_sources.include?(source)
    record(failures, "projects.yml: #{project["slug"]} has invalid release_source #{source.inspect}")
  end
  next if source == "public_tag"
  %w[en zh].each do |lang|
    if project.dig("snapshot_label", lang).to_s.empty?
      record(failures, "projects.yml: #{project["slug"]} missing snapshot_label.#{lang}")
    end
  end
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

  # 2026-10-12 (PR 2): with the repeated list gone from section (03), the Status
  # panel is the home page's only per-project public/private/release record.
  # Every project keeps its own status pill there, in data order (tool rows,
  # which carry the --tool modifier, are not projects and are skipped).
  lang = relative.start_with?("zh/") ? "zh" : "en"
  panel = html[%r{<aside class="hero-proof".*?</aside>}m].to_s
  pills = panel.scan(%r{<li class="hero-proof__item">.*?<span class="status-pill" data-status="([^"]+)">([^<]+)</span>}m)
  expected_pills = PROJECTS.map { |project| [project["status"].to_s, project.dig("status_label", lang).to_s] }
  unless pills == expected_pills
    record(failures, "#{relative}: Status panel must show one status pill per project #{expected_pills.inspect}, got #{pills.inspect}")
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

# ZH status term of record: "Private/local" → 私有、本地 (顿号). Slash forms
# already regressed once across blurbs + detail copy; ban them site-wide under
# /zh/ so the next label tweak can't reintroduce 私有 / 本地 or 私有/本地.
slash_private_local = /私有\s*[\/／]\s*本地/
Pathname.glob(SITE.join("zh/**/*.html").to_s).each do |path|
  html = path.read
  if html.match?(slash_private_local)
    record(failures, "#{path.relative_path_from(SITE)}: slash form of 私有、本地 (use 顿号, not /)")
  end
end

# --- Route-aware progressive-enhancement scripts ---
global_scripts = %w[main.js theme.js reveal.js].freeze
home_only_scripts = %w[].freeze
case_study_scripts = %w[contents.js].freeze
gm_only_scripts = %w[copy.js].freeze
explainer_only_scripts = %w[video-captions.js].freeze
known_scripts = global_scripts + home_only_scripts + case_study_scripts + gm_only_scripts + explainer_only_scripts

known_scripts.each do |script|
  record(failures, "Missing script asset: assets/js/#{script}") unless SITE.join("assets/js", script).exist?
end

Pathname.glob(SITE.join("**/*.html").to_s).each do |path|
  html = path.read
  source = path.relative_path_from(SITE).to_s
  actual = html.scan(%r{<script\s+src="/assets/js/([^"]+)"[^>]*></script>}).flatten
  expected = global_scripts.dup
  expected.concat(home_only_scripts) if home_pages.include?(source)
  expected.concat(case_study_scripts) if project_pages.include?(source)
  expected.concat(gm_only_scripts) if %w[projects/gm-crypto-rs/index.html zh/projects/gm-crypto-rs/index.html].include?(source)

  expected.concat(explainer_only_scripts) if %w[projects/explainer-engine/index.html zh/projects/explainer-engine/index.html].include?(source)

  known_scripts.each do |script|
    count = actual.count(script)
    wanted = expected.include?(script)
    if wanted && count != 1
      record(failures, "#{source}: expected exactly one #{script} include, found #{count}")
    elsif !wanted && count != 0
      record(failures, "#{source}: optional #{script} must not load on this route")
    end
  end
  record(failures, "#{source}: missing inline motion gate") unless html.include?("classList.add('motion')")
end

# Home heroes must keep their real, server-rendered title. The decrypt effect
# was removed for #100 (spec A): no script may rewrite the headline.
%w[index.html zh/index.html].each do |relative|
  html = read_file(SITE.join(relative), failures)
  record(failures, "#{relative}: hero headline must not load a scramble script") if html.include?("decrypt.js")
end
record(failures, "assets/js/decrypt.js must stay removed (#100 spec A)") if ROOT.join("assets/js/decrypt.js").exist?
# 2026-10-12 (PR 2): the headline is "Building useful software with AI." The
# footer tagline now carries the same words, so match inside the <h1> only — a
# page-wide match would pass even if the headline lost its text.
{ "index.html" => "useful software", "zh/index.html" => "有用的软件" }.each do |relative, needle|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  hero_title = html[%r{<h1 class="hero__title">(.*?)</h1>}m, 1].to_s
  record(failures, "#{relative}: hero title lost real text (#{needle.inspect})") unless hero_title.include?(needle)
  record(failures, "#{relative}: hero__title missing") unless html.include?(%(class="hero__title"))
end
# 2026-10-12 (PR 2): the ZH accent line is pinned to one line (.nowrap), so it
# is as many em wide as it has glyphs. style.css caps the ZH title at
# 100cqi / 7.1 inside a size-container copy column so the line stays in its
# column from 760px up; a longer phrase needs a new divisor.
zh_hero = read_file(SITE.join("zh/index.html"), failures)
zh_accent = zh_hero[%r{<h1 class="hero__title">.*?<em class="nowrap">(.*?)</em>.*?</h1>}m, 1].to_s
if zh_accent.empty?
  record(failures, "zh/index.html: hero accent line must stay one .nowrap <em> (the style.css width cap assumes it)")
elsif zh_accent.length > 7
  record(failures, "zh/index.html: hero accent line is #{zh_accent.length} glyphs; style.css caps the ZH title for 7 (100cqi / 7.1) — change both together")
end
hero_css = read_file(SITE.join("assets/css/style.css"), failures).gsub(/\s+/, " ")
zh_cap_clamp = hero_css[%r{body\.lang-zh \.hero__title \{ font-size: min\((clamp\([^;]*?\)), 100cqi / 7\.1\); \}}, 1]
unless hero_css.include?("body.lang-zh .hero__copy { container-type: inline-size; }") && zh_cap_clamp
  record(failures, "style.css: the ZH hero title must keep its column cap (size-container .hero__copy, font-size min(…, 100cqi / 7.1))")
end
# The cap repeats the base clamp (a var() would turn into the inherited size in
# engines without cqi), so the two must stay equal.
base_title_clamp = hero_css.scan(/\} \.hero__title \{([^}]*)\}/).flatten.map { |body| body[/font-size: (clamp\([^;]*\));/, 1] }.compact.first
if zh_cap_clamp && zh_cap_clamp != base_title_clamp
  record(failures, "style.css: the ZH hero cap's clamp #{zh_cap_clamp.inspect} must equal the base .hero__title clamp #{base_title_clamp.inspect}")
end
# The ZH About Interests value nests .nowrap spans, so the facts label/value
# selectors must stay scoped to the row's direct children.
unless hero_css.include?(".facts dt, .facts li > span:first-child {") && hero_css.include?(".facts dd, .facts li > span:last-child {")
  record(failures, "style.css: .facts label/value selectors must target direct children (li > span), or nested value spans take the label style")
end

# The locale-aware <title> splice in _includes/head.html rebuilds jekyll-seo-tag's
# document title so the home-page suffix follows the page locale. Pin both
# branches (home suffix / interior "page | site") in both locales: if a
# github-pages bump changes seo-tag's output shape, or the splice regresses,
# this fails loudly instead of shipping an English tagline in the Chinese tab.
{
  "index.html" => "Frank Xue | Software engineer",
  "zh/index.html" => "Frank Xue | 软件工程师",
  "about/index.html" => "About | Frank Xue",
  "zh/about/index.html" => "关于 | Frank Xue"
}.each do |relative, expected_title|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  record(failures, "#{relative}: <title> is not #{expected_title.inspect}") unless html.include?("<title>#{expected_title}</title>")
end

# The splice's failure mode if seo-tag ever emits no <title> is duplicated head
# meta. Exactly one document title per page; SVG <title> elements all carry an
# id attribute, so the bare form counts only the document title.
Pathname.glob(SITE.join("**/*.html").to_s).each do |path|
  html = path.read
  source = path.relative_path_from(SITE).to_s
  count = html.scan("<title>").length
  record(failures, "#{source}: expected exactly one document <title>, found #{count}") unless count == 1
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
  assets/img/social-card.zh.png
  assets/img/apple-touch-icon.png
  assets/img/icon-192.png
  assets/img/icon-512.png
  assets/img/icon-maskable-192.png
  assets/img/icon-maskable-512.png
  assets/img/favicon-32.png
  assets/img/favicon-16.png
  site.webmanifest
].each do |rel|
  record(failures, "Missing share/icon asset: #{rel}") unless SITE.join(rel).exist?
end

%w[social-card.png social-card.zh.png].each do |card_name|
  card = SITE.join("assets/img", card_name)
  next unless card.exist?

  dimensions = png_dimensions(card)
  if dimensions
    width, height = dimensions
    unless width == 1200 && height == 630
      record(failures, "#{card_name} must be 1200x630 (Open Graph), got #{width}x#{height}")
    end
  else
    record(failures, "#{card_name} is not a valid PNG")
  end
  record(failures, "#{card_name} must be at most 175000 bytes, got #{card.size}") if card.size > 175_000
end

{
  "icon-maskable-192.png" => [192, 192],
  "icon-maskable-512.png" => [512, 512]
}.each do |icon_name, expected_dimensions|
  icon = SITE.join("assets/img", icon_name)
  next unless icon.exist?

  dimensions = png_dimensions(icon)
  record(failures, "#{icon_name} must be #{expected_dimensions.join('x')}, got #{dimensions.inspect}") unless dimensions == expected_dimensions
end

manifest = SITE.join("site.webmanifest")
if manifest.exist?
  begin
    data = JSON.parse(manifest.read)
    record(failures, "site.webmanifest: missing name") unless data["name"].to_s != ""
    icons = Array(data["icons"])
    record(failures, "site.webmanifest: needs 192px and 512px icons") unless
      icons.any? { |i| i["sizes"] == "192x192" } && icons.any? { |i| i["sizes"] == "512x512" }
    {
      "/assets/img/icon-maskable-192.png" => "192x192",
      "/assets/img/icon-maskable-512.png" => "512x512"
    }.each do |src, sizes|
      matches = icons.select { |icon| icon["src"] == src && icon["sizes"] == sizes && icon["purpose"] == "maskable" }
      record(failures, "site.webmanifest: expected one dedicated maskable entry for #{src}") unless matches.length == 1
    end
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

  # Undefined custom-property guard. Every `var(--x)` used WITHOUT a fallback
  # must have a `--x:` definition somewhere in the sheet — otherwise it silently
  # falls back to the property's initial value (e.g. text-decoration-color ->
  # currentColor, line-height -> normal), which is how the v1 glossary shipped a
  # same-as-text underline. `var(--x, fallback)` is exempt (it has a fallback).
  defined_props = css.scan(/(--[a-zA-Z0-9-]+)\s*:/).flatten.uniq
  used_no_fallback = css.scan(/var\(\s*(--[a-zA-Z0-9-]+)\s*\)/).flatten.uniq
  undefined_used = used_no_fallback - defined_props
  undefined_used.each do |prop|
    record(failures, "style.css: var(#{prop}) used but #{prop} is never defined (silent initial-value fallback)")
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
# contents.js must ship and load on case studies only (the route matrix above
# guards inclusion). The script still self-guards as progressive enhancement.
# The CSS must carry the rail styles, the sticky-header scroll-margin, and the
# print rule that drops the rail. The bilingual label must exist in i18n and be
# emitted as data-toc-label on the detail-page bodies the rail attaches to.
record(failures, "Missing contents script: assets/js/contents.js") unless SITE.join("assets/js/contents.js").exist?

if css_path.exist?
  css = css_path.read
  record(failures, "style.css: missing contents-rail grid (.section.has-toc)") unless css.include?(".section.has-toc")
  record(failures, "style.css: missing contents-rail link style (.toc__link)") unless css.include?(".toc__link")
  record(failures, "style.css: missing scroll-margin-top on detail headings") unless
    css.match?(/\.project-detail h2\s*\{[^}]*scroll-margin-top/)
  record(failures, "style.css: missing print rule hiding the contents rail") unless
    css.match?(/@media print\s*\{\s*\.toc\s*\{\s*display:\s*none/)
end

i18n = I18N
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
# copy.js must ship and load on gm-crypto-rs only. The gm pages (EN + ZH) must
# carry the install block; the private/local projects must NOT — only the
# public crate gets an install command (source-of-truth boundary).
record(failures, "Missing copy script: assets/js/copy.js") unless SITE.join("assets/js/copy.js").exist?

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
    headings: [["what-it-is", "What it is"], ["problem", "The problem"],
               ["decisions", "Constraints &amp; key decisions"], ["evidence", "Evidence"],
               ["next", "Next"], ["limits", "What it isn't"]],
    cost: "Cost:", overclaims: %w[production-ready guaranteed secure],
    caveat: "detection events", version_before: ["<h2 id=\"next\">", "v1.11.0"],
    # Non-affiliation note ties to the named interop targets (trademark-disclaimer
    # convention) instead of denying ties to unnamed parties. "either project" is
    # the tell; if it reverts to the generic enumerated form, this guard trips.
    # "/projects/gm-crypto-rs/releases/" guards the split's only inbound link (the
    # "Full history" row, 2026-08-05) — delete that row and the release page
    # becomes orphaned with nothing else to catch it.
    must_include: ["either project", "/projects/gm-crypto-rs/releases/",
                   # 2026-10-12: the audit disclosure and the timing check's real
                   # enforcement (path-filtered, not a required merge check) must survive.
                   "Not independently audited", "not a required merge check",
                   "pull requests that change the crypto code", "x86-64 Linux",
                   # GmSSL interop: the skip condition must stay visible here (the
                   # byte-identity notes and the v1.10 release rows are pinned in
                   # source_contracts), and no effective date is assigned to the
                   # required check (only the ruleset's own history is inspectable).
                   "skipped with a warning and the check still passes",
                   # 2026-10-12 (PR 2): the short opening keeps the Owner-confirmed
                   # contribution wording and the GmSSL caveat as the workflow runs it;
                   # the release line is described per cycle, not as a general rule.
                   "<strong>My part.</strong> I defined the initial requirements and used AI coding assistants to implement features.",
                   "I am new to Rust and focus primarily on practical usability and compatibility with existing implementations such as GmSSL.",
                   "I do not regularly review the code line by line.",
                   "Initially, I reviewed changes myself; later, to improve efficiency, I shifted more of the code review to AI agents following defined rules.",
                   "<strong>Problem.</strong> While working with Chinese cryptographic tools, I found relatively few related tools in the Rust ecosystem, which led me to start this project.",
                   "provisioning and version check succeed; if either fails, the comparison is skipped with a warning while the job still passes",
                   "the site does not state a general rule"],
    forbid: ["on every PR", "on every commit", "build-failing", "re-audit", "multi-model",
             "constant-time on every commit", "fails the build", "The gate has teeth",
             "since 2026-10-11", "for merging since",
             "skip releases that change nothing", "The same rule", "is never published",
             "a cycle that changes no output bytes merges"],
    source_link: %(github.com/frankxue831/gm-crypto-rs")
  },
  "zh/projects/gm-crypto-rs/index.html" => {
    headings: [["what-it-is", "是什么"], ["problem", "要解决的问题"],
               ["decisions", "约束与关键决策"], ["evidence", "证据"],
               ["next", "下一步"], ["limits", "它不是什么"]],
    cost: "代价：", overclaims: ["生产就绪", "保证安全", "绝对常量时间"],
    caveat: "检测事件", version_before: ["<h2 id=\"next\">", "v1.11.0"],
    # ZH mirror of the interop-tied non-affiliation guard ("这两个项目" = the two
    # named projects gmssl/OpenSSL); trips if it reverts to the enumerated form.
    # ZH mirror of the releases-page inbound-link guard above (2026-08-05).
    must_include: ["这两个项目", "/zh/projects/gm-crypto-rs/releases/",
                   "未经独立审计", "不是合并的必需检查", "改动密码代码的 PR", "x86-64 Linux",
                   "带着警告跳过，这项检查照样通过",
                   "<strong>我负责的部分。</strong>我提出了最初的需求，并借助 AI 编程助手实现功能。",
                   "我是 Rust 新手，主要关注实际使用体验，以及与 GmSSL 等现有实现的兼容性，并不经常逐行细审代码。",
                   "起初，我自己复核改动；后来，为了提高效率，我把更多代码评审交给了遵循既定规则的 AI Agent。",
                   "<strong>为什么做这个项目。</strong>在使用国密工具的过程中，我发现 Rust 生态中的相关工具还比较少，于是开始了这个项目。",
                   "准备就绪且版本校验通过后，才会执行这项比对。如果准备或版本校验失败，CI 会发出警告并跳过比对，任务仍会通过",
                   "本站不把它们归纳成一条通用规则"],
    forbid: ["每个 PR 都", "每次提交", "复审", "多模型", "让构建失败", "构建就会失败", "每次都", "门禁不是摆设",
             "自 2026-10-11", "起是合并的必需检查",
             "输出没变就不发版", "同一条规矩", "一轮没改任何输出字节的工作，不发版"],
    source_link: %(github.com/frankxue831/gm-crypto-rs")
  },
  "projects/repolens-rs/index.html" => {
    headings: [["what-it-is", "What it is"], ["problem", "The problem"],
               ["decisions", "Constraints &amp; key decisions"], ["evidence", "Evidence"],
               ["next", "Next"], ["limits", "What it isn't"]],
    cost: "Cost:", overclaims: %w[production-ready guaranteed secure],
    must_include: ["warnings-only", "not the typed graph", "scaffolding"]
  },
  "zh/projects/repolens-rs/index.html" => {
    headings: [["what-it-is", "是什么"], ["problem", "要解决的问题"],
               ["decisions", "约束与关键决策"], ["evidence", "证据"],
               ["next", "下一步"], ["limits", "它不是什么"]],
    cost: "代价：", overclaims: ["生产就绪", "保证安全"],
    must_include: ["只给 warning", "不是那张类型化记忆图", "脚手架"]
  },
  # ghrunners: private/local — observability + guarded control, not read-only.
  # Guard the current local tag + the "guarded" framing, and forbid the stale
  # v0.1.1 label from creeping back.
  "projects/ghrunners/index.html" => {
    headings: [["what-it-is", "What it is"], ["problem", "The problem"],
               ["decisions", "Constraints &amp; key decisions"], ["evidence", "Evidence"],
               ["next", "Next"], ["limits", "What it isn't"]],
    cost: "Cost:", overclaims: %w[production-ready guaranteed secure],
    must_include: ["v0.5.0", "guarded"], forbid: ["v0.1.1"]
  },
  "zh/projects/ghrunners/index.html" => {
    headings: [["what-it-is", "是什么"], ["problem", "要解决的问题"],
               ["decisions", "约束与关键决策"], ["evidence", "证据"],
               ["next", "下一步"], ["limits", "它不是什么"]],
    cost: "代价：", overclaims: ["生产就绪", "保证安全"],
    # 单次运行 is the one-shot term of record; 一次性 regressed on this page's
    # description + lede before the 2026-08-06 readthrough closed it.
    must_include: ["v0.5.0", "受控", "单次运行"], forbid: ["v0.1.1", "一次性"]
  },
  # Explainer: visitor-facing order differs; source and local-history limits
  # remain mandatory, along with all four decision costs.
  "projects/explainer-engine/index.html" => {
    headings: [["examples", "Three examples to watch"], ["what-it-is", "From script to screen"],
               ["evidence", "What you can check"], ["decisions", "Decisions and trade-offs"],
               ["next", "Where it stands"], ["limits", "Limits"]],
    cost: "Cost:", overclaims: %w[production-ready guaranteed secure],
    must_include: ["simplified", "gate's verdict", "explainer plan", "tree/v0.2.0",
      "This command checks citations; it does not re-render the video.",
      "It does not establish that the explanation is semantically correct or educationally effective.",
      "no language model writes that code", "first public tag", "<code>v0.1.0</code>", "2026-10-15",
      "historical result lacks public run evidence and is not independently checkable",
      "without pinning a commit",
      "Text embedded in the videos has not been remade",
      "blob/v0.2.0/CHANGELOG.md\" rel=\"noopener noreferrer\">Changelog</a>",
      "<span class=\"status-pill\" data-status=\"public-pre-release\">Public source, pre-release</span>", "<dt>Tag</dt>"],
    # ManimSimpleRender has a public tag: v0.1.0, annotated tagger timestamp
    # 2026-10-15 05:07:40 UTC.
    forbid: ["no published tag", "No published tag", "no tagged release", "No tagged release", "explainer-plan",
             "GitHub Release", "PyPI", "ManimSimpleRender/releases/tag/", "<dt>Release</dt>"]
  },
  "zh/projects/explainer-engine/index.html" => {
    headings: [["examples", "先看三段成果"], ["what-it-is", "从脚本到画面"],
               ["evidence", "能核对哪些证据"], ["decisions", "取舍与约束"],
               ["next", "目前进展"], ["limits", "使用边界"]],
    cost: "代价：", overclaims: ["生产就绪", "保证安全"],
    must_include: ["简化视图", "校验门的结论", "explainer plan", "tree/v0.2.0",
      "这条命令只检查引用，不会重新渲染视频。",
      "它不证明讲解语义正确，也不证明教学效果。",
      "这段代码不由语言模型编写", "首个公开 tag", "<code>v0.1.0</code>", "2026-10-15",
      "历史校验结果缺少公开运行证据，无法由外部独立核验",
      "没有固定 commit",
      "视频内嵌文字没有重做",
      "blob/v0.2.0/CHANGELOG.md\" rel=\"noopener noreferrer\">更新日志</a>",
      "<span class=\"status-pill\" data-status=\"public-pre-release\">源码公开、预发布</span>", "<dt>tag</dt>"],
    forbid: ["没有已发布的 tag", "尚未打正式发布标签", "explainer-plan", "GitHub Release", "PyPI", "ManimSimpleRender/releases/tag/", "<dt>Release</dt>", "<dt>发布</dt>"]
  }
}
case_study.each do |relative, spec|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?

  # All six headings are source-rendered with stable, locale-independent IDs.
  actual_headings = html.scan(%r{<h2 id="([^"]+)">(.*?)</h2>}m).map do |id, text|
    [id, text.gsub(/\s+/, " ").strip]
  end
  unless actual_headings == spec[:headings]
    record(failures, "#{relative}: case-study heading/ID sequence mismatch expected #{spec[:headings].inspect} got #{actual_headings.inspect}")
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

  # Stale phrases that must NOT reappear after a source-of-truth refresh.
  Array(spec[:forbid]).each do |phrase|
    record(failures, "#{relative}: stale phrase #{phrase.inspect} present (refresh guard)") if normalized.include?(phrase)
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

# The colophon states how much JavaScript the site ships (EN and ZH), and the
# count has drifted when a script was added. Tie it to assets/js: the file
# count exactly, the "approximately N lines" figures within 5%.
js_files = Pathname.glob(SITE.join("assets/js/*.js").to_s)
js_lines = js_files.sum { |file| File.foreach(file).count }
js_words = %w[zero one two three four five six seven eight nine ten eleven twelve]
{
  "colophon/index.html" => ["across #{js_words[js_files.size]} focused files", "lines across #{js_files.size} files"],
  "zh/colophon/index.html" => ["分散在 #{js_files.size} 个职责集中的文件里", "#{js_files.size} 个文件、约"]
}.each do |relative, phrases|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  text = html.gsub(/\s+/, " ")
  phrases.each do |phrase|
    record(failures, "#{relative}: JavaScript file count must read #{phrase.inspect} (assets/js has #{js_files.size} files)") unless text.include?(phrase)
  end
  stated = text.scan(/(?:approximately|~|约) ?(\d+) ?(?:lines|行)/).flatten.map(&:to_i)
  record(failures, "#{relative}: no JavaScript line count found") if stated.empty?
  stated.each do |count|
    record(failures, "#{relative}: says ~#{count} lines of JavaScript; assets/js has #{js_lines}") if (count - js_lines).abs > js_lines * 0.05
  end
end

# Explainer examples retain playable no-JS media and inspectable source.
%w[en zh].each do |lang|
  %w[label off waiting off_message download].each do |key|
    record(failures, "i18n.yml: missing #{lang}.explainer_video.#{key}") if
      I18N.dig(lang, "explainer_video", key).to_s.empty?
  end
end
%w[projects/explainer-engine/index.html zh/projects/explainer-engine/index.html].each do |relative|
  html = read_file(SITE.join(relative), failures)
  videos = html.scan(%r{<video\b(.*?)</video>}m).flatten
  record(failures, "#{relative}: expected three native videos") unless videos.size == 3
  videos.each do |video|
    record(failures, "#{relative}: video lost native controls/no-JS captions") unless
      video.include?("controls") && video.scan(/<track\b/).size == 2 && video.scan(/ default/).size == 1
    record(failures, "#{relative}: examples must not autoplay") if video.include?("autoplay")
  end
  %w[harness-field-explainer evidence-budget citation-gate].each do |name|
    record(failures, "#{relative}: missing #{name} media") unless html.include?("/assets/video/#{name}.mp4")
  end
  # Every poster, video and caption file the page references must exist in the build.
  html.scan(/\b(?:poster|src)="(\/assets\/video\/[^"]+)"/).flatten.uniq.each do |asset|
    record(failures, "#{relative}: missing video asset #{asset}") unless SITE.join(asset.delete_prefix("/")).exist?
  end
  input_i = html.index('<h2 id="what-it-is">') || 0
  video_positions = html.enum_for(:scan, /<video\b/).map { Regexp.last_match.begin(0) }
  record(failures, "#{relative}: all examples must precede pipeline explanation") unless
    video_positions.size == 3 && video_positions.all? { |index| index < input_i }
  %w[examples/evidence-budget.story.yaml explainer/plan/evidence.py#L55-L58
     explainer/plan/evidence.py#L205-L211 explainer/plan/evidence.py#L312-L313].each do |path|
    url = "https://github.com/frankxue831/ManimSimpleRender/blob/c345e667dae448860b449e82415c81c80e59f7b1/#{path}"
    record(failures, "#{relative}: missing pinned evidence #{path}") unless html.include?(url)
  end
  record(failures, "#{relative}: missing pinned citation-gate script") unless
    html.include?("https://github.com/frankxue831/ManimSimpleRender/blob/9a59b3f0f92f7742709f15edd2c0a0a40ff03933/examples/citation-gate.story.yaml")
  record(failures, "#{relative}: missing actual verification command") unless
    html.include?("explainer verify examples/evidence-budget.story.yaml")
  record(failures, "#{relative}: missing real script/frame pair") unless
    CGI.unescapeHTML(html).include?('cite: "explainer/plan/evidence.py:56"') &&
    html.include?("/assets/img/evidence-budget-12s.jpg")
  record(failures, "#{relative}: captions must initialize hidden") unless
    html.scan('<div class="video-captions" hidden>').size == 3
  record(failures, "#{relative}: history drawer must not hide a contents heading") if
    html.match?(/<details\b[^>]*>(?:(?!<\/details>).)*?<h2/m)
end

# Native-interactivity guards on the gm-crypto pages: the popover glossary must
# survive edits, and the constant-time visualizer must keep its data-table
# fallback and its public-source pin.
%w[projects/gm-crypto-rs/index.html zh/projects/gm-crypto-rs/index.html].each do |relative|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  record(failures, "#{relative}: missing popover glossary (popovertarget=\"gloss-\")") unless html.include?('popovertarget="gloss-')
  record(failures, "#{relative}: missing constant-time visualizer figure (class=\"dudect\")") unless html.include?('class="dudect')
  record(failures, "#{relative}: visualizer missing data-table fallback (.dudect__table)") unless html.include?("dudect__table")
  record(failures, "#{relative}: visualizer missing public source link (v1.2.0)") unless html.include?("SECURITY.md @ v1.2.0")
  record(failures, "#{relative}: <h2> inside <details> breaks the contents rail") if html.match?(/<details\b[^>]*>(?:(?!<\/details>).)*?<h2/m)
end

# The <details> audit drawer (earlier releases) moved to the dedicated releases
# page (2026-08-05 content-expression split) and must survive there. A drawer must
# never wrap an <h2> — the check is carried alongside as a latent guard that
# protects the case-study pages (which build a contents rail from h2s) and is
# currently inert on the releases pages (which have no h2s).
#
# The split also made the return trip load-bearing (2026-08-05): the case study's
# "Full history" row is each release page's only inbound link (guarded above via
# case_study's must_include), and each release page must link back to its own
# case study or a reader who lands there has nowhere onward. Keyed per locale so
# each page is checked against its own case-study path, not both against one.
{
  "projects/gm-crypto-rs/releases/index.html" => "/projects/gm-crypto-rs/",
  "zh/projects/gm-crypto-rs/releases/index.html" => "/zh/projects/gm-crypto-rs/"
}.each do |relative, back_link|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  record(failures, "#{relative}: missing <details> audit drawer") unless html.include?("<details")
  record(failures, "#{relative}: <h2> inside <details> breaks the contents rail") if html.match?(/<details\b[^>]*>(?:(?!<\/details>).)*?<h2/m)
  record(failures, "#{relative}: missing back-link to case study (#{back_link})") unless html.include?(%(href="#{back_link}"))
end

# ZH releases page once forked 免确认 SM2-KX next to 免密钥确认完成器 in the
# same file. Forbid the shortened form (not a substring of 免密钥确认) so the
# term of record can't re-split on the next release-history sync.
zh_releases = "zh/projects/gm-crypto-rs/releases/index.html"
zh_releases_html = read_file(SITE.join(zh_releases), failures)
unless zh_releases_html.empty?
  normalized = zh_releases_html.gsub(/\s+/, " ")
  if normalized.include?("免确认")
    record(failures, "#{zh_releases}: shortened 免确认 present (use 免密钥确认)")
  end
end

# High-churn ZH work-list blurbs sit outside case_study and have re-hosted the
# same terminology regressions (会过期, 一次性, 对过源码). Pin the current
# terms of record so the next blurb edit keeps them.
# ghrunners blurbs lead with purpose ("跑一次就能看出…为什么卡住"); the
# term-of-record 单次运行 stays on the detail page + glossary, not the blurb.
# 2026-10-12 (PR 2): the home page no longer repeats these blurbs (section 03
# now features one case study), so only the projects index carries them.
{
  "zh/projects/index.html" => %w[会衰减 跑一次就能看出 核对源码]
}.each do |relative, phrases|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  normalized = html.gsub(/\s+/, " ")
  phrases.each do |phrase|
    record(failures, "#{relative}: required blurb phrase #{phrase.inspect} missing") unless normalized.include?(phrase)
  end
end

# ManimSimpleRender's current public tag on the work-list blurbs (v0.2.0;
# v0.1.0 was the first, tagged 2026-10-15 UTC); the pre-tag phrasings must not come back.
{
  "projects/index.html" => { must: ["tree/v0.2.0", "<code>v0.2.0</code>"],
                             forbid: ["no tagged release", "No tagged release", "no published tag", "No published tag", "ManimSimpleRender/releases/tag/"] },
  "zh/projects/index.html" => { must: ["当前 tag 为", "tree/v0.2.0", "<code>v0.2.0</code>"],
                                forbid: ["尚未打正式发布标签", "没有已发布的 tag", "ManimSimpleRender/releases/tag/"] }
}.each do |relative, spec|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  normalized = html.gsub(/\s+/, " ")
  spec[:must].each { |p| record(failures, "#{relative}: required tag phrase #{p.inspect} missing") unless normalized.include?(p) }
  spec[:forbid].each { |p| record(failures, "#{relative}: stale phrase #{p.inspect} present (refresh guard)") if normalized.include?(p) }
end

%w[
  projects/repolens-rs/index.html projects/ghrunners/index.html
  projects/explainer-engine/index.html
  zh/projects/repolens-rs/index.html zh/projects/ghrunners/index.html
  zh/projects/explainer-engine/index.html
].each do |relative|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  # Glossary extension: these pages annotate load-bearing jargon, so the popover
  # affordance must survive edits (parity with the gm-crypto guard above).
  record(failures, "#{relative}: missing popover glossary (popovertarget=\"gloss-\")") unless html.include?('popovertarget="gloss-')
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

# Glossary popover definitions: every term needs a label + def in both languages.
# gm-crypto terms first, then the repolens-rs / ghrunners extension terms.
%w[en zh].each do |lang|
  %w[constant-time storyboard manim sm2 sm3 sm4 no_std dudect
     mcp rag grounding launchd self-hosted-runner daemon].each do |term|
    %w[label def].each do |key|
      record(failures, "i18n.yml: missing #{lang}.glossary.#{term}.#{key}") if i18n.dig(lang, "glossary", term, key).to_s.empty?
    end
  end
  record(failures, "i18n.yml: missing #{lang}.details.earlier_releases") if i18n.dig(lang, "details", "earlier_releases").to_s.empty?
end

# --- Constant-time visualizer: pin the published dudect facts to public state ---
# The four |tau| values, the gate, and the caught-leak before/after MUST equal
# the values published in gm-crypto-rs SECURITY.md @ v1.2.0. A silent drift
# here would misrepresent public release state — fail CI instead.
dudect_path = ROOT.join("_data/dudect.yml")
if !dudect_path.exist?
  record(failures, "_data/dudect.yml: missing (constant-time visualizer data)")
else
  dd = YAML.load_file(dudect_path)
  expected_tau = { "ct_sign" => 0.0044, "ct_sign_k_class" => 0.0708,
                   "ct_fn_invert" => 0.0071, "ct_fp_invert" => 0.0063 }
  measured = (dd["measured"] || []).each_with_object({}) { |m, h| h[m["target"]] = m["tau"] }
  expected_tau.each do |target, tau|
    got = measured[target]
    record(failures, "_data/dudect.yml: #{target} |tau| is #{got.inspect}, expected #{tau} (public v1.2.0)") unless got == tau
  end
  record(failures, "_data/dudect.yml: gate must be 0.2 (public)") unless dd["gate"] == 0.20
  record(failures, "_data/dudect.yml: sentinel must be 0.55 (public)") unless dd["sentinel"] == 0.55
  expected_policy = {
    "ct_sign" => "gate", "ct_sign_k_class" => "sentinel",
    "ct_fn_invert" => "sentinel", "ct_fp_invert" => "sentinel"
  }
  measured_policy = (dd["measured"] || []).each_with_object({}) { |m, h| h[m["target"]] = m["policy"] }
  expected_policy.each do |target, policy|
    unless measured_policy[target] == policy
      record(failures, "_data/dudect.yml: #{target} policy is #{measured_policy[target].inspect}, expected #{policy.inspect}")
    end
  end
  record(failures, "_data/dudect.yml: leak.before must be 0.7 (public)") unless dd.dig("leak", "before") == 0.70
  record(failures, "_data/dudect.yml: leak.after must be 0.006 (public)") unless dd.dig("leak", "after") == 0.006
  record(failures, "_data/dudect.yml: must NOT publish more than 4 per-target values (others are unpublished)") if (dd["measured"] || []).length != 4
  record(failures, "_data/dudect.yml: source_url must point at the public v1.2.0 tag") unless dd["source_url"].to_s.include?("v1.2.0")
end

dudect_chart_source = read_file(ROOT.join("_includes/dudect-chart.html"), failures)
# Table thresholds are "&le;" + a space or no-break space + the display string
# (the dudect parsers fail only when the median |tau| is strictly above the limit,
# so a value AT the limit passes: "<" would misstate the check);
# match the cell form so a bare "{{ d.sentinel_display }}" elsewhere (the axis
# tick) can't satisfy the precision guard, and &nbsp; can't dodge the hardcode guard.
threshold_sep = /(?:\s|&nbsp;|&#160;| )+/
record(failures, "dudect-chart.html: sentinel threshold must preserve display precision from dudect.yml") unless dudect_chart_source.match?(/&le;#{threshold_sep}\{\{\s*d\.sentinel_display\s*\}\}/)
record(failures, "dudect-chart.html: gate threshold must preserve display precision from dudect.yml") unless dudect_chart_source.match?(/&le;#{threshold_sep}\{\{\s*d\.gate_display\s*\}\}/)
if dudect_chart_source.match?(/(?:&lt;|&le;|≤)#{threshold_sep}0\.(?:20|55)/)
  record(failures, "dudect-chart.html: policy threshold is hardcoded instead of rendered from dudect.yml")
end
if dudect_chart_source.match?(/&lt;#{threshold_sep}\{\{\s*d\.(?:gate|sentinel)_display\s*\}\}/)
  record(failures, "dudect-chart.html: threshold rendered with \"<\"; the check passes AT the limit, so use \"&le;\"")
end

# dudect i18n parity: every required key present + non-empty in both languages.
%w[en zh].each do |lang|
  %w[title fig_num intro axis_label gate_label control_label cluster_label caveat
     provenance source table_caption col_target col_measures col_tau col_gate
     col_status status_pass status_sentinel status_fire status_caught
     policy_sentinel_label].each do |key|
    record(failures, "i18n.yml: missing #{lang}.dudect.#{key}") if i18n.dig(lang, "dudect", key).to_s.empty?
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
  # No .btn entry: the contact-form styles (.form/.field/.btn) shipped unused
  # — contact is GitHub-first with no form markup — and were removed. If a
  # form ever returns, its button needs a :focus-visible rule and a guard here.
  {
    ".work-list__row:focus-visible"  => "work-list row focus parity",
    ".hero__cta:focus-visible"       => "hero CTA focus parity"
  }.each do |selector, label|
    record(failures, "style.css: missing #{label} (#{selector})") unless css.include?(selector)
  end

  # Cross-document View Transitions: the cross-fade at-rule must be present.
  record(failures, "style.css: missing @view-transition rule") unless css.include?("@view-transition")

  # Popover glossary: term affordance + definition-card styles must be present.
  record(failures, "style.css: missing .gloss-term glossary style") unless css.include?(".gloss-term")
  record(failures, "style.css: missing .gloss-def popover style") unless css.include?(".gloss-def")

  # Constant-time visualizer styles must be present.
  record(failures, "style.css: missing .dudect visualizer styles") unless css.include?(".dudect__chart")
  record(failures, "style.css: missing monograph figure styles (.fig__cap)") unless css.include?(".fig__cap")

  # --- Tap-target floor for footer links (WCAG 2.2 SC 2.5.8, target size min) ---
  # Footer social links are standalone targets (not inline-in-prose), so keep
  # them a >=24px tap target. Measured: text-only line box is ~22.7px; the rule
  # must carry a min-block-size floor so it holds even if LinkedIn/Twitter/Email
  # stack densely.
  footer_link_rule = css[/\.site-footer__list a\s*\{[^}]*\}/m]
  if footer_link_rule.nil?
    record(failures, "style.css: missing .site-footer__list a rule")
  elsif !footer_link_rule.include?("min-block-size")
    record(failures, "style.css: footer links missing 24px tap-target floor (min-block-size)")
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

# Note lists show each written excerpt whole. Their truncation caps only bound
# Jekyll's auto-generated excerpt (a note without `excerpt:`). A written excerpt
# cut at the old 160-character cap broke mid-word, and the EN warrant note lost
# the closing caveat that the ZH list kept. Liquid 4 also appends the ellipsis
# to a text of exactly the truncatewords count, hence the "…" check. Each
# excerpt is read from its own row's note, and a page with no matched rows
# fails, so changed row markup cannot turn this guard into a silent pass.
%w[index.html notes/index.html zh/index.html zh/notes/index.html].each do |relative|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  listed = 0
  note_specs.each_value do |spec|
    row_note = html[%r{class="work-list__row" href="#{Regexp.escape(spec['permalink'].to_s)}".*?<p class="work-list__note">(.*?)</p>}m, 1]
    next unless row_note
    listed += 1
    excerpt = spec["excerpt"].to_s
    next if excerpt.empty? || (row_note.include?(excerpt) && !row_note.include?("#{excerpt}…"))
    record(failures, "#{relative}: excerpt of #{spec['permalink']} is cut; written excerpts must fit the list cap (EN under 40 words, ZH at most 160 characters)")
  end
  record(failures, "#{relative}: excerpt guard matched no note rows (did the work-list row markup change?)") if listed.zero?
end

# Terminal pages (notes, contact) carry an onward CTA so reading doesn't
# dead-end — parity with the section CTAs on the home page. Regression guard
# for the interactivity quick-wins pass.
%w[notes/index.html zh/notes/index.html contact/index.html zh/contact/index.html].each do |relative|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  record(failures, "#{relative}: missing onward CTA (preview__link--section)") unless html.include?("preview__link--section")
end

# Colophon ("how it's built / how to audit it"): must carry its audit substance
# (the CSP), keep the onward CTA, and stay reachable from the footer on every
# page. The page is the site's auditability claim made legible — guard it.
%w[colophon/index.html zh/colophon/index.html].each do |relative|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  record(failures, "#{relative}: colophon missing audit substance (validator self-reference)") unless html.gsub("<wbr>", "").include?("scripts/validate_site.rb")
  # The <wbr> is the path's only break point on a narrow phone (see .prose code wbr in style.css).
  record(failures, "#{relative}: colophon validator path lost its <wbr> (it overflows a 320px screen)") unless html.include?("<code>scripts/<wbr>validate_site.rb</code>")
  record(failures, "#{relative}: colophon missing onward CTA (preview__link--section)") unless html.include?("preview__link--section")
end
{ "index.html" => "/colophon/", "zh/index.html" => "/zh/colophon/" }.each do |relative, colophon_path|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  record(failures, "#{relative}: footer missing colophon link (#{colophon_path})") unless html.include?(%(href="#{colophon_path}"))
end

# Home pages surface a "Latest writing" teaser that links to the notes index,
# so the writing section is reachable in one click from the front door.
{ "index.html" => "/notes/", "zh/index.html" => "/zh/notes/" }.each do |relative, notes_path|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  record(failures, "#{relative}: missing Latest-writing teaser (aria-labelledby=\"writing-h\")") unless html.include?('aria-labelledby="writing-h"')
  record(failures, "#{relative}: writing teaser missing link to #{notes_path}") unless html.include?(%(href="#{notes_path}"))
end

note_pages.each do |relative|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  record(failures, "#{relative}: missing en hreflang alternate") unless html.match?(%r{<link rel="alternate" hreflang="en" href="#{Regexp.escape(BASE_URL)}/notes/[^"]+">})
  record(failures, "#{relative}: missing zh-CN hreflang alternate") unless html.match?(%r{<link rel="alternate" hreflang="zh-CN" href="#{Regexp.escape(BASE_URL)}/zh/notes/[^"]+">})
end

i18n = I18N
%w[en zh].each do |lang|
  record(failures, "i18n.yml: missing #{lang}.nav.writing") if i18n.dig(lang, "nav", "writing").to_s.empty?
  %w[all read_more none].each do |key|
    record(failures, "i18n.yml: missing #{lang}.notes.#{key}") if i18n.dig(lang, "notes", key).to_s.empty?
  end
end

note_pages.each do |relative|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  lang = relative.start_with?("zh/") ? "zh" : "en"
  label = i18n.dig(lang, "nav", "writing")
  record(failures, "#{relative}: note eyebrow does not use the localized Notes label") unless html.match?(%r{page-header__eyebrow[^>]*>[^<]*#{Regexp.escape(label)}</p>})
end

{ "about/index.html" => "en", "zh/about/index.html" => "zh" }.each do |relative, lang|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  label = i18n.dig(lang, "nav", "writing")
  record(failures, "#{relative}: facts list does not use the localized Notes label") unless html.include?("<span>#{label}</span>")
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
  source = path.relative_path_from(SITE).to_s
  font_preloads = html.scan(/<link\b[^>]*\bas="font"[^>]*>/i).select { |tag| tag.include?('rel="preload"') }
  expected_count = home_pages.include?(source) ? 2 : 0
  unless font_preloads.length == expected_count
    record(failures, "#{source}: expected #{expected_count} font preloads, found #{font_preloads.length}")
  end

  font_preloads.each do |tag|
    record(failures, "#{source}: font preload missing type=font/woff2") unless tag.include?('type="font/woff2"')
    record(failures, "#{source}: font preload missing crossorigin") unless tag.match?(/\bcrossorigin(?:\s|=|>)/)
    href = tag[/href="([^"]+)"/, 1]
    next unless href
    rel = href.sub(%r{\Ahttps?://[^/]+}, "").sub(%r{\A/}, "")
    record(failures, "#{source}: preload font missing on disk: #{href}") unless SITE.join(rel).exist?
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
  json_ld_count = html.scan(%r{<script type="application/ld\+json">}).length
  record(failures, "#{source}: expected exactly one JSON-LD script, found #{json_ld_count}") unless json_ld_count == 1
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

# --- 2026-08-09 site-review content contracts ---
# These values are intentionally local/static: immutable public release facts
# are verified during review, then pinned here so routine builds never depend
# on network availability.
release_history_expected = {
  "v0.15.0" => "2026-05-27",
  "v0.10.0" => "2026-05-22",
  "v0.9.0" => "2026-05-20",
  "v0.8.0" => "2026-05-17",
  "v0.7.0" => "2026-05-15"
}.freeze

%w[projects/gm-crypto-rs-releases.html zh/projects/gm-crypto-rs-releases.html].each do |relative|
  source = read_file(ROOT.join(relative), failures)
  release_history_expected.each do |version, date|
    row = %r{<dt>#{Regexp.escape(version)}</dt>\s*<dd>#{Regexp.escape(date)}\b}m
    record(failures, "#{relative}: #{version} must use public release date #{date}") unless source.match?(row)
  end
end

gm_case_studies = %w[projects/gm-crypto-rs.html zh/projects/gm-crypto-rs.html]
gm_case_studies.each do |relative|
  source = read_file(ROOT.join(relative), failures)
  record(failures, "#{relative}: demo must pin gmcrypto-core =1.16.0") unless source.include?('gmcrypto-core = "=1.16.0"')
  record(failures, "#{relative}: dudect workflow evidence must link line 169") unless source.include?("dudect-pr.yml#L169")
  record(failures, "#{relative}: stale dudect workflow line 166 remains") if source.include?("dudect-pr.yml#L166")
  %w[constant-time-warrant constant-time-ci-gate byte-identity unsafe-opt-in].each do |slug|
    record(failures, "#{relative}: missing #{slug} note link") unless source.include?(slug)
  end
end

dudect_data = YAML.load_file(ROOT.join("_data/dudect.yml"))
record(failures, "_data/dudect.yml: gate_display must preserve 0.20") unless dudect_data["gate_display"] == "0.20"
record(failures, "_data/dudect.yml: sentinel_display must preserve 0.55") unless dudect_data["sentinel_display"] == "0.55"
dudect_chart_contract = read_file(ROOT.join("_includes/dudect-chart.html"), failures)
record(failures, "dudect-chart.html: historical leak must use status_caught") unless dudect_chart_contract.include?("t.status_caught")
unless dudect_chart_contract.scan("t.status_fire").length == 1
  record(failures, "dudect-chart.html: status_fire must be exclusive to negative_control")
end

vtt = read_file(ROOT.join("assets/video/harness-field-explainer.en.vtt"), failures)
record(failures, "harness-field-explainer.en.vtt: missing load-bearing-line wording") unless vtt.include?("The load-bearing line")

claude_source = read_file(ROOT.join("CLAUDE.md"), failures)
if claude_source.match?(/v0\.8[^\n]*AEAD[^\n]*next|v0\.8 AEAD work is "next"/i)
  record(failures, "CLAUDE.md: stale v0.8 AEAD-next guidance remains")
end

rejected_content = {
  "colophon.html" => ["six small files", "~500 lines"],
  "zh/colophon.html" => ["六个小文件", "约 500 行"],
  "projects/gm-crypto-rs.html" => ["<code>1.9.0</code>, behind", "<code>hash</code> / <code>sign</code> /"],
  "zh/projects/gm-crypto-rs.html" => ["固定在 <code>1.9.0</code>", "<code>hash</code> / <code>sign</code> /"],
  "projects/repolens-rs.html" => ["Planned until"],
  "notes.html" => ["Rust, cryptography, CI, and tooling."],
  # 2026-10-12 (PR 2): the release line is explained per cycle from the project
  # records; the notes must not state a general rule as the project's policy.
  "_notes/releases-that-change-nothing.md" => ["follows a rule:", "The rule has kept applying", "That rule shows up",
                                                "a cycle that changes no output", "refused to bill assurance churn"],
  "_notes/releases-that-change-nothing.zh.md" => ["有条规矩", "这条规矩后来也一直在用", "这条规矩，体现成", "什么都没变的版本，就不发",
                                                   "输出没变就不发版", "的周期都合进了主干", "拒绝把「只做保障」的变动"],
  "_notes/starting-a-notebook.md" => ["The real rule is narrower", "That rule is stated under Evidence", "the *policy* behind a skip"],
  "_notes/starting-a-notebook.zh.md" => ["真正的规矩更窄", "这条规矩写在", "[什么都没变的版本，就不发]", "背后的**规则**"],
  # PR 2: the note describes the project's opt-in design from its source and
  # does not say who made the decision.
  "_notes/unsafe-opt-in.md" => ["I didn't, because", "That's the property I", "I chose", "I decided"],
  "_notes/unsafe-opt-in.zh.md" => ["我没这么干", "这正是我想让它默认成立", "我选择", "我决定"],
  # Positioning (PR 2): "mostly Rust" describes the projects, not the person.
  "index.html" => ["software engineer, mostly Rust", "Outcomes, <em>mostly in Rust.</em>"],
  "zh/index.html" => ["软件工程师，主要写 Rust", "大多用 Rust。</em>"]
}.freeze

# 2026-10-12 (PR 2): contribution statements stay within what the Owner
# confirmed: requirements by him, implementation by AI coding assistants, review
# shifted to AI agents following defined rules. No authorship, audit or
# every-finding claims; rule authorship and merge/release authority stay unstated.
{
  "en" => ["I wrote the code", "I wrote most", "I wrote all", "I wrote it myself", "I personally", "every finding", "single-handedly", "sole author",
           "I audited", "I designed all", "I reviewed every", "I approve", "my approval"],
  "zh" => ["我亲手写", "每一条发现", "我审计", "独自完成", "由我一个人", "我批准", "须经我"]
}.then do |overclaims|
  %w[index.html about.html projects/gm-crypto-rs.html zh/index.html zh/about.html zh/projects/gm-crypto-rs.html].each do |relative|
    normalized = read_file(ROOT.join(relative), failures).gsub(/\s+/, " ")
    lang = relative.start_with?("zh/") ? "zh" : "en"
    overclaims[lang].each do |phrase|
      record(failures, "#{relative}: unconfirmed contribution claim #{phrase.inspect}") if normalized.include?(phrase)
    end
  end
end

rejected_content.each do |relative, phrases|
  # Whitespace-normalized, so a phrase hard-wrapped across lines still counts.
  source = read_file(ROOT.join(relative), failures).gsub(/\s+/, " ")
  phrases.each do |phrase|
    record(failures, "#{relative}: rejected reviewed phrase remains: #{phrase.inspect}") if source.include?(phrase)
  end
end

i18n_content = YAML.load_file(ROOT.join("_data/i18n.yml"))
expected_identity = {
  "en" => {
    "tagline" => "Software engineer building useful software with AI. I share selected work with its status, evidence, and limits visible.",
    "short_tagline" => "Software engineer"
  },
  "zh" => {
    "tagline" => "软件工程师，借助 AI 开发有用的软件。我在这里分享部分项目，说明各自的进展、验证依据和使用限制。",
    "short_tagline" => "软件工程师"
  }
}.freeze
expected_identity.each do |lang, values|
  values.each do |key, expected|
    actual = i18n_content.dig(lang, key)
    record(failures, "i18n.yml: #{lang}.#{key} must be #{expected.inspect}") unless actual == expected
  end
end

# Visitors expect "Home"; "Index" reads as a monograph voice choice.
record(failures, 'i18n.yml: en.nav.home must be "Home"') unless i18n_content.dig("en", "nav", "home") == "Home"
record(failures, 'i18n.yml: zh.nav.home must be "首页"') unless i18n_content.dig("zh", "nav", "home") == "首页"

# About's "Lately" row interpolates public_project; hide it when none exists,
# matching the home-page guard.
%w[about.html zh/about.html].each do |relative|
  source = read_file(ROOT.join(relative), failures)
  record(failures, "#{relative}: Lately/最近 row missing {% if public_project %} guard") unless
    source.match?(/\{%\s*if public_project\s*%\}[\s\S]*?(Released|已发布)[\s\S]*?\{%\s*endif\s*%\}/)
end

# Explainer case study back-links the published extraction-trigger note under
# the shared-core decision (same pattern as gm-crypto → constant-time notes).
{
  "projects/explainer-engine.html" => "/notes/extraction-trigger/",
  "zh/projects/explainer-engine.html" => "/zh/notes/extraction-trigger/"
}.each do |relative, href|
  source = read_file(ROOT.join(relative), failures)
  record(failures, "#{relative}: missing extraction-trigger note back-link (#{href})") unless source.include?(href)
end

source_contracts = {
  "about.html" => [
    'description: "Why I enjoy building software with AI, and how these projects began."',
    "<span>Building with AI, developer tools, cryptography, verified explanation</span>"
  ],
  "zh/about.html" => [
    'description: "我为什么喜欢借助 AI 做软件，以及这些项目是怎样开始的。"',
    # Each item is one .nowrap run, so the row breaks only after 、 (never inside 密码学).
    '<span><span class="nowrap">借助 AI 做软件</span>、<span class="nowrap">开发者工具</span>、<span class="nowrap">密码学</span>、<span class="nowrap">能按源码核对的讲解</span></span>'
  ],
  "contact.html" => [
    'description: "Ways to contact Frank Xue, with response expectations and links to public work."'
  ],
  "zh/contact.html" => [
    'description: "联系 Frank Xue 的方式、回复预期，以及公开作品链接。"'
  ],
  # 2026-10-12 (PR 2): section (03) no longer repeats the project list, so the
  # per-project "no public source link" notes live on the projects index (pinned
  # below). The home page keeps the Status-panel disclosure, an intro that says
  # status is stated per project and that some work is private or pre-release,
  # and the featured case study's audit disclosure.
  "index.html" => ["View selected work", "Browse all notes",
                   "Only public-tagged work is independently verifiable here.",
                   "I enjoy building software with AI coding assistants.",
                   "the tools for AI coding agents and CI runners are private projects",
                   "the explainer-video pipeline is written in Python, with public source and pre-release status.",
                   "including that it has not been independently audited"],
  "zh/index.html" => ["查看精选项目", "浏览全部笔记",
                      "别人能自己核对的，只有已打公开标签（tag）的作品。",
                      "我喜欢借助 AI 编程助手做软件，也很享受这个过程。",
                      "面向 AI 编程 Agent 和 CI runner 的工具目前是私有项目",
                      "讲解视频生成流程则用 Python 编写，源码已公开，处于预发布阶段。",
                      "这个库没有经过独立审计"],
  "projects.html" => ["Private project — no public source link.", "Local prototype — no public source link."],
  "zh/projects.html" => ["私有项目——暂无公开源码链接。", "本地原型——暂无公开源码链接。"],
  "notes.html" => [
    'description: "Working notes on software engineering: evidence, interfaces, reliability, cryptography, CI, and the choices behind shipped systems."',
    "These are working notes on how software claims become inspectable"
  ],
  "zh/notes.html" => [
    'description: "软件工程工作笔记：证据、接口、可靠性、密码学、CI，以及已交付系统背后的取舍。"',
    "这些工作笔记关心的是：软件说法怎样变得可核对"
  ],
  "_notes/starting-a-notebook.md" => [
    "Put the most decision-relevant evidence first, then make its limits easy to find.",
    "/notes/constant-time-warrant/",
    "/notes/extraction-trigger/"
  ],
  "_notes/starting-a-notebook.zh.md" => [
    "先放最影响判断的证据，再让它的边界也容易找到。",
    "/zh/notes/constant-time-warrant/",
    "/zh/notes/extraction-trigger/"
  ],
  "projects/repolens-rs.html" => ["Planned work remains uncommitted until it is tied to a public milestone."],
  "zh/projects/repolens-rs.html" => ["后续工作在绑定公开里程碑之前，不写成已承诺计划。"],
  # 2026-10-12: the GmSSL interop skip condition must stay visible wherever the
  # comparison is summarised outside the case study (which pins it in case_study).
  "_notes/byte-identity.md" => ["skipped with a warning"],
  "_notes/byte-identity.zh.md" => ["带着警告跳过"],
  "projects/gm-crypto-rs-releases.html" => ["skips it with a warning"],
  # PR 2: the opt-in design is stated with the reason gmcrypto-core's Cargo.toml gives.
  "_notes/unsafe-opt-in.md" => ["The core's default feature set is empty, and its",
                                "gm-crypto-rs/blob/v1.16.0/crates/gmcrypto-core/Cargo.toml#L51-L54) gives the reason for the split"],
  "_notes/unsafe-opt-in.zh.md" => ["核心的默认 feature 集合是空的；它的",
                                   "gm-crypto-rs/blob/v1.16.0/crates/gmcrypto-core/Cargo.toml#L51-L54) 也写明了这样拆的原因"],
  "zh/projects/gm-crypto-rs-releases.html" => ["带着警告跳过"]
}.freeze

source_contracts.each do |relative, phrases|
  source = read_file(ROOT.join(relative), failures)
  normalized = source.gsub(/\s+/, " ")
  phrases.each do |phrase|
    record(failures, "#{relative}: missing reviewed content contract #{phrase.inspect}") unless normalized.include?(phrase)
  end
end

gm_en = read_file(ROOT.join("projects/gm-crypto-rs.html"), failures)
gm_zh = read_file(ROOT.join("zh/projects/gm-crypto-rs.html"), failures)
# gm-crypto-rs is "MIT OR Apache-2.0"; the tag ships LICENSE-APACHE and
# LICENSE-MIT, with no plain LICENSE file. Assert both, or a dropped half
# would silently misstate the terms.
{ "projects/gm-crypto-rs.html" => gm_en, "zh/projects/gm-crypto-rs.html" => gm_zh }.each do |relative, source|
  %w[LICENSE-APACHE LICENSE-MIT].each do |file|
    record(failures, "#{relative}: missing immutable #{file} link") unless source.include?("v1.11.0/#{file}")
  end
end
record(failures, "projects/gm-crypto-rs.html: missing FIPS expansion") unless gm_en.include?("U.S. Federal Information Processing Standards (FIPS)")
record(failures, "zh/projects/gm-crypto-rs.html: missing FIPS expansion") unless gm_zh.include?("美国联邦信息处理标准（FIPS）")

%w[colophon.html zh/colophon.html].each do |relative|
  source = read_file(ROOT.join(relative), failures)
  record(failures, "#{relative}: missing localStorage privacy disclosure") unless source.include?("frankxue.theme")
end

%w[about.html zh/about.html].each do |relative|
  source = read_file(ROOT.join(relative), failures)
  normalized = source.gsub(/\s+/, " ")
  # 2026-10-13: the approved About is a short personal introduction.
  # Contribution and technical disclosures remain mandatory in the case study
  # opening below. If timing claims return here, require their caveats locally.
  zh = relative.start_with?("zh/")
  required = zh ? ["数学和计算机科学背景", "借助 AI 编程助手实现", "实际使用体验",
                   "与 GmSSL 等现有实现的兼容性", "我还在学习 Rust",
                   "/zh/projects/gm-crypto-rs/"] :
                  ["background in mathematics and computer science", "used AI coding assistants to implement",
                   "practical usability", "compatibility with existing implementations such as GmSSL",
                   "I'm still learning Rust", "/projects/gm-crypto-rs/"]
  stale = zh ? ["每次提交", "构建就会失败", "在发布前拦住", "软件工程，主要写 Rust", "主要写 Rust，做的多是", "软件工程师，主要",
                "一份还在改的说明", "这份介绍还在修改", "关于，<em>大概如此"] :
               ["every commit", "fails the build", "before a release", "who works mostly in Rust", "Software engineering, mostly Rust", "software engineer, mostly",
                "A working draft", "more or less"]
  required.each { |phrase| record(failures, "#{relative}: About summary missing #{phrase.inspect}") unless normalized.include?(phrase) }
  stale.each { |phrase| record(failures, "#{relative}: stale About claim #{phrase.inspect}") if normalized.include?(phrase) }
  if normalized.match?(zh ? /时序|常量时间/ : /timing|constant-time/i)
    caveats = zh ? ["没有经过独立审计", "统计证据", "不能证明"] : ["not been independently audited", "statistical evidence", "not a proof"]
    caveats.each { |phrase| record(failures, "#{relative}: timing mention missing caveat #{phrase.inspect}") unless normalized.include?(phrase) }
  end
  full_name = zh ? "Fengxiang（Frank）Xue" : "Fengxiang (Frank) Xue"
  full_name_count = normalized.scan(full_name).length
  record(failures, "#{relative}: #{full_name.inspect} must appear exactly once (found #{full_name_count})") unless full_name_count == 1
end


# Keep the case-study opening's safeguards even when About is shortened.
{
  "projects/gm-crypto-rs.html" => ["My part.", "AI coding assistants", "AI agents following defined rules",
    "I do not regularly review the code line by line", "GmSSL oracle's provisioning and version check succeed",
    "if either fails, the comparison is skipped with a warning while the job still passes",
    "selected paths", "x86-64 Linux runners", "Not independently audited",
    "adversarial review by two AI models", "evidence under the tested conditions, not proof of constant-time behavior"],
  "zh/projects/gm-crypto-rs.html" => ["我负责的部分", "AI 编程助手", "遵循既定规则的 AI Agent",
    "并不经常逐行细审代码", "准备就绪且版本校验通过后，才会执行这项比对",
    "如果准备或版本校验失败，CI 会发出警告并跳过比对，任务仍会通过",
    "选定路径", "x86-64 Linux runner", "没有经过独立审计", "两个 AI 模型以对抗方式进行",
    "只能作为测试条件下的证据，不能证明常量时间行为"]
}.each do |relative, phrases|
  opening = read_file(ROOT.join(relative), failures).split("{% include project-summary.html %}", 2).first.gsub(/\s+/, " ")
  phrases.each { |phrase| record(failures, "#{relative}: opening missing safeguard #{phrase.inspect}") unless opening.include?(phrase) }
end

# A deliberately leaky control must be detected; detection is not CI failure.
{
  "control_label" => "negative_control：必须检测到此处刻意引入的泄漏（确认检测器能识别这处泄漏）",
  "status_fire" => "必须检出泄漏"
}.each do |key, expected|
  record(failures, "i18n.yml: zh.dudect.#{key} must distinguish detection from check failure") unless i18n_content.dig("zh", "dudect", key) == expected
end
{
  "_notes/constant-time-warrant.md" => "a detector that must flag a deliberately introduced leak",
  "_notes/constant-time-warrant.zh.md" => "一个必须检出刻意引入的泄漏的检测器"
}.each do |relative, phrase|
  excerpt = YAML.safe_load(read_file(ROOT.join(relative), failures).split("---", 3)[1], permitted_classes: [Date]).fetch("excerpt")
  record(failures, "#{relative}: negative control excerpt must describe detection") unless excerpt.include?(phrase)
end

# Check the body as well: a corrected excerpt must not hide the opposite claim.
{
  "_notes/constant-time-warrant.md" => "The detector must flag its deliberately introduced leak; if it does not, the check fails.",
  "_notes/constant-time-warrant.zh.md" => "检测器必须检出其中刻意引入的泄漏；未检出才会导致这项检查失败。"
}.each do |relative, phrase|
  body = read_file(ROOT.join(relative), failures).split("---", 3).last.gsub(/\s+/, " ")
  record(failures, "#{relative}: negative control body must distinguish detection from check failure") unless body.include?(phrase)
end

# --- 2026-08-10 site-review accessibility contracts ---
accessibility_i18n_keys = %w[
  nav.menu nav.skip theme.aria_template install.copy install.copied install.aria
  install.copied_aria install.manual install.manual_aria dudect.table_scroll_label
].freeze
%w[en zh].each do |lang|
  accessibility_i18n_keys.each do |path|
    value = path.split(".").reduce(i18n_content[lang]) { |node, key| node.is_a?(Hash) ? node[key] : nil }
    record(failures, "i18n.yml: missing #{lang}.#{path}") if value.to_s.empty?
  end

  theme_template = i18n_content.dig(lang, "theme", "aria_template").to_s
  %w[{current} {effective} {next}].each do |placeholder|
    record(failures, "i18n.yml: #{lang}.theme.aria_template missing #{placeholder}") unless theme_template.include?(placeholder)
  end
end

main_js = read_file(ROOT.join("assets/js/main.js"), failures)
{
  "main background" => "document.getElementById('main')",
  "footer backgrounds" => "document.querySelectorAll('footer')",
  "background inert state" => ".inert",
  "first navigation link" => "firstNavLink",
  "focus placement on open" => "firstNavLink.focus()",
  "Escape focus restoration" => "setOpen(false, { restoreFocus: true })",
  "backdrop pointer dismissal" => "pointerdown",
  "body backdrop hit target" => "event.target === document.body",
  "desktop media-query cleanup" => "matchMedia('(min-width: 760px)')",
  "bfcache cleanup" => "pageshow"
}.each do |label, needle|
  record(failures, "main.js: missing #{label} contract") unless main_js.include?(needle)
end

copy_js = read_file(ROOT.join("assets/js/copy.js"), failures)
{
  "shared state updater" => "setState",
  "manual-copy failure state" => "showManual",
  "accessible-name update" => "setAttribute('aria-label'",
  "localized manual label" => "data-label-manual",
  "localized idle accessible name" => "data-aria-copy",
  "localized success accessible name" => "data-aria-done",
  "localized manual accessible name" => "data-aria-manual"
}.each do |label, needle|
  record(failures, "copy.js: missing #{label} contract") unless copy_js.include?(needle)
end

%w[projects/gm-crypto-rs/index.html zh/projects/gm-crypto-rs/index.html].each do |relative|
  html = read_file(SITE.join(relative), failures)
  %w[data-label-manual data-aria-copy data-aria-done data-aria-manual].each do |attribute|
    record(failures, "#{relative}: install control missing #{attribute}") unless html.include?(attribute)
  end
end

contents_js = read_file(ROOT.join("assets/js/contents.js"), failures)
unless contents_js.include?("if (h.id) { used.add(h.id); return h.id; }")
  record(failures, "contents.js: source-rendered heading ID branch must be retained")
end
# Last-resort TOC label must follow the page locale when data-toc-label is absent.
record(failures, "contents.js: missing ZH last-resort TOC label") unless contents_js.include?("本页内容")
record(failures, "contents.js: TOC fallback must inspect document language") unless
  contents_js.match?(/documentElement\.lang|lang-zh/)

theme_js_source = read_file(ROOT.join("assets/js/theme.js"), failures)
%w[跟随系统 浅色 深色].each do |needle|
  record(failures, "theme.js: missing ZH last-resort label #{needle.inspect}") unless theme_js_source.include?(needle)
end
record(failures, "theme.js: state fallbacks must inspect document language") unless
  theme_js_source.match?(/documentElement\.lang|lang-zh/)

if css_path.exist?
  css = css_path.read
  proof_title_rule = css[/^\.hero-proof__title\s*\{[^}]*\}/m].to_s
  record(failures, "style.css: .hero-proof__title must use supported font-weight 600") unless proof_title_rule.match?(/font-weight:\s*600\s*;/)
  record(failures, "style.css: unsupported hero proof font-weight 650 remains") if proof_title_rule.match?(/font-weight:\s*650\s*;/)

  install_copy_rule = css[/\.install__copy\s*\{[^}]*\}/m].to_s
  unless install_copy_rule.match?(/min-(?:block-size|height):\s*44px\s*;/)
    record(failures, "style.css: .install__copy missing 44px minimum target size")
  end

  table_scroll_rule = css[/\.dudect__table-scroll\s*\{[^}]*\}/m].to_s
  unless table_scroll_rule.match?(/overflow-x:\s*auto\s*;/)
    record(failures, "style.css: .dudect__table-scroll missing horizontal overflow")
  end

  # The colophon path's <wbr> (guarded above) is switched off from 22em up, so
  # it breaks the path only on narrow phones. Without this rule wider lines in
  # that paragraph re-wrap (ZH from 416px).
  unless css.match?(/@media\s*\(min-width:\s*22em\)\s*\{\s*\.prose code wbr\s*\{\s*display:\s*none;\s*\}\s*\}/)
    record(failures, "style.css: missing @media (min-width: 22em) { .prose code wbr { display: none; } } (the colophon path's <wbr> would re-wrap wider lines)")
  end

  print_blocks = css.scan(/@media\s+print\s*\{.*?\n\}/m).join("\n")
  %w[.nav-toggle .primary-nav__item--theme .primary-nav__item--switch].each do |selector|
    record(failures, "style.css: print CSS must hide #{selector}") unless print_blocks.include?(selector)
  end
end

dudect_source = read_file(ROOT.join("_includes/dudect-chart.html"), failures)
unless dudect_source.match?(/class="dudect__table-scroll"[^>]*tabindex="0"[^>]*role="region"[^>]*aria-label="\{\{\s*t\.table_scroll_label\s*\|\s*escape\s*\}\}"/m)
  record(failures, "dudect-chart.html: table must be wrapped in a localized keyboard-scrollable region")
end

# --- crates.io publication dates (2026-10-12) ---------------------------------
# Every dated row on the gm-crypto-rs release pages, and the case study's
# current-release row, must show the crates.io publication date in UTC from
# _data/crate_publications.yml. "Not published" rows must not name a version
# that crates.io has. Catches local-time (UTC+8) dates and hand-typed drift,
# not just a missing phrase.
pubs = (YAML.load_file(ROOT.join("_data/crate_publications.yml"))["published_utc"] || {}).transform_keys(&:to_s)
record(failures, "crate_publications.yml: no published versions") if pubs.empty?
version_key = ->(v) { v.split(".").map(&:to_i) }
{ "projects/gm-crypto-rs/releases/index.html" => ["Not published", "crates.io publication dates in UTC"],
  "zh/projects/gm-crypto-rs/releases/index.html" => ["未单独发版", "crates.io 的发布日期（UTC）"] }.each do |relative, (unpublished_marker, utc_label)|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  record(failures, "#{relative}: missing UTC date-convention label") unless html.gsub(/\s+/, " ").include?(utc_label)
  shown = []
  html.scan(%r{<dt>\s*v?([0-9][0-9.]*(?:\s*[–-]\s*[0-9][0-9.]*)?)\s*</dt>\s*<dd>(.*?)</dd>}m).each do |label, body|
    label = label.strip
    text = body.gsub(/<[^>]+>/, "").strip
    if text.start_with?(unpublished_marker)
      if (lo, hi = label.split(/\s*[–-]\s*/)) && hi
        lo_k = version_key.(lo)[0, 2]; hi_k = version_key.(hi)[0, 2]
        inside = pubs.keys.select { |v| k = version_key.(v)[0, 2]; (k <=> lo_k) >= 0 && (k <=> hi_k) <= 0 }
        record(failures, "#{relative}: range #{label} marked unpublished but crates.io has #{inside.join(', ')}") unless inside.empty?
      elsif pubs.key?(label)
        record(failures, "#{relative}: v#{label} marked unpublished but crates.io has it")
      end
      next
    end
    date = text[/\A(\d{4}-\d{2}-\d{2})/, 1]
    next unless date
    shown << label
    if !pubs.key?(label)
      record(failures, "#{relative}: v#{label} dated #{date} but not in crate_publications.yml")
    elsif pubs[label][0, 10] != date
      record(failures, "#{relative}: v#{label} shows #{date}, crates.io UTC date is #{pubs[label][0, 10]}")
    end
  end
  missing = pubs.keys.select { |v| (version_key.(v) <=> [0, 6, 0]) >= 0 } - shown
  record(failures, "#{relative}: published versions missing a dated row: #{missing.sort_by(&version_key).join(', ')}") unless missing.empty?
end
%w[projects/gm-crypto-rs/index.html zh/projects/gm-crypto-rs/index.html].each do |relative|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  m = html.match(%r{<dt>\s*(?:Current|当前版本)\s*</dt>\s*<dd>\s*<strong>v([0-9.]+)</strong>[^<]*?(\d{4}-\d{2}-\d{2})\s*(?:\(UTC\)|（UTC）)})
  newest = pubs.keys.max_by(&version_key)
  if m.nil?
    record(failures, "#{relative}: Current row must show a version with a UTC-labelled publication date")
  elsif pubs[m[1]].nil? || pubs[m[1]][0, 10] != m[2]
    record(failures, "#{relative}: current release v#{m[1]} shows #{m[2]}, crates.io UTC date is #{pubs[m[1]].to_s[0, 10]}")
  elsif m[1] != newest
    record(failures, "#{relative}: Current row shows v#{m[1]} but the newest published version is v#{newest}")
  end
end

# --- LinkedIn contact route (2026-10-12) -------------------------------------
config = YAML.load_file(ROOT.join("_config.yml"))
linkedin = config["linkedin_username"].to_s
if linkedin.empty?
  record(failures, "_config.yml: linkedin_username missing (Owner-approved contact route)")
else
  linkedin_url = "https://www.linkedin.com/in/#{linkedin}/"
  (core_pages.keys + project_pages).each do |relative|
    html = read_file(SITE.join(relative), failures)
    next if html.empty?
    footer = html[%r{<footer class="site-footer".*?</footer>}m].to_s
    record(failures, "#{relative}: footer missing LinkedIn link #{linkedin_url}") unless footer.include?(%(href="#{linkedin_url}"))
    people = graph_nodes_of_type(json_ld_graph(html, failures, relative), "Person")
    record(failures, "#{relative}: Person sameAs missing LinkedIn") unless people.any? { |n| Array(n["sameAs"]).include?(linkedin_url) }
  end
  %w[contact/index.html zh/contact/index.html].each do |relative|
    html = read_file(SITE.join(relative), failures)
    record(failures, "#{relative}: contact list missing LinkedIn") unless html[%r{<dl class="contact-direct">.*?</dl>}m].to_s.include?(linkedin_url)
  end
end

# --- Corrected notes keep their dated correction (2026-10-12) ----------------
# Each banner must also END its own blockquote: without a blank line after the
# "> " line, kramdown folds the note's first paragraph into the banner.
{ "notes/constant-time-ci-gate/index.html" => ["Correction (2026-10-12, UTC)", "case study</a>."],
  "zh/notes/constant-time-ci-gate/index.html" => ["更正（2026-10-12，UTC）", "案例页</a>。"],
  "notes/constant-time-warrant/index.html" => ["Corrected 2026-10-12 (UTC)", "scope and enforcement."],
  "zh/notes/constant-time-warrant/index.html" => ["2026-10-12（UTC）更正", "约束力一致。"] }.each do |relative, (phrase, ending)|
  html = read_file(SITE.join(relative), failures)
  next if html.empty?
  record(failures, "#{relative}: dated correction notice missing") unless html.include?(phrase)
  quote = html.scan(%r{<blockquote>(.*?)</blockquote>}m).map(&:first).find { |q| q.include?(phrase) }
  record(failures, "#{relative}: correction notice must stand alone (its blockquote swallowed body text)") if quote && !quote.strip.sub(%r{</p>\z}, "").rstrip.end_with?(ending)
  record(failures, "#{relative}: timing threshold shown as \"<\"; the check passes at the limit") if html.match?(/\|τ\|(?:<\/code>)?\s*(?:&lt;|<)\s*0\.20/)
end

if failures.empty?
  puts "Site validation passed"
else
  warn failures.join("\n")
  warn "Hint: run `bundle exec jekyll build` before validation; `jekyll serve` can leave localhost URLs in _site."
  exit 1
end
