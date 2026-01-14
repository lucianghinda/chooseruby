# frozen_string_literal: true

require "test_helper"

class Avo::Actions::ApproveEntriesTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "approve action updates entry status to approved and sets published to true" do
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

    action = Avo::Actions::ApproveEntries.new(record: entry, resource: nil, user: nil, view: :index)
    action.handle(records: [ entry ], fields: {}, current_user: nil, resource: nil)

    entry.reload
    assert_equal "approved", entry.status
    assert entry.published
  end

  test "approve action creates EntryReview with status approved" do
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

    assert_difference "EntryReview.count", 1 do
      action = Avo::Actions::ApproveEntries.new(record: entry, resource: nil, user: nil, view: :index)
      action.handle(records: [ entry ], fields: {}, current_user: nil, resource: nil)
    end

    review = entry.entry_reviews.last
    assert_equal "approved", review.status
  end

  test "approve action queues approval notification email job" do
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
      action = Avo::Actions::ApproveEntries.new(record: entry, resource: nil, user: nil, view: :index)
      action.handle(records: [ entry ], fields: {}, current_user: nil, resource: nil)
    end
  end

  test "approve action processes multiple entries correctly" do
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

    assert_difference "EntryReview.count", 2 do
      action = Avo::Actions::ApproveEntries.new(record: entry1, resource: nil, user: nil, view: :index)
      action.handle(records: [ entry1, entry2 ], fields: {}, current_user: nil, resource: nil)
    end

    entry1.reload
    entry2.reload
    assert_equal "approved", entry1.status
    assert_equal "approved", entry2.status
    assert entry1.published
    assert entry2.published
  end
end
