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

  def handle(records:, fields:, **)
    admin_comment = fields[:admin_comment]

    if admin_comment.blank?
      error "Admin comment is required when rejecting proposals"
      return
    end

    success_count = 0
    error_messages = []

    records.each do |proposal|
      # AuthorProposal#reject! owns the whole rejection workflow.
      proposal.reject!(admin_comment: admin_comment)
      success_count += 1
    rescue StandardError => exception
      error_messages << "Proposal ##{proposal.id}: #{exception.message}"
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
