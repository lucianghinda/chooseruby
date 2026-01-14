# frozen_string_literal: true

# Article delegated type model for Ruby articles and blog posts
#
# Represents articles and blog posts about Ruby from various platforms
# like Dev.to, Medium, personal blogs, etc.
#
# Attributes:
#   - reading_time_minutes: Estimated reading time (optional)
#   - publication_date: When the article was published (optional)
#   - author_name: Article author (optional, separate from Author model)
#   - platform: Publishing platform (e.g., "Dev.to", "Medium", "Personal Blog")
#
# Associations:
#   - has_one :resource (as: :resourceable) - the base resource record
# == Schema Information
#
# Table name: articles
#
#  id                   :integer          not null, primary key
#  author_name          :string
#  platform             :string
#  publication_date     :date
#  reading_time_minutes :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class Article < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Display name for Avo dropdown
  def display_name
    entry&.title || "Article ##{id}"
  end

  # Validations
  validates :reading_time_minutes, numericality: { greater_than: 0 }, allow_blank: true
  validates :publication_date, comparison: { less_than_or_equal_to: -> { Date.current },
                                            message: "cannot be in the future" },
                              allow_blank: true
end
