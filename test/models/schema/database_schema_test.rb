# frozen_string_literal: true

require "test_helper"

class DatabaseSchemaTest < ActiveSupport::TestCase
  test "entries table has required columns for DelegatedTypes" do
    columns = Entry.column_names
    assert_includes columns, "entryable_type"
    assert_includes columns, "entryable_id"
    assert_includes columns, "slug"
    assert_includes columns, "tags"
    assert_includes columns, "published"
    assert_includes columns, "experience_level"
  end

  test "categories_entries join table has foreign keys with cascade delete" do
    # Test that foreign keys exist and cascade deletes work
    category = Category.create!(name: "Test Category")
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com",
      status: :approved
    )

    join_record = CategoriesEntry.create!(category: category, entry: entry)
    assert join_record.persisted?

    # Test cascade delete when category is deleted
    category.destroy
    refute CategoriesEntry.exists?(join_record.id)
  end

  test "categories_entries has unique composite index on category_id and entry_id" do
    category = Category.create!(name: "Test Category 2")
    entry = Entry.create!(
      title: "Test Entry 2",
      url: "https://example.com",
      status: :approved
    )

    CategoriesEntry.create!(category: category, entry: entry)

    # Test that creating a duplicate raises a database uniqueness error
    assert_raises(ActiveRecord::RecordNotUnique) do
      CategoriesEntry.create!(category: category, entry: entry)
    end
  end

  test "entries table has polymorphic index on entryable_type and entryable_id" do
    indexes = ActiveRecord::Base.connection.indexes(:entries)
    polymorphic_index = indexes.find do |idx|
      idx.columns == [ "entryable_type", "entryable_id" ]
    end

    assert_not_nil polymorphic_index, "Polymorphic index on [entryable_type, entryable_id] should exist"
  end

  test "slug has unique index on entries table" do
    indexes = ActiveRecord::Base.connection.indexes(:entries)
    slug_index = indexes.find { |idx| idx.columns == [ "slug" ] && idx.unique }

    assert_not_nil slug_index, "Unique index on slug should exist"
  end

  test "gem_name has unique index on ruby_gems table" do
    indexes = ActiveRecord::Base.connection.indexes(:ruby_gems)
    gem_name_index = indexes.find { |idx| idx.columns == [ "gem_name" ] && idx.unique }

    assert_not_nil gem_name_index, "Unique index on gem_name should exist"
  end
end
