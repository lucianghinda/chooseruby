# frozen_string_literal: true

require "test_helper"

class EntrySubmissionWorkflowTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "pending submissions ignore publication attributes" do
    submission = EntrySubmission.new(submission_attributes.merge(status: :approved, published: true))

    assert submission.save
    assert_predicate submission.entry, :pending?
    assert_not submission.entry.published?
  end

  test "an unknown author does not prevent a valid submission" do
    submission = EntrySubmission.new(submission_attributes.merge(author_id: -1))

    assert submission.save
    assert_empty submission.entry.authors
  end

  test "unknown types are rejected before records can be saved" do
    submission = EntrySubmission.new(submission_attributes.merge(resource_type: "User"))

    assert_no_difference "Entry.count" do
      assert_raises(ArgumentError) { submission.save }
    end
  end

  test "mail jobs wait for the surrounding transaction to commit" do
    clear_enqueued_jobs

    Entry.transaction do
      assert EntrySubmission.new(submission_attributes).save
      assert_enqueued_jobs 0
    end

    assert_enqueued_jobs 2
  end

  test "rolled-back submissions do not enqueue mail" do
    clear_enqueued_jobs

    assert_no_difference "Entry.count" do
      Entry.transaction do
        assert EntrySubmission.new(submission_attributes).save
        raise ActiveRecord::Rollback
      end
    end

    assert_enqueued_jobs 0
  end

  private

  def submission_attributes
    { title: "Submitted resource", url: "https://example.com/submission", resource_type: "Book",
      submitter_email: "submitter@example.com", publisher: "Ruby Publisher" }
  end
end
