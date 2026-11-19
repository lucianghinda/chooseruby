# frozen_string_literal: true

class Avo::Actions::PublishEntries < Avo::BaseAction
  self.name = "Publish Resources"
  self.message = "Are you sure you want to publish the selected resources?"
  self.confirm_button_label = "Publish"
  self.cancel_button_label = "Cancel"
  self.no_confirmation = false

  def handle(records:, **)
    # Counted up front: `records` may be a relation whose scope no longer
    # matches the entries once they have been published.
    published_count = records.count

    records.each do |entry|
      entry.update(published: true)
    end

    succeed "#{published_count} #{'resource'.pluralize(published_count)} published successfully!"
  end
end
