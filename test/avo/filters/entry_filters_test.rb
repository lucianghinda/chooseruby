# frozen_string_literal: true

require "test_helper"

class Avo::Filters::EntryFiltersTest < ActiveSupport::TestCase
  setup do
    @category = categories(:testing)
    @published = Entry.create!(title: "Published", url: "https://example.com/p", status: :approved, published: true,
                               experience_level: :beginner, tags: [ "rails" ], entryable: RubyGem.create!(gem_name: "filter-gem"))
    @unpublished = Entry.create!(title: "Unpublished", url: "https://example.com/u", status: :rejected, published: false,
                                 experience_level: :advanced, entryable: Book.create!(publisher: "Pragmatic"))
    @published.categories << @category
  end

  test "status filter narrows to the selected status and ignores unknown values" do
    filter = Avo::Filters::EntryStatusFilter.new

    assert_equal [ @published ], filter.apply(nil, Entry.all, "approved").to_a
    assert_equal [ @unpublished ], filter.apply(nil, Entry.all, "rejected").to_a
    assert_empty filter.apply(nil, Entry.all, "pending").to_a
    assert_equal 2, filter.apply(nil, Entry.all, "bogus").count
    assert_equal %w[pending approved rejected], filter.options.values
  end

  test "published filter narrows by the selected boolean and ignores contradictory selections" do
    filter = Avo::Filters::EntryPublishedFilter.new

    assert_equal [ @published ], filter.apply(nil, Entry.all, { "true" => true }).to_a
    assert_equal [ @unpublished ], filter.apply(nil, Entry.all, { "false" => true }).to_a
    assert_equal 2, filter.apply(nil, Entry.all, { "true" => true, "false" => true }).count
    assert_equal %w[true false], filter.options.keys
  end

  test "experience level filter narrows by level when given" do
    filter = Avo::Filters::EntryExperienceLevelFilter.new

    assert_equal [ @unpublished ], filter.apply(nil, Entry.all, "advanced").to_a
    assert_equal 2, filter.apply(nil, Entry.all, "").count
    assert_includes filter.options.values, "beginner"
  end

  test "type filter narrows by entryable type when given" do
    filter = Avo::Filters::EntryTypeFilter.new

    assert_equal [ @published ], filter.apply(nil, Entry.all, "RubyGem").to_a
    assert_equal 2, filter.apply(nil, Entry.all, nil).count
    assert_equal "RubyGem", filter.options["Ruby Gem"]
  end

  test "category filter narrows by category when given" do
    filter = Avo::Filters::EntryCategoryFilter.new

    assert_equal [ @published ], filter.apply(nil, Entry.all, @category.id).to_a
    assert_equal 2, filter.apply(nil, Entry.all, nil).count
    assert_equal @category.id, filter.options[@category.name]
  end

  test "tags filter narrows by tag when given" do
    filter = Avo::Filters::EntryTagsFilter.new

    assert_equal [ @published ], filter.apply(nil, Entry.all, "rails").to_a
    assert_empty filter.apply(nil, Entry.all, "%").to_a
    assert_equal 2, filter.apply(nil, Entry.all, "").count
    assert_equal({ "Rails" => "rails" }, filter.options)
  end
end
