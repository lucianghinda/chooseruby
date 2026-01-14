# frozen_string_literal: true

# == Schema Information
#
# Table name: categories_entries
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
require "test_helper"

class CategoriesEntryTest < ActiveSupport::TestCase
  test "allows creating a categories_entry with is_primary flag" do
    category = Category.create!(name: "Testing Primary", slug: "testing-primary")
    entry = Entry.create!(title: "Test Entry", url: "https://example.com", status: :approved)

    categories_entry = CategoriesEntry.create!(
      category: category,
      entry: entry,
      is_primary: true
    )

    assert categories_entry.is_primary
  end

  test "allows creating a categories_entry with is_featured flag" do
    category = Category.create!(name: "Testing Featured", slug: "testing-featured")
    entry = Entry.create!(title: "Test Entry", url: "https://example.com", status: :approved)

    categories_entry = CategoriesEntry.create!(
      category: category,
      entry: entry,
      is_featured: true
    )

    assert categories_entry.is_featured
  end

  test "validates only one primary category per entry" do
    category1 = Category.create!(name: "Category One", slug: "category-one")
    category2 = Category.create!(name: "Category Two", slug: "category-two")
    entry = Entry.create!(title: "Test Entry", url: "https://example.com", status: :approved)

    # Create first primary category
    CategoriesEntry.create!(
      category: category1,
      entry: entry,
      is_primary: true
    )

    # Try to create second primary category - should fail validation
    categories_entry2 = CategoriesEntry.new(
      category: category2,
      entry: entry,
      is_primary: true
    )

    refute categories_entry2.valid?
    assert_includes categories_entry2.errors[:is_primary], "An entry can only have one primary category"
  end

  test "allows multiple non-primary categories for same entry" do
    category1 = Category.create!(name: "Category Alpha", slug: "category-alpha")
    category2 = Category.create!(name: "Category Beta", slug: "category-beta")
    entry = Entry.create!(title: "Test Entry", url: "https://example.com", status: :approved)

    # Create first non-primary category
    CategoriesEntry.create!(
      category: category1,
      entry: entry,
      is_primary: false
    )

    # Create second non-primary category - should succeed
    categories_entry2 = CategoriesEntry.create!(
      category: category2,
      entry: entry,
      is_primary: false
    )

    assert categories_entry2.valid?
  end
end
