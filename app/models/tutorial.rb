# frozen_string_literal: true

# Tutorial delegated type model for Ruby tutorials
#
# Represents tutorial content like "Getting Started with Rails",
# step-by-step guides, etc.
#
# Attributes:
#   - reading_time_minutes: Estimated reading time (optional)
#   - publication_date: When the tutorial was published (optional)
#   - author_name: Tutorial author (optional, separate from Author model)
#   - platform: Publishing platform (e.g., "Dev.to", "Medium", "Personal Blog")
#
# Associations:
#   - has_one :resource (as: :resourceable) - the base resource record
# == Schema Information
#
# Table name: tutorials
# Database name: primary
#
#  id                   :integer          not null, primary key
#  author_name          :string
#  platform             :string
#  publication_date     :date
#  reading_time_minutes :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class Tutorial < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Display name for Avo dropdown
  def display_name
    entry&.title || "Tutorial ##{id}"
  end

  # Validations
  validates :reading_time_minutes, numericality: { greater_than: 0 }, allow_blank: true
  validates :publication_date, comparison: { less_than_or_equal_to: -> { Date.current },
                                            message: "cannot be in the future" },
                              allow_blank: true
end
