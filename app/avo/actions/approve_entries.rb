# frozen_string_literal: true

class Avo::Actions::ApproveEntries < Avo::BaseAction
  self.name = "Approve Resources"
  self.message = "Are you sure you want to approve the selected resources?"
  self.confirm_button_label = "Approve"
  self.cancel_button_label = "Cancel"
  self.no_confirmation = false

  def handle(records:, **)
    # Counted up front: `records` may be a relation whose scope no longer
    # matches the entries once their status has changed.
    approved_count = records.count

    records.each do |entry|
      ActiveRecord::Base.transaction do
        entry.update!(status: :approved, published: true)
        EntryReview.create!(entry: entry, status: :approved)
        ResourceSubmissionMailer.approval_notification(entry).deliver_later
      end
    end

    succeed "#{approved_count} #{'resource'.pluralize(approved_count)} approved successfully!"
  end
end
