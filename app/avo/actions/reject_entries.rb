# frozen_string_literal: true

# Rejects entries while recording review feedback and notifying submitters.
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
    @entries = records
    reject_entries(fields[:comment])
    report_count
  end

  private

  attr_reader :entries

  def reject_entries(comment)
    entries.each { |entry| entry.reject_with_review(comment: comment) }
  end

  def report_count
    count = entries.count
    succeed "#{count} #{'resource'.pluralize(count)} rejected successfully!"
  end
end
