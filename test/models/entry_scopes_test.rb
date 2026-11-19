# frozen_string_literal: true

require "test_helper"

# Covers the ordering and filtering scopes the entry directory listing is built from.
class EntryScopesTest < ActiveSupport::TestCase
  test "by_popularity puts the gem with the most downloads first" do
    quiet = gem_entry("quiet_gem", 10)
    popular = gem_entry("popular_gem", 5_000)

    assert_equal [ popular.id, quiet.id ], entries(quiet, popular).by_popularity.map(&:id)
  end

  test "by_popularity falls back to the most recently updated entry without a popularity metric" do
    older = entry("Older", updated_at: 2.hours.ago)
    newer = entry("Newer", updated_at: 1.hour.ago)

    assert_equal [ newer.id, older.id ], entries(older, newer).by_popularity.map(&:id)
  end

  test "oldest_first starts with the entry that was updated longest ago" do
    older = entry("Older", updated_at: 2.hours.ago)
    newer = entry("Newer", updated_at: 1.hour.ago)

    assert_equal [ older.id, newer.id ], entries(older, newer).oldest_first.map(&:id)
  end

  test "beginner_first works up from the most approachable level" do
    advanced = entry("Advanced", updated_at: 1.hour.ago, experience_level: :advanced)
    beginner = entry("Beginner", updated_at: 2.hours.ago, experience_level: :beginner)
    intermediate = entry("Intermediate", updated_at: 3.hours.ago, experience_level: :intermediate)

    ordered = entries(advanced, beginner, intermediate).beginner_first

    assert_equal [ beginner.id, intermediate.id, advanced.id ], ordered.map(&:id)
  end

  test "beginner_first sorts an entry without a level last" do
    unset = entry("Unset", updated_at: 1.hour.ago, experience_level: nil)
    everyone = entry("Everyone", updated_at: 2.hours.ago, experience_level: :all_levels)
    advanced = entry("Advanced", updated_at: 3.hours.ago, experience_level: :advanced)

    ordered = entries(advanced, unset, everyone).beginner_first

    assert_equal [ advanced.id, everyone.id, unset.id ], ordered.map(&:id)
  end

  test "for_experience_level keeps the level asked for and everything meant for all levels" do
    beginner = entry("Beginner", experience_level: :beginner)
    everyone = entry("Everyone", experience_level: :all_levels)
    advanced = entry("Advanced", experience_level: :advanced)

    found = entries(beginner, everyone, advanced).for_experience_level("beginner")

    assert_equal [ beginner.id, everyone.id ].sort, found.map(&:id).sort
  end

  test "selectable_experience_levels offers every level a submitter may pick" do
    assert_equal [
      [ "Beginner", "beginner" ],
      [ "Intermediate", "intermediate" ],
      [ "Advanced", "advanced" ]
    ], Entry.selectable_experience_levels
  end

  private

  def entry(title, **attributes)
    Entry.create!(
      title: title,
      url: "https://example.com/#{title.parameterize}",
      published: true,
      status: :approved,
      **attributes
    )
  end

  def gem_entry(gem_name, downloads_count)
    entry(gem_name.titleize, entryable: RubyGem.create!(gem_name: gem_name, downloads_count: downloads_count))
  end

  def entries(*records)
    Entry.where(id: records.map(&:id))
  end
end
