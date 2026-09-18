# frozen_string_literal: true

source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", github: "rails/rails", branch: "main"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use sqlite3 as the database for Active Record
gem "sqlite3", ">= 2.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails", "~> 3.0"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# Admin framework for managing authors and resources
gem "avo", "~> 3.0"

# Pagination for author resource lists
gem "kaminari", "~> 1.2"

# Rate limiting and throttling middleware
gem "rack-attack"

# Proof-of-work spam protection
gem "active_hashcash"

gem "aws-sdk-s3"


group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Test coverage reporting [https://github.com/simplecov-ruby/simplecov]
  gem "simplecov", require: false

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Code smell detector [https://github.com/troessner/reek]
  gem "reek", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Additional cops: performance, minitest and thread-safety linting
  gem "rubocop-performance", require: false
  gem "rubocop-minitest", require: false
  gem "rubocop-thread_safety", require: false

  # A Ruby Gem that adds annotations to your Rails models and route files.
  gem "annotaterb"

  # HTML+ERB linter. `herb lint` itself shells out to `npx @herb-tools/linter` (Node), which
  # doesn't fit an app that deliberately keeps Node off its stack (importmap-rails +
  # tailwindcss-ruby). herb-embedded runs the same upstream rule engine inside Ruby via an
  # embedded JS runtime instead. [https://github.com/defmethodinc/herb-embedded]
  gem "herb-embedded", require: false

  # Detects likely-unused methods (static analysis) [https://github.com/seattlerb/debride]
  gem "debride", require: false

  # Finds Rails routes with no matching controller action, or vice versa.
  # No `require: false`: its Railtie needs to load for `rake traceroute` to exist.
  gem "traceroute"

  # Ranks files by (churn * complexity * code smells) to find hotspots worth refactoring first
  gem "skunk", require: false

  # Structural duplication detector (already a transitive dep of skunk;
  # listed directly for its own bin/flay, since Reek doesn't catch
  # duplication *across* files/classes - see docs/llms/development.md)
  gem "flay", require: false

  # Architecture linter: declares component boundaries in Archspec.rb and
  # checks them via static analysis (no app boot, no AI) [https://archspecrb.dev]
  gem "archspec", require: false

  # Detects N+1 queries at runtime by flagging them during the test run.
  # Its default non-MySQL fingerprinting needs the `pg_query` gem (Postgres-only
  # syntax), which can't parse SQLite's already-parameterized queries anyway -
  # config/initializers/prosopite.rb overrides fingerprinting for SQLite
  # instead, so no extra gem needed here. [https://github.com/charkost/prosopite]
  gem "prosopite"

  # Property-based testing. Compared against Rantly: both have zero external
  # deps, but PropCheck's shrinking (reducing a failing case to its simplest
  # form) is the more complete implementation, and it documents first-class
  # Minitest/RSpec/test-unit integration - Rantly needs a hand-rolled Minitest
  # adapter. Actively released (1.0 reached in 2026); Rantly's shrinking gaps
  # are a known, unaddressed limitation. [https://github.com/Qqwy/ruby-prop_check]
  gem "prop_check", require: false

  # Mutation testing. Compared against mutant, the category's best-known tool:
  # mutant carries 6 runtime deps and needs a separate mutant-minitest adapter,
  # and its free tier's license explicitly excludes closed-source/commercial
  # use. Mutineer is Prism + Ruby stdlib only (zero runtime deps, Ruby >= 3.4),
  # ships first-class `--rails`/`--daemon` support with a fork-safe per-worker
  # SQLite test DB (our adapter), and `--since`/`--baseline` scope a run to a
  # diff - relevant for adopting this on an existing app instead of mutating
  # everything at once. [https://github.com/davidteren/mutineer]
  gem "mutineer", require: false

  # Dependency health / "gem smell" checks: last-commit activity, archived
  # repos, OpenSSF Scorecard, poison-pill transitive caps - none of which
  # bundler-audit or `bundle outdated` cover (CVEs and version drift only).
  # Compared against holepicker: holepicker only re-covers bundler-audit's CVE
  # ground (last released 2016, unmaintained) with none of the maintenance
  # signals. still_active is actively released (3.x in 2026), has 6 CI gate
  # flags and a --baseline diff mode built for exactly this use.
  # [https://github.com/SeanLF/still_active]
  gem "still_active", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Git hooks runner: blocks bad commits/pushes before they use any CI time
  # [https://github.com/evilmartians/lefthook]
  gem "lefthook", require: false
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"

  # CGI library for HTML unescaping (required for Ruby 4.0+)
  gem "cgi"
end
