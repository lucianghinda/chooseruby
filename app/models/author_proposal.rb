# frozen_string_literal: true

# AuthorProposal model representing community-submitted proposals to edit author profiles
#
# This model handles proposals for:
# - Adding resources to existing authors
# - Updating author link fields (github_url, website_url, etc.)
# - Editing author bio and description
# - Creating entirely new author profiles
#
# All proposals require admin approval before being applied.
#
# Attributes:
#   - author_id: Foreign key to authors table (nullable for new author proposals)
#   - matched_entry_id: Foreign key to entries table (nullable, auto-matched from resource_url)
#   - resource_url: Normalized URL for resource to associate with author
#   - original_resource_url: User's raw input URL before normalization
#   - link_updates: JSON hash of proposed link changes (github_url, website_url, etc.)
#   - bio_text: Proposed bio text (max 500 characters)
#   - description_text: Proposed description text
#   - author_name: Name for new author proposals (required when author_id is nil)
#   - submitter_name: Name of person submitting proposal (optional)
#   - submitter_email: Email of submitter (required)
#   - submission_notes: Additional context from submitter (optional)
#   - status: Workflow state (pending, approved, rejected)
#   - reviewer_id: Admin who reviewed the proposal (nullable)
#   - admin_comment: Feedback from admin on rejection
#   - reviewed_at: Timestamp of review
#
# Associations:
#   - belongs_to :author (optional: true for new author proposals)
#   - belongs_to :matched_entry (optional: true, auto-populated via URL matching)
#
# Validations:
#   - submitter_email required and valid format
#   - At least one proposed change (resource_url OR link_updates OR bio/description OR author_name)
#   - Link URLs in link_updates must be valid http/https format
#   - author_name required when author_id is nil
#   - bio_text maximum 500 characters
#   - No duplicate pending proposals for same author + email within 24 hours
#
# Usage:
#   # Edit existing author
#   proposal = AuthorProposal.create(
#     author: author,
#     link_updates: { "github_url" => "https://github.com/newuser" },
#     submitter_email: "user@example.com"
#   )
#
#   # Propose new author
#   proposal = AuthorProposal.create(
#     author_name: "Jane Doe",
#     bio_text: "Ruby developer",
#     submitter_email: "user@example.com"
#   )
#
# == Schema Information
#
# Table name: author_proposals
# Database name: primary
#
#  id                    :integer          not null, primary key
#  admin_comment         :text
#  author_name           :string
#  bio_text              :text
#  description_text      :text
#  link_updates          :text
#  original_resource_url :text
#  resource_url          :text
#  reviewed_at           :datetime
#  status                :integer          default("pending"), not null
#  submission_notes      :text
#  submitter_email       :string           not null
#  submitter_name        :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  author_id             :integer
#  matched_entry_id      :integer
#  reviewer_id           :integer
#
# Indexes
#
#  index_author_proposals_on_author_id         (author_id)
#  index_author_proposals_on_created_at        (created_at)
#  index_author_proposals_on_matched_entry_id  (matched_entry_id)
#  index_author_proposals_on_status            (status)
#  index_author_proposals_on_submitter_email   (submitter_email)
#
# Foreign Keys
#
#  author_id         (author_id => authors.id) ON DELETE => cascade
#  matched_entry_id  (matched_entry_id => entries.id) ON DELETE => nullify
#
class AuthorProposal < ApplicationRecord
  include AuthorProposal::Approvable
  include AuthorProposal::UrlMatching

  # Enable strict loading to prevent N+1 queries
  self.strict_loading_by_default = true
  # Always preload associations we render to avoid strict loading violations in admin views
  default_scope { includes(:author, :matched_entry) }

  # Associations
  belongs_to :author, optional: true  # Nil for new author proposals
  belongs_to :matched_entry, class_name: "Entry", optional: true

  # JSON serialization for link_updates hash
  serialize :link_updates, coder: JSON

  # Status enum
  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  VALID_LINK_FIELDS = %w[
    github_url gitlab_url website_url bluesky_url ruby_social_url
    twitter_url linkedin_url youtube_url twitch_url blog_url
  ].freeze

  # Validations
  validates :submitter_email, presence: true
  validates :submitter_email, format: {
    with: URI::MailTo::EMAIL_REGEXP,
    message: "must be a valid email address"
  }, allow_blank: true

  validates :bio_text, length: { maximum: 500 }, allow_blank: true

  # Author name required for new author proposals
  validates :author_name, presence: true, if: -> { author_id.blank? }

  # Custom validations
  validate :has_proposed_changes?
  validate :validate_link_urls
  validate :prevent_duplicate_pending_proposals

  # ========================================
  # Domain Query Methods
  # ========================================

  # Returns true if this is a proposal to create a new author
  #
  # @return [Boolean] true when author_id is nil
  def new_author_proposal?
    author_id.blank?
  end

  # Returns true if this is a proposal to edit an existing author
  #
  # @return [Boolean] true when author_id is present
  def existing_author_proposal?
    author_id.present?
  end

  # Returns true if this proposal includes a resource URL suggestion
  #
  # @return [Boolean] true when resource_url is present
  def has_resource_proposal?
    resource_url.present?
  end

  # Returns true if this proposal includes link updates
  #
  # @return [Boolean] true when link_updates hash is present
  def has_link_updates?
    link_updates.present?
  end

  # Returns true if this proposal includes bio or description changes
  #
  # @return [Boolean] true when bio_text or description_text is present
  def has_bio_changes?
    bio_text.present? || description_text.present?
  end

  # Returns true if the resource URL was matched to an existing entry
  #
  # @return [Boolean] true when matched_entry_id is present
  def matched_entry?
    matched_entry_id.present?
  end

  private

  # Validates that at least one change is proposed
  def has_proposed_changes?
    has_changes = resource_url.present? ||
                  link_updates.present? ||
                  bio_text.present? ||
                  description_text.present? ||
                  author_name.present?

    unless has_changes
      errors.add(:base, "At least one change must be proposed")
    end
  end

  # Validates URL format for each link in link_updates hash
  def validate_link_urls
    return if link_updates.blank?

    link_updates.each { |field_name, url| validate_link_field(field_name, url) }
  end

  def validate_link_field(field_name, url)
    return if url.blank?
    return errors.add(:link_updates, "#{field_name} is not a valid link field") unless VALID_LINK_FIELDS.include?(field_name)

    unless url.match?(URI::DEFAULT_PARSER.make_regexp(%w[http https]))
      errors.add(:link_updates, "#{field_name} must be a valid URL starting with http:// or https://")
    end
  end

  # Prevents duplicate pending proposals for same author by same email within 24 hours
  def prevent_duplicate_pending_proposals
    return if author_id.blank?  # Skip for new author proposals
    return unless status == "pending"

    duplicate = AuthorProposal
      .where(author_id: author_id, submitter_email: submitter_email, status: :pending)
      .where("created_at > ?", 24.hours.ago)
      .where.not(id: id)
      .exists?

    if duplicate
      errors.add(:base, "You already have a pending proposal for this author submitted within the last 24 hours")
    end
  end
end
