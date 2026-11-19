# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class YamlImporterTest < ActiveSupport::TestCase
  # Every file import_all reads. Any file a test does not describe stays empty.
  FILES = %w[
    tags authors books courses newsletters podcasts communities
    youtubes screencasts lessons authorings taggings
  ].freeze

  CREATED = "2020-01-02 03:04:05"
  UPDATED = "2020-02-03 04:05:06"

  test "imports every entity type together with its entry, author and category" do
    out = import(
      "tags" => [ tag_row(7, "Metaprogramming") ],
      "authors" => [ author_row(3, "Imported Author") ],
      "books" => [ row(1, entry_for("Imported Book"),
                       "isbn" => "9781234567897", "year" => "2015", "page" => "300",
                       "amazon_url" => "https://amazon.example/book", "featured" => "t") ],
      "courses" => [ row(2, entry_for("Imported Course", "website_url" => "https://courses.example"), "free" => "t") ],
      "newsletters" => [ row(3, entry_for("Imported Newsletter", "website_url" => "https://news.example")) ],
      "podcasts" => [ row(4, entry_for("Imported Podcast", "website_url" => "https://pod.example")) ],
      "communities" => [ row(5, entry_for("Imported Community", "website_url" => "https://chat.example")) ],
      "youtubes" => [ row(6, entry_for("Imported Youtube", "website_url" => "https://yt.example")) ],
      "screencasts" => [ row(7, entry_for("Imported Screencast", "website_url" => "https://cast.example")) ],
      "lessons" => [ row(8, entry_for("Imported Lesson", "url" => "dQw4w9WgXcQ")) ],
      "authorings" => [ { "author_id" => 3, "authorabble_type" => "Book", "authorabble_id" => 1 } ],
      "taggings" => [ { "tag_id" => 7, "taggable_type" => "Book", "taggable_id" => 1 } ]
    )

    category = Category.find_by(name: "Metaprogramming")
    assert_equal Time.zone.parse(CREATED), category.created_at
    assert_equal Time.zone.parse(UPDATED), category.updated_at

    imported_author = Author.find_by(name: "Imported Author")
    assert_predicate imported_author, :approved?
    assert_equal "https://twitter.com/imported-author", imported_author.twitter_url
    assert_equal "https://imported-author.example", imported_author.website_url

    book_entry = Entry.find_by(title: "Imported Book")
    book = book_entry.entryable
    assert_equal "9781234567897", book.isbn
    assert_equal 2015, book.publication_year
    assert_equal 300, book.page_count
    assert_equal "https://amazon.example/book", book.purchase_url
    assert_equal "both", book.format
    assert_equal Time.zone.parse(CREATED), book.created_at
    assert_equal Time.zone.parse(UPDATED), book.updated_at
    # No entry or entity website_url, so the amazon_url becomes the entry URL.
    assert_equal "https://amazon.example/book", book_entry.url
    assert_equal Time.zone.parse(CREATED), book_entry.created_at
    assert_equal Time.zone.parse(CREATED), book_entry.featured_at
    assert_predicate book_entry, :approved?
    assert_predicate book_entry, :published?
    assert_equal "intermediate", book_entry.experience_level
    assert_equal [], book_entry.tags
    assert_equal "Imported Book", book_entry.description.to_plain_text.strip

    assert_predicate Entry.find_by(title: "Imported Course").entryable, :is_free?
    assert_equal "Imported Newsletter", Entry.find_by(title: "Imported Newsletter").entryable.name

    community = Entry.find_by(title: "Imported Community").entryable
    assert_equal "Other", community.platform
    assert_equal "https://chat.example", community.join_url
    assert_not_predicate community, :is_official?
    assert_nil community.member_count

    [ "Imported Youtube", "Imported Screencast", "Imported Lesson" ].each do |title|
      entry = Entry.find_by(title: title)
      assert_equal "Video", entry.entryable_type
      assert_equal title, entry.entryable.name
    end

    lesson_entry = Entry.find_by(title: "Imported Lesson")
    assert_equal "https://www.youtube.com/watch?v=dQw4w9WgXcQ", lesson_entry.url
    assert_equal "all_levels", lesson_entry.experience_level
    assert_nil lesson_entry.featured_at

    assert_equal [ imported_author ], book_entry.authors
    assert_equal [ category ], book_entry.categories
    assert_predicate CategoriesEntry.find_by(entry: book_entry, category: category), :is_primary?

    assert_includes out, "✓ Imported 1 books (0 errors, 0 skipped)"
    assert_includes out, "Books: 1 success"
    assert_includes out, "ID Mappings: {categories: 1, authors: 1, entries: 8}"
  end

  test "skips rows that have no entry or no entry title" do
    out = import(
      "courses" => [
        { "id" => 1, "created_at" => CREATED, "updated_at" => UPDATED },
        row(2, entry_for(""))
      ]
    )

    assert_equal 0, Entry.where(entryable_type: "Course").count
    assert_includes out, "✓ Imported 0 courses (0 errors, 2 skipped)"
    assert_includes out, "  Skipped: 2"
  end

  test "counts and reports a row whose record is invalid" do
    out = import("podcasts" => [ row(1, entry_for("X", "website_url" => "https://short.example")) ])

    assert_nil Entry.find_by(title: "X")
    assert_includes out, "✗ Error importing podcasts 1: Validation failed:"
    assert_includes out, "✓ Imported 0 podcasts (1 errors, 0 skipped)"
    assert_includes out, "  Errors: 1"
  end

  test "re-importing a book with an ISBN reuses both the book and its entry" do
    data = { "books" => [ row(1, entry_for("Idempotent Book", "website_url" => "https://idem.example"),
                              "isbn" => "9780000000002") ] }

    with_yaml(data) do |dir|
      2.times { capture_io { Imports::Rubyandrailsinfo::YamlImporter.new(yaml_dir: dir).import_all } }
    end

    assert_equal 1, Book.where(isbn: "9780000000002").count
    assert_equal 1, Entry.where(title: "Idempotent Book").count
  end

  test "a book without an ISBN reuses the book behind an entry with the same slug" do
    book = Book.create!(format: :both)
    entry = Entry.create!(title: "Reused Book", url: "https://reused.example", status: :approved, entryable: book)
    assert_equal "reused-book", entry.slug

    assert_no_difference [ "Book.count", "Entry.count" ] do
      import("books" => [ row(1, entry_for("Reused Book", "website_url" => "https://other.example")) ])
    end

    assert_equal 1, Entry.where(entryable: book).count
    # The entry already existed, so none of the YAML values were applied.
    assert_equal "https://reused.example", entry.reload.url
  end

  test "a book without an ISBN and without a matching entry creates a new book" do
    import("books" => [ row(1, entry_for("Fresh Book"),
                            "year" => "2001", "page" => "120", "website_url" => "https://fresh.example") ])

    book = Entry.find_by(title: "Fresh Book").entryable
    assert_nil book.isbn
    assert_equal 2001, book.publication_year
    assert_equal 120, book.page_count
    assert_equal "https://fresh.example", book.purchase_url
  end

  test "an entry keeps the slug the YAML carries" do
    import("newsletters" => [ row(1, { "title" => "Slugged News", "slug" => "yaml-slug",
                                       "website_url" => "https://slug.example" }) ])

    assert_equal "yaml-slug", Entry.find_by(title: "Slugged News").slug
  end

  test "an entry without a slug in the YAML derives one from its title" do
    import("newsletters" => [ row(1, { "title" => "Unslugged News", "website_url" => "https://slug.example" }) ])

    assert_equal "unslugged-news", Entry.find_by(title: "Unslugged News").slug
  end

  test "a lesson whose url is not a bare video id keeps that url" do
    import("lessons" => [ row(1, entry_for("Vimeo Lesson", "url" => "https://vimeo.com/12345")) ])

    assert_equal "https://vimeo.com/12345", Entry.find_by(title: "Vimeo Lesson").url
  end

  test "an entry falls back to the entity url and then to a slug placeholder" do
    import(
      "newsletters" => [
        row(1, entry_for("Entity Url News"), "website_url" => "https://entity.example"),
        row(2, entry_for("No Url News"))
      ]
    )

    assert_equal "https://entity.example", Entry.find_by(title: "Entity Url News").url
    assert_equal "https://example.com/no-url-news", Entry.find_by(title: "No Url News").url
  end

  test "a community without any url joins through a slug placeholder" do
    import("communities" => [ row(1, entry_for("Placeholder Community")) ])

    assert_equal "https://example.com/placeholder-community",
                 Entry.find_by(title: "Placeholder Community").entryable.join_url
  end

  test "timestamps that cannot be parsed leave the record with its own" do
    import(
      "podcasts" => [ {
        "id" => 1, "created_at" => "2020-13-45", "updated_at" => "",
        "entry" => entry_for("Broken Time Podcast", "website_url" => "https://bt.example")
      } ]
    )

    entry = Entry.find_by(title: "Broken Time Podcast")
    assert_in_delta Time.current, entry.created_at, 30
    assert_in_delta Time.current, entry.updated_at, 30
  end

  test "a YAML file with no content imports nothing" do
    out = import("tags" => "")

    assert_includes out, "✓ Imported 0 categories (0 errors, 0 skipped)"
    assert_includes out, "Categories: 0 success"
  end

  test "authorings and taggings skip rows whose author, category or entry is unknown" do
    out = import(
      "tags" => [ tag_row(7, "Known Tag") ],
      "authors" => [ author_row(3, "Known Author") ],
      "podcasts" => [ row(4, entry_for("Linked Podcast", "website_url" => "https://linked.example")) ],
      "authorings" => [
        { "author_id" => 99, "authorabble_type" => "Podcast", "authorabble_id" => 4 },
        { "author_id" => 3, "authorabble_type" => "Podcast", "authorabble_id" => 99 },
        { "author_id" => 3, "authorabble_type" => "Podcast", "authorabble_id" => 4 }
      ],
      "taggings" => [
        { "tag_id" => 99, "taggable_type" => "Podcast", "taggable_id" => 4 },
        { "tag_id" => 7, "taggable_type" => "Podcast", "taggable_id" => 99 },
        { "tag_id" => 7, "taggable_type" => "Podcast", "taggable_id" => 4 }
      ]
    )

    entry = Entry.find_by(title: "Linked Podcast")
    assert_equal [ "Known Author" ], entry.authors.map(&:name)
    assert_equal [ "Known Tag" ], entry.categories.map(&:name)
    assert_includes out, "✓ Imported 1 authorings (0 errors, 2 skipped)"
    assert_includes out, "✓ Imported 1 taggings (0 errors, 2 skipped)"
  end

  test "only the first category of an entry becomes its primary one" do
    import(
      "tags" => [ tag_row(7, "Alpha Tag"), tag_row(8, "Beta Tag") ],
      "podcasts" => [ row(4, entry_for("Twice Tagged", "website_url" => "https://twice.example")) ],
      "taggings" => [
        { "tag_id" => 7, "taggable_type" => "Podcast", "taggable_id" => 4 },
        { "tag_id" => 8, "taggable_type" => "Podcast", "taggable_id" => 4 }
      ]
    )

    entry = Entry.find_by(title: "Twice Tagged")
    taggings = CategoriesEntry.where(entry: entry).includes(:category).to_a
    assert_equal 2, taggings.size
    assert_equal [ "Alpha Tag" ], taggings.select(&:is_primary?).map { |t| t.category.name }
    assert_not taggings.any?(&:is_featured?)
  end

  private

  # Writes `data` as YAML files into a throwaway directory and runs a full import.
  # Returns everything the importer printed.
  test "the legacy slugs are kept so the old links keep working" do
    import(legacy_dump)

    assert_equal "legacy-metaprogramming", Category.find_by(name: "Metaprogramming").slug
    assert_equal "legacy-imported-author", Author.find_by(name: "Imported Author").slug
    assert_equal "legacy-imported-course", Entry.find_by(title: "Imported Course").slug
  end

  test "importing the same dump twice creates nothing the second time" do
    import(legacy_dump)

    assert_no_difference [ "Category.count", "Author.count", "Entry.count", "Course.count" ] do
      import(legacy_dump)
    end
  end

  test "a re-import leaves no entryable behind without an entry" do
    import(legacy_dump)
    import(legacy_dump)

    assert_equal Entry.where(entryable_type: "Course").count, Course.count
    assert_empty Course.where.missing(:entry)
  end

  # A dump whose slugs do not match what the models would generate, which is what
  # the legacy data looks like.
  def legacy_dump
    {
      "tags" => [ tag_row(7, "Metaprogramming").merge("slug" => "legacy-metaprogramming") ],
      "authors" => [ author_row(3, "Imported Author").merge("slug" => "legacy-imported-author") ],
      "courses" => [ row(2, entry_for("Imported Course", "website_url" => "https://courses.example")
                              .merge("slug" => "legacy-imported-course"), "free" => "t") ]
    }
  end

  def import(data = {})
    with_yaml(data) do |dir|
      out, = capture_io { Imports::Rubyandrailsinfo::YamlImporter.new(yaml_dir: dir).import_all }
      out
    end
  end

  private

  # A String value is written verbatim, anything else is dumped as YAML.
  def with_yaml(data)
    Dir.mktmpdir do |dir|
      FILES.each do |name|
        body = data.fetch(name, [])
        File.write(File.join(dir, "#{name}.yml"), body.is_a?(String) ? body : body.to_yaml)
      end

      yield dir
    end
  end

  def row(id, entry, fields = {})
    { "id" => id, "created_at" => CREATED, "updated_at" => UPDATED, "entry" => entry }.merge(fields)
  end

  def entry_for(title, fields = {})
    { "title" => title, "slug" => title.parameterize, "content" => title }.merge(fields)
  end

  def tag_row(id, title)
    { "id" => id, "title" => title, "slug" => title.parameterize, "created_at" => CREATED, "updated_at" => UPDATED }
  end

  def author_row(id, name)
    {
      "id" => id, "name" => name, "slug" => name.parameterize,
      "twitter_url" => "https://twitter.com/#{name.parameterize}",
      "website_url" => "https://#{name.parameterize}.example",
      "created_at" => CREATED, "updated_at" => UPDATED
    }
  end
end
