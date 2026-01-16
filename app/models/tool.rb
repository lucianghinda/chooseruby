# frozen_string_literal: true

# Tool delegated type model for Ruby development tools
#
# Represents development tools like RuboCop, Bundler, code editors,
# CLI utilities, web apps, editor plugins, etc.
#
# Attributes:
#   - tool_type: Type of tool (e.g., "CLI", "Web App", "Editor Plugin")
#   - github_url: Link to GitHub repository (optional)
#   - documentation_url: Link to documentation (optional)
#   - license: Software license (e.g., "MIT", "Apache 2.0")
#   - is_open_source: Whether the tool is open source (default: true)
#
# Associations:
#   - has_one :resource (as: :resourceable) - the base resource record
# == Schema Information
#
# Table name: tools
# Database name: primary
#
#  id                :integer          not null, primary key
#  documentation_url :string
#  github_url        :string
#  is_open_source    :boolean          default(TRUE), not null
#  license           :string
#  tool_type         :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Tool < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Display name for Avo dropdown
  def display_name
    entry&.title || "Tool ##{id}"
  end

  # Validations
  validates :github_url, :documentation_url,
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
                     message: "must be a valid URL starting with http:// or https://" },
            allow_blank: true
end
