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

  def handle(records:, fields:, **)
    comment = fields[:comment]
    # Counted up front: `records` may be a relation whose scope no longer
    # matches the entries once their status has changed.
    rejected_count = records.count

    records.each do |entry|
      ActiveRecord::Base.transaction do
        entry.update!(status: :rejected)
        EntryReview.create!(entry: entry, status: :rejected, comment: comment)
        ResourceSubmissionMailer.rejection_notification(entry).deliver_later
      end
    end

    succeed "#{rejected_count} #{'resource'.pluralize(rejected_count)} rejected successfully!"
  end
end
