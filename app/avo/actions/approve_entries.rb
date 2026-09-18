# frozen_string_literal: true

# Approves and publishes entries while recording reviews and notifying submitters.
class Avo::Actions::ApproveEntries < Avo::BaseAction
  self.name = "Approve Resources"
  self.message = "Are you sure you want to approve the selected resources?"
  self.confirm_button_label = "Approve"
  self.cancel_button_label = "Cancel"
  self.no_confirmation = false

  def handle(records:, **)
    @entries = records
    approve_entries
    report_count
  end

  private

  attr_reader :entries

  def approve_entries
    entries.each(&:approve_with_review)
  end

  def report_count
    count = entries.count
    succeed "#{count} #{'resource'.pluralize(count)} approved successfully!"
  end
end
