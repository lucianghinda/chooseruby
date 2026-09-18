# frozen_string_literal: true

require "test_helper"

class AvoFiltersTest < ActiveSupport::TestCase
  test "author status accepts known strings and preserves unknown selections" do
    filter = Avo::Filters::AuthorStatusFilter.new
    query = Author.all

    %w[approved pending].each do |status|
      assert_equal query.where(status: status).to_sql, filter.apply(nil, query, status).to_sql
    end
    [ nil, "", "rejected", :approved ].each { |value| assert_same query, filter.apply(nil, query, value) }
    assert_equal({ "approved" => "Approved", "pending" => "Pending" }, filter.options)
  end

  [ [ Avo::Filters::AuthorProposalStatusFilter, AuthorProposal ], [ Avo::Filters::EntryStatusFilter, Entry ] ].each do |filter_class, model|
    test "#{filter_class} filters all review statuses and normalizes capitalization" do
      filter = filter_class.new
      query = model.all
      %w[pending approved rejected].each do |status|
        assert_equal query.where(status: status).to_sql, filter.apply(nil, query, status.upcase).to_sql
      end
      [ nil, "", "unknown" ].each { |value| assert_same query, filter.apply(nil, query, value) }
      assert_equal %w[pending approved rejected], filter.options.keys
    end
  end

  test "proposals default to pending review" do
    assert_equal "pending", Avo::Filters::AuthorProposalStatusFilter.new.default
  end

  test "entry type and experience level preserve empty selections" do
    query = Entry.all
    [ [ Avo::Filters::EntryTypeFilter, :entryable_type, "Book" ], [ Avo::Filters::EntryExperienceLevelFilter, :experience_level, "beginner" ] ].each do |filter_class, attribute, selection|
      filter = filter_class.new
      [ nil, "", "unknown" ].each { |value| assert_same query, filter.apply(nil, query, value) }
      assert_equal query.where(attribute => selection).to_sql, filter.apply(nil, query, selection).to_sql
      assert_includes filter.options.keys, selection
    end
  end

  test "published filter supports checkbox combinations and legacy values" do
    filter = Avo::Filters::EntryPublishedFilter.new
    query = Entry.all
    {
      "true" => true,
      "false" => false,
      { "true" => true, "false" => false } => true,
      { true: false, false: true } => false,
      { "true" => true, "unrelated" => true } => true
    }.each do |selection, expected|
      assert_equal query.where(published: expected).to_sql, filter.apply(nil, query, selection).to_sql
    end
    [ nil, "", "unknown", {}, { "true" => true, "false" => true }, { "true" => false, "false" => false } ].each do |selection|
      assert_same query, filter.apply(nil, query, selection)
    end
    assert_equal({ "true" => "Published", "false" => "Unpublished" }, filter.options)
  end

  test "category filter lists names alphabetically and selects only assigned entries" do
    category = Category.create!(name: "ZZZ category")
    first = Category.create!(name: "AAA category")
    entry = Entry.create!(title: "Categorized entry", description: "Description", url: "https://example.com/category", entryable: Book.new, status: :approved, categories: [ category ])
    filter = Avo::Filters::EntryCategoryFilter.new
    query = Entry.all

    [ nil, "", "unknown" ].each { |value| assert_same query, filter.apply(nil, query, value) }
    assert_equal [ entry ], filter.apply(nil, query, category.id).to_a
    assert_equal "AAA category", filter.options.fetch(first.id.to_s)
    assert_equal "ZZZ category", filter.options.fetch(category.id.to_s)
    assert_operator filter.options.values.index("AAA category"), :<, filter.options.values.index("ZZZ category")
  end

  test "tag filter escapes wildcard input and lists unique sorted tags" do
    entry = Entry.create!(title: "Tagged entry", description: "Description", url: "https://example.com/tags", entryable: Book.new, status: :approved, tags: %w[ruby rails ruby%])
    filter = Avo::Filters::EntryTagsFilter.new
    query = Entry.all

    assert_same query, filter.apply(nil, query, "")
    assert_equal [ entry ], filter.apply(nil, query, "ruby%").to_a
    assert_empty filter.apply(nil, query, "%")
    assert_equal({ "rails" => "Rails", "ruby" => "Ruby", "ruby%" => "Ruby%" }, filter.options)
  end

  test "dynamic options are loaded once per filter instance" do
    [ Avo::Filters::EntryCategoryFilter, Avo::Filters::EntryTagsFilter ].each do |filter_class|
      filter = filter_class.new
      filter.options

      queries = []
      subscriber = ->(_name, _start, _finish, _id, payload) { queries << payload.fetch(:sql) }
      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
        2.times { filter.options }
      end

      assert_empty queries, "#{filter_class} should reuse options when Avo renders the filter"
    end
  end
end
