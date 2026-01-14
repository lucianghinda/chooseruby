# frozen_string_literal: true

class Avo::Actions::PublishEntries < Avo::BaseAction
  self.name = "Publish Resources"
  self.message = "Are you sure you want to publish the selected resources?"
  self.confirm_button_label = "Publish"
  self.cancel_button_label = "Cancel"
  self.no_confirmation = false

  def handle(records:, fields:, current_user:, resource:, **args)
    records.each do |resource|
      resource.update(published: true)
    end

    succeed "#{records.count} #{'resource'.pluralize(records.count)} published successfully!"
  end
end
