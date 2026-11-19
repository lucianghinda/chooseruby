# frozen_string_literal: true

# Removes the selected entries from public listings.
class Avo::Actions::UnpublishEntries < Avo::BaseAction
  self.name = "Unpublish Resources"
  self.message = "Are you sure you want to unpublish the selected resources?"
  self.confirm_button_label = "Unpublish"
  self.cancel_button_label = "Cancel"
  self.no_confirmation = false

  def handle(records:, **)
    @entries = records
    unpublish_entries
    report_count
  end

  private

  attr_reader :entries

  def unpublish_entries
    entries.each { |entry| entry.update(published: false) }
  end

  def report_count
    count = entries.count
    succeed "#{count} #{'resource'.pluralize(count)} unpublished successfully!"
  end
end
