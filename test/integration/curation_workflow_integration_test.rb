# frozen_string_literal: true

require "test_helper"

# Integration tests for Curation Workflow and Review Queue feature (Spec 006)
# These tests verify complete end-to-end workflows for approval and rejection actions
# including entry updates, EntryReview creation, and email job processing
class CurationWorkflowIntegrationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    # Clear deliveries before each test
    ActionMailer::Base.deliveries.clear
  end

  # Test 1: Complete approve workflow - entry updated, review created, email processed
  test "complete approve workflow updates entry, creates review, and delivers email" do
    ruby_gem = RubyGem.create!(gem_name: "workflow-gem")
    entry = Entry.create!(
      title: "Workflow Test Gem",
      url: "https://rubygems.org/gems/workflow-gem",
      description: "Testing complete approval workflow",
      entryable: ruby_gem,
      status: :pending,
      published: false,
      submitter_name: "Workflow Developer",
      submitter_email: "workflow@example.com",
      slug: "workflow-test-gem"
    )

    # Verify starting state
    assert_equal "pending", entry.status
    assert_equal false, entry.published
    assert_equal 0, entry.entry_reviews.count

    # Perform approval action and process enqueued jobs
    perform_enqueued_jobs do
      action = Avo::Actions::ApproveEntries.new(record: entry, resource: nil, user: nil, view: :index)
      action.handle(records: [ entry ], fields: {}, current_user: nil, resource: nil)
    end

    # Verify entry was updated
    entry.reload
    assert_equal "approved", entry.status
    assert entry.published

    # Verify EntryReview was created
    assert_equal 1, entry.entry_reviews.count
    review = entry.entry_reviews.last
    assert_equal "approved", review.status
    assert_nil review.comment

    # Verify email was delivered
    assert_equal 1, ActionMailer::Base.deliveries.count
    email = ActionMailer::Base.deliveries.last
    assert_equal [ "workflow@example.com" ], email.to
    assert_equal "Your ChooseRuby submission has been approved: Workflow Test Gem", email.subject
    assert_match "Workflow Test Gem", email.html_part.body.to_s
  end

  # Test 2: Complete reject workflow with comment - entry updated, review with comment created, email processed
  test "complete reject workflow with comment updates entry, creates review, and delivers email" do
    book = Book.create!(isbn: "9781234567890", publisher: "Test Publisher")
    entry = Entry.create!(
      title: "Rejected Book",
      url: "https://example.com/rejected-book",
      description: "Testing rejection workflow",
      entryable: book,
      status: :pending,
      published: false,
      submitter_email: "author@example.com",
      slug: "rejected-book"
    )

    rejection_comment = "Missing detailed description and technical depth"

    # Perform rejection action and process enqueued jobs
    perform_enqueued_jobs do
      action = Avo::Actions::RejectEntries.new(record: entry, resource: nil, user: nil, view: :index)
      action.handle(records: [ entry ], fields: { comment: rejection_comment }, current_user: nil, resource: nil)
    end

    # Verify entry was updated
    entry.reload
    assert_equal "rejected", entry.status
    assert_equal false, entry.published

    # Verify EntryReview was created with comment
    assert_equal 1, entry.entry_reviews.count
    review = entry.entry_reviews.last
    assert_equal "rejected", review.status
    assert_equal rejection_comment, review.comment

    # Verify email was delivered with comment
    assert_equal 1, ActionMailer::Base.deliveries.count
    email = ActionMailer::Base.deliveries.last
    assert_equal [ "author@example.com" ], email.to
    assert_equal "Update on your ChooseRuby submission: Rejected Book", email.subject
    assert_match "Rejected Book", email.html_part.body.to_s
    assert_match rejection_comment, email.html_part.body.to_s
  end

  # Test 3: Complete reject workflow without comment - verify nil comment handling
  test "complete reject workflow without comment handles nil gracefully" do
    tool = Tool.create!(tool_type: "CLI", license: "MIT")
    entry = Entry.create!(
      title: "Rejected Tool",
      url: "https://example.com/tool",
      description: "Testing rejection without comment",
      entryable: tool,
      status: :pending,
      submitter_email: "dev@example.com",
      slug: "rejected-tool"
    )

    # Perform rejection action without comment
    perform_enqueued_jobs do
      action = Avo::Actions::RejectEntries.new(record: entry, resource: nil, user: nil, view: :index)
      action.handle(records: [ entry ], fields: { comment: nil }, current_user: nil, resource: nil)
    end

    # Verify EntryReview was created with nil comment
    entry.reload
    review = entry.entry_reviews.last
    assert_equal "rejected", review.status
    assert_nil review.comment

    # Verify email was delivered with fallback message
    email = ActionMailer::Base.deliveries.last
    assert_equal [ "dev@example.com" ], email.to
    # Should not include specific comment, but should render successfully
    assert_no_match "Missing documentation", email.html_part.body.to_s
  end

  # Test 4: Test EntryReview associations - entry.approved_entry_reviews
  test "entry.approved_entry_reviews returns only approved reviews" do
    ruby_gem = RubyGem.create!(gem_name: "association-test-gem")
    entry = Entry.create!(
      title: "Association Test Entry",
      url: "https://example.com/association",
      description: "Testing associations",
      entryable: ruby_gem,
      status: :pending,
      submitter_email: "test@example.com",
      slug: "association-test-entry"
    )

    # Create multiple reviews with different statuses
    approved_review1 = EntryReview.create!(entry: entry, status: :approved)
    rejected_review = EntryReview.create!(entry: entry, status: :rejected, comment: "First rejection")
    approved_review2 = EntryReview.create!(entry: entry, status: :approved)

    # Test approved_entry_reviews convenience method
    approved_reviews = entry.approved_entry_reviews
    assert_equal 2, approved_reviews.count
    assert_includes approved_reviews, approved_review1
    assert_includes approved_reviews, approved_review2
    assert_not_includes approved_reviews, rejected_review
  end

  # Test 5: Test EntryReview associations - entry.rejected_entry_reviews
  test "entry.rejected_entry_reviews returns only rejected reviews" do
    course = Course.create!(platform: "Udemy", instructor: "Test Instructor")
    entry = Entry.create!(
      title: "Rejection Association Test",
      url: "https://example.com/rejection-assoc",
      description: "Testing rejection associations",
      entryable: course,
      status: :pending,
      submitter_email: "test@example.com",
      slug: "rejection-association-test"
    )

    # Create multiple reviews
    approved_review = EntryReview.create!(entry: entry, status: :approved)
    rejected_review1 = EntryReview.create!(entry: entry, status: :rejected, comment: "First rejection")
    rejected_review2 = EntryReview.create!(entry: entry, status: :rejected, comment: "Second rejection")

    # Test rejected_entry_reviews convenience method
    rejected_reviews = entry.rejected_entry_reviews
    assert_equal 2, rejected_reviews.count
    assert_includes rejected_reviews, rejected_review1
    assert_includes rejected_reviews, rejected_review2
    assert_not_includes rejected_reviews, approved_review
  end

  # Test 6: Verify reviewer_id remains NULL when no admin user context exists
  test "reviewer_id remains NULL when no admin user system exists" do
    tutorial = Tutorial.create!(author_name: "Test Author", platform: "Dev.to")
    entry = Entry.create!(
      title: "Reviewer ID Test",
      url: "https://example.com/reviewer-test",
      description: "Testing reviewer_id behavior",
      entryable: tutorial,
      status: :pending,
      submitter_email: "test@example.com",
      slug: "reviewer-id-test"
    )

    # Perform approval action
    action = Avo::Actions::ApproveEntries.new(record: entry, resource: nil, user: nil, view: :index)
    action.handle(records: [ entry ], fields: {}, current_user: nil, resource: nil)

    # Verify reviewer_id is NULL
    review = entry.entry_reviews.last
    assert_nil review.reviewer_id
  end

  # Test 7: Test email job delivery using perform_enqueued_jobs for approval
  test "approval email job is processed and delivered successfully" do
    article = Article.create!(author_name: "Test Author", platform: "Medium")
    entry = Entry.create!(
      title: "Email Job Test",
      url: "https://example.com/email-job",
      description: "Testing email job processing",
      entryable: article,
      status: :pending,
      submitter_email: "emailtest@example.com",
      slug: "email-job-test"
    )

    # Process jobs and verify email delivery
    perform_enqueued_jobs do
      action = Avo::Actions::ApproveEntries.new(record: entry, resource: nil, user: nil, view: :index)
      action.handle(records: [ entry ], fields: {}, current_user: nil, resource: nil)
    end

    # Verify exactly one email was delivered
    assert_equal 1, ActionMailer::Base.deliveries.count
    email = ActionMailer::Base.deliveries.last
    assert_equal [ "emailtest@example.com" ], email.to
    assert_match "Email Job Test", email.html_part.body.to_s
  end

  # Test 8: Test email job delivery using perform_enqueued_jobs for rejection
  test "rejection email job is processed and delivered successfully" do
    podcast = Podcast.create!(host: "Test Host", frequency: "Weekly")
    entry = Entry.create!(
      title: "Rejection Email Job Test",
      url: "https://example.com/rejection-email",
      description: "Testing rejection email job processing",
      entryable: podcast,
      status: :pending,
      submitter_email: "rejection@example.com",
      slug: "rejection-email-job-test"
    )

    # Process jobs and verify email delivery
    perform_enqueued_jobs do
      action = Avo::Actions::RejectEntries.new(record: entry, resource: nil, user: nil, view: :index)
      action.handle(records: [ entry ], fields: { comment: "Testing rejection email" }, current_user: nil, resource: nil)
    end

    # Verify exactly one email was delivered
    assert_equal 1, ActionMailer::Base.deliveries.count
    email = ActionMailer::Base.deliveries.last
    assert_equal [ "rejection@example.com" ], email.to
    assert_match "Rejection Email Job Test", email.html_part.body.to_s
    assert_match "Testing rejection email", email.html_part.body.to_s
  end

  # Test 9: Test transaction atomicity by verifying all steps succeed together
  test "transaction ensures all steps succeed atomically in approval workflow" do
    community = Community.create!(platform: "Discord", join_url: "https://discord.gg/ruby")
    entry = Entry.create!(
      title: "Transaction Atomicity Test",
      url: "https://example.com/atomicity",
      description: "Testing transaction atomicity",
      entryable: community,
      status: :pending,
      submitter_email: "atomicity@example.com",
      slug: "transaction-atomicity-test"
    )

    # Count enqueued jobs and created reviews
    assert_difference "entry.entry_reviews.count", 1 do
      assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
        action = Avo::Actions::ApproveEntries.new(record: entry, resource: nil, user: nil, view: :index)
        action.handle(records: [ entry ], fields: {}, current_user: nil, resource: nil)
      end
    end

    # Verify all steps completed
    entry.reload
    assert_equal "approved", entry.status
    assert entry.published
    assert_equal 1, entry.entry_reviews.count
    assert_equal "approved", entry.entry_reviews.last.status
  end

  # Test 10: Test complete review history tracking across multiple reviews
  test "review history tracks multiple reviews for re-review capability" do
    book = Book.create!(isbn: "9789876543210", publisher: "History Publisher")
    entry = Entry.create!(
      title: "Review History Test",
      url: "https://example.com/history",
      description: "Testing review history tracking",
      entryable: book,
      status: :pending,
      submitter_email: "history@example.com",
      slug: "review-history-test"
    )

    # First rejection
    EntryReview.create!(entry: entry, status: :rejected, comment: "First rejection - needs improvement")
    entry.update!(status: :rejected)

    # Second review - approval
    EntryReview.create!(entry: entry, status: :approved)
    entry.update!(status: :approved, published: true)

    # Third review - another rejection
    EntryReview.create!(entry: entry, status: :rejected, comment: "Second rejection - outdated content")
    entry.update!(status: :rejected, published: false)

    # Verify complete history is tracked
    assert_equal 3, entry.entry_reviews.count

    # Verify can query by status
    approved_reviews = entry.entry_reviews.where(status: :approved)
    assert_equal 1, approved_reviews.count

    rejected_reviews = entry.entry_reviews.where(status: :rejected)
    assert_equal 2, rejected_reviews.count

    # Verify most recent review
    latest_review = entry.entry_reviews.last
    assert_equal "rejected", latest_review.status
    assert_equal "Second rejection - outdated content", latest_review.comment
  end
end
