# frozen_string_literal: true

require "test_helper"

# Delegated types without a name of their own take their display name from
# their entry, falling back to a type-specific label.
class EntryableDisplayNameTest < ActiveSupport::TestCase
  ENTRYABLES_WITHOUT_NAME = {
    Article => {},
    Community => { platform: "Discord", join_url: "https://example.com/join" },
    Course => {},
    Podcast => {},
    Tool => {},
    Tutorial => {}
  }.freeze

  ENTRYABLES_WITHOUT_NAME.each do |model, attributes|
    test "#{model} display_name returns entry title when entry exists" do
      entryable = model.create!(attributes)
      Entry.create!(title: "Entry for #{model}", url: "https://example.com/#{model.name.underscore}", entryable: entryable, status: :approved)

      assert_equal "Entry for #{model}", entryable.display_name
    end

    test "#{model} display_name returns fallback when entry does not exist" do
      entryable = model.create!(attributes)

      assert_equal "#{model} ##{entryable.id}", entryable.display_name
    end
  end

  test "RubyGem display_name returns entry title when entry exists" do
    ruby_gem = RubyGem.create!(gem_name: "display-name-gem")
    Entry.create!(title: "Display Name Gem", url: "https://example.com/gem", entryable: ruby_gem, status: :approved)

    assert_equal "Display Name Gem", ruby_gem.display_name
  end

  test "RubyGem display_name returns gem name when entry does not exist" do
    ruby_gem = RubyGem.create!(gem_name: "display-name-gem")

    assert_equal "display-name-gem", ruby_gem.display_name
  end
end
