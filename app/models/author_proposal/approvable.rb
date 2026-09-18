# frozen_string_literal: true

# Approval/rejection workflow for AuthorProposal: creating or updating the
# Author, applying link updates, linking the matched entry, and notifying the
# submitter by email. The entire approval is one transaction so a failed step
# leaves the proposal untouched and pending.
module AuthorProposal::Approvable
  extend ActiveSupport::Concern

  included do
    after_create :send_submission_confirmation_email
  end

  # Approves the proposal and applies all changes to the Author model.
  #
  # Leverages Author model callbacks: GithubAvatarService for github_url
  # changes, FTS sync for name changes.
  #
  # @raise [ActiveRecord::RecordInvalid] if author validation fails
  # @return [Boolean] true if approval succeeded
  def approve!
    ActiveRecord::Base.transaction { perform_approval! }
    true
  end

  # Rejects the proposal without applying any changes.
  #
  # @param admin_comment [String] required feedback explaining rejection
  # @raise [ArgumentError] if admin_comment is not provided
  # @return [Boolean] true if rejection succeeded
  def reject!(admin_comment:)
    raise ArgumentError, "admin_comment is required for rejection" if admin_comment.blank?

    update!(status: :rejected, admin_comment: admin_comment, reviewed_at: Time.current, reviewer_id: nil)
    send_rejection_email

    true
  end

  private

  def perform_approval!
    target_author = prepare_author!
    link_proposal_to_author!(target_author)
    mark_approved!
    send_approval_email
  end

  # Finds or creates the target Author, and applies bio/link changes to it.
  def prepare_author!
    target_author = author_id.present? ? Author.find(author_id) : create_new_author!
    apply_proposed_changes(target_author)
    target_author
  end

  def apply_proposed_changes(target_author)
    target_author.bio = bio_text if bio_text.present?
    apply_link_updates_to_author(target_author) if link_updates.present?
    target_author.save!
  end

  # Points this proposal at the author and links the matched entry, if any.
  def link_proposal_to_author!(target_author)
    self.author_id = target_author.id if author_id.blank?
    create_entries_author_association(target_author) if matched_entry_id.present?
  end

  def mark_approved!
    update!(status: :approved, reviewed_at: Time.current, reviewer_id: nil) # reviewer_id: populated when admin system exists
  end

  def create_new_author!
    Author.new(name: author_name)
  end

  # Applies link_updates to the author's link fields. link_updates has
  # already been validated (see AuthorProposal::VALID_LINK_FIELDS) by the
  # time a proposal can be approved, so this trusts the whitelist.
  def apply_link_updates_to_author(target_author)
    link_updates.each do |field_name, url_value|
      target_author.public_send(:"#{field_name}=", url_value) if url_value.present?
    end
  end

  # Creates EntriesAuthor association between author and matched entry.
  # Only creates association if it doesn't already exist, to stay idempotent.
  def create_entries_author_association(target_author)
    return if EntriesAuthor.exists?(author: target_author, entry_id: matched_entry_id)

    EntriesAuthor.create!(author: target_author, entry_id: matched_entry_id)
  end

  def send_submission_confirmation_email
    AuthorProposalMailer.submission_confirmation(self).deliver_later
  end

  def send_approval_email
    AuthorProposalMailer.approval_notification(self).deliver_later
  end

  def send_rejection_email
    AuthorProposalMailer.rejection_notification(self).deliver_later
  end
end
