# frozen_string_literal: true

require "test_helper"

class Avo::Actions::PublishEntriesTest < ActiveSupport::TestCase
  test "publish action marks every selected resource as published" do
    first = unpublished_entry("Test Entry 1", "test-gem-1", "https://example.com/1")
    second = unpublished_entry("Test Entry 2", "test-gem-2", "https://example.com/2")

    action = Avo::Actions::PublishEntries.new(record: first, resource: nil, user: nil, view: :index)
    action.handle(records: [ first, second ], fields: {}, current_user: nil, resource: nil)

    assert_predicate first.reload, :published?
    assert_predicate second.reload, :published?
  end

  test "publish action reports the number of published resources in plural" do
    first = unpublished_entry("Test Entry 1", "test-gem-1", "https://example.com/1")
    second = unpublished_entry("Test Entry 2", "test-gem-2", "https://example.com/2")

    action = Avo::Actions::PublishEntries.new(record: first, resource: nil, user: nil, view: :index)
    action.handle(records: [ first, second ], fields: {}, current_user: nil, resource: nil)

    message = action.response[:messages].last
    assert_equal :success, message[:type]
    assert_equal "2 resources published successfully!", message[:body]
  end

  test "publish action reports a single resource in singular" do
    entry = unpublished_entry("Test Entry", "test-gem", "https://example.com")

    action = Avo::Actions::PublishEntries.new(record: entry, resource: nil, user: nil, view: :index)
    action.handle(records: [ entry ], fields: {}, current_user: nil, resource: nil)

    message = action.response[:messages].last
    assert_equal :success, message[:type]
    assert_equal "1 resource published successfully!", message[:body]
  end

  test "publish action does not change the curation status" do
    entry = unpublished_entry("Test Entry", "test-gem", "https://example.com")

    action = Avo::Actions::PublishEntries.new(record: entry, resource: nil, user: nil, view: :index)
    action.handle(records: [ entry ], fields: {}, current_user: nil, resource: nil)

    assert_equal "pending", entry.reload.status
  end

  private

  def unpublished_entry(title, gem_name, url)
    Entry.create!(
      title: title,
      description: "Test description",
      url: url,
      entryable: RubyGem.create!(gem_name: gem_name),
      status: :pending,
      published: false,
      submitter_email: "user@example.com"
    )
  end
end
