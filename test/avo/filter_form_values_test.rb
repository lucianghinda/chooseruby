# frozen_string_literal: true

require "test_helper"

class AvoFilterFormValuesTest < ActionView::TestCase
  helper Avo::ApplicationHelper

  setup do
    @resource = Avo::Resources::Entry.new(view: :index)
    @applied_filters = {}.freeze
  end

  test "author status form values select matching authors" do
    approved = Author.create!(name: "Approved author", status: :approved)
    pending = Author.create!(name: "Pending author", status: :pending)
    filter = Avo::Filters::AuthorStatusFilter.new

    assert_equal [ approved ], filter.apply_query(nil, Author.all, select_value(filter, "Approved")).to_a
    assert_equal [ pending ], filter.apply_query(nil, Author.all, select_value(filter, "Pending")).to_a
  end

  test "review status forms submit enum values and proposals select the pending default" do
    [ Avo::Filters::EntryStatusFilter, Avo::Filters::AuthorProposalStatusFilter ].each do |filter_class|
      filter = filter_class.new
      assert_equal "pending", select_value(filter, "Pending")
      assert_equal "approved", select_value(filter, "Approved")
      assert_equal "rejected", select_value(filter, "Rejected")
    end

    form = render_filter(Avo::Filters::AuthorProposalStatusFilter.new)
    assert_equal "pending", form.at_css("option[selected]")["value"]
  end

  test "experience and type form values select matching entries" do
    beginner = create_entry(title: "Beginner book", experience_level: :beginner)
    gem = create_entry(title: "Advanced gem", experience_level: :advanced, entryable: RubyGem.new)
    experience = Avo::Filters::EntryExperienceLevelFilter.new
    type = Avo::Filters::EntryTypeFilter.new

    assert_equal [ beginner ], experience.apply_query(nil, Entry.all, select_value(experience, "Beginner")).to_a
    assert_equal [ gem ], type.apply_query(nil, Entry.all, select_value(type, "Ruby Gem")).to_a
  end

  test "category and tag form values select matching entries" do
    category = Category.create!(name: "Learning resources")
    tagged = create_entry(title: "Ruby tags", tags: [ "ruby-on-rails" ], categories: [ category ])
    create_entry(title: "Other entry", tags: [ "other" ])
    categories = Avo::Filters::EntryCategoryFilter.new
    tags = Avo::Filters::EntryTagsFilter.new

    assert_equal [ tagged ], categories.apply_query(nil, Entry.all, select_value(categories, category.name)).to_a
    assert_equal [ tagged ], tags.apply_query(nil, Entry.all, select_value(tags, "Ruby On Rails")).to_a
  end

  test "published checkbox values select visibility and retain checked state" do
    published = create_entry(title: "Published entry", published: true)
    unpublished = create_entry(title: "Unpublished entry", published: false)
    filter = Avo::Filters::EntryPublishedFilter.new
    @applied_filters = { filter.class.to_s => { "true" => true, "false" => false } }.freeze
    form = render_filter(filter)
    choices = form.css("input[type=checkbox]").index_by { |input| input["value"] }

    assert_equal %w[true false], choices.keys
    assert choices.fetch("true")["checked"]
    assert_nil choices.fetch("false")["checked"]
    assert_equal [ published ], filter.apply_query(nil, Entry.all, { choices.fetch("true")["value"] => true }).to_a
    assert_equal [ unpublished ], filter.apply_query(nil, Entry.all, { choices.fetch("false")["value"] => true }).to_a
  end

  private

  def render_filter(filter)
    Nokogiri::HTML.fragment(render(partial: filter.template, locals: { filter: filter }))
  end

  def select_value(filter, label)
    render_filter(filter).css("option").find { |option| option.text == label }["value"]
  end

  def create_entry(**attributes)
    Entry.create!({ description: "Filter test", url: "https://example.com/filter", entryable: Book.new, status: :approved }.merge(attributes))
  end
end
