# frozen_string_literal: true

require "test_helper"

class AuthorProposalsControllerTest < ActionDispatch::IntegrationTest
  test "GET new displays form for existing author" do
    author = Author.create!(name: "Test Author", status: :approved)

    get propose_author_edit_path(author_id: author.id)

    assert_response :success
    assert_select "form"
    assert_select "h1", text: /#{author.name}/
  end

  test "GET new_author displays new author form" do
    get new_author_proposal_path

    assert_response :success
    assert_select "form"
    assert_select "input#author_proposal_author_name"
  end

  test "POST create validates required fields" do
    author = Author.create!(name: "Test Author", status: :approved)

    post author_proposals_path, params: {
      author_proposal: {
        author_id: author.id,
        submitter_name: "John Doe"
        # Missing submitter_email (required)
        # Missing any proposed changes
      }
    }

    assert_response :unprocessable_entity
    assert_select "div.text-rose-700", text: /couldn't save/
  end

  test "POST create successfully creates pending proposal" do
    author = Author.create!(name: "Test Author", status: :approved)

    assert_difference "AuthorProposal.count", 1 do
      post author_proposals_path, params: {
        author_proposal: {
          author_id: author.id,
          resource_url: "https://example.com/resource",
          submitter_email: "user@example.com",
          submitter_name: "John Doe"
        }
      }
    end

    proposal = AuthorProposal.last
    assert_equal "pending", proposal.status
    assert_equal author.id, proposal.author_id
    assert_equal "user@example.com", proposal.submitter_email
    assert_redirected_to author_proposal_success_path(proposal)
  end

  test "POST create prevents duplicate submissions within 24 hours" do
    author = Author.create!(name: "Test Author", status: :approved)

    # Create first proposal
    AuthorProposal.create!(
      author: author,
      resource_url: "https://example.com/first",
      submitter_email: "user@example.com",
      status: :pending
    )

    # Try to create duplicate within 24 hours
    assert_no_difference "AuthorProposal.count" do
      post author_proposals_path, params: {
        author_proposal: {
          author_id: author.id,
          resource_url: "https://example.com/second",
          submitter_email: "user@example.com"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "div.text-rose-700", text: /pending proposal/
  end

  test "POST create redirects to success page" do
    author = Author.create!(name: "Test Author", status: :approved)

    post author_proposals_path, params: {
      author_proposal: {
        author_id: author.id,
        bio_text: "Updated bio text",
        submitter_email: "user@example.com"
      }
    }

    proposal = AuthorProposal.last
    assert_redirected_to author_proposal_success_path(proposal)

    follow_redirect!
    assert_response :success
    assert_select "h1", text: /Thank You/
  end
end
