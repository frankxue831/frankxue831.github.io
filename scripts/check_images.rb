#!/usr/bin/env ruby
# frozen_string_literal: true

# Image budget check (pure stdlib). Run after `bundle exec jekyll build`:
#   ruby scripts/check_images.rb
# 1. Every file under assets/img/<subfolder>/** must be .webp and <= 100 KB.
#    Top-level assets/img/* (evidence-budget-12s.jpg, social cards, icons) is
#    deliberately out of scope.
# 2. Every <img> in _site/**/*.html whose src is under /assets/img/<subfolder>/
#    must carry width, height and alt attributes (use _includes/picture.html).

require "pathname"
Encoding.default_external = Encoding::UTF_8

ROOT = Pathname.new(__dir__).parent
SITE = ROOT.join("_site")
MAX_BYTES = 100 * 1024
failures = []

Pathname.glob(ROOT.join("assets/img/*/**/*")).select(&:file?).each do |f|
  rel = f.relative_path_from(ROOT)
  failures << "#{rel}: not .webp" unless f.extname.downcase == ".webp"
  failures << "#{rel}: #{(f.size / 1024.0).round(1)} KB > 100 KB" if f.size > MAX_BYTES
end

abort "check_images: _site/ missing; run `bundle exec jekyll build` first" unless SITE.directory?
Pathname.glob(SITE.join("**/*.html")).each do |page|
  page.read.scan(/<img\b[^>]*>/im).each do |tag|
    src = tag[/\ssrc\s*=\s*["']([^"']+)["']/i, 1].to_s
    next unless src.sub(%r{\Ahttps?://[^/]+}i, "") =~ %r{\A/assets/img/[^/]+/}
    missing = %w[width height alt].reject { |a| tag =~ /\s#{a}\s*=/i }
    failures << "#{page.relative_path_from(SITE)}: <img src=\"#{src}\"> missing #{missing.join(', ')}" unless missing.empty?
  end
end

if failures.empty?
  puts "check_images: OK"
else
  warn failures.join("\n")
  exit 1
end
