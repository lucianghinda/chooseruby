# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

# `bin/rails test` boots the application before it loads test_helper.rb, so
# starting SimpleCov there misses everything loaded during boot. Keyed on the
# command rather than RAILS_ENV, which bin/ci does not export. Configuration
# lives in .simplecov.
if ARGV.grep(/\Atest(:|\z)/).any?
  require "simplecov"
  SimpleCov.start
end
