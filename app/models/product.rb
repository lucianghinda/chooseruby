# frozen_string_literal: true

# Product delegated type model for Ruby products
#
# Represents commercial products and services for Ruby developers.
#
# Associations:
#   - has_one :entry (as: :entryable) - the base entry record
#
# Usage:
#   product = Product.create!
#   entry = Entry.create!(
#     title: "Ruby Mine IDE",
#     url: "https://jetbrains.com/ruby",
#     entryable: product
#   )
# == Schema Information
#
# Table name: products
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Product < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 200 }

  # Display name for Avo dropdown
  def display_name
    name.presence || entry&.title || "Product ##{id}"
  end
end
