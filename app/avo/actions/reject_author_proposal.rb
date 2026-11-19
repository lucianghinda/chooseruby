# frozen_string_literal: true

# Rejects pending author proposals with feedback for their submitters.
class Avo::Actions::RejectAuthorProposal < Avo::BaseAction
  self.name = "Reject Proposal"
  self.message = "Are you sure you want to reject the selected proposal(s)?"
  self.confirm_button_label = "Reject"
  self.cancel_button_label = "Cancel"
  self.no_confirmation = false

  def fields
    field :admin_comment, as: :textarea,
          help: "Required: Explain why this proposal is being rejected",
          placeholder: "Provide feedback for the submitter...",
          required: true
  end

  def handle(records:, fields:, **)
    admin_comment = fields[:admin_comment]

    # Validate that admin_comment is provided
    if admin_comment.blank?
      error "Admin comment is required when rejecting proposals"
      return
    end

    reject_proposals(records, admin_comment)
  end

  # Only show this action for pending proposals
  def visible?
    return true if view == :index && !record

    record&.pending?
  end

  private

  def reject_proposals(records, admin_comment)
    result = Avo::ProposalReviewResult.new
    records.each { |proposal| result.reject(proposal, admin_comment) }
    report_result(result)
  end

  def report_result(result)
    message = result.message("rejected")
    result.success? ? succeed(message) : error(message)
  end
end
