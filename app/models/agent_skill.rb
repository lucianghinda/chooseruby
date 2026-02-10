# frozen_string_literal: true

# AgentSkill delegated type model for AI agent skills
#
# Represents agent skills from markdown skill files that define capabilities
# for AI agents using Ruby (e.g., opencode skills)
#
# Attributes:
#   - skill_file_url: URL to the .md skill file (required)
#   - name: Parsed from frontmatter
#   - skill_description: Parsed description field (avoids conflict with Entry's description)
#   - license: License information
#   - compatibility: Ruby/compatibility version info
#   - pattern: Pattern/trigger for the skill
#   - metadata: JSON serialized Hash with additional metadata
#   - allowed_tools: JSON serialized Array of allowed tools
#   - body: Markdown content after frontmatter
#   - parse_status: Enum (pending/completed/failed)
#   - parse_error: Error message if parsing failed
#
# Associations:
#   - has_one :entry (as: :entryable) - the base entry record
# == Schema Information
#
# Table name: agent_skills
# Database name: primary
#
#  id                :integer          not null, primary key
#  allowed_tools     :text
#  body              :text
#  compatibility     :string
#  license           :string
#  metadata          :text
#  name              :string
#  parse_error       :text
#  parse_status      :integer          default("parse_pending"), not null
#  pattern           :string
#  skill_description :string
#  skill_file_url    :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class AgentSkill < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  serialize :metadata, coder: JSON
  serialize :allowed_tools, coder: JSON

  enum :parse_status, { parse_pending: 0, parse_completed: 1, parse_failed: 2 }

  validates :skill_file_url, presence: true,
                            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[https]),
                                     message: "must be a valid HTTPS URL" }
  validates :name, presence: true, length: { minimum: 2, maximum: 200 }, if: :name_present?

  def display_name
    entry&.title || name || "Agent Skill ##{id}"
  end

  private

  def name_present?
    name.present?
  end
end
