# frozen_string_literal: true

require "test_helper"

class EntryDirectorySortTest < ActiveSupport::TestCase
  setup do
    @older = Entry.create!(title: "Ruby older", url: "https://example.com/older", status: :approved,
      published: true, experience_level: :beginner, updated_at: 2.days.ago)
    @newer = Entry.create!(title: "Ruby newer", url: "https://example.com/newer", status: :approved,
      published: true, experience_level: :advanced, updated_at: 1.day.ago)
  end

  test "oldest sorting orders by ascending update time" do
    assert_equal [ @older, @newer ], EntryDirectoryQuery.new({ sort: "oldest" }).call.to_a
  end

  test "unknown sorting falls back to newest first" do
    assert_equal [ @newer, @older ], EntryDirectoryQuery.new({ sort: "unexpected" }).call.to_a
  end

  test "unknown sorting preserves search relevance" do
    expected = EntryDirectoryQuery.new({ q: "Ruby" }).call.to_a

    assert_equal expected, EntryDirectoryQuery.new({ q: "Ruby", sort: "unexpected" }).call.to_a
  end

  test "invalid experience level does not restrict entries" do
    assert_equal [ @newer, @older ], EntryDirectoryQuery.new({ level: "unknown" }).call.to_a
  end

  test "popular sorts by the resource popularity measure" do
    @older.update!(entryable: RubyGem.create!(gem_name: "popular-ruby", downloads_count: 100))
    @newer.update!(entryable: Community.create!(member_count: 5, platform: "Discord", join_url: "https://example.com/join"))

    assert_equal [ @older, @newer ], EntryDirectoryQuery.new({ sort: "popular" }).call.to_a
  end

  test "search ignores a word consisting only of removable punctuation" do
    assert_equal [ @newer, @older ], EntryDirectoryQuery.new({ q: "Ruby -" }).call.to_a
  end

  test "beginner sorting gives beginners precedence over advanced entries" do
    assert_equal [ @older, @newer ], EntryDirectoryQuery.new({ sort: "beginner_first" }).call.to_a
  end
end
