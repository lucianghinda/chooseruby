# frozen_string_literal: true

# EntryReview model for tracking review history of entry submissions
#
# EntryReview records track all review actions (approve/reject) performed on entries.
# Each review captures the decision status, optional feedback comment, and reviewer
# information for audit trail purposes.
#
# Attributes:
#   - entry_id: Foreign key to Entry (required)
#   - status: Review decision (enum: approved, rejected) (required)
#   - comment: Optional feedback text for submitter
#   - reviewer_id: Future admin user tracking (nullable, NULL until admin system exists)
#   - created_at: When review was performed
#   - updated_at: Last update timestamp
#
# Associations:
#   - belongs_to :entry
#
# Usage:
#   # Create approval review
#   EntryReview.create!(entry: entry, status: :approved)
#
#   # Create rejection review with comment
#   EntryReview.create!(
#     entry: entry,
#     status: :rejected,
#     comment: "Missing required documentation"
#   )
#
#   # Query review history
#   entry.entry_reviews.where(status: :approved)
#   entry.entry_reviews.where(status: :rejected)
#
# == Schema Information
#
# Table name: entry_reviews
#
#  id          :integer          not null, primary key
#  comment     :text
#  reviewer_id :integer
#  status      :integer          default("approved"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  entry_id    :integer          not null
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
class EntryReview < ApplicationRecord
  # Associations
  belongs_to :entry

  # Enums
  enum :status, { approved: 0, rejected: 1 }

  # Validations
  validates :entry_id, presence: true
  validates :status, presence: true
end
