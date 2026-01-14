# frozen_string_literal: true

# RubyGem delegated type model for Ruby gems from RubyGems.org
#
# Represents gems like RSpec, Devise, Sidekiq, etc. Contains gem-specific
# attributes while the base Entry model holds shared attributes.
#
# Attributes:
#   - gem_name: Official gem name from RubyGems (required, unique)
#   - rubygems_url: Link to RubyGems.org page (auto-constructed)
#   - github_url: Link to GitHub repository (optional)
#   - documentation_url: Link to documentation (optional)
#   - downloads_count: Total downloads from RubyGems (optional, can be synced)
#   - current_version: Current gem version (optional)
#
# Associations:
#   - has_one :resource (as: :resourceable) - the base resource record
#
# Usage:
#   ruby_gem = RubyGem.create(gem_name: "rspec")
#   resource = Entry.create(
#     title: "RSpec",
#     url: "https://rspec.info",
#     entryable: ruby_gem
#   )
# == Schema Information
#
# Table name: ruby_gems
#
#  id                :integer          not null, primary key
#  current_version   :string
#  documentation_url :string
#  downloads_count   :integer
#  gem_name          :string           not null
#  github_url        :string
#  rubygems_url      :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_ruby_gems_on_gem_name  (gem_name) UNIQUE
#
class RubyGem < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Display name for Avo dropdown - prefers entry title, falls back to gem_name
  def display_name
    entry&.title || gem_name || "RubyGem ##{id}"
  end

  # Validations
  validates :gem_name, presence: true, uniqueness: true
  validates :rubygems_url, :github_url, :documentation_url,
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
                     message: "must be a valid URL starting with http:// or https://" },
            allow_blank: true
  validates :downloads_count, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
end
