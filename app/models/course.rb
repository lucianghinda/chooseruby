# frozen_string_literal: true

# Course delegated type model for online Ruby courses
#
# Represents online courses and training programs like Michael Hartl's
# Rails Tutorial, GoRails courses, Udemy courses, etc.
#
# Attributes:
#   - platform: Course platform (e.g., "Udemy", "Coursera", "Custom")
#   - instructor: Course instructor name (optional)
#   - duration_hours: Course duration in hours (optional, decimal)
#   - price_cents: Price in cents to avoid floating-point issues (optional)
#   - currency: Currency code (default: "USD")
#   - is_free: Whether the course is free (default: false)
#   - enrollment_url: Link to enroll in the course (optional)
#
# Associations:
#   - has_one :resource (as: :resourceable) - the base resource record
# == Schema Information
#
# Table name: courses
#
#  id             :integer          not null, primary key
#  currency       :string           default("USD")
#  duration_hours :decimal(5, 2)
#  enrollment_url :string
#  instructor     :string
#  is_free        :boolean          default(FALSE), not null
#  platform       :string
#  price_cents    :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Course < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Display name for Avo dropdown
  def display_name
    entry&.title || "Course ##{id}"
  end

  # Validations
  validates :duration_hours, numericality: { greater_than: 0 }, allow_blank: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :enrollment_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
                                      message: "must be a valid URL starting with http:// or https://" },
                            allow_blank: true
end
