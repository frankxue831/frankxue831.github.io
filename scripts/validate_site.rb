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

(core_pages.keys + project_pages).each do |relative|
  path = SITE.join(relative)
  html = read_file(path, failures)
  next if html.empty?

  record(failures, "#{relative}: missing canonical URL") unless html.match?(%r{<link rel="canonical" href="#{Regexp.escape(BASE_URL)}/})
  record(failures, "#{relative}: missing meta description") unless html.match?(%r{<meta name="description" content="[^"]+"})
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
    pattern = %r{<link rel="alternate" hreflang="#{Regexp.escape(alternate[:hreflang])}" href="#{Regexp.escape(alternate[:href])}">}
    unless html.match?(pattern)
      record(failures, "#{relative}: missing alternate #{alternate[:hreflang]} #{alternate[:href]}")
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
    href = CGI.unescapeHTML(match.first)
    source = path.relative_path_from(SITE).to_s
    target = generated_target_for(href)
    if target == :outside_site
      record(failures, "#{source}: internal link escapes _site: #{href}")
    elsif target
      internal_targets << [source, target]
    end
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
