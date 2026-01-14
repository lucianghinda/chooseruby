# frozen_string_literal: true

require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  test "index action renders successfully with multiple categories" do
    get categories_path

    assert_response :success
    assert_select "h1", text: "Discover the Ruby ecosystem by topic"
  end

  test "show action loads category and displays entries_count" do
    category = categories(:testing)

    # Create visible entries for accurate entries_count
    2.times do |i|
      entry = Entry.create!(
        title: "Test Entry #{i + 1}",
        url: "https://example.com/test-#{i + 1}",
        published: true,
        status: :approved
      )
      CategoriesEntry.create!(category: category, entry: entry)
    end

    get category_path(category.slug)

    assert_response :success
    # Verify that entries_count is displayed in the view
    assert_select "p.text-sm", text: /2 resources? in this category/
  end

  test "show action displays featured entries when available" do
    category = categories(:testing)

    # Create featured entries
    featured_entry1 = Entry.create!(
      title: "Featured Test 1",
      url: "https://example.com/featured-1",
      published: true,
      status: :approved
    )
    featured_entry1.description = "Featured description"
    featured_entry1.save!

    featured_entry2 = Entry.create!(
      title: "Featured Test 2",
      url: "https://example.com/featured-2",
      published: true,
      status: :approved
    )
    featured_entry2.description = "Featured description"
    featured_entry2.save!

    CategoriesEntry.create!(category: category, entry: featured_entry1, is_featured: true)
    CategoriesEntry.create!(category: category, entry: featured_entry2, is_featured: true)

    get category_path(category.slug)

    assert_response :success

    # Verify featured section exists
    assert_select "h2", text: "Featured Resources"
    # Verify featured entries are displayed
    assert_select "article.border-rose-50", minimum: 2
  end

  test "show action with category filtering returns correct entries" do
    category = categories(:testing)

    # Create entries for this category
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com/test",
      published: true,
      status: :approved
    )
    entry.description = "Test description"
    entry.save!
    CategoriesEntry.create!(category: category, entry: entry)

    get category_path(category.slug)

    assert_response :success
    # Verify the entry appears in the category page
    assert_select "h3 a", text: "Test Entry"
  end

  test "show action with experience level filter works correctly" do
    category = categories(:testing)

    # Create entry with specific experience level
    entry = Entry.create!(
      title: "Beginner Test Entry",
      url: "https://example.com/beginner",
      published: true,
      status: :approved,
      experience_level: :beginner
    )
    entry.description = "Beginner description"
    entry.save!
    CategoriesEntry.create!(category: category, entry: entry)

    get category_path(category.slug), params: { level: "beginner" }

    assert_response :success
    # Verify experience level filter is applied (button should show as selected)
    assert_select "select[name=level] option[value=beginner][selected]"
  end

  test "show action handles category with no entries gracefully" do
    empty_category = Category.create!(name: "Empty Category", slug: "empty-category")

    get category_path(empty_category.slug)

    assert_response :success
    # Should display 0 resources
    assert_select "p.text-sm", text: /0 resources? in this category/
  end

  test "show action limits featured resources to 3 items" do
    category = categories(:testing)

    # Create 5 featured entries
    5.times do |i|
      entry = Entry.create!(
        title: "Featured Test #{i + 1}",
        url: "https://example.com/featured-#{i + 1}",
        published: true,
        status: :approved
      )
      entry.description = "Featured description #{i + 1}"
      entry.save!
      CategoriesEntry.create!(category: category, entry: entry, is_featured: true)
    end

    get category_path(category.slug)

    assert_response :success

    # Verify featured section exists
    assert_select "h2", text: "Featured Resources"
    # Verify only 3 featured entries are displayed
    assert_select "article.border-rose-50", count: 3
  end
end
