# frozen_string_literal: true

require "test_helper"
require "ostruct"

class AvoLikeInjectionSecurityTest < ActionDispatch::IntegrationTest
  # Test that all Avo resources sanitize LIKE wildcards to prevent LIKE injection attacks

  def setup
    # Use unique names/slugs to avoid conflicts across test runs
    timestamp = Time.now.to_f.to_s.gsub(".", "")

    # Create test data for searches
    @entry1 = Entry.create!(
      title: "Rails Guide #{timestamp}",
      description: "Learn Rails",
      url: "https://example.com/rails-#{timestamp}",
      entryable: Book.create!(publication_year: 2024),
      status: :approved,
      published: true
    )

    @entry2 = Entry.create!(
      title: "PostgreSQL Guide #{timestamp}",
      description: "Learn PostgreSQL",
      url: "https://example.com/postgres-#{timestamp}",
      entryable: Book.create!(publication_year: 2024),
      status: :approved,
      published: true
    )

    @author1 = Author.create!(name: "David Test #{timestamp}", status: :approved)
    @author2 = Author.create!(name: "Aaron Test #{timestamp}", status: :approved)

    @category1 = Category.create!(name: "Testing #{timestamp}", slug: "testing-#{timestamp}")
    @category2 = Category.create!(name: "Performance #{timestamp}", slug: "performance-#{timestamp}")
  end

  # Entry resource search tests
  test "Entry resource search sanitizes percent wildcard" do
    # Test that searching for "%" doesn't match all entries
    search_lambda = Avo::Resources::Entry.search[:query]

    # Simulate Avo search context with params containing wildcard
    context = OpenStruct.new(params: { q: "%" }, query: Entry.all)
    results = context.instance_exec(&search_lambda)

    # Should not return all entries (sanitized % becomes literal % which matches nothing)
    assert_operator results.count, :<, Entry.count,
      "Wildcard % should be sanitized and not match all entries"
  end

  test "Entry resource search sanitizes underscore wildcard" do
    # Test that searching for "___" doesn't act as wildcard pattern
    search_lambda = Avo::Resources::Entry.search[:query]

    context = OpenStruct.new(params: { q: "___" }, query: Entry.all)
    results = context.instance_exec(&search_lambda)

    # Should not match entries with 3-character words (sanitized _ becomes literal _)
    assert_equal 0, results.count,
      "Underscore _ should be sanitized and treated as literal character"
  end

  test "Entry resource search works correctly with normal text" do
    search_lambda = Avo::Resources::Entry.search[:query]

    context = OpenStruct.new(params: { q: "Rails Guide" }, query: Entry.all)
    results = context.instance_exec(&search_lambda)

    assert_includes results, @entry1, "Should find entry with 'Rails Guide' in title"
    assert_not_includes results, @entry2, "Should not find entry without 'Rails Guide'"
  end

  test "Entry resource search escapes wildcards in mixed query" do
    # Test query with both wildcards and normal text
    search_lambda = Avo::Resources::Entry.search[:query]

    context = OpenStruct.new(params: { q: "Rails Guide%" }, query: Entry.all)
    results = context.instance_exec(&search_lambda)

    # Should look for literal "Rails Guide%" string, not "Rails Guide" followed by anything
    assert_equal 0, results.count,
      "Mixed query 'Rails Guide%' should treat % as literal character"
  end

  # Author resource search tests
  test "Author resource search sanitizes percent wildcard" do
    search_lambda = Avo::Resources::Author.search[:query]

    context = OpenStruct.new(params: { q: "%" }, query: Author.all)
    results = context.instance_exec(&search_lambda)

    assert_operator results.count, :<, Author.count,
      "Wildcard % should be sanitized in Author search"
  end

  test "Author resource search sanitizes underscore wildcard" do
    search_lambda = Avo::Resources::Author.search[:query]

    context = OpenStruct.new(params: { q: "___" }, query: Author.all)
    results = context.instance_exec(&search_lambda)

    assert_equal 0, results.count,
      "Underscore _ should be sanitized in Author search"
  end

  test "Author resource search works correctly with normal text" do
    search_lambda = Avo::Resources::Author.search[:query]

    context = OpenStruct.new(params: { q: "David Test" }, query: Author.all)
    results = context.instance_exec(&search_lambda)

    assert_includes results, @author1, "Should find author with 'David Test' in name"
    assert_not_includes results, @author2, "Should not find author without 'David Test'"
  end

  # Category resource search tests
  test "Category resource search sanitizes percent wildcard" do
    search_lambda = Avo::Resources::Category.search[:query]

    context = OpenStruct.new(params: { q: "%" }, query: Category.all)
    results = context.instance_exec(&search_lambda)

    assert_operator results.count, :<, Category.count,
      "Wildcard % should be sanitized in Category search"
  end

  test "Category resource search sanitizes underscore wildcard" do
    search_lambda = Avo::Resources::Category.search[:query]

    context = OpenStruct.new(params: { q: "___" }, query: Category.all)
    results = context.instance_exec(&search_lambda)

    assert_equal 0, results.count,
      "Underscore _ should be sanitized in Category search"
  end

  test "Category resource search works correctly with normal text" do
    search_lambda = Avo::Resources::Category.search[:query]

    context = OpenStruct.new(params: { q: "Testing" }, query: Category.all)
    results = context.instance_exec(&search_lambda)

    assert_includes results, @category1, "Should find category with 'Testing' in name (partial match)"
    assert_not_includes results, @category2, "Should not find category without 'Testing'"
  end

  # EntryTagsFilter tests
  test "EntryTagsFilter sanitizes percent wildcard in filter value" do
    # Create entries with tags
    @entry1.update!(tags: [ "ruby", "rails" ])
    @entry2.update!(tags: [ "postgresql", "database" ])

    filter = Avo::Filters::EntryTagsFilter.new
    query = Entry.all

    # Apply filter with wildcard
    result = filter.apply(nil, query, "%")

    # Should not return all entries (% should be literal)
    assert_operator result.count, :<, Entry.count,
      "Wildcard % should be sanitized in filter"
  end

  test "EntryTagsFilter sanitizes underscore wildcard in filter value" do
    @entry1.update!(tags: [ "ruby", "rails" ])
    @entry2.update!(tags: [ "postgresql", "database" ])

    filter = Avo::Filters::EntryTagsFilter.new
    query = Entry.all

    result = filter.apply(nil, query, "___")

    # Should not match tags with 3 characters
    assert_equal 0, result.count,
      "Underscore _ should be sanitized in filter"
  end

  test "EntryTagsFilter works correctly with normal tag value" do
    @entry1.update!(tags: [ "ruby", "rails" ])
    @entry2.update!(tags: [ "postgresql", "database" ])

    filter = Avo::Filters::EntryTagsFilter.new
    query = Entry.all

    result = filter.apply(nil, query, "ruby")

    assert_includes result, @entry1, "Should find entry with 'ruby' tag"
    assert_not_includes result, @entry2, "Should not find entry without 'ruby' tag"
  end

  test "EntryTagsFilter returns unmodified query when value is blank" do
    filter = Avo::Filters::EntryTagsFilter.new
    query = Entry.all

    result_nil = filter.apply(nil, query, nil)
    result_empty = filter.apply(nil, query, "")

    assert_equal query, result_nil, "Should return original query when value is nil"
    assert_equal query, result_empty, "Should return original query when value is empty"
  end

  # Cross-cutting security tests
  test "all Avo resources use sanitize_sql_like" do
    # Verify that the code contains sanitization
    entry_code = File.read(Rails.root.join("app/avo/resources/entry.rb"))
    author_code = File.read(Rails.root.join("app/avo/resources/author.rb"))
    category_code = File.read(Rails.root.join("app/avo/resources/category.rb"))
    filter_code = File.read(Rails.root.join("app/avo/filters/entry_tags_filter.rb"))

    assert_match(/sanitize_sql_like/, entry_code,
      "Entry resource should use sanitize_sql_like")
    assert_match(/sanitize_sql_like/, author_code,
      "Author resource should use sanitize_sql_like")
    assert_match(/sanitize_sql_like/, category_code,
      "Category resource should use sanitize_sql_like")
    assert_match(/sanitize_sql_like/, filter_code,
      "EntryTagsFilter should use sanitize_sql_like")
  end

  test "no unsanitized LIKE patterns exist in Avo resources" do
    # This test ensures we don't regress by adding new unsanitized LIKE queries
    entry_code = File.read(Rails.root.join("app/avo/resources/entry.rb"))
    author_code = File.read(Rails.root.join("app/avo/resources/author.rb"))
    category_code = File.read(Rails.root.join("app/avo/resources/category.rb"))
    filter_code = File.read(Rails.root.join("app/avo/filters/entry_tags_filter.rb"))

    # Pattern: LIKE query with interpolation before sanitization
    # This is a simplified check - looking for params[:q] or value in LIKE without prior sanitize_sql_like
    unsafe_pattern = /LIKE.*%#\{(?!sanitized)/

    assert_no_match unsafe_pattern, entry_code,
      "Entry should not have unsanitized LIKE patterns"
    assert_no_match unsafe_pattern, author_code,
      "Author should not have unsanitized LIKE patterns"
    assert_no_match unsafe_pattern, category_code,
      "Category should not have unsanitized LIKE patterns"
    assert_no_match unsafe_pattern, filter_code,
      "Filter should not have unsanitized LIKE patterns"
  end
end
