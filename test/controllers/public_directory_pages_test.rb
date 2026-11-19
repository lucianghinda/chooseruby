# frozen_string_literal: true

require "test_helper"

class PublicDirectoryPagesTest < ActionDispatch::IntegrationTest
  test "collection index links to each curated collection" do
    get collections_path
    assert_response :success
    assert_select "a[href=?]", collection_path("hotwire-speed")
    assert_select "a[href=?]", collection_path("career-switch")
  end

  test "collection defaults survive blank overrides" do
    get collection_path("hotwire-speed"), params: { q: "" }
    assert_response :success
    assert_select "input[name=q][value=hotwire]"
  end

  test "collection accepts nonblank search overrides" do
    get collection_path("hotwire-speed"), params: { q: "testing" }
    assert_response :success
    assert_select "input[name=q][value=testing]"
  end

  test "unknown collections return not found" do
    get collection_path("missing")
    assert_response :not_found
  end

  test "communities page renders its empty directory" do
    Community.delete_all
    get communities_path
    assert_response :success
    assert_select "h1", text: /Connect with the Ruby community/
  end

  %w[why-ruby mission roadmap].each do |page|
    test "public information page #{page} has a heading" do
      get "/#{page}"
      assert_response :success
      assert_select "h1", count: 1
    end
  end

  test "resource directory lists visible entries and filters hidden ones" do
    Entry.create!(title: "Visible Directory Gem", url: "https://example.com/visible", status: :approved, published: true)
    Entry.create!(title: "Hidden Directory Gem", url: "https://example.com/hidden", status: :approved, published: false)
    get resources_path
    assert_response :success
    assert_select "h3", text: "Visible Directory Gem"
    assert_select "h3", text: "Hidden Directory Gem", count: 0
  end

  test "suggestions return no markup for short terms" do
    get entries_suggestions_path, params: { q: "r" }
    assert_response :success
    assert_empty response.body
  end

  test "suggestions include matching visible entries" do
    Entry.create!(title: "Ruby Suggestions", url: "https://example.com/suggestions", status: :approved, published: true)
    get entries_suggestions_path, params: { q: "Ruby" }
    assert_response :success
    assert_select "a", text: /Ruby Suggestions/
  end

  test "suggestion wildcard characters are treated literally" do
    Entry.create!(title: "Not A Wildcard", url: "https://example.com/wildcards", status: :approved, published: true)
    get entries_suggestions_path, params: { q: "%%" }
    assert_response :success
    assert_select "a", text: /Not A Wildcard/, count: 0
  end

  test "missing author and proposal identifiers return not found" do
    get propose_author_edit_path(author_id: -1)
    assert_response :not_found
    get author_proposal_success_path(-1)
    assert_response :not_found
  end

  test "invalid new author proposal renders validation errors" do
    assert_no_difference "AuthorProposal.count" do
      post author_proposals_path, params: { author_proposal: { author_name: "", submitter_email: "invalid" } }
    end
    assert_response :unprocessable_entity
    assert_select "input#author_proposal_author_name"
  end

  test "CSP reports are accepted without a session" do
    post "/csp-violation-report", params: '{"csp-report":{"blocked-uri":"https://example.com"}}',
      headers: { "CONTENT_TYPE" => "application/csp-report" }
    assert_response :no_content
    assert_empty response.body
  end
end
