# frozen_string_literal: true

# Approves the author profiles selected by an administrator.
class Avo::Actions::ApproveAuthors < Avo::BaseAction
  self.name = "Approve Authors"
  self.message = "Are you sure you want to approve the selected authors?"
  self.confirm_button_label = "Approve"
  self.cancel_button_label = "Cancel"
  self.no_confirmation = false

  def handle(records:, **)
    @authors = records
    approve_authors
    report_count
  end

  private

  attr_reader :authors

  def approve_authors
    authors.each { |author| author.update(status: :approved) }
  end

  def report_count
    count = authors.count
    succeed "#{count} #{'author'.pluralize(count)} approved successfully!"
  end
end
