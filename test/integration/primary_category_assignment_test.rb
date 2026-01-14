# frozen_string_literal: true

require "test_helper"

class PrimaryCategoryAssignmentTest < ActiveSupport::TestCase
  test "assigning first category to entry without primary sets first as fallback" do
    entry = Entry.create!(title: "Test Entry", url: "https://example.com", status: :approved)
    category = Category.create!(name: "Test Category", slug: "test-category")

    # Add category without explicitly setting primary
    entry.categories << category

    # primary_category should return the first (and only) category
    assert_equal category.id, entry.primary_category.id
  end

  test "setting primary flag on second category updates primary_category" do
    entry = Entry.create!(title: "Test Entry", url: "https://example.com", status: :approved)
    category1 = Category.create!(name: "Category 1", slug: "category-1")
    category2 = Category.create!(name: "Category 2", slug: "category-2")

    # Add first category without primary
    CategoriesEntry.create!(entry: entry, category: category1, is_primary: false)

    # Add second category as primary
    CategoriesEntry.create!(entry: entry, category: category2, is_primary: true)

    # primary_category should return category2
    assert_equal category2.id, entry.primary_category.id
  end

  test "updating primary flag from one category to another works correctly" do
    entry = Entry.create!(title: "Test Entry", url: "https://example.com", status: :approved)
    category1 = Category.create!(name: "Category 1", slug: "category-1")
    category2 = Category.create!(name: "Category 2", slug: "category-2")

    # Set category1 as primary
    ce1 = CategoriesEntry.create!(entry: entry, category: category1, is_primary: true)
    CategoriesEntry.create!(entry: entry, category: category2, is_primary: false)

    # Verify category1 is primary
    assert_equal category1.id, entry.primary_category.id

    # Update: remove primary from category1
    ce1.update!(is_primary: false)

    # Add primary to category2
    ce2 = CategoriesEntry.find_by(entry: entry, category: category2)
    ce2.update!(is_primary: true)

    # Reload entry and verify category2 is now primary
    entry.reload
    assert_equal category2.id, entry.primary_category.id
  end
end
