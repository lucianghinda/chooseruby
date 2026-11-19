# frozen_string_literal: true

require "test_helper"

# Covers the failure handling and the visibility rules of the
# "Approve Proposal" action. The happy path lives in
# test/avo/actions/approve_author_proposal_test.rb.
class Avo::Actions::ApproveAuthorProposalFailuresTest < ActiveSupport::TestCase
  test "approve action reports proposals that fail author validation" do
    proposal = AuthorProposal.create!(
      author_name: "A",
      submitter_email: "user@example.com",
      status: :pending
    )

    action = Avo::Actions::ApproveAuthorProposal.new(record: proposal, resource: nil, user: nil, view: :index)

    assert_no_difference "Author.count" do
      action.handle(records: [ proposal ], fields: {}, current_user: nil, resource: nil)
    end

    message = action.response[:messages].last
    assert_equal :error, message[:type]
    assert_match(/\A0 approved, 1 failed: Proposal ##{proposal.id}: Validation failed/, message[:body])
  end

  test "approve action leaves a failing proposal pending" do
    proposal = AuthorProposal.create!(
      author_name: "A",
      submitter_email: "user@example.com",
      status: :pending
    )

    action = Avo::Actions::ApproveAuthorProposal.new(record: proposal, resource: nil, user: nil, view: :index)
    action.handle(records: [ proposal ], fields: {}, current_user: nil, resource: nil)

    assert_predicate proposal.reload, :pending?
    assert_nil proposal.reviewed_at
  end

  test "approve action approves the healthy proposals of a failing batch" do
    author = Author.create!(name: "Yukihiro Matsumoto", status: :approved)
    good = AuthorProposal.create!(
      author: author,
      bio_text: "Creator of Ruby",
      submitter_email: "good@example.com",
      status: :pending
    )
    bad = AuthorProposal.create!(
      author_name: "A",
      submitter_email: "bad@example.com",
      status: :pending
    )

    action = Avo::Actions::ApproveAuthorProposal.new(record: good, resource: nil, user: nil, view: :index)
    action.handle(records: [ good, bad ], fields: {}, current_user: nil, resource: nil)

    assert_predicate good.reload, :approved?
    assert_predicate bad.reload, :pending?
    assert_equal "Creator of Ruby", author.reload.bio

    message = action.response[:messages].last
    assert_equal :error, message[:type]
    assert_match(/\A1 approved, 1 failed: Proposal ##{bad.id}: /, message[:body])
  end

  test "approve action reports unexpected errors raised while approving" do
    proposal = AuthorProposal.new(id: 99, author_name: "Jane Doe", submitter_email: "user@example.com")
    def proposal.approve!
      raise StandardError, "the author service is unavailable"
    end

    action = Avo::Actions::ApproveAuthorProposal.new(record: proposal, resource: nil, user: nil, view: :index)
    action.handle(records: [ proposal ], fields: {}, current_user: nil, resource: nil)

    message = action.response[:messages].last
    assert_equal :error, message[:type]
    assert_equal "0 approved, 1 failed: Proposal #99: the author service is unavailable", message[:body]
  end

  test "approve action is visible on the index view without a record" do
    action = Avo::Actions::ApproveAuthorProposal.new(record: nil, resource: nil, user: nil, view: :index)

    assert action.visible?
  end

  test "approve action is visible for a pending proposal" do
    proposal = AuthorProposal.new(status: :pending)

    action = Avo::Actions::ApproveAuthorProposal.new(record: proposal, resource: nil, user: nil, view: :show)

    assert action.visible?
  end

  test "approve action is hidden on a record-less view other than index" do
    action = Avo::Actions::ApproveAuthorProposal.new(record: nil, resource: nil, user: nil, view: :show)

    assert_not action.visible?
  end
end
