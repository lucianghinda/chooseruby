# frozen_string_literal: true

require "test_helper"

class AvoAuthorProposalsAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    post session_url, params: { email_address: "admin@test.com", password: "password" }
    @proposal = AuthorProposal.create!(author_name: "Proposed author", submitter_email: "author@example.com")
  end

  test "administrators can list and inspect proposals" do
    get "/avo/resources/author_proposals"
    assert_response :success

    get "/avo/resources/author_proposals/#{@proposal.id}"
    assert_response :success
    assert_select "body", text: /Proposed author/
    assert controller.authorize_action(@proposal, :show)
  end

  test "new and edit forms reject direct access" do
    get "/avo/resources/author_proposals/new"
    assert_response :forbidden

    get "/avo/resources/author_proposals/#{@proposal.id}/edit"
    assert_response :forbidden
  end

  test "creating a proposal through Avo is forbidden" do
    assert_no_difference "AuthorProposal.count" do
      post "/avo/resources/author_proposals", params: { author_proposal: { author_name: "Injected author", submitter_email: "injected@example.com" } }
    end
    assert_response :forbidden
  end

  test "updating a proposal through Avo is forbidden" do
    patch "/avo/resources/author_proposals/#{@proposal.id}", params: { author_proposal: { author_name: "Changed author" } }

    assert_response :forbidden
    assert_equal "Proposed author", @proposal.reload.author_name
  end

  test "deleting a proposal through Avo is forbidden" do
    assert_no_difference "AuthorProposal.count" do
      delete "/avo/resources/author_proposals/#{@proposal.id}"
    end
    assert_response :forbidden
  end

  test "administrators can still approve a proposal through its review action" do
    post "/avo/resources/author_proposals/#{@proposal.id}/actions/#{Avo::Actions::ApproveAuthorProposal.to_param}",
      params: { fields: { avo_resource_ids: @proposal.id.to_s } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_predicate @proposal.reload, :approved?
  end
end
