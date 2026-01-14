# frozen_string_literal: true

require "test_helper"

class CategoriesShowViewTest < ActionDispatch::IntegrationTest
  test "category show page displays total resource count in header" do
    category = categories(:testing)

    # Create visible entries
    3.times do |i|
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
    # Check that resource count appears in header section
    assert_select "section.rounded-3xl" do
      assert_select "h1", text: "Testing"
      assert_select "p", text: /3 resources?/
    end
  end

  test "category show page displays featured resources section when present" do
    category = categories(:testing)

    # Create featured entries
    2.times do |i|
      entry = Entry.create!(
        title: "Featured Entry #{i + 1}",
        url: "https://example.com/featured-#{i + 1}",
        published: true,
        status: :approved
      )
      entry.description = "Featured resource description"
      entry.save!
      CategoriesEntry.create!(
        category: category,
        entry: entry,
        is_featured: true
      )
    end

    # Create a regular (non-featured) entry
    regular_entry = Entry.create!(
      title: "Regular Entry",
      url: "https://example.com/regular",
      published: true,
      status: :approved
    )
    CategoriesEntry.create!(category: category, entry: regular_entry)

    get category_path(category.slug)

    assert_response :success
    # Check that featured section exists with heading
    assert_select "h2", text: "Featured Resources"
    # Check that featured entries are displayed (using rose-50 border)
    assert_select "article.border-rose-50", count: 2
    # Check that both featured entries appear by title
    assert_select "h3 a", text: "Featured Entry 1"
    assert_select "h3 a", text: "Featured Entry 2"
  end

  test "featured resources use correct styling with rose-50 border" do
    category = categories(:testing)

    # Create a featured entry
    entry = Entry.create!(
      title: "Featured Entry",
      url: "https://example.com/featured",
      published: true,
      status: :approved
    )
    entry.description = "Featured resource description"
    entry.save!
    CategoriesEntry.create!(
      category: category,
      entry: entry,
      is_featured: true
    )

    get category_path(category.slug)

    assert_response :success
    # Check that featured section heading exists
    assert_select "h2", text: "Featured Resources"
    # Featured resources should have border-rose-50 class
    assert_select "article.border-rose-50", minimum: 1
  end

  test "category show page does not display featured section when no featured resources" do
    category = categories(:authentication)

    # Create only regular (non-featured) entries
    entry = Entry.create!(
      title: "Regular Entry",
      url: "https://example.com/regular",
      published: true,
      status: :approved
    )
    CategoriesEntry.create!(category: category, entry: entry, is_featured: false)

    get category_path(category.slug)

    assert_response :success
    # Featured section should not exist
    assert_select "h2", { text: "Featured Resources", count: 0 }
  end
end
