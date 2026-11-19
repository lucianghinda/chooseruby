# frozen_string_literal: true

require "test_helper"
require_relative "../avo_admin_helper"

# Author proposals are settled with the Approve and Reject actions. Avo must not
# offer a way to create, edit or delete them, and must refuse the routes even when
# they are requested directly.
class AvoAuthorProposalReadOnlyTest < ActionDispatch::IntegrationTest
  include AvoAdminHelper

  INDEX_PATH = "/avo/resources/author_proposals"

  setup do
    sign_in_as_admin
    @proposal = AuthorProposal.create!(
      submitter_email: "read-only@test.com",
      author_name: "Read Only",
      bio_text: "Proposed for the read only test",
      status: :pending
    )
  end

  test "reading a proposal still works" do
    assert_match "read-only@test.com", get_avo(INDEX_PATH)
    assert_match "Read Only", get_avo("#{INDEX_PATH}/#{@proposal.id}")
  end

  test "the new and edit forms are refused" do
    [ "#{INDEX_PATH}/new", "#{INDEX_PATH}/#{@proposal.id}/edit" ].each do |path|
      get path

      assert_redirected_to INDEX_PATH
      assert_equal Avo::AuthorProposalsController::READ_ONLY_NOTICE, flash[:alert]
    end
  end

  test "creating a proposal through Avo is refused" do
    assert_no_difference -> { AuthorProposal.count } do
      post INDEX_PATH, params: { author_proposal: { submitter_email: "sneaked-in@test.com" } }
    end

    assert_redirected_to INDEX_PATH
  end

  test "updating a proposal through Avo is refused" do
    patch "#{INDEX_PATH}/#{@proposal.id}", params: { author_proposal: { author_name: "Renamed" } }

    assert_redirected_to INDEX_PATH
    assert_equal "Read Only", @proposal.reload.author_name
  end

  test "deleting a proposal through Avo is refused" do
    assert_no_difference -> { AuthorProposal.count } do
      delete "#{INDEX_PATH}/#{@proposal.id}"
    end

    assert_redirected_to INDEX_PATH
  end

  test "the index and the rows offer no way in to the write routes" do
    body = get_avo(INDEX_PATH)

    assert_no_match(/#{INDEX_PATH}\/new/, body)
    assert_no_match(%r{#{INDEX_PATH}/#{@proposal.id}/edit}, body)
    assert_match "#{INDEX_PATH}/#{@proposal.id}", body, "the row still links to the proposal"
  end

  test "the show page offers no way in to the write routes" do
    body = get_avo("#{INDEX_PATH}/#{@proposal.id}")

    assert_no_match(%r{#{INDEX_PATH}/#{@proposal.id}/edit}, body)
  end
end
