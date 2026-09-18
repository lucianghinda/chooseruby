# frozen_string_literal: true

require "test_helper"

class Imports::Rubyandrailsinfo::YamlImporterTest < ActiveSupport::TestCase
  YAML_DIR = Rails.root.join("test/fixtures/files/rubyandrailsinfo/yaml")

  setup do
    @importer = Imports::Rubyandrailsinfo::YamlImporter.new(yaml_dir: YAML_DIR)
  end

  test "import_all imports categories, authors, entities, entries and relationships" do
    output = capture_io { @importer.import_all }.first

    category = Category.find_by!(slug: "ruby-on-rails-7")
    author = Author.find_by!(slug: "jane-author")
    book_entry = Entry.find_by!(slug: "modern-front-end-development-for-rails")

    assert_equal "Ruby on Rails 7", category.name
    assert author.approved?
    assert_equal "https://github.com/jane", author.github_url

    assert_equal "Book", book_entry.entryable_type
    assert_equal "9781680507218", book_entry.entryable.isbn
    assert_equal 2022, book_entry.entryable.publication_year
    assert_equal 408, book_entry.entryable.page_count
    assert_equal "https://pragprog.com/titles/nrclient2/", book_entry.url
    assert_equal Time.parse("2022-06-19 09:24:14.950515"), book_entry.featured_at
    assert book_entry.approved? && book_entry.published?
    assert_equal [ author ], book_entry.authors.to_a
    assert_equal %w[hotwire ruby-on-rails-7], book_entry.categories.map(&:slug).sort
    assert book_entry.categories_entries.find_by(category: category).is_primary

    assert_match "Imported 2 categories (1 errors)", output
    assert_match "Imported 1 authors (1 errors)", output
    assert_match "Imported 3 books (1 errors, 1 skipped)", output
    assert_match "Imported 1 courses (1 errors, 1 skipped)", output
    assert_match "Imported 3 lessons (1 errors, 1 skipped)", output
    assert_match "Imported 2 authorings (0 errors, 2 skipped)", output
    assert_match "Imported 2 taggings (0 errors, 2 skipped)", output
    assert_match "Error importing category 3", output
    assert_match "ID Mappings: {categories: 2, authors: 1, entries: 13}", output
  end

  test "books without an ISBN reuse the book behind an existing entry slug" do
    capture_io { @importer.import_all }

    entry = Entry.find_by!(slug: "book-without-isbn")
    assert_equal 1, Entry.where(slug: "book-without-isbn").count
    assert_nil entry.entryable.isbn
    assert_equal "https://example.com/book-without-isbn", entry.url
    assert_nil entry.featured_at
  end

  test "lessons build YouTube URLs from video ids and keep other URLs" do
    capture_io { @importer.import_all }

    assert_equal "https://www.youtube.com/watch?v=MwbmKqdDsyI", Entry.find_by!(slug: "static-pages").url
    assert_equal "https://vimeo.com/123", Entry.find_by!(slug: "full-url-lesson").url
    assert_equal "https://example.com/website-lesson", Entry.find_by!(slug: "website-lesson").url
    assert Entry.find_by!(slug: "static-pages").all_levels?
  end

  test "communities get a placeholder join URL when the entry has none" do
    capture_io { @importer.import_all }

    assert_equal "https://discord.gg/ruby", Entry.find_by!(slug: "ruby-discord").entryable.join_url
    assert_equal "https://example.com/ruby-forum", Entry.find_by!(slug: "ruby-forum").entryable.join_url
  end

  test "relationship errors are counted and reported" do
    output = with_failing_creation(EntriesAuthor, CategoriesEntry) do
      capture_io { @importer.import_all }.first
    end

    assert_match "Error importing authoring: boom", output
    assert_match "Imported 0 authorings (2 errors, 2 skipped)", output
    assert_match "Error importing tagging: boom", output
    assert_match "Imported 0 taggings (2 errors, 2 skipped)", output
  end

  private

  # Makes find_or_create_by! raise on the given models for the duration of the block
  def with_failing_creation(*models)
    models.each do |model|
      model.define_singleton_method(:find_or_create_by!) { |*, **| raise "boom" }
    end
    yield
  ensure
    models.each { |model| model.singleton_class.remove_method(:find_or_create_by!) }
  end
end
