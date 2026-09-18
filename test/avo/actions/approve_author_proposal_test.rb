# frozen_string_literal: true

require "test_helper"

class Avo::Actions::ApproveAuthorProposalTest < ActiveSupport::TestCase
  test "approve action calls approve! method on proposal" do
    author = Author.create!(name: "Yukihiro Matsumoto", status: :approved)
    proposal = AuthorProposal.create!(
      author: author,
      link_updates: { "github_url" => "https://github.com/matz" },
      submitter_email: "user@example.com",
      status: :pending
    )

    action = Avo::Actions::ApproveAuthorProposal.new(record: proposal, resource: nil, user: nil, view: :index)
    action.handle(records: [ proposal ], fields: {}, current_user: nil, resource: nil)

    proposal.reload
    assert_equal "approved", proposal.status
    assert_not_nil proposal.reviewed_at
  end

  test "approve action updates proposal status correctly" do
    author = Author.create!(name: "Yukihiro Matsumoto", status: :approved)
    proposal = AuthorProposal.create!(
      author: author,
      bio_text: "Updated bio",
      submitter_email: "user@example.com",
      status: :pending
    )

    assert_equal "pending", proposal.status

    action = Avo::Actions::ApproveAuthorProposal.new(record: proposal, resource: nil, user: nil, view: :index)
    action.handle(records: [ proposal ], fields: {}, current_user: nil, resource: nil)

    proposal.reload
    assert_equal "approved", proposal.status
    author.reload
    assert_equal "Updated bio", author.bio
  end

  test "approve action is only available for pending proposals" do
    author = Author.create!(name: "Yukihiro Matsumoto", status: :approved)
    approved_proposal = AuthorProposal.create!(
      author: author,
      link_updates: { "website_url" => "https://example.com" },
      submitter_email: "user@example.com",
      status: :approved
    )

    action = Avo::Actions::ApproveAuthorProposal.new(record: approved_proposal, resource: nil, user: nil, view: :show)

    # The action should not be visible for non-pending proposals
    # This is handled by the visible? method in the action
    assert_not action.visible?
  end

  test "approve action handles multiple proposals correctly" do
    author1 = Author.create!(name: "Yukihiro Matsumoto", status: :approved)
    proposal1 = AuthorProposal.create!(
      author: author1,
      bio_text: "Updated bio 1",
      submitter_email: "user1@example.com",
      status: :pending
    )

    author2 = Author.create!(name: "David Heinemeier Hansson", status: :approved)
    proposal2 = AuthorProposal.create!(
      author: author2,
      bio_text: "Updated bio 2",
      submitter_email: "user2@example.com",
      status: :pending
    )

    action = Avo::Actions::ApproveAuthorProposal.new(record: proposal1, resource: nil, user: nil, view: :index)
    action.handle(records: [ proposal1, proposal2 ], fields: {}, current_user: nil, resource: nil)

    proposal1.reload
    proposal2.reload
    assert_equal "approved", proposal1.status
    assert_equal "approved", proposal2.status

    author1.reload
    author2.reload
    assert_equal "Updated bio 1", author1.bio
    assert_equal "Updated bio 2", author2.bio
  end

  test "approve action reports proposals that fail to approve" do
    proposal = AuthorProposal.create!(author_name: "X", submitter_email: "user@example.com")

    action = Avo::Actions::ApproveAuthorProposal.new(record: proposal, resource: nil, user: nil, view: :index)
    action.handle(records: [ proposal ], fields: {}, current_user: nil, resource: nil)

    assert proposal.reload.pending?
    message = action.response[:messages].sole
    assert_equal :error, message[:type]
    assert_match "0 approved, 1 failed: Proposal ##{proposal.id}: Validation failed: Name is too short", message[:body]
  end

  test "approve action is visible on the index and only for pending records" do
    author = Author.create!(name: "Visible Author", status: :approved)
    pending = AuthorProposal.create!(author: author, bio_text: "Bio", submitter_email: "p@example.com")
    approved = AuthorProposal.create!(author: author, bio_text: "Bio", submitter_email: "a@example.com", status: :approved)

    assert Avo::Actions::ApproveAuthorProposal.new(record: nil, resource: nil, user: nil, view: :index).visible?
    assert Avo::Actions::ApproveAuthorProposal.new(record: pending, resource: nil, user: nil, view: :show).visible?
    assert_not Avo::Actions::ApproveAuthorProposal.new(record: approved, resource: nil, user: nil, view: :show).visible?
    assert_not Avo::Actions::ApproveAuthorProposal.new(record: nil, resource: nil, user: nil, view: :show).visible?
  end
end
