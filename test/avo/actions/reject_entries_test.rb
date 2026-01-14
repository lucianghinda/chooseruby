# frozen_string_literal: true

require "test_helper"

class Avo::Actions::RejectEntriesTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "reject action creates EntryReview with status rejected and comment" do
    ruby_gem = RubyGem.create!(gem_name: "test-gem")
    entry = Entry.create!(
      title: "Test Entry",
      description: "Test description",
      url: "https://example.com",
      entryable: ruby_gem,
      status: :pending,
      published: false,
      submitter_email: "user@example.com"
    )

    comment_text = "Missing documentation and examples"

    assert_difference "EntryReview.count", 1 do
      action = Avo::Actions::RejectEntries.new(record: entry, resource: nil, user: nil, view: :index)
      action.handle(records: [ entry ], fields: { comment: comment_text }, current_user: nil, resource: nil)
    end

    entry.reload
    assert_equal "rejected", entry.status

    review = entry.entry_reviews.last
    assert_equal "rejected", review.status
    assert_equal comment_text, review.comment
  end

  test "reject action queues rejection notification email job" do
    ruby_gem = RubyGem.create!(gem_name: "test-gem")
    entry = Entry.create!(
      title: "Test Entry",
      description: "Test description",
      url: "https://example.com",
      entryable: ruby_gem,
      status: :pending,
      published: false,
      submitter_email: "user@example.com"
    )

    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      action = Avo::Actions::RejectEntries.new(record: entry, resource: nil, user: nil, view: :index)
      action.handle(records: [ entry ], fields: { comment: "Not suitable" }, current_user: nil, resource: nil)
    end
  end

  test "reject action handles nil comment gracefully" do
    ruby_gem = RubyGem.create!(gem_name: "test-gem")
    entry = Entry.create!(
      title: "Test Entry",
      description: "Test description",
      url: "https://example.com",
      entryable: ruby_gem,
      status: :pending,
      published: false,
      submitter_email: "user@example.com"
    )

    action = Avo::Actions::RejectEntries.new(record: entry, resource: nil, user: nil, view: :index)
    action.handle(records: [ entry ], fields: { comment: nil }, current_user: nil, resource: nil)

    entry.reload
    review = entry.entry_reviews.last
    assert_equal "rejected", review.status
    assert_nil review.comment
  end

  test "reject action processes multiple entries with same comment" do
    ruby_gem1 = RubyGem.create!(gem_name: "test-gem-1")
    entry1 = Entry.create!(
      title: "Test Entry 1",
      description: "Test description",
      url: "https://example.com/1",
      entryable: ruby_gem1,
      status: :pending,
      published: false,
      submitter_email: "user1@example.com"
    )

    ruby_gem2 = RubyGem.create!(gem_name: "test-gem-2")
    entry2 = Entry.create!(
      title: "Test Entry 2",
      description: "Test description",
      url: "https://example.com/2",
      entryable: ruby_gem2,
      status: :pending,
      published: false,
      submitter_email: "user2@example.com"
    )

    comment = "Does not meet quality standards"

    assert_difference "EntryReview.count", 2 do
      action = Avo::Actions::RejectEntries.new(record: entry1, resource: nil, user: nil, view: :index)
      action.handle(records: [ entry1, entry2 ], fields: { comment: comment }, current_user: nil, resource: nil)
    end

    entry1.reload
    entry2.reload
    assert_equal "rejected", entry1.status
    assert_equal "rejected", entry2.status
    assert_equal comment, entry1.entry_reviews.last.comment
    assert_equal comment, entry2.entry_reviews.last.comment
  end
end
