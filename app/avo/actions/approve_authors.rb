# frozen_string_literal: true

class Avo::Actions::ApproveAuthors < Avo::BaseAction
  self.name = "Approve Authors"
  self.message = "Are you sure you want to approve the selected authors?"
  self.confirm_button_label = "Approve"
  self.cancel_button_label = "Cancel"
  self.no_confirmation = false

  def handle(records:, **)
    # Counted up front: `records` may be a relation whose scope no longer
    # matches the authors once their status has changed.
    approved_count = records.count

    records.each do |author|
      author.update(status: :approved)
    end

    succeed "#{approved_count} #{'author'.pluralize(approved_count)} approved successfully!"
  end
end
