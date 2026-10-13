#!/usr/bin/env ruby
# frozen_string_literal: true

# Release-drift check (NON-BLOCKING, network-dependent).
#
# Why this is separate from validate_site.rb: that validator is hermetic — it
# reads only local files so it never flakes and runs offline. This check is the
# opposite: it reaches out to crates.io to answer one question the local files
# can't — "has a crate published a version newer than the one the site claims?"
#
# It exists because the site silently sat at v0.16.0 for weeks while
# gmcrypto-core had already published 1.0.0. A hermetic validator can't catch
# that; only a comparison against the live registry can.
#
# Source of truth: the crates.io SPARSE INDEX (https://index.crates.io/...),
# not the JSON API (the API enforces a data-access policy that 403s automated
# clients; the sparse index is the supported way to read publish state).
#
# Posture: warn-only BY DEFAULT. A publish can land at any time, and an
# unrelated PR must never go red because the registry moved ahead — so on PRs
# and pushes this only annotates and exits 0.
#
# Set DRIFT_STRICT=1 to exit non-zero when drift is found. The weekly cron and
# manual runs use it: a warning nobody reads is the same as no check (the site
# sat at v1.6.0 for six weeks while gmcrypto-core shipped 1.9.0, warning green
# the whole time). A red scheduled run is an actual notification and blocks no
# one's work. Unverified crates never fail — only real drift does.

require "json"
require "net/http"
require "pathname"
require "uri"
require "yaml"

ROOT = Pathname.new(__dir__).parent
PROJECTS = YAML.load_file(ROOT.join("_data/projects.yml"))

# GitHub Actions annotation helpers (no-ops when run locally — the prefixes are
# just inert text outside Actions).
def warn_annotation(message)
  puts "::warning::#{message}"
end

def summary(line)
  path = ENV["GITHUB_STEP_SUMMARY"]
  return if path.nil? || path.empty?

  File.write(path, "#{line}\n", mode: "a")
rescue StandardError
  nil # best-effort: a summary write must never fail the run
end

# crates.io sparse-index path: 1-char -> "1/{name}", 2 -> "2/{name}",
# 3 -> "3/{c}/{name}", else "{c1c2}/{c3c4}/{name}". Names are lowercased.
def sparse_index_path(crate)
  c = crate.downcase
  case c.length
  when 1 then "1/#{c}"
  when 2 then "2/#{c}"
  when 3 then "3/#{c[0]}/#{c}"
  else "#{c[0, 2]}/#{c[2, 2]}/#{c}"
  end
end

# Returns the latest non-yanked STABLE version (a Gem::Version), or a symbol:
#   :no_stable   — fetched OK, but the crate has only prereleases
#   :unreachable — network/HTTP/parse failure, or an empty/garbage response
def latest_published_version(crate)
  uri = URI("https://index.crates.io/#{sparse_index_path(crate)}")
  # Honor standard proxy env vars (https_proxy / no_proxy). find_proxy returns
  # nil when none apply — e.g. on GitHub-hosted runners — so we connect direct
  # there and via the proxy in environments that require one.
  proxy = uri.find_proxy
  http = if proxy
    Net::HTTP.new(uri.host, uri.port, proxy.host, proxy.port, proxy.user, proxy.password)
  else
    Net::HTTP.new(uri.host, uri.port)
  end
  http.use_ssl = true
  http.open_timeout = 10
  http.read_timeout = 10

  response = http.get(uri.request_uri)
  return :unreachable unless response.is_a?(Net::HTTPSuccess)

  body = response.body

  versions = []
  body.each_line do |line|
    line = line.strip
    next if line.empty?

    begin
      entry = JSON.parse(line)
      next if entry["yanked"]

      versions << Gem::Version.new(entry["vers"])
    rescue ArgumentError, JSON::ParserError
      next
    end
  end

  return :unreachable if versions.empty? # empty/garbage response — treat as a miss

  # Compare against the latest STABLE release: the site lists stable public
  # tags, so a published prerelease (e.g. 1.1.0-rc.1) must not register as drift.
  versions.reject(&:prerelease?).max || :no_stable
rescue StandardError => e
  warn "release-drift: #{crate} lookup failed — #{e.class}: #{e.message}"
  :unreachable
end

def crate_name_from_url(crate_url)
  return nil if crate_url.nil? || crate_url.to_s.strip.empty?

  uri = URI.parse(crate_url.to_s.strip)
  return nil unless uri.host == "crates.io"

  match = uri.path.match(%r{\A/crates/([^/]+)})
  match && match[1]
rescue URI::InvalidURIError
  nil
end

# release labels are git tags ("v1.0.0"); crate versions are bare ("1.0.0").
def normalize_release(release)
  release.to_s.strip.sub(/\Av/, "")
end


# --- GitHub release source (second upstream) --------------------------------
# crates.io can lag or lead the GitHub release (publish is a separate step), so
# the site is also compared against the repo's latest published GitHub release,
# falling back to the highest stable semver tag when the repo has no releases.
# Public API, no secrets; GITHUB_TOKEN (if set) only raises the rate limit.
def github_get(path)
  uri = URI("https://api.github.com#{path}")
  proxy = uri.find_proxy
  http = proxy ? Net::HTTP.new(uri.host, uri.port, proxy.host, proxy.port, proxy.user, proxy.password) : Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 10
  http.read_timeout = 10
  req = Net::HTTP::Get.new(uri.request_uri)
  req["Accept"] = "application/vnd.github+json"
  req["User-Agent"] = "frankxue-release-drift"
  token = ENV["GITHUB_TOKEN"].to_s.strip
  req["Authorization"] = "Bearer #{token}" unless token.empty?
  http.request(req)
end

def stable_version(tag)
  v = Gem::Version.new(normalize_release(tag))
  v.prerelease? ? nil : v
rescue ArgumentError
  nil
end

# Returns [Gem::Version, label] or :unreachable / :no_stable.
# Upstream = max(latest published GitHub Release, highest stable semver tag).
# Both are needed: gm-crypto-rs has pushed tags (v1.16.0) without cutting a
# GitHub Release (latest Release was still v1.13.0), so releases/latest alone
# would report a false "site ahead"; tags alone would miss a release whose tag
# falls past the first page.
def latest_github_version(owner_repo)
  candidates = []
  res = github_get("/repos/#{owner_repo}/releases/latest")
  if res.is_a?(Net::HTTPSuccess)
    v = stable_version(JSON.parse(res.body)["tag_name"])
    candidates << [v, "release"] if v
  elsif !res.is_a?(Net::HTTPNotFound) # 404 = no releases; fall back to tags
    warn "release-drift: #{owner_repo} releases/latest HTTP #{res.code}"
    return :unreachable
  end
  res = github_get("/repos/#{owner_repo}/tags?per_page=100")
  return :unreachable unless res.is_a?(Net::HTTPSuccess)

  tag = JSON.parse(res.body).filter_map { |t| stable_version(t["name"]) }.max
  candidates << [tag, "tag"] if tag
  return :no_stable if candidates.empty?

  best = candidates.max_by(&:first)
  rel = candidates.find { |c| c[1] == "release" }
  label = rel && rel[0] < best[0] ? "tag (latest GitHub Release is only v#{rel[0]})" : best[1]
  [best[0], label]
rescue StandardError => e
  warn "release-drift: #{owner_repo} lookup failed — #{e.class}: #{e.message}"
  :unreachable
end

def github_repo_from_url(url)
  m = url.to_s.strip.match(%r{\Ahttps://github\.com/([^/]+/[^/]+?)(?:\.git)?/?\z})
  m && m[1]
end

# Case-study pages that pin the demo dependency (`<crate> = "=X.Y.Z"`).
DEMO_PIN_PAGES = {
  "gm-crypto-rs" => ["projects/gm-crypto-rs.html", "zh/projects/gm-crypto-rs.html"]
}.freeze

checked = 0
drift = 0
unverified = 0

PROJECTS.each do |project|
  next unless project["release_source"] == "public_tag"

  crate = crate_name_from_url(project["crate_url"])
  next if crate.nil? || crate.empty?

  slug = project["slug"] || crate
  site_raw = normalize_release(project["release"])

  begin
    site_version = Gem::Version.new(site_raw)
  rescue ArgumentError
    warn_annotation("#{slug}: release #{project["release"].inspect} is not a comparable version — skipping drift check")
    next
  end


  # GitHub latest release / tag.
  if (owner_repo = github_repo_from_url(project["repo_url"]))
    gh = latest_github_version(owner_repo)
    checked += 1
    if gh.is_a?(Array)
      gh_version, kind = gh
      if site_version < gh_version
        drift += 1
        warn_annotation("#{slug}: site release v#{site_version} trails GitHub #{owner_repo} latest #{kind} v#{gh_version} — update `release:` in _data/projects.yml, the demo pins in #{(DEMO_PIN_PAGES[slug] || []).join(", ")}, and the case study copy")
        summary("- 🔴 **#{slug}** — site `v#{site_version}` < GitHub latest #{kind} `v#{gh_version}` (DRIFT)")
        puts "DRIFT  #{slug}: site v#{site_version} < GitHub #{owner_repo} latest #{kind} v#{gh_version}"
        puts "       update: _data/projects.yml (#{slug} release:), #{(DEMO_PIN_PAGES[slug] || []).join(", ")}"
      elsif site_version > gh_version
        # Not counted as drift: crates.io (checked below) is authoritative for
        # "published", and a tag can trail a crates.io publish briefly.
        warn_annotation("#{slug}: site release v#{site_version} is AHEAD of GitHub #{owner_repo} latest #{kind} v#{gh_version}")
        puts "AHEAD  #{slug}: site v#{site_version} > GitHub #{owner_repo} latest #{kind} v#{gh_version}"
      else
        summary("- ✅ **#{slug}** — site `v#{site_version}` matches GitHub latest #{kind}")
        puts "OK     #{slug}: site v#{site_version} == GitHub #{owner_repo} latest #{kind} v#{gh_version}"
      end
    else
      unverified += 1
      warn_annotation("#{slug}: could not read latest release/tag for #{owner_repo} (#{gh}) — not verified this run")
    end
  end

  # Demo dependency pins must equal the site release (local check, no network).
  (DEMO_PIN_PAGES[slug] || []).each do |rel|
    path = ROOT.join(rel)
    unless path.exist?
      warn_annotation("#{slug}: demo pin page #{rel} not found")
      next
    end
    pins = path.read.scan(/#{Regexp.escape(crate)}\s*=\s*(?:"|&quot;)=([0-9][0-9A-Za-z.\-]*)/).flatten.uniq
    checked += 1
    if pins.empty?
      warn_annotation("#{slug}: no `#{crate} = \"=X.Y.Z\"` pin found in #{rel}")
    elsif pins != [site_version.to_s]
      drift += 1
      warn_annotation("#{slug}: #{rel} pins #{crate} =#{pins.join(", =")} but _data/projects.yml release is v#{site_version} — update the pin in #{rel}")
      puts "PIN    #{slug}: #{rel} pins =#{pins.join(", =")} != release v#{site_version}"
    else
      puts "OK     #{slug}: #{rel} pins =#{pins.first}"
    end
  end

  published = latest_published_version(crate)
  checked += 1

  case published
  when :unreachable
    unverified += 1
    warn_annotation("#{slug}: could not read #{crate} from the crates.io sparse index — drift not verified this run")
    summary("- ⚠️ **#{slug}** — could not verify (`#{crate}` unreachable)")
    next
  when :no_stable
    unverified += 1
    warn_annotation("#{slug}: #{crate} has no stable release on crates.io yet — nothing to compare")
    summary("- ⚠️ **#{slug}** — no stable `#{crate}` release on crates.io yet")
    next
  end

  if site_version < published
    drift += 1
    msg = "#{slug}: site release v#{site_version} trails crates.io #{crate} #{published} — refresh _data/projects.yml + the case study"
    warn_annotation(msg)
    summary("- 🔴 **#{slug}** — site `v#{site_version}` < crates.io `#{crate} #{published}` (DRIFT)")
    puts "DRIFT  #{slug}: site v#{site_version} < crates.io #{crate} #{published}"
  elsif site_version > published
    drift += 1
    msg = "#{slug}: site release v#{site_version} is AHEAD of crates.io #{crate} #{published} — site claims an unpublished version"
    warn_annotation(msg)
    summary("- 🟠 **#{slug}** — site `v#{site_version}` > crates.io `#{crate} #{published}` (site ahead of registry)")
    puts "AHEAD  #{slug}: site v#{site_version} > crates.io #{crate} #{published}"
  else
    summary("- ✅ **#{slug}** — site `v#{site_version}` matches crates.io `#{crate} #{published}`")
    puts "OK     #{slug}: site v#{site_version} == crates.io #{crate} #{published}"
  end
end

strict = !ENV["DRIFT_STRICT"].to_s.strip.empty?
posture = strict ? "strict" : "warn-only"

if checked.zero?
  puts "No public_tag projects with a crate_url to check."
else
  puts "\nChecked #{checked} crate(s); #{drift} with drift; #{unverified} unverified. (#{posture})"
end

# Unverified crates never fail the run — a network blip is not drift.
exit 1 if strict && drift.positive?

exit 0
