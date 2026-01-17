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

  # Validations
  validates :submitter_email, presence: true
  validates :submitter_email, format: {
    with: URI::MailTo::EMAIL_REGEXP,
    message: "must be a valid email address"
  }, allow_blank: true

  validates :bio_text, length: { maximum: 500 }, allow_blank: true

  # Author name required for new author proposals
  validates :author_name, presence: true, if: -> { author_id.nil? }

  # Custom validations
  validate :has_proposed_changes?
  validate :validate_link_urls
  validate :prevent_duplicate_pending_proposals

  # Callbacks
  before_validation :normalize_and_match_resource_url, if: -> { resource_url.present? }
  after_create :send_submission_confirmation_email

  # ========================================
  # Public API - Approval Workflow Methods
  # ========================================

  # Approves the proposal and applies all changes to the Author model
  #
  # This method handles:
  # - Creating new authors from proposals (when author_id is nil)
  # - Updating existing authors with proposed changes
  # - Applying link_updates to author's link fields
  # - Creating EntriesAuthor associations when matched_entry_id exists
  # - Setting proposal status to approved with reviewed_at timestamp
  # - Sending approval notification email to submitter
  #
  # The entire operation is wrapped in a transaction for atomicity.
  # If any step fails, all changes are rolled back and the proposal
  # remains in pending status.
  #
  # Leverages Author model callbacks:
  # - GithubAvatarService for github_url changes
  # - FTS sync for name changes
  #
  # @raise [ActiveRecord::RecordInvalid] if author validation fails
  # @return [Boolean] true if approval succeeded
  #
  # Example:
  #   proposal.approve!
  #   proposal.approved? # => true
  #   proposal.author.reload.bio # => "Updated bio text"
  def approve!
    ActiveRecord::Base.transaction do
      # Eager load author to avoid strict loading violations
      existing_author = author_id.present? ? Author.find(author_id) : nil
      target_author = existing_author || create_new_author!

      # Apply bio changes if present (note: Author does not have description field)
      target_author.bio = bio_text if bio_text.present?

      # Apply link_updates to author
      apply_link_updates_to_author(target_author) if link_updates.present?

      # Save author with validations
      target_author.save!

      # Update proposal's author_id if this was a new author
      self.author_id = target_author.id if author_id.nil?

      # Create EntriesAuthor association if matched entry exists
      create_entries_author_association(target_author) if matched_entry_id.present?

      # Mark proposal as approved
      update!(
        status: :approved,
        reviewed_at: Time.current,
        reviewer_id: nil  # Will be populated when admin system exists
      )

      # Send approval email - reload with author association to avoid strict loading violation
      send_approval_email
    end

    true
  end

  # Rejects the proposal without applying any changes
  #
  # Sets the proposal status to rejected and records the admin's
  # feedback comment and review timestamp. Does not modify the
  # Author model or create any associations.
  #
  # Sends rejection notification email to submitter with feedback.
  #
  # @param admin_comment [String] required feedback explaining rejection
  # @raise [ArgumentError] if admin_comment is not provided
  # @return [Boolean] true if rejection succeeded
  #
  # Example:
  #   proposal.reject!(admin_comment: "Bio needs more detail")
  #   proposal.rejected? # => true
  #   proposal.admin_comment # => "Bio needs more detail"
  def reject!(admin_comment:)
    raise ArgumentError, "admin_comment is required for rejection" if admin_comment.blank?

    update!(
      status: :rejected,
      admin_comment: admin_comment,
      reviewed_at: Time.current,
      reviewer_id: nil  # Will be populated when admin system exists
    )

    # Send rejection email
    send_rejection_email

    true
  end

  # ========================================
  # Domain Query Methods
  # ========================================

  # Returns true if this is a proposal to create a new author
  #
  # @return [Boolean] true when author_id is nil
  def new_author_proposal?
    author_id.nil?
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

  # ========================================
  # Private Helper Methods - Email Notifications
  # ========================================

  # Sends submission confirmation email after proposal is created
  # Delivers email asynchronously using deliver_later
  # Creates a plain hash with proposal data to avoid strict loading issues
  def send_submission_confirmation_email
    # Pass self directly - mailer will handle accessing the association
    AuthorProposalMailer.submission_confirmation(self).deliver_later
  end

  # Sends approval notification email after proposal is approved
  # Delivers email asynchronously using deliver_later
  # Creates a plain hash with proposal data to avoid strict loading issues
  def send_approval_email
    # Pass self directly - mailer will handle accessing the association
    AuthorProposalMailer.approval_notification(self).deliver_later
  end

  # Sends rejection notification email after proposal is rejected
  # Delivers email asynchronously using deliver_later
  # Creates a plain hash with proposal data to avoid strict loading issues
  def send_rejection_email
    # Pass self directly - mailer will handle accessing the association
    AuthorProposalMailer.rejection_notification(self).deliver_later
  end

  # ========================================
  # Private Helper Methods - Approval Workflow
  # ========================================

  # Creates a new Author from proposal data
  #
  # @return [Author] newly created author instance (unsaved)
  # @raise [ActiveRecord::RecordInvalid] if author validation fails
  def create_new_author!
    new_author = Author.new(name: author_name)
    new_author
  end

  # Applies link_updates hash to author's link fields
  #
  # Only updates fields that are present in the link_updates hash.
  # Validates that all link fields are valid Author attributes.
  #
  # @param target_author [Author] the author to update
  # @return [void]
  def apply_link_updates_to_author(target_author)
    link_updates.each do |field_name, url_value|
      next if url_value.blank?

      # Validate field exists on Author model
      unless target_author.respond_to?("#{field_name}=")
        raise ArgumentError, "Invalid link field: #{field_name}"
      end

      target_author.send("#{field_name}=", url_value)
    end
  end

  # Creates EntriesAuthor association between author and matched entry
  #
  # Only creates association if it doesn't already exist.
  # Silently skips if association already exists to maintain idempotency.
  #
  # @param target_author [Author] the author to associate with entry
  # @return [void]
  def create_entries_author_association(target_author)
    return if EntriesAuthor.exists?(author: target_author, entry_id: matched_entry_id)

    EntriesAuthor.create!(
      author: target_author,
      entry_id: matched_entry_id
    )
  end

  # ========================================
  # Private Helper Methods - Validations
  # ========================================

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

    valid_link_fields = %w[
      github_url gitlab_url website_url bluesky_url ruby_social_url
      twitter_url linkedin_url youtube_url twitch_url blog_url
    ]

    link_updates.each do |field_name, url|
      next if url.blank?

      unless valid_link_fields.include?(field_name)
        errors.add(:link_updates, "#{field_name} is not a valid link field")
        next
      end

      unless url.match?(URI::DEFAULT_PARSER.make_regexp(%w[http https]))
        errors.add(:link_updates, "#{field_name} must be a valid URL starting with http:// or https://")
      end
    end
  end

  # Prevents duplicate pending proposals for same author by same email within 24 hours
  def prevent_duplicate_pending_proposals
    return if author_id.nil?  # Skip for new author proposals
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

  # ========================================
  # Private Helper Methods - URL Matching
  # ========================================

  # Normalizes resource_url and attempts to match with existing Entry
  # Stores original URL and sets matched_entry_id if found
  def normalize_and_match_resource_url
    return if resource_url.blank?

    # Store original URL before normalization
    self.original_resource_url = resource_url.dup

    # Normalize the URL
    self.resource_url = normalize_url(resource_url)

    # Attempt to match with existing entries
    match_entry_by_url
  end

  # Normalizes a URL for consistent matching
  # Handles: whitespace, http/https, trailing slashes, www prefix, case
  def normalize_url(url)
    return nil if url.blank?

    normalized = url.strip.downcase

    # Normalize protocol to http://
    normalized = normalized.sub(/\Ahttps:\/\//, "http://")

    # Remove www prefix
    normalized = normalized.sub(/\Ahttp:\/\/www\./, "http://")

    # Remove trailing slash
    normalized = normalized.sub(/\/\z/, "")

    normalized
  end

  # Searches for matching Entry by normalized URL
  # Sets matched_entry_id if exact match found
  def match_entry_by_url
    return if resource_url.blank?

    # Search all entries and normalize their URLs for comparison
    matched = Entry.find_by(
      "REPLACE(REPLACE(LOWER(TRIM(url)), 'https://', 'http://'), 'www.', '') = ?",
      resource_url.sub(/\/$/, "")
    )

    self.matched_entry_id = matched&.id
  end
end
