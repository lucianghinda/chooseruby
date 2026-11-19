# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class ImportsRubyandrailsinfoYamlImporterTest < ActiveSupport::TestCase
  setup do
    @directory = Dir.mktmpdir("rubyandrailsinfo-yaml")
    %w[ tags authors books courses newsletters podcasts communities youtubes screencasts lessons authorings taggings ].each do |table|
      write_table(table, [])
    end
  end

  teardown do
    FileUtils.remove_entry(@directory)
  end

  test "imports every resource type with attributes and mapped relationships" do
    write_table("tags", [ { "id" => "91", "title" => "Imported Tag", "slug" => "imported-tag" }, { "id" => "92", "title" => "Second Tag", "slug" => "imported-second-tag" } ])
    write_table("authors", [ { "id" => "81", "name" => "Imported Author", "slug" => "imported-author", "github_url" => "https://github.com/imported", "website_url" => "https://author.example", "twitter_url" => "https://twitter.com/imported" } ])
    write_table("books", [ entity("books", "isbn" => "1234567890", "year" => "2024", "page" => "240", "amazon_url" => "https://shop.example/book", "featured" => "t") ])
    write_table("courses", [ entity("courses", "free" => "true") ])
    %w[ newsletters podcasts communities youtubes screencasts ].each { |table| write_table(table, [ entity(table) ]) }
    lesson = entity("lessons")
    lesson["entry"]["url"] = "abcdefghijk"
    write_table("lessons", [ lesson ])
    write_table("authorings", [ { "author_id" => "81", "authorabble_type" => "Book", "authorabble_id" => "1" } ])
    write_table("taggings", [ { "tag_id" => "91", "taggable_type" => "Book", "taggable_id" => "1" }, { "tag_id" => "92", "taggable_type" => "Book", "taggable_id" => "1" } ])

    output = run_import
    book_entry = Entry.find_by!(slug: "imported-books")
    book = book_entry.entryable
    assert_equal [ 2024, 240, "https://shop.example/book", "both" ], [ book.publication_year, book.page_count, book.purchase_url, book.format ]
    assert_equal [ "approved", true, "intermediate" ], [ book_entry.status, book_entry.published, book_entry.experience_level ]
    assert_equal Time.parse("2024-01-15 09:30:00 UTC"), book_entry.featured_at
    assert_includes book_entry.description.to_plain_text, "Imported content"
    assert_equal [ "Imported Author" ], book_entry.authors.pluck(:name)
    assert_equal [ "Imported Tag", "Second Tag" ], book_entry.categories.order(:name).pluck(:name)
    assert_equal [ true, false ], book_entry.categories_entries.order(:id).pluck(:is_primary)
    assert_equal 8, Entry.where("slug LIKE ?", "imported-%").count
    assert_same true, Entry.find_by!(slug: "imported-courses").entryable.is_free
    assert_equal "Imported newsletters", Entry.find_by!(slug: "imported-newsletters").entryable.name
    assert_equal "https://www.youtube.com/watch?v=abcdefghijk", Entry.find_by!(slug: "imported-lessons").url
    assert_equal "all_levels", Entry.find_by!(slug: "imported-lessons").experience_level
    assert_equal "Other", Entry.find_by!(slug: "imported-communities").entryable.platform
    assert_match(/ID Mappings:.*categories.*2.*authors.*1.*entries.*8/, output)
  end

  test "reuses books with ISBN or entry slug and does not duplicate joins" do
    write_table("books", [ entity("books", "isbn" => "1234567890"), entity("unidentified", "id" => "2") ])
    write_table("tags", [ { "id" => "91", "title" => "Imported Tag", "slug" => "imported-tag" } ])
    write_table("authors", [ { "id" => "81", "name" => "Imported Author", "slug" => "imported-author" } ])
    write_table("authorings", [ { "author_id" => "81", "authorabble_type" => "Book", "authorabble_id" => "1" } ])
    write_table("taggings", [ { "tag_id" => "91", "taggable_type" => "Book", "taggable_id" => "1" } ])
    run_import

    assert_no_difference [ "Book.count", "Entry.count", "Author.count", "Category.count", "EntriesAuthor.count", "CategoriesEntry.count" ] do
      run_import
    end
  end

  test "skips absent titles and unresolved associations while reporting invalid rows" do
    write_table("tags", [ { "id" => "91", "title" => "Imported Tag", "slug" => "imported-tag" }, { "id" => "92", "title" => "", "slug" => "invalid-tag" } ])
    write_table("authors", [ { "id" => "81", "name" => "Imported Author", "slug" => "imported-author" }, { "id" => "82", "name" => "", "slug" => "invalid-author" } ])
    write_table("books", [ { "id" => "1" }, { "id" => "2", "entry" => { "title" => "" } }, entity("broken", "isbn" => "bad"), entity("books") ])
    write_table("authorings", [ { "author_id" => "missing" }, { "author_id" => "81", "authorabble_type" => "Book", "authorabble_id" => "missing" } ])
    write_table("taggings", [ { "tag_id" => "missing" }, { "tag_id" => "91", "taggable_type" => "Book", "taggable_id" => "missing" } ])

    output = run_import

    assert_equal 1, Entry.where("slug LIKE ?", "imported-%").count
    assert_match(/Imported 1 books \(1 errors, 2 skipped\)/, output)
    assert_match(/Imported 0 authorings \(0 errors, 2 skipped\)/, output)
    assert_match(/Imported 0 taggings \(0 errors, 2 skipped\)/, output)
    assert_includes output, "Errors: 1"
    assert_includes output, "Skipped: 2"
  end

  test "uses URL fallbacks and tolerates null YAML documents" do
    book = entity("fallback", "website_url" => "https://entity.example")
    book["entry"].delete("website_url")
    amazon_book = entity("amazon", "amazon_url" => "https://amazon.example")
    amazon_book["entry"].delete("website_url")
    placeholder = entity("placeholder")
    placeholder["entry"]["website_url"] = ""
    write_table("books", [ book, amazon_book, placeholder ])
    community = entity("community-fallback")
    community["entry"].delete("website_url")
    write_table("communities", [ community ])
    lesson_url = entity("lesson-url")
    lesson_url["entry"]["url"] = "https://video.example/lesson"
    lesson_website = entity("lesson-website")
    write_table("lessons", [ lesson_url, lesson_website ])
    File.write(File.join(@directory, "podcasts.yml"), "")

    run_import

    assert_equal "https://entity.example", Entry.find_by!(slug: "imported-fallback").url
    assert_equal "https://amazon.example", Entry.find_by!(slug: "imported-amazon").url
    assert_equal "https://example.com/imported-placeholder", Entry.find_by!(slug: "imported-placeholder").url
    assert_equal "https://example.com/imported-community-fallback", Entry.find_by!(slug: "imported-community-fallback").entryable.join_url
    assert_equal "https://video.example/lesson", Entry.find_by!(slug: "imported-lesson-url").url
    assert_equal "https://lesson-website.example", Entry.find_by!(slug: "imported-lesson-website").url
  end

  private

  def write_table(table, rows)
    File.write(File.join(@directory, "#{table}.yml"), rows.to_yaml)
  end

  def run_import
    capture_io { Imports::Rubyandrailsinfo::YamlImporter.new(yaml_dir: @directory).import_all }.first
  end

  def entity(name, attributes = {})
    {
      "id" => "1", "created_at" => "2024-01-15 09:30:00 UTC", "updated_at" => "2024-01-16 09:30:00 UTC",
      "entry" => { "title" => "Imported #{name}", "slug" => "imported-#{name}", "content" => "Imported content", "website_url" => "https://#{name}.example" }
    }.merge(attributes)
  end
end
