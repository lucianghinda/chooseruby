# frozen_string_literal: true

# Makes the selected entries publicly visible.
class Avo::Actions::PublishEntries < Avo::BaseAction
  self.name = "Publish Resources"
  self.message = "Are you sure you want to publish the selected resources?"
  self.confirm_button_label = "Publish"
  self.cancel_button_label = "Cancel"
  self.no_confirmation = false

  def handle(records:, **)
    @entries = records
    publish_entries
    report_count
  end

  private

  attr_reader :entries

  def publish_entries
    entries.each { |entry| entry.update(published: true) }
  end

  def report_count
    count = entries.count
    succeed "#{count} #{'resource'.pluralize(count)} published successfully!"
  end
end
