# frozen_string_literal: true

require "test_helper"

class EntryReviewAssociationTest < ActiveSupport::TestCase
  test "entry.approved_entry_reviews returns only approved reviews" do
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com",
      status: :approved
    )

    approved_review1 = EntryReview.create!(entry: entry, status: :approved)
    approved_review2 = EntryReview.create!(entry: entry, status: :approved)
    EntryReview.create!(entry: entry, status: :rejected, comment: "Rejected")

    approved_reviews = entry.approved_entry_reviews
    assert_equal 2, approved_reviews.count
    assert_includes approved_reviews, approved_review1
    assert_includes approved_reviews, approved_review2
  end

  test "entry.rejected_entry_reviews returns only rejected reviews" do
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com",
      status: :approved
    )

    EntryReview.create!(entry: entry, status: :approved)
    rejected_review1 = EntryReview.create!(entry: entry, status: :rejected, comment: "Issue 1")
    rejected_review2 = EntryReview.create!(entry: entry, status: :rejected, comment: "Issue 2")

    rejected_reviews = entry.rejected_entry_reviews
    assert_equal 2, rejected_reviews.count
    assert_includes rejected_reviews, rejected_review1
    assert_includes rejected_reviews, rejected_review2
  end

  test "dependent destroy removes entry_reviews when entry is destroyed" do
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com",
      status: :approved
    )

    EntryReview.create!(entry: entry, status: :approved)
    EntryReview.create!(entry: entry, status: :rejected, comment: "Rejected")

    entry_id = entry.id
    assert_equal 2, EntryReview.where(entry_id: entry_id).count

    entry.destroy
    assert_equal 0, EntryReview.where(entry_id: entry_id).count
  end
end
