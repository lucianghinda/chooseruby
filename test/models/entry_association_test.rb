# frozen_string_literal: true

require "test_helper"

class EntryAssociationTest < ActiveSupport::TestCase
  test "entry has many categories through categories_entries" do
    category = Category.create!(name: "Testing Association 1")
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com",
      status: :approved
    )

    entry.categories << category
    assert_includes entry.categories, category
  end

  test "entry has many authors through entries_authors" do
    author = Author.create!(name: "Test Author")
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com",
      status: :approved
    )

    entry.authors << author
    assert_includes entry.authors, author
  end

  test "category has many entries through categories_entries" do
    category = Category.create!(name: "Testing Association 2")
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com",
      status: :approved
    )

    category.entries << entry
    assert_includes category.entries, entry
  end

  test "slug is auto-generated from title" do
    entry = Entry.new(
      title: "My Amazing Entry",
      url: "https://example.com",
      status: :approved
    )
    entry.valid?

    assert_equal "my-amazing-entry", entry.slug
  end

  test "slug collision is handled by appending counter" do
    Entry.create!(
      title: "Same Title",
      url: "https://example.com",
      status: :approved
    )

    entry2 = Entry.create!(
      title: "Same Title",
      url: "https://example2.com",
      status: :approved
    )

    assert_equal "same-title-1", entry2.slug
  end

  test "enums work correctly for status" do
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com",
      status: :approved
    )

    assert entry.approved?
    refute entry.pending?
    refute entry.rejected?
  end

  test "enums work correctly for experience_level" do
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com",
      status: :approved,
      experience_level: :intermediate
    )

    assert entry.intermediate?
    refute entry.beginner?
    refute entry.advanced?
  end

  test "tags serialize and deserialize as JSON array" do
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com",
      status: :approved,
      tags: [ "ruby", "testing", "rspec" ]
    )

    entry.reload
    assert_equal [ "ruby", "testing", "rspec" ], entry.tags
  end
end
