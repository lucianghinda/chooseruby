# frozen_string_literal: true

# == Schema Information
#
# Table name: categories
#
#  id            :integer          not null, primary key
#  description   :text
#  display_order :integer          default(0), not null
#  icon          :string
#  name          :string           not null
#  slug          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_categories_on_name  (name) UNIQUE
#  index_categories_on_slug  (slug) UNIQUE
#
require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "entries_count returns correct count of visible entries" do
    category = Category.create!(name: "Testing Count", slug: "testing-count")

    # Create visible entries (published and approved)
    visible_entry1 = Entry.create!(
      title: "Visible Entry 1",
      url: "https://example.com/1",
      published: true,
      status: :approved
    )
    visible_entry2 = Entry.create!(
      title: "Visible Entry 2",
      url: "https://example.com/2",
      published: true,
      status: :approved
    )

    # Create non-visible entries
    unpublished_entry = Entry.create!(
      title: "Unpublished Entry",
      url: "https://example.com/3",
      published: false,
      status: :approved
    )
    pending_entry = Entry.create!(
      title: "Pending Entry",
      url: "https://example.com/4",
      published: true,
      status: :pending,
      submitter_email: "pending@example.com"
    )

    # Associate all entries with category
    category.entries << [ visible_entry1, visible_entry2, unpublished_entry, pending_entry ]

    assert_equal 2, category.entries_count
  end

  test "featured_entries returns up to 3 featured visible entries" do
    category = Category.create!(name: "Testing Featured", slug: "testing-featured")

    # Create 4 featured visible entries
    4.times do |i|
      entry = Entry.create!(
        title: "Featured Entry #{i + 1}",
        url: "https://example.com/featured-#{i + 1}",
        published: true,
        status: :approved
      )
      CategoriesEntry.create!(
        category: category,
        entry: entry,
        is_featured: true
      )
    end

    featured = category.featured_entries

    assert_equal 3, featured.size
  end

  test "featured_entries excludes non-visible entries" do
    category = Category.create!(name: "Testing Featured Visible", slug: "testing-featured-visible")

    # Create featured but non-visible entries
    unpublished_entry = Entry.create!(
      title: "Unpublished Featured",
      url: "https://example.com/unpublished",
      published: false,
      status: :approved
    )
    CategoriesEntry.create!(
      category: category,
      entry: unpublished_entry,
      is_featured: true
    )

    # Create visible featured entry
    visible_entry = Entry.create!(
      title: "Visible Featured",
      url: "https://example.com/visible",
      published: true,
      status: :approved
    )
    CategoriesEntry.create!(
      category: category,
      entry: visible_entry,
      is_featured: true
    )

    featured = category.featured_entries

    assert_equal 1, featured.size
    assert_equal visible_entry.id, featured.first.id
  end

  test "featured_entries accepts custom limit parameter" do
    category = Category.create!(name: "Testing Featured Limit", slug: "testing-featured-limit")

    # Create 5 featured visible entries
    5.times do |i|
      entry = Entry.create!(
        title: "Featured Entry #{i + 1}",
        url: "https://example.com/featured-limit-#{i + 1}",
        published: true,
        status: :approved
      )
      CategoriesEntry.create!(
        category: category,
        entry: entry,
        is_featured: true
      )
    end

    featured = category.featured_entries(limit: 2)

    assert_equal 2, featured.size
  end
end
