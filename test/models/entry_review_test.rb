# frozen_string_literal: true

# == Schema Information
#
# Table name: entry_reviews
# Database name: primary
#
#  id          :integer          not null, primary key
#  comment     :text
#  status      :integer          default("approved"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  entry_id    :integer          not null
#  reviewer_id :integer
#
# Indexes
#
#  index_entry_reviews_on_entry_id  (entry_id)
#  index_entry_reviews_on_status    (status)
#
# Foreign Keys
#
#  entry_id  (entry_id => entries.id)
#
require "test_helper"

class EntryReviewTest < ActiveSupport::TestCase
  test "validates presence of entry_id" do
    review = EntryReview.new(status: :approved)
    assert_not review.valid?
    assert_includes review.errors[:entry_id], "can't be blank"
  end

  test "validates presence of status" do
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com",
      status: :approved
    )
    review = EntryReview.new(entry: entry)
    review.status = nil
    assert_not review.valid?
    assert_includes review.errors[:status], "can't be blank"
  end

  test "belongs_to entry association works correctly" do
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com",
      status: :approved
    )
    review = EntryReview.create!(entry: entry, status: :approved)

    assert_equal entry, review.entry
  end

  test "status enum accepts approved value" do
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com",
      status: :approved
    )
    review = EntryReview.create!(entry: entry, status: :approved)

    assert review.approved?
    assert_not review.rejected?
    assert_equal "approved", review.status
  end

  test "status enum accepts rejected value" do
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com",
      status: :approved
    )
    review = EntryReview.create!(entry: entry, status: :rejected)

    assert review.rejected?
    assert_not review.approved?
    assert_equal "rejected", review.status
  end

  test "entry has_many entry_reviews association works" do
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com",
      status: :approved
    )
    review1 = EntryReview.create!(entry: entry, status: :approved)
    review2 = EntryReview.create!(entry: entry, status: :rejected, comment: "Needs improvement")

    assert_includes entry.entry_reviews, review1
    assert_includes entry.entry_reviews, review2
    assert_equal 2, entry.entry_reviews.count
  end

  test "can query approved reviews using where" do
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com",
      status: :approved
    )
    approved_review = EntryReview.create!(entry: entry, status: :approved)
    EntryReview.create!(entry: entry, status: :rejected)

    approved_reviews = entry.entry_reviews.where(status: :approved)
    assert_equal 1, approved_reviews.count
    assert_includes approved_reviews, approved_review
  end

  test "can query rejected reviews using where" do
    entry = Entry.create!(
      title: "Test Entry",
      url: "https://example.com",
      status: :approved
    )
    EntryReview.create!(entry: entry, status: :approved)
    rejected_review = EntryReview.create!(entry: entry, status: :rejected, comment: "Not suitable")

    rejected_reviews = entry.entry_reviews.where(status: :rejected)
    assert_equal 1, rejected_reviews.count
    assert_includes rejected_reviews, rejected_review
  end
end
