# frozen_string_literal: true

require "test_helper"

class Avo::Actions::ActionConfirmationTest < ActiveSupport::TestCase
  test "custom actions require confirmation before execution" do
    actions = [
      Avo::Actions::ApproveAuthorProposal,
      Avo::Actions::ApproveAuthors,
      Avo::Actions::ApproveEntries,
      Avo::Actions::PublishEntries,
      Avo::Actions::RejectAuthorProposal,
      Avo::Actions::RejectEntries,
      Avo::Actions::UnpublishEntries
    ]

    actions.each do |action|
      assert action.confirmation, "#{action.name} should require confirmation"
    end
  end
end
