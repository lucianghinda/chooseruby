# frozen_string_literal: true

class Avo::Actions::RejectEntries < Avo::BaseAction
  self.name = "Reject Resources"
  self.message = "Are you sure you want to reject the selected resources?"
  self.confirm_button_label = "Reject"
  self.cancel_button_label = "Cancel"
  self.no_confirmation = false

  def fields
    field :comment, as: :textarea,
          help: "Optional feedback for the submitter",
          placeholder: "Explain why this submission was rejected..."
  end

  def handle(records:, fields:, current_user:, resource:, **args)
    records.each do |resource|
      ActiveRecord::Base.transaction do
        # Update entry: status to rejected
        resource.update!(status: :rejected)

        # Create EntryReview record with status: :rejected and comment
        EntryReview.create!(
          entry: resource,
          status: :rejected,
          comment: fields[:comment]
        )

        # Queue rejection notification email
        ResourceSubmissionMailer.rejection_notification(resource).deliver_later
      end
    end

    succeed "#{records.count} #{'resource'.pluralize(records.count)} rejected successfully!"
  end
end
