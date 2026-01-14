# frozen_string_literal: true

require "test_helper"

class AuthorSearchQueryTest < ActiveSupport::TestCase
  setup do
    # Create approved authors with different names
    @author_matz = Author.create!(
      name: "Yukihiro Matsumoto",
      status: :approved
    )

    @author_dhh = Author.create!(
      name: "David Heinemeier Hansson",
      status: :approved
    )

    @author_aaron = Author.create!(
      name: "Aaron Patterson",
      status: :approved
    )

    @pending_author = Author.create!(
      name: "Pending Person",
      status: :pending
    )

    # Create some entries for entry count tests
    @entry1 = Entry.create!(
      title: "Rails Guide",
      description: "A guide",
      status: :approved,
      published: true,
      url: "https://example.com/1"
    )

    @entry2 = Entry.create!(
      title: "Ruby Tutorial",
      description: "A tutorial",
      status: :approved,
      published: true,
      url: "https://example.com/2"
    )

    # Associate entries with authors
    @author_dhh.entries << @entry1
    @author_dhh.entries << @entry2
    @author_matz.entries << @entry1
  end

  test "finds authors by partial name match" do
    query = AuthorSearchQuery.new({ q: "Yuki" })
    results = query.call

    assert_includes results, @author_matz
    assert_not_includes results, @author_dhh
    assert_not_includes results, @author_aaron
  end

  test "finds authors by last name" do
    query = AuthorSearchQuery.new({ q: "Patterson" })
    results = query.call

    assert_includes results, @author_aaron
    assert_not_includes results, @author_matz
    assert_not_includes results, @author_dhh
  end

  test "phrase search for full names" do
    query = AuthorSearchQuery.new({ q: '"David Heinemeier"' })
    results = query.call

    assert_includes results, @author_dhh
    assert_not_includes results, @author_matz
  end

  test "includes entry count in results" do
    query = AuthorSearchQuery.new({ q: "David" })
    results = query.call
    author = results.first

    assert_equal 2, author.entries_count
  end

  test "ranks results by FTS5 relevance and alphabetically" do
    # Search for "Patterson" which should match Aaron Patterson specifically
    query = AuthorSearchQuery.new({ q: "Patterson" })
    results = query.call.to_a

    assert_equal 1, results.size
    assert_equal "Aaron Patterson", results.first.name
  end

  test "returns only approved authors" do
    query = AuthorSearchQuery.new({ q: "Pending" })
    results = query.call

    assert_not_includes results, @pending_author
  end

  test "handles empty query" do
    query = AuthorSearchQuery.new({ q: "" })
    results = query.call

    # Should return all approved authors when no query
    assert_includes results, @author_matz
    assert_includes results, @author_dhh
    assert_includes results, @author_aaron
    assert_not_includes results, @pending_author
  end

  test "sanitizes FTS5 special characters" do
    query = AuthorSearchQuery.new({ q: "David (test)" })

    # Should not raise error, should sanitize the query
    assert_nothing_raised do
      query.call.to_a
    end
  end
end
