# frozen_string_literal: true

require "test_helper"

# Covers the action field declaration and the success message of the
# "Reject Resources" action. The record side effects are covered in
# test/avo/actions/reject_entries_test.rb.
class Avo::Actions::RejectEntriesFieldsTest < ActiveSupport::TestCase
  test "reject action exposes an optional comment textarea" do
    action = Avo::Actions::RejectEntries.new(record: nil, resource: nil, user: nil, view: :index)
    action.fields

    field = action.get_field_definitions.sole
    assert_equal :comment, field.id
    assert_equal "textarea", field.type
    assert_not field.required
    assert_equal "Optional feedback for the submitter", field.help
  end

  test "reject action reports a single resource in singular" do
    entry = pending_entry("Test Entry", "test-gem", "https://example.com")

    action = Avo::Actions::RejectEntries.new(record: entry, resource: nil, user: nil, view: :index)
    action.handle(records: [ entry ], fields: { comment: "Not suitable" }, current_user: nil, resource: nil)

    message = action.response[:messages].last
    assert_equal :success, message[:type]
    assert_equal "1 resource rejected successfully!", message[:body]
  end

  test "reject action reports several resources in plural" do
    first = pending_entry("Test Entry 1", "test-gem-1", "https://example.com/1")
    second = pending_entry("Test Entry 2", "test-gem-2", "https://example.com/2")

    action = Avo::Actions::RejectEntries.new(record: first, resource: nil, user: nil, view: :index)
    action.handle(records: [ first, second ], fields: { comment: "Not suitable" }, current_user: nil, resource: nil)

    message = action.response[:messages].last
    assert_equal :success, message[:type]
    assert_equal "2 resources rejected successfully!", message[:body]
  end

  private

  def pending_entry(title, gem_name, url)
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
