# frozen_string_literal: true

require "test_helper"

# Unit tests for the Avo filters mounted on Avo::Resources::Entry.
#
# Each filter is exercised through its public `apply` contract: given a query
# and a selected value it must narrow the result set. `options` is asserted
# because Avo renders it as the select's choices.
class AvoEntryFiltersTest < ActiveSupport::TestCase
  setup do
    @pending_entry = build_entry(title: "Pending Filter Entry", status: :pending, published: false,
                                 experience_level: :beginner, tags: [ "rails" ],
                                 submitter_email: "submitter@example.com")
    @approved_entry = build_entry(title: "Approved Filter Entry", status: :approved, published: true,
                                  experience_level: :advanced, tags: [ "hotwire" ])
    @rejected_entry = build_entry(title: "Rejected Filter Entry", status: :rejected, published: false,
                                  experience_level: :intermediate, tags: [ "legacy" ],
                                  submitter_email: "submitter@example.com")
  end

  # --- EntryStatusFilter ---------------------------------------------------

  test "status filter narrows to pending entries" do
    results = Avo::Filters::EntryStatusFilter.new.apply(nil, Entry.all, "pending")

    assert_includes results, @pending_entry
    assert_not_includes results, @approved_entry
    assert_not_includes results, @rejected_entry
  end

  test "status filter narrows to approved entries" do
    results = Avo::Filters::EntryStatusFilter.new.apply(nil, Entry.all, "approved")

    assert_includes results, @approved_entry
    assert_not_includes results, @pending_entry
  end

  test "status filter narrows to rejected entries" do
    results = Avo::Filters::EntryStatusFilter.new.apply(nil, Entry.all, "rejected")

    assert_includes results, @rejected_entry
    assert_not_includes results, @approved_entry
  end

  test "status filter downcases the incoming value" do
    results = Avo::Filters::EntryStatusFilter.new.apply(nil, Entry.all, "Approved")

    assert_includes results, @approved_entry
    assert_not_includes results, @pending_entry
  end

  test "status filter returns the untouched query for an unknown value" do
    results = Avo::Filters::EntryStatusFilter.new.apply(nil, Entry.all, "")

    assert_includes results, @pending_entry
    assert_includes results, @approved_entry
    assert_includes results, @rejected_entry
  end

  test "status filter offers the three workflow states" do
    assert_equal({ "Pending" => "pending", "Approved" => "approved", "Rejected" => "rejected" },
                 Avo::Filters::EntryStatusFilter.new.options)
  end

  # --- EntryPublishedFilter ------------------------------------------------

  test "published filter narrows to published entries when only true is checked" do
    results = Avo::Filters::EntryPublishedFilter.new.apply(nil, Entry.all, { "true" => true, "false" => false })

    assert_includes results, @approved_entry
    assert_not_includes results, @pending_entry
  end

  test "published filter narrows to unpublished entries when only false is checked" do
    results = Avo::Filters::EntryPublishedFilter.new.apply(nil, Entry.all, { "false" => true, "true" => false })

    assert_includes results, @pending_entry
    assert_not_includes results, @approved_entry
  end

  test "published filter accepts symbol keys from Avo" do
    results = Avo::Filters::EntryPublishedFilter.new.apply(nil, Entry.all, { true: true, false: false })

    assert_includes results, @approved_entry
    assert_not_includes results, @pending_entry
  end

  test "published filter returns everything when both boxes are checked" do
    results = Avo::Filters::EntryPublishedFilter.new.apply(nil, Entry.all, { "true" => true, "false" => true })

    assert_includes results, @approved_entry
    assert_includes results, @pending_entry
  end

  test "published filter returns everything when neither box is checked" do
    results = Avo::Filters::EntryPublishedFilter.new.apply(nil, Entry.all, { "true" => false, "false" => false })

    assert_includes results, @approved_entry
    assert_includes results, @pending_entry
  end

  test "published filter accepts a plain true string" do
    results = Avo::Filters::EntryPublishedFilter.new.apply(nil, Entry.all, "true")

    assert_includes results, @approved_entry
    assert_not_includes results, @pending_entry
  end

  test "published filter accepts a plain false string" do
    results = Avo::Filters::EntryPublishedFilter.new.apply(nil, Entry.all, "false")

    assert_includes results, @pending_entry
    assert_not_includes results, @approved_entry
  end

  test "published filter returns the untouched query for a blank value" do
    results = Avo::Filters::EntryPublishedFilter.new.apply(nil, Entry.all, nil)

    assert_includes results, @approved_entry
    assert_includes results, @pending_entry
  end

  test "published filter labels both states" do
    assert_equal({ "true" => "Published", "false" => "Unpublished" },
                 Avo::Filters::EntryPublishedFilter.new.options)
  end

  # --- EntryExperienceLevelFilter -----------------------------------------

  test "experience level filter narrows to the selected level" do
    results = Avo::Filters::EntryExperienceLevelFilter.new.apply(nil, Entry.all, "beginner")

    assert_includes results, @pending_entry
    assert_not_includes results, @approved_entry
  end

  test "experience level filter returns the untouched query for a blank value" do
    results = Avo::Filters::EntryExperienceLevelFilter.new.apply(nil, Entry.all, "")

    assert_includes results, @pending_entry
    assert_includes results, @approved_entry
  end

  test "experience level filter offers every level of the model enum" do
    assert_equal Entry.experience_levels.keys.sort,
                 Avo::Filters::EntryExperienceLevelFilter.new.options.values.sort
  end

  # --- EntryTypeFilter -----------------------------------------------------

  test "type filter narrows to entries of the selected entryable type" do
    book_entry = build_entry(title: "Book Type Entry", status: :approved, entryable: Book.create!(format: :ebook))

    results = Avo::Filters::EntryTypeFilter.new.apply(nil, Entry.all, "Book")

    assert_includes results, book_entry
    assert_not_includes results, @approved_entry
  end

  test "type filter returns the untouched query for a blank value" do
    results = Avo::Filters::EntryTypeFilter.new.apply(nil, Entry.all, nil)

    assert_includes results, @approved_entry
  end

  test "type filter offers every delegated type of the Entry model" do
    assert_equal Entry.entryable_types.sort,
                 Avo::Filters::EntryTypeFilter.new.options.values.sort
  end

  # --- EntryCategoryFilter -------------------------------------------------

  test "category filter narrows to entries in the selected category" do
    category = categories(:testing)
    @approved_entry.categories << category

    results = Avo::Filters::EntryCategoryFilter.new.apply(nil, Entry.all, category.id)

    assert_includes results, @approved_entry
    assert_not_includes results, @pending_entry
  end

  test "category filter returns the untouched query for a blank value" do
    results = Avo::Filters::EntryCategoryFilter.new.apply(nil, Entry.all, "")

    assert_includes results, @approved_entry
    assert_includes results, @pending_entry
  end

  test "category filter offers every category by name" do
    options = Avo::Filters::EntryCategoryFilter.new.options

    assert_equal Category.order(:name).pluck(:name), options.keys
    assert_equal categories(:testing).id, options[categories(:testing).name]
  end

  # --- EntryTagsFilter -----------------------------------------------------

  test "tags filter narrows to entries carrying the selected tag" do
    results = Avo::Filters::EntryTagsFilter.new.apply(nil, Entry.all, "hotwire")

    assert_includes results, @approved_entry
    assert_not_includes results, @pending_entry
  end

  test "tags filter treats LIKE wildcards as literal characters" do
    results = Avo::Filters::EntryTagsFilter.new.apply(nil, Entry.all, "%")

    assert_not_includes results, @approved_entry
    assert_not_includes results, @pending_entry
  end

  test "tags filter returns the untouched query for a blank value" do
    results = Avo::Filters::EntryTagsFilter.new.apply(nil, Entry.all, nil)

    assert_includes results, @approved_entry
    assert_includes results, @pending_entry
  end

  test "tags filter offers titleized labels for the distinct tags in use" do
    options = Avo::Filters::EntryTagsFilter.new.options

    assert_equal "rails", options["Rails"]
    assert_equal "hotwire", options["Hotwire"]
    assert_equal options.values, options.values.uniq
    assert_equal options.values, options.values.sort
  end

  private

  def build_entry(title:, status:, published: false, experience_level: nil, tags: nil,
                  entryable: nil, submitter_email: nil)
    Entry.create!(
      title: title,
      description: "Filter test entry",
      url: "https://example.com/#{title.parameterize}",
      entryable: entryable || RubyGem.create!(gem_name: title.parameterize),
      status: status,
      published: published,
      experience_level: experience_level,
      tags: tags,
      submitter_email: submitter_email
    )
  end
end
