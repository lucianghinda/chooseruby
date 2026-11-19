# frozen_string_literal: true

require "test_helper"

class Avo::Actions::UnpublishEntriesTest < ActiveSupport::TestCase
  test "unpublish action hides every selected resource" do
    first = published_entry("Test Entry 1", "test-gem-1", "https://example.com/1")
    second = published_entry("Test Entry 2", "test-gem-2", "https://example.com/2")

    action = Avo::Actions::UnpublishEntries.new(record: first, resource: nil, user: nil, view: :index)
    action.handle(records: [ first, second ], fields: {}, current_user: nil, resource: nil)

    assert_not_predicate first.reload, :published?
    assert_not_predicate second.reload, :published?
  end

  test "unpublish action reports the number of unpublished resources in plural" do
    first = published_entry("Test Entry 1", "test-gem-1", "https://example.com/1")
    second = published_entry("Test Entry 2", "test-gem-2", "https://example.com/2")

    action = Avo::Actions::UnpublishEntries.new(record: first, resource: nil, user: nil, view: :index)
    action.handle(records: [ first, second ], fields: {}, current_user: nil, resource: nil)

    message = action.response[:messages].last
    assert_equal :success, message[:type]
    assert_equal "2 resources unpublished successfully!", message[:body]
  end

  test "unpublish action reports a single resource in singular" do
    entry = published_entry("Test Entry", "test-gem", "https://example.com")

    action = Avo::Actions::UnpublishEntries.new(record: entry, resource: nil, user: nil, view: :index)
    action.handle(records: [ entry ], fields: {}, current_user: nil, resource: nil)

    message = action.response[:messages].last
    assert_equal :success, message[:type]
    assert_equal "1 resource unpublished successfully!", message[:body]
  end

  test "unpublish action keeps the approved curation status" do
    entry = published_entry("Test Entry", "test-gem", "https://example.com")

    action = Avo::Actions::UnpublishEntries.new(record: entry, resource: nil, user: nil, view: :index)
    action.handle(records: [ entry ], fields: {}, current_user: nil, resource: nil)

    assert_equal "approved", entry.reload.status
  end

  private

  def published_entry(title, gem_name, url)
    Entry.create!(
      title: title,
      description: "Test description",
      url: url,
      entryable: RubyGem.create!(gem_name: gem_name),
      status: :approved,
      published: true,
      submitter_email: "user@example.com"
    )
  end
end
