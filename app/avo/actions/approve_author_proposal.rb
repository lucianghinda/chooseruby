# frozen_string_literal: true

class Avo::Actions::ApproveAuthorProposal < Avo::BaseAction
  self.name = "Approve Proposal"
  self.message = "Are you sure you want to approve the selected proposal(s)?"
  self.confirm_button_label = "Approve"
  self.cancel_button_label = "Cancel"
  self.no_confirmation = false

  def handle(records:, fields:, current_user:, resource:, **args)
    success_count = 0
    error_messages = []

    records.each do |proposal|
      begin
        # Call the approve! method which handles all the logic
        proposal.approve!
        success_count += 1
      rescue ActiveRecord::RecordInvalid => e
        error_messages << "Proposal ##{proposal.id}: #{e.message}"
      rescue StandardError => e
        error_messages << "Proposal ##{proposal.id}: #{e.message}"
      end
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
