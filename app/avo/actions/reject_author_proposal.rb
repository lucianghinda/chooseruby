# frozen_string_literal: true

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

  def handle(records:, fields:, current_user:, resource:, **args)
    admin_comment = fields[:admin_comment]

    # Validate that admin_comment is provided
    if admin_comment.blank?
      error "Admin comment is required when rejecting proposals"
      return
    end

    success_count = 0
    error_messages = []

    records.each do |proposal|
      begin
        # Call the reject! method with admin_comment
        proposal.reject!(admin_comment: admin_comment)
        success_count += 1
      rescue ArgumentError => e
        error_messages << "Proposal ##{proposal.id}: #{e.message}"
      rescue StandardError => e
        error_messages << "Proposal ##{proposal.id}: #{e.message}"
      end
    end

    if error_messages.any?
      error "#{success_count} rejected, #{error_messages.count} failed: #{error_messages.join('; ')}"
    else
      succeed "#{success_count} #{'proposal'.pluralize(success_count)} rejected successfully!"
    end
  end

  # Only show this action for pending proposals
  def visible?
    return true if view == :index && !record

    record&.pending?
  end
end
