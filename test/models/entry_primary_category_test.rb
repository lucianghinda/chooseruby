# frozen_string_literal: true

require "test_helper"

class EntryPrimaryCategoryTest < ActiveSupport::TestCase
  test "primary_category returns the category marked as primary" do
    category1 = Category.create!(name: "Primary Category", slug: "primary-category")
    category2 = Category.create!(name: "Secondary Category", slug: "secondary-category")
    entry = Entry.create!(title: "Test Entry", url: "https://example.com", status: :approved)

    # Add non-primary category first
    CategoriesEntry.create!(
      category: category2,
      entry: entry,
      is_primary: false
    )

    # Add primary category second
    CategoriesEntry.create!(
      category: category1,
      entry: entry,
      is_primary: true
    )

    assert_equal category1.id, entry.primary_category.id
  end

  test "primary_category returns first category when no primary is set" do
    category1 = Category.create!(name: "First Category", slug: "first-category")
    category2 = Category.create!(name: "Second Category", slug: "second-category")
    entry = Entry.create!(title: "Test Entry", url: "https://example.com", status: :approved)

    # Add categories without primary flag
    entry.categories << category1
    entry.categories << category2

    # Should return first category as fallback
    assert_equal category1.id, entry.primary_category.id
  end

  test "primary_category returns nil when entry has no categories" do
    entry = Entry.create!(title: "Test Entry", url: "https://example.com", status: :approved)

    assert_nil entry.primary_category
  end
end
