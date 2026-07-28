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
