# frozen_string_literal: true

require "test_helper"
require "ostruct"
require_relative "../avo_admin_helper"

# Drives the Avo Entry admin pages. Entry is the widest resource in the panel,
# and several of its field options are lambdas (`suggestions:` on tags, `scope:`
# on entry_reviews) that only run while a page renders, so each view is
# requested and the rendered result asserted.
class AvoEntryResourceTest < ActionDispatch::IntegrationTest
  include AvoAdminHelper

  setup do
    sign_in_as_admin
    @entry = Entry.create!(
      title: "Avo Entry Under Test",
      description: "A description rendered by the admin panel",
      url: "https://example.com/avo-entry-under-test",
      entryable: RubyGem.create!(gem_name: "avo-entry-under-test"),
      status: :approved,
      published: true,
      experience_level: :intermediate,
      image_url: "https://example.com/logo.png",
      submitter_name: "Sam Submitter",
      submitter_email: "sam@example.com",
      tags: [ "rails", "hotwire" ]
    )
  end

  test "index lists entries with their sortable columns" do
    body = get_avo("/avo/resources/entries")

    assert_match @entry.title, body
    assert_match "Title", body
    assert_match "Status", body
    assert_match "Published", body
    assert_match "Created at", body
  end

  test "index hides the fields marked hide_on index" do
    body = get_avo("/avo/resources/entries")

    assert_no_match(/Submitter email/, body)
    assert_no_match(/Image url/, body)
    assert_no_match(/Updated at/, body)
  end

  test "index offers every filter mounted on the resource" do
    body = get_avo("/avo/resources/entries")

    assert_match "Avo::Filters::EntryStatusFilter", body
    assert_match "Avo::Filters::EntryPublishedFilter", body
    assert_match "Avo::Filters::EntryExperienceLevelFilter", body
    assert_match "Avo::Filters::EntryTypeFilter", body
    assert_match "Avo::Filters::EntryCategoryFilter", body
    assert_match "Avo::Filters::EntryTagsFilter", body
  end

  test "index offers every curation action" do
    body = get_avo("/avo/resources/entries")

    assert_match "Avo::Actions::ApproveEntries", body
    assert_match "Avo::Actions::RejectEntries", body
    assert_match "Avo::Actions::PublishEntries", body
    assert_match "Avo::Actions::UnpublishEntries", body
  end

  test "show renders the entry attributes including the ones hidden on index" do
    body = get_avo("/avo/resources/entries/#{@entry.id}")

    assert_match @entry.title, body
    assert_match "A description rendered by the admin panel", body
    assert_match "https://example.com/avo-entry-under-test", body
    assert_match "sam@example.com", body
    assert_match "Sam Submitter", body
    assert_match "https://example.com/logo.png", body
    assert_match @entry.slug, body
  end

  test "show renders the tags assigned to the entry" do
    body = get_avo("/avo/resources/entries/#{@entry.id}")
    tags_markup = body[/data-field-id="tags".{0,2000}/m]

    assert_not_nil tags_markup
    assert_match "rails", tags_markup
    assert_match "hotwire", tags_markup
  end

  test "show links to the polymorphic entryable record" do
    body = get_avo("/avo/resources/entries/#{@entry.id}")

    assert_match "/avo/resources/ruby_gems/#{@entry.entryable_id}", body
  end

  test "show defers the has_many associations to their own turbo frames" do
    body = get_avo("/avo/resources/entries/#{@entry.id}")

    assert_match "has_many_field_show_categories", body
    assert_match "has_many_field_show_authors", body
    assert_match "has_many_field_show_entry_reviews", body
  end

  test "the categories association frame lists the assigned categories" do
    @entry.categories << categories(:testing)

    body = get_avo(association_frame_path(:categories))

    assert_match categories(:testing).name, body
    assert_match "/avo/resources/categories/#{categories(:testing).id}", body
  end

  test "the authors association frame lists the assigned authors" do
    author = Author.create!(name: "Entry Resource Author", status: :approved)
    @entry.authors << author

    body = get_avo(association_frame_path(:authors))

    assert_match author.name, body
    assert_match "/avo/resources/authors/#{author.id}", body
  end

  test "the entry reviews association frame orders the newest review first" do
    # Created in id order but with the newest review last, so row order can only
    # match the resource's `scope: -> { query.order(created_at: :desc) }`.
    older = EntryReview.create!(entry: @entry, status: :rejected, comment: "Older review", created_at: 2.days.ago)
    newer = EntryReview.create!(entry: @entry, status: :approved, comment: "Newer review", created_at: 1.hour.ago)

    body = get_avo(association_frame_path(:entry_reviews))
    newer_row = body.index("data-resource-id=\"#{newer.id}\"")
    older_row = body.index("data-resource-id=\"#{older.id}\"")

    assert_not_nil newer_row
    assert_not_nil older_row
    assert_operator newer_row, :<, older_row,
                    "the entry_reviews scope must order the newest review first"
  end

  test "new renders the form with every delegated type selectable" do
    body = get_avo("/avo/resources/entries/new")

    assert_match "Title", body
    assert_match "Entryable", body
    %w[Article Blog Book Channel Community Course DevelopmentEnvironment Directory
       Documentation Framework JobBoard Newsletter Podcast Product RubyGem
       TestingResource Tool Tutorial Video].each do |type|
      assert_match type, body, "the entryable polymorphic field must offer #{type}"
    end
  end

  test "new renders the experience level and status choices" do
    body = get_avo("/avo/resources/entries/new")

    %w[all_levels beginner intermediate advanced].each do |level|
      assert_match "<option value=\"#{level}\">", body
    end
    %w[approved rejected].each do |status|
      assert_match "<option value=\"#{status}\">", body
    end
    assert_match "<option selected=\"selected\" value=\"pending\">", body
  end

  test "edit suggests the tags already in use across entries" do
    Entry.create!(
      title: "Other Tagged Entry",
      description: "Contributes a tag suggestion",
      url: "https://example.com/other-tagged-entry",
      entryable: RubyGem.create!(gem_name: "other-tagged-entry"),
      status: :approved,
      tags: [ "turbo" ]
    )

    body = get_avo("/avo/resources/entries/#{@entry.id}/edit")
    suggestions = body[/data-tags-field-whitelist-items-value="([^"]*)"/, 1]

    assert_not_nil suggestions, "the tags field must publish its suggestions"
    suggestions = CGI.unescapeHTML(suggestions)
    assert_match "turbo", suggestions, "tags from other entries must be offered as suggestions"
    assert_match "rails", suggestions
    assert_match "hotwire", suggestions
  end

  test "edit renders the writable fields prefilled" do
    body = get_avo("/avo/resources/entries/#{@entry.id}/edit")

    assert_match @entry.title, body
    assert_match "https://example.com/avo-entry-under-test", body
    assert_match "sam@example.com", body
  end

  test "search finds entries by the body of their rich text description" do
    other = Entry.create!(
      title: "Unrelated Entry",
      description: "Nothing to do with the search term",
      url: "https://example.com/unrelated-entry",
      entryable: RubyGem.create!(gem_name: "unrelated-entry"),
      status: :approved
    )

    context = OpenStruct.new(params: { q: "rendered by the admin panel" }, query: Entry.all)
    results = context.instance_exec(&Avo::Resources::Entry.search[:query])

    assert_includes results, @entry, "the search must join the rich text description"
    assert_not_includes results, other
  end

  test "the resource describes the two step creation flow to admins" do
    assert_match(/First create a Book\/RubyGem/, Avo::Resources::Entry.description)
  end

  private

  def association_frame_path(association)
    "/avo/resources/entries/#{@entry.id}/#{association}" \
      "?view=show&turbo_frame=has_many_field_show_#{association}"
  end
end
