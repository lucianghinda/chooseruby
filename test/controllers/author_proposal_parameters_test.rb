# frozen_string_literal: true

require "test_helper"

class AuthorProposalParametersTest < ActiveSupport::TestCase
  test "allowed proposal fields are preserved and unknown fields are discarded" do
    attributes = {
      author_id: "71", author_name: "Name", resource_url: "https://example.com/resource",
      bio_text: "Bio", description_text: "Description", submitter_name: "Submitter",
      submitter_email: "submitter@example.com", submission_notes: "Notes"
    }

    permitted = proposal_params(attributes.merge(status: "approved", reviewed_at: "2026-01-01"))

    assert permitted.permitted?
    assert_equal attributes.stringify_keys, permitted.to_h
  end

  test "link updates discard blank and unpermitted links" do
    permitted = proposal_params(submitter_email: "person@example.com", link_updates: {
      github_url: "https://github.com/person", website_url: " ", twitter_url: "",
      unknown_url: "https://example.com/unapproved"
    })

    assert_equal({ "github_url" => "https://github.com/person" }, permitted.to_h.fetch("link_updates"))
  end

  test "only blank permitted links normalize to nil" do
    permitted = proposal_params(submitter_email: "person@example.com", link_updates: { github_url: " ", website_url: "" })

    assert permitted.key?(:link_updates)
    assert_nil permitted[:link_updates]
  end

  test "an empty link object stays empty and absent links remain absent" do
    assert_empty proposal_params(submitter_email: "person@example.com", link_updates: {})[:link_updates]
    assert_not proposal_params(submitter_email: "person@example.com").key?(:link_updates)
    assert_not proposal_params(submitter_email: "person@example.com", link_updates: nil).key?(:link_updates)
  end

  test "normalization remains permitted when the controller reads parameters again" do
    controller = AuthorProposalsController.new
    controller.params = ActionController::Parameters.new(author_proposal: {
      submitter_email: "person@example.com", link_updates: { github_url: "https://github.com/person", website_url: " " }
    })
    first = controller.send(:author_proposal_params).to_h

    assert_equal first, controller.send(:author_proposal_params).to_h
  end

  private

  def proposal_params(attributes)
    controller = AuthorProposalsController.new
    controller.params = ActionController::Parameters.new(author_proposal: attributes)
    controller.send(:author_proposal_params)
  end
end
