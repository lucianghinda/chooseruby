# frozen_string_literal: true

class Avo::Actions::ApproveAuthors < Avo::BaseAction
  self.name = "Approve Authors"
  self.message = "Are you sure you want to approve the selected authors?"
  self.confirm_button_label = "Approve"
  self.cancel_button_label = "Cancel"
  self.no_confirmation = false

  def handle(records:, fields:, current_user:, resource:, **args)
    records.each do |author|
      author.update(status: :approved)
    end

    succeed "#{records.count} #{'author'.pluralize(records.count)} approved successfully!"
  end
end
