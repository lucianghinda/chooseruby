# frozen_string_literal: true

class Avo::Actions::UnpublishEntries < Avo::BaseAction
  self.name = "Unpublish Resources"
  self.message = "Are you sure you want to unpublish the selected resources?"
  self.confirm_button_label = "Unpublish"
  self.cancel_button_label = "Cancel"
  self.no_confirmation = false

  def handle(records:, **)
    # Counted up front: `records` may be a relation whose scope no longer
    # matches the entries once they have been unpublished.
    unpublished_count = records.count

    records.each do |entry|
      entry.update(published: false)
    end

    succeed "#{unpublished_count} #{'resource'.pluralize(unpublished_count)} unpublished successfully!"
  end
end
