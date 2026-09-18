# frozen_string_literal: true

require "test_helper"

class DomainEdgeCasesTest < ActiveSupport::TestCase
  test "categories with differently punctuated names get unique slugs" do
    original = Category.create!(name: "Ruby Testing")
    alternate = Category.create!(name: "Ruby-Testing")
    third = Category.create!(name: "Ruby & Testing")

    assert_equal "ruby-testing", original.slug
    assert_equal "ruby-testing-1", alternate.slug
    assert_equal "ruby-testing-2", third.slug
  end

  test "clearing a github profile preserves the existing avatar" do
    author = Author.create!(name: "Avatar Author", github_url: "https://github.com/matz")

    author.update!(github_url: nil)

    assert_equal "https://github.com/matz.png", author.reload.avatar_url
  end

  test "a non-github URL does not overwrite an existing avatar" do
    author = Author.create!(name: "Avatar Author", avatar_url: "https://example.com/avatar.png")

    author.update!(github_url: "https://example.com/profile")

    assert_equal "https://example.com/avatar.png", author.reload.avatar_url
  end

  test "an entry without a rich description can change visibility" do
    entry = Entry.create!(title: "No rich text", url: "https://example.com/plain", status: :approved)

    entry.reload.update!(published: true)

    assert_predicate entry.reload, :published?
    assert_equal [ entry ], EntryDirectoryQuery.new({ q: "rich" }).call.to_a
  end

  test "zero related resource limit returns no resources even with categories" do
    entry = Entry.create!(title: "Related resource", url: "https://example.com/related", status: :approved)
    entry.categories << categories(:testing)

    assert_empty entry.related_resources(limit: 0)
  end
end
