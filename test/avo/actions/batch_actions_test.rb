# frozen_string_literal: true

require "test_helper"

class AvoBatchActionsTest < ActiveSupport::TestCase
  ProposalReviewDouble = Struct.new(:id, :failure) do
    def approve!
      raise failure if failure

      true
    end

    def reject!(admin_comment:)
      approve!
    end
  end
  test "author approval reports the selected count and changes status" do
    author = Author.create!(name: "Awaiting Review")
    action = Avo::Actions::ApproveAuthors.new(view: :index)

    action.handle(records: [ author ], fields: {}, resource: nil, current_user: nil, query: Author.all)

    assert_equal "approved", author.reload.status
    assert_equal "1 author approved successfully!", action.response[:messages].last[:body]
  end

  test "publish and unpublish actions toggle only public visibility" do
    entry = Entry.create!(title: "Visibility", url: "https://example.com/visibility", description: "A resource", entryable: Book.new, status: :approved)

    [ [ Avo::Actions::PublishEntries, true, "published" ], [ Avo::Actions::UnpublishEntries, false, "unpublished" ] ].each do |action_class, published, verb|
      action = action_class.new(view: :index)
      action.handle(records: [ entry ], fields: {}, resource: nil, current_user: nil)

      assert_equal published, entry.reload.published
      assert_equal "approved", entry.status
      assert_equal "1 resource #{verb} successfully!", action.response[:messages].last[:body]
    end
  end

  [ [ Avo::Actions::ApproveAuthorProposal, :approve!, "approved" ], [ Avo::Actions::RejectAuthorProposal, :reject!, "rejected" ] ].each do |action_class, operation, verb|
    test "#{verb} action continues after a failed proposal and reports its error" do
      failed_proposal = ProposalReviewDouble.new(73, StandardError.new("Cannot review"))
      successful_proposal = ProposalReviewDouble.new(74)
      action = action_class.new(view: :index)

      action.handle(records: [ failed_proposal, successful_proposal ], fields: { admin_comment: "Needs detail" }, resource: nil, current_user: nil)

      assert_equal :error, action.response[:messages].last[:type]
      assert_equal "1 #{verb}, 1 failed: Proposal #73: Cannot review", action.response[:messages].last[:body]
    end

    test "#{verb} action is visible for pending records and an empty index only" do
      assert action_class.new(view: :index).visible?
      assert action_class.new(view: :show, record: AuthorProposal.new(status: :pending)).visible?
      assert_not action_class.new(view: :show, record: AuthorProposal.new(status: :approved)).visible?
      assert_not action_class.new(view: :show).visible?
    end
  end
end
