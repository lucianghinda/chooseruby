# frozen_string_literal: true

# Applies pending author proposals and reports any failures to the administrator.
class Avo::Actions::ApproveAuthorProposal < Avo::BaseAction
  self.name = "Approve Proposal"
  self.message = "Are you sure you want to approve the selected proposal(s)?"
  self.confirm_button_label = "Approve"
  self.cancel_button_label = "Cancel"
  self.no_confirmation = false

  def handle(records:, **)
    result = Avo::ProposalReviewResult.new
    records.each { |proposal| result.approve(proposal) }
    report_result(result)
  end

  # Only show this action for pending proposals
  def visible?
    return true if view == :index && !record

    record&.pending?
  end

  private

  def report_result(result)
    message = result.message("approved")
    result.success? ? succeed(message) : error(message)
  end
end
