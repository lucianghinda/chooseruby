# frozen_string_literal: true

class Avo::Actions::ApproveEntries < Avo::BaseAction
  self.name = "Approve Resources"
  self.message = "Are you sure you want to approve the selected resources?"
  self.confirm_button_label = "Approve"
  self.cancel_button_label = "Cancel"
  self.no_confirmation = false

  def handle(records:, fields:, current_user:, resource:, **args)
    records.each do |resource|
      ActiveRecord::Base.transaction do
        # Update entry: status to approved AND published to true
        resource.update!(status: :approved, published: true)

        # Create EntryReview record with status: :approved
        EntryReview.create!(entry: resource, status: :approved)

        # Queue approval notification email
        ResourceSubmissionMailer.approval_notification(resource).deliver_later
      end
    end

    succeed "#{records.count} #{'resource'.pluralize(records.count)} approved successfully!"
  end
end
