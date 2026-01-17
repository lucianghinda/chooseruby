# frozen_string_literal: true

# Book delegated type model for Ruby books
#
# Represents published books about Ruby such as "The Well-Grounded Rubyist",
# "Eloquent Ruby", etc.
#
# Attributes:
#   - isbn: International Standard Book Number (optional)
#   - publisher: Publishing company name (optional)
#   - publication_year: Year published (optional, 1990-current)
#   - page_count: Number of pages (optional)
#   - format: Book format (enum: physical, ebook, both)
#   - purchase_url: Link to purchase the book (optional)
#
# Associations:
#   - has_one :resource (as: :resourceable) - the base resource record
# == Schema Information
#
# Table name: books
# Database name: primary
#
#  id               :integer          not null, primary key
#  format           :integer
#  isbn             :string
#  page_count       :integer
#  publication_year :integer
#  publisher        :string
#  purchase_url     :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class Book < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Enums
  enum :format, { physical: 0, ebook: 1, both: 2 }

  # Display name for Avo dropdown
  def display_name
    entry&.title || "Book ##{id}"
  end

  # Validations
  validates :isbn, format: { with: /\A(\d{10}|\d{13})\z/,
                            message: "must be a valid 10 or 13 digit ISBN" },
                   allow_blank: true
  validates :publication_year, numericality: { greater_than_or_equal_to: 1990,
                                              less_than_or_equal_to: -> { Time.current.year } },
                              allow_blank: true
  validates :page_count, numericality: { greater_than: 0 }, allow_blank: true
  validates :purchase_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
                                    message: "must be a valid URL starting with http:// or https://" },
                          allow_blank: true
end
