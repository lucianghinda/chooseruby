# frozen_string_literal: true

require "test_helper"

# Avo drives every action through `Avo::BaseAction#handle_action`, which always
# calls `handle` with the full `fields:/current_user:/resource:/records:/query:`
# keyword set. Our actions only declare the keywords they actually use and
# absorb the rest, so these tests pin that contract to the framework's real
# entry point rather than to a hand-written `handle` call.
class AvoHandleActionDispatchTest < ActiveSupport::TestCase
  test "handle_action publishes the selected entries" do
    entry = pending_entry

    dispatch(Avo::Actions::PublishEntries, entry)

    assert_predicate entry.reload, :published?
  end

  test "handle_action unpublishes the selected entries" do
    entry = pending_entry(published: true)

    dispatch(Avo::Actions::UnpublishEntries, entry)

    assert_not_predicate entry.reload, :published?
  end

  test "handle_action approves the selected entries" do
    entry = pending_entry

    dispatch(Avo::Actions::ApproveEntries, entry)

    assert_predicate entry.reload, :approved?
  end

  test "handle_action rejects the selected entries" do
    entry = pending_entry

    dispatch(Avo::Actions::RejectEntries, entry)

    assert_predicate entry.reload, :rejected?
  end

  test "handle_action approves the selected authors" do
    author = Author.create!(name: "Dispatch Author", status: :pending)

    action = Avo::Actions::ApproveAuthors.new(record: author, resource: nil, user: nil, view: :index)
    action.handle_action(query: Author.where(id: author.id), current_user: nil, resource: nil)

    assert_predicate author.reload, :approved?
  end

  test "handle_action approves the selected author proposals" do
    proposal = AuthorProposal.create!(
      author_name: "Dispatch Proposal Author",
      submitter_email: "dispatch@example.com",
      status: :pending
    )

    action = Avo::Actions::ApproveAuthorProposal.new(record: proposal, resource: nil, user: nil, view: :index)
    action.handle_action(query: AuthorProposal.where(id: proposal.id), current_user: nil, resource: nil)

    assert_predicate proposal.reload, :approved?
  end

  test "handle_action reaches the reject proposal action with an empty fields hash" do
    proposal = AuthorProposal.create!(
      author_name: "Dispatch Proposal Author",
      submitter_email: "dispatch@example.com",
      status: :pending
    )

    action = Avo::Actions::RejectAuthorProposal.new(record: proposal, resource: nil, user: nil, view: :index)
    action.handle_action(query: AuthorProposal.where(id: proposal.id), current_user: nil, resource: nil)

    assert_predicate proposal.reload, :pending?
    assert_equal "Admin comment is required when rejecting proposals",
                 action.response[:messages].last[:body]
  end

  private

  def dispatch(action_class, entry)
    action = action_class.new(record: entry, resource: nil, user: nil, view: :index)
    action.handle_action(query: Entry.where(id: entry.id), current_user: nil, resource: nil)
  end

  def pending_entry(published: false)
    Entry.create!(
      title: "Dispatch Entry #{SecureRandom.hex(4)}",
      description: "Entry used to drive an Avo action through handle_action",
      url: "https://example.com/dispatch-#{SecureRandom.hex(4)}",
      entryable: RubyGem.create!(gem_name: "dispatch-#{SecureRandom.hex(4)}"),
      status: :pending,
      published: published,
      submitter_email: "dispatch@example.com"
    )
  end
end
