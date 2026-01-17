# frozen_string_literal: true

# Join table model for many-to-many relationship between Categories and Entries
#
# This model represents the association table that connects categories to entries,
# allowing each entry to belong to multiple categories and each category to have
# multiple entries.
#
# Attributes:
#   - is_primary: Boolean flag indicating if this is the primary category for the entry
#   - is_featured: Boolean flag indicating if this entry is featured in this category
#
# Associations:
#   - belongs_to :category
#   - belongs_to :entry
#
# Validations:
#   - Ensures only one primary category per entry
#
# Usage:
#   category = Category.find_by(name: "Testing")
#   entry = Entry.find_by(title: "RSpec")
#   CategoriesEntry.create(category: category, entry: entry, is_primary: true)
#
# == Schema Information
#
# Table name: categories_entries
# Database name: primary
#
#  id          :integer          not null, primary key
#  is_featured :boolean          default(FALSE), not null
#  is_primary  :boolean          default(FALSE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  category_id :integer          not null
#  entry_id    :integer          not null
#
# Indexes
#
#  index_categories_entries_on_category_id               (category_id)
#  index_categories_entries_on_category_id_and_entry_id  (category_id,entry_id) UNIQUE
#  index_categories_entries_on_entry_id                  (entry_id)
#  index_categories_entries_on_entry_id_primary          (entry_id) UNIQUE WHERE is_primary = 1
#
# Foreign Keys
#
#  category_id  (category_id => categories.id) ON DELETE => cascade
#  entry_id     (entry_id => entries.id) ON DELETE => cascade
#
class CategoriesEntry < ApplicationRecord
  belongs_to :category
  belongs_to :entry

  # Custom validation to ensure only one primary category per entry
  validate :validate_single_primary_category, if: :is_primary?

  private

  # Validates that an entry can only have one primary category
  # Checks if another categories_entry with is_primary=true exists for the same entry
  def validate_single_primary_category
    existing_primary = CategoriesEntry
      .where(entry_id: entry_id, is_primary: true)
      .where.not(id: id)
      .exists?

    if existing_primary
      errors.add(:is_primary, "An entry can only have one primary category")
    end
  end
end
