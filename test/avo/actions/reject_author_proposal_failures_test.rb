# frozen_string_literal: true

require "test_helper"

# Covers the admin comment field, the blank comment guard, the failure
# handling and the visibility rules of the "Reject Proposal" action.
# The happy path lives in test/avo/actions/reject_author_proposal_test.rb.
class Avo::Actions::RejectAuthorProposalFailuresTest < ActiveSupport::TestCase
  test "reject action exposes a required admin comment textarea" do
    action = Avo::Actions::RejectAuthorProposal.new(record: nil, resource: nil, user: nil, view: :index)
    action.fields

    field = action.get_field_definitions.sole
    assert_equal :admin_comment, field.id
    assert_equal "textarea", field.type
    assert field.required
    assert_equal "Required: Explain why this proposal is being rejected", field.help
  end

  test "reject action refuses to run without an admin comment" do
    proposal = pending_proposal

    action = Avo::Actions::RejectAuthorProposal.new(record: proposal, resource: nil, user: nil, view: :index)
    action.handle(records: [ proposal ], fields: {}, current_user: nil, resource: nil)

    assert_predicate proposal.reload, :pending?
    assert_nil proposal.admin_comment
    assert_nil proposal.reviewed_at

    message = action.response[:messages].last
    assert_equal :error, message[:type]
    assert_equal "Admin comment is required when rejecting proposals", message[:body]
  end

  test "reject action treats a whitespace only admin comment as missing" do
    proposal = pending_proposal

    action = Avo::Actions::RejectAuthorProposal.new(record: proposal, resource: nil, user: nil, view: :index)
    action.handle(records: [ proposal ], fields: { admin_comment: "   " }, current_user: nil, resource: nil)

    assert_predicate proposal.reload, :pending?

    message = action.response[:messages].last
    assert_equal :error, message[:type]
    assert_equal "Admin comment is required when rejecting proposals", message[:body]
  end

  test "reject action reports proposals that cannot be saved" do
    proposal = pending_proposal
    # Left invalid in memory, so `reject!` fails on save without the test
    # having to write an invalid row.
    proposal.submitter_email = ""

    action = Avo::Actions::RejectAuthorProposal.new(record: proposal, resource: nil, user: nil, view: :index)
    action.handle(records: [ proposal ], fields: { admin_comment: "Not enough detail" }, current_user: nil, resource: nil)

    assert_predicate proposal.reload, :pending?

    message = action.response[:messages].last
    assert_equal :error, message[:type]
    assert_match(/\A0 rejected, 1 failed: Proposal ##{proposal.id}: Validation failed/, message[:body])
  end

  test "reject action rejects the healthy proposals of a failing batch" do
    good = pending_proposal(name: "Jane Doe", email: "good@example.com")
    bad = pending_proposal(name: "John Roe", email: "bad@example.com")
    bad.submitter_email = ""

    action = Avo::Actions::RejectAuthorProposal.new(record: good, resource: nil, user: nil, view: :index)
    action.handle(records: [ good, bad ], fields: { admin_comment: "Not enough detail" }, current_user: nil, resource: nil)

    assert_predicate good.reload, :rejected?
    assert_equal "Not enough detail", good.admin_comment
    assert_predicate bad.reload, :pending?

    message = action.response[:messages].last
    assert_equal :error, message[:type]
    assert_match(/\A1 rejected, 1 failed: Proposal ##{bad.id}: /, message[:body])
  end

  test "reject action is visible on the index view without a record" do
    action = Avo::Actions::RejectAuthorProposal.new(record: nil, resource: nil, user: nil, view: :index)

    assert action.visible?
  end

  test "reject action is visible for a pending proposal" do
    action = Avo::Actions::RejectAuthorProposal.new(
      record: AuthorProposal.new(status: :pending), resource: nil, user: nil, view: :show
    )

    assert action.visible?
  end

  test "reject action is hidden on a record-less view other than index" do
    action = Avo::Actions::RejectAuthorProposal.new(record: nil, resource: nil, user: nil, view: :show)

    assert_not action.visible?
  end

  private

  def pending_proposal(name: "Jane Doe", email: "user@example.com")
    AuthorProposal.create!(
      author_name: name,
      bio_text: "Ruby developer",
      submitter_email: email,
      status: :pending
    )
  end
end
