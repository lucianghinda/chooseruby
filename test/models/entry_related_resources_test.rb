# frozen_string_literal: true

require "test_helper"

class EntryRelatedResourcesTest < ActiveSupport::TestCase
  setup do
    # Create categories for testing
    @category1 = categories(:testing)
    @category2 = categories(:authentication)
    @category3 = categories(:background_jobs)
    @category4 = categories(:web_development)

    # Create the main entry that we'll find related resources for
    @main_entry = Entry.create!(
      title: "Main Resource",
      url: "https://example.com/main",
      published: true,
      status: :approved
    )
    @main_entry.categories << [ @category1, @category2, @category3 ]
  end

  test "returns up to 6 related resources" do
    # Create 10 resources in category1
    10.times do |i|
      entry = Entry.create!(
        title: "Category1 Resource #{i}",
        url: "https://example.com/cat1-#{i}",
        published: true,
        status: :approved,
        updated_at: i.hours.ago
      )
      entry.categories << @category1
    end

    related = @main_entry.related_resources(limit: 6)

    assert_equal 6, related.length, "Should return exactly 6 related resources"
  end

  test "excludes current entry from results" do
    # Create resources in the same category
    5.times do |i|
      entry = Entry.create!(
        title: "Related Resource #{i}",
        url: "https://example.com/related-#{i}",
        published: true,
        status: :approved
      )
      entry.categories << @category1
    end

    related = @main_entry.related_resources

    refute_includes related, @main_entry, "Should not include the current entry in results"
  end

  test "distributes 2 resources from each of first 3 categories" do
    # Create 3 resources in category1
    cat1_entries = 3.times.map do |i|
      entry = Entry.create!(
        title: "Cat1 Resource #{i}",
        url: "https://example.com/cat1-#{i}",
        published: true,
        status: :approved,
        updated_at: (i + 1).hours.ago
      )
      entry.categories << @category1
      entry
    end

    # Create 3 resources in category2
    cat2_entries = 3.times.map do |i|
      entry = Entry.create!(
        title: "Cat2 Resource #{i}",
        url: "https://example.com/cat2-#{i}",
        published: true,
        status: :approved,
        updated_at: (i + 4).hours.ago
      )
      entry.categories << @category2
      entry
    end

    # Create 3 resources in category3
    cat3_entries = 3.times.map do |i|
      entry = Entry.create!(
        title: "Cat3 Resource #{i}",
        url: "https://example.com/cat3-#{i}",
        published: true,
        status: :approved,
        updated_at: (i + 7).hours.ago
      )
      entry.categories << @category3
      entry
    end

    related = @main_entry.related_resources(limit: 6)

    # Check that we got 6 resources
    assert_equal 6, related.length

    # Check that we have 2 from each category
    cat1_count = related.count { |e| e.categories.include?(@category1) }
    cat2_count = related.count { |e| e.categories.include?(@category2) }
    cat3_count = related.count { |e| e.categories.include?(@category3) }

    assert_equal 2, cat1_count, "Should have 2 resources from category1"
    assert_equal 2, cat2_count, "Should have 2 resources from category2"
    assert_equal 2, cat3_count, "Should have 2 resources from category3"
  end

  test "handles entry with single category correctly" do
    # Create an entry with only one category
    single_cat_entry = Entry.create!(
      title: "Single Category Entry",
      url: "https://example.com/single",
      published: true,
      status: :approved
    )
    single_cat_entry.categories << @category1

    # Create 8 resources in the same category
    8.times do |i|
      entry = Entry.create!(
        title: "Same Category Resource #{i}",
        url: "https://example.com/same-#{i}",
        published: true,
        status: :approved,
        updated_at: i.hours.ago
      )
      entry.categories << @category1
    end

    related = single_cat_entry.related_resources(limit: 6)

    assert_equal 6, related.length, "Should still return 6 resources from single category"
    assert related.all? { |e| e.categories.include?(@category1) }, "All should be from category1"
  end

  test "only returns visible published and approved entries" do
    # Create a published and approved entry (visible)
    visible_entry = Entry.create!(
      title: "Visible Resource",
      url: "https://example.com/visible",
      published: true,
      status: :approved
    )
    visible_entry.categories << @category1

    # Create an unpublished entry
    unpublished_entry = Entry.create!(
      title: "Unpublished Resource",
      url: "https://example.com/unpublished",
      published: false,
      status: :approved
    )
    unpublished_entry.categories << @category1

    # Create a pending entry
    pending_entry = Entry.create!(
      title: "Pending Resource",
      url: "https://example.com/pending",
      published: true,
      status: :pending,
      submitter_email: "pending@example.com"
    )
    pending_entry.categories << @category1

    # Create a rejected entry
    rejected_entry = Entry.create!(
      title: "Rejected Resource",
      url: "https://example.com/rejected",
      published: true,
      status: :rejected
    )
    rejected_entry.categories << @category1

    related = @main_entry.related_resources

    assert_includes related, visible_entry, "Should include visible entry"
    refute_includes related, unpublished_entry, "Should not include unpublished entry"
    refute_includes related, pending_entry, "Should not include pending entry"
    refute_includes related, rejected_entry, "Should not include rejected entry"
  end

  test "orders by updated_at desc recently curated" do
    # Create resources with different update times
    old_entry = Entry.create!(
      title: "Old Resource",
      url: "https://example.com/old",
      published: true,
      status: :approved,
      updated_at: 10.hours.ago
    )
    old_entry.categories << @category1

    recent_entry = Entry.create!(
      title: "Recent Resource",
      url: "https://example.com/recent",
      published: true,
      status: :approved,
      updated_at: 1.hour.ago
    )
    recent_entry.categories << @category1

    middle_entry = Entry.create!(
      title: "Middle Resource",
      url: "https://example.com/middle",
      published: true,
      status: :approved,
      updated_at: 5.hours.ago
    )
    middle_entry.categories << @category1

    related = @main_entry.related_resources

    # The most recently updated should come first
    assert_equal recent_entry, related.first, "Most recently updated should be first"
  end

  test "handles entry with no categories gracefully" do
    # Create an entry with no categories
    no_cat_entry = Entry.create!(
      title: "No Categories Entry",
      url: "https://example.com/nocat",
      published: true,
      status: :approved
    )

    related = no_cat_entry.related_resources

    assert_empty related, "Should return empty array for entry with no categories"
  end

  test "handles insufficient resources in categories" do
    # Make the main entry from setup not visible for this test to avoid interference
    @main_entry.update!(published: false)

    # Create entry with 3 categories but only 1 resource per category
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com/test",
      published: true,
      status: :approved
    )
    entry.categories << [ @category1, @category2, @category3 ]

    # Create only 1 resource in each category
    Entry.create!(
      title: "Cat1 Resource",
      url: "https://example.com/cat1-1",
      published: true,
      status: :approved
    ).categories << @category1

    Entry.create!(
      title: "Cat2 Resource",
      url: "https://example.com/cat2-1",
      published: true,
      status: :approved
    ).categories << @category2

    Entry.create!(
      title: "Cat3 Resource",
      url: "https://example.com/cat3-1",
      published: true,
      status: :approved
    ).categories << @category3

    related = entry.related_resources(limit: 6)

    assert_equal 3, related.length, "Should return 3 resources when only 1 per category available"
  end
end
