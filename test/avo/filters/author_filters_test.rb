# frozen_string_literal: true

require "test_helper"

# Unit tests for the Avo filters mounted on Avo::Resources::Author and
# Avo::Resources::AuthorProposal.
class AvoAuthorFiltersTest < ActiveSupport::TestCase
  setup do
    @pending_author = Author.create!(name: "Pending Filter Author", status: :pending)
    @approved_author = Author.create!(name: "Approved Filter Author", status: :approved)
  end

  # --- AuthorStatusFilter --------------------------------------------------

  test "author status filter narrows to approved authors" do
    results = Avo::Filters::AuthorStatusFilter.new.apply(nil, Author.all, "approved")

    assert_includes results, @approved_author
    assert_not_includes results, @pending_author
  end

  test "author status filter narrows to pending authors" do
    results = Avo::Filters::AuthorStatusFilter.new.apply(nil, Author.all, "pending")

    assert_includes results, @pending_author
    assert_not_includes results, @approved_author
  end

  test "author status filter returns the untouched query for a blank value" do
    results = Avo::Filters::AuthorStatusFilter.new.apply(nil, Author.all, nil)

    assert_includes results, @pending_author
    assert_includes results, @approved_author
  end

  test "author status filter offers approved and pending" do
    assert_equal({ "Approved" => "approved", "Pending" => "pending" },
                 Avo::Filters::AuthorStatusFilter.new.options)
  end

  # --- AuthorProposalStatusFilter ------------------------------------------

  test "proposal status filter narrows to pending proposals" do
    results = Avo::Filters::AuthorProposalStatusFilter.new.apply(nil, AuthorProposal.all, "pending")

    assert_includes results, pending_proposal
    assert_not_includes results, approved_proposal
    assert_not_includes results, rejected_proposal
  end

  test "proposal status filter narrows to approved proposals" do
    results = Avo::Filters::AuthorProposalStatusFilter.new.apply(nil, AuthorProposal.all, "approved")

    assert_includes results, approved_proposal
    assert_not_includes results, pending_proposal
  end

  test "proposal status filter narrows to rejected proposals" do
    results = Avo::Filters::AuthorProposalStatusFilter.new.apply(nil, AuthorProposal.all, "rejected")

    assert_includes results, rejected_proposal
    assert_not_includes results, approved_proposal
  end

  test "proposal status filter downcases the incoming value" do
    results = Avo::Filters::AuthorProposalStatusFilter.new.apply(nil, AuthorProposal.all, "Rejected")

    assert_includes results, rejected_proposal
    assert_not_includes results, pending_proposal
  end

  test "proposal status filter returns the untouched query for an unknown value" do
    results = Avo::Filters::AuthorProposalStatusFilter.new.apply(nil, AuthorProposal.all, "whatever")

    assert_includes results, pending_proposal
    assert_includes results, approved_proposal
    assert_includes results, rejected_proposal
  end

  test "proposal status filter offers the three workflow states" do
    assert_equal({ "Pending" => "pending", "Approved" => "approved", "Rejected" => "rejected" },
                 Avo::Filters::AuthorProposalStatusFilter.new.options)
  end

  test "proposal status filter defaults to pending so admins land on the review queue" do
    assert_equal "pending", Avo::Filters::AuthorProposalStatusFilter.new.default
  end

  private

  def pending_proposal
    @pending_proposal ||= create_proposal(status: :pending, email: "pending-proposal@example.com")
  end

  def approved_proposal
    @approved_proposal ||= create_proposal(status: :approved, email: "approved-proposal@example.com")
  end

  def rejected_proposal
    @rejected_proposal ||= create_proposal(status: :rejected, email: "rejected-proposal@example.com")
  end

  def create_proposal(status:, email:)
    AuthorProposal.create!(
      author: @approved_author,
      bio_text: "Proposed bio for #{status}",
      submitter_email: email,
      status: status
    )
  end
end
