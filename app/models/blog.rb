# frozen_string_literal: true

# Blog delegated type model for Ruby blogs
#
# Represents blogs about Ruby development.
#
# Associations:
#   - has_one :entry (as: :entryable) - the base entry record
#
# Usage:
#   blog = Blog.create!
#   entry = Entry.create!(
#     title: "Ruby on Rails Blog",
#     url: "https://rubyonrails.org/blog",
#     entryable: blog
#   )
# == Schema Information
#
# Table name: blogs
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Blog < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 200 }

  # Display name for Avo dropdown
  def display_name
    name.presence || entry&.title || "Blog ##{id}"
  end
end
