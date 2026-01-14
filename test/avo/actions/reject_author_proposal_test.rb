# frozen_string_literal: true

require "test_helper"

class Avo::Actions::RejectAuthorProposalTest < ActiveSupport::TestCase
  test "reject action requires admin_comment field" do
    author = Author.create!(name: "Yukihiro Matsumoto", status: :approved)
    proposal = AuthorProposal.create!(
      author: author,
      link_updates: { "github_url" => "https://github.com/matz" },
      submitter_email: "user@example.com",
      status: :pending
    )

    comment_text = "Needs more details about the contribution"

    action = Avo::Actions::RejectAuthorProposal.new(record: proposal, resource: nil, user: nil, view: :index)
    action.handle(records: [ proposal ], fields: { admin_comment: comment_text }, current_user: nil, resource: nil)

    proposal.reload
    assert_equal "rejected", proposal.status
    assert_equal comment_text, proposal.admin_comment
    assert_not_nil proposal.reviewed_at
  end

  test "reject action updates proposal status correctly" do
    author = Author.create!(name: "Yukihiro Matsumoto", status: :approved)
    proposal = AuthorProposal.create!(
      author: author,
      bio_text: "Updated bio",
      submitter_email: "user@example.com",
      status: :pending
    )

    assert_equal "pending", proposal.status

    action = Avo::Actions::RejectAuthorProposal.new(record: proposal, resource: nil, user: nil, view: :index)
    action.handle(records: [ proposal ], fields: { admin_comment: "Bio too short" }, current_user: nil, resource: nil)

    proposal.reload
    assert_equal "rejected", proposal.status
    assert_equal "Bio too short", proposal.admin_comment

    # Author should not be updated
    author.reload
    assert_not_equal "Updated bio", author.bio
  end

  test "reject action is only available for pending proposals" do
    author = Author.create!(name: "Yukihiro Matsumoto", status: :approved)
    rejected_proposal = AuthorProposal.create!(
      author: author,
      link_updates: { "website_url" => "https://example.com" },
      submitter_email: "user@example.com",
      status: :rejected,
      admin_comment: "Already rejected"
    )

    action = Avo::Actions::RejectAuthorProposal.new(record: rejected_proposal, resource: nil, user: nil, view: :show)

    # The action should not be visible for non-pending proposals
    assert_not action.visible?
  end
end
