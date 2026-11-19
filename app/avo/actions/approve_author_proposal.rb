# frozen_string_literal: true

class Avo::Actions::ApproveAuthorProposal < Avo::BaseAction
  self.name = "Approve Proposal"
  self.message = "Are you sure you want to approve the selected proposal(s)?"
  self.confirm_button_label = "Approve"
  self.cancel_button_label = "Cancel"
  self.no_confirmation = false

  def handle(records:, **)
    success_count = 0
    error_messages = []

    records.each do |proposal|
      # AuthorProposal#approve! owns the whole approval workflow.
      proposal.approve!
      success_count += 1
    rescue StandardError => exception
      error_messages << "Proposal ##{proposal.id}: #{exception.message}"
    end

    if error_messages.any?
      error "#{success_count} approved, #{error_messages.count} failed: #{error_messages.join('; ')}"
    else
      succeed "#{success_count} #{'proposal'.pluralize(success_count)} approved successfully!"
    end
  end

  # Only show this action for pending proposals
  def visible?
    return true if view == :index && !record

    record&.pending?
  end
end
