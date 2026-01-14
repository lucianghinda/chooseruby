# frozen_string_literal: true

class Avo::Actions::UnpublishEntries < Avo::BaseAction
  self.name = "Unpublish Resources"
  self.message = "Are you sure you want to unpublish the selected resources?"
  self.confirm_button_label = "Unpublish"
  self.cancel_button_label = "Cancel"
  self.no_confirmation = false

  def handle(records:, fields:, current_user:, resource:, **args)
    records.each do |resource|
      resource.update(published: false)
    end

    succeed "#{records.count} #{'resource'.pluralize(records.count)} unpublished successfully!"
  end
end
