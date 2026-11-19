# frozen_string_literal: true

require "test_helper"
require "ostruct"
require_relative "../avo_admin_helper"

# Drives the Avo AuthorProposal admin pages.
#
# The `proposal_type` and `changes_summary` computed fields are asserted
# through the rendered show page: Avo instance_execs their blocks against an
# ExecutionContext that exposes `record`, so the summary text really is built.
class AvoAuthorProposalResourceTest < ActionDispatch::IntegrationTest
  include AvoAdminHelper

  setup do
    sign_in_as_admin
    @author = Author.create!(
      name: "Existing Proposal Author",
      status: :approved,
      bio: "Current bio on file",
      github_url: "https://github.com/existing"
    )
  end

  test "index lists proposals with their submitter and status columns" do
    proposal = new_author_proposal

    body = get_avo("/avo/resources/author_proposals")

    assert_match proposal.submitter_email, body
    assert_match "Submitter email", body
    assert_match "Status", body
    assert_match "Created at", body
  end

  test "index hides the fields marked hide_on index" do
    new_author_proposal

    body = get_avo("/avo/resources/author_proposals")

    assert_no_match(/Submission notes/, body)
    assert_no_match(/Bio text/, body)
    assert_no_match(/Admin comment/, body)
  end

  test "show renders the submitter details and proposed bio of a new author proposal" do
    proposal = new_author_proposal

    body = get_avo("/avo/resources/author_proposals/#{proposal.id}")

    assert_match "Bio for the brand new person", body
    assert_match proposal.submitter_email, body
    assert_match "Submitter name", body
    assert_match "Bio text", body
  end

  test "show links a proposal to the existing author it edits" do
    proposal = edit_author_proposal

    body = get_avo("/avo/resources/author_proposals/#{proposal.id}")

    assert_match @author.name, body
    assert_match "/avo/resources/authors/#{@author.id}", body
  end

  test "show links to the entry that was matched from the resource URL" do
    entry = Entry.create!(
      title: "Matched Resource Entry",
      description: "Target of the proposal",
      url: "https://example.com/matched-resource",
      entryable: RubyGem.create!(gem_name: "matched-resource"),
      status: :approved
    )
    proposal = AuthorProposal.create!(
      author: @author,
      resource_url: "https://example.com/matched-resource",
      submitter_email: "matched@example.com"
    )
    assert_equal entry.id, proposal.matched_entry_id, "proposal should auto-match the entry by URL"

    body = get_avo("/avo/resources/author_proposals/#{proposal.id}")

    assert_match entry.title, body
    assert_match "/avo/resources/entries/#{entry.id}", body
    assert_match "Resource: Matched entry ##{entry.id} - #{entry.title}", body
  end

  test "show renders the normalized and original resource URLs side by side" do
    proposal = AuthorProposal.create!(
      author: @author,
      resource_url: "https://WWW.Example.com/Nothing-Here/",
      submitter_email: "unmatched@example.com"
    )
    assert_nil proposal.matched_entry_id

    body = get_avo("/avo/resources/author_proposals/#{proposal.id}")

    assert_match "Resource url", body
    assert_match "http://example.com/nothing-here", body
    assert_match "Original resource url", body
    assert_match "https://WWW.Example.com/Nothing-Here/", body
  end

  test "show renders the proposed link updates as JSON" do
    proposal = AuthorProposal.create!(
      author: @author,
      link_updates: {
        "github_url" => "https://github.com/proposed",
        "website_url" => "https://proposed.example.com"
      },
      submitter_email: "links@example.com"
    )

    body = get_avo("/avo/resources/author_proposals/#{proposal.id}")

    assert_match "Link updates", body
    assert_match "github_url", body
    assert_match "https://github.com/proposed", body
  end

  test "show renders the review trail of a rejected proposal" do
    proposal = AuthorProposal.create!(
      author: @author,
      bio_text: "Rejected bio proposal",
      submitter_email: "rejected@example.com"
    )
    proposal.reject!(admin_comment: "Not enough context provided")

    body = get_avo("/avo/resources/author_proposals/#{proposal.id}")

    assert_match "Admin comment", body
    assert_match "Not enough context provided", body
    assert_match "Reviewed at", body
  end

  test "show renders the free text fields submitted with the proposal" do
    proposal = AuthorProposal.create!(
      author: @author,
      description_text: "A proposed long-form description",
      submission_notes: "Please review quickly",
      submitter_name: "Sam Submitter",
      submitter_email: "notes@example.com"
    )

    body = get_avo("/avo/resources/author_proposals/#{proposal.id}")

    assert_match "A proposed long-form description", body
    assert_match "Please review quickly", body
    assert_match "Sam Submitter", body
  end

  test "show summarises the changes an edit proposal asks for" do
    proposal = AuthorProposal.create!(
      author: @author,
      bio_text: "A freshly proposed bio",
      link_updates: { "github_url" => "https://github.com/proposed" },
      submitter_email: "summary@example.com"
    )

    body = get_avo("/avo/resources/author_proposals/#{proposal.id}")

    assert_match "Edit Existing Author", body
    assert_match "Editing author: #{@author.name}", body
    assert_match "github_url: https://github.com/existing", body
    assert_match "Current: Current bio on file", body
    assert_match "Proposed: A freshly proposed bio", body
  end

  test "show summarises a new author proposal and its unmatched resource URL" do
    proposal = AuthorProposal.create!(
      author_name: "Brand New Person",
      description_text: "A proposed description",
      link_updates: { "github_url" => "https://github.com/brand-new" },
      resource_url: "https://example.com/nothing-matched",
      submitter_email: "newsummary@example.com"
    )

    body = get_avo("/avo/resources/author_proposals/#{proposal.id}")

    assert_match "New Author", body
    assert_match "Creating new author: Brand New Person", body
    assert_match "Resource: Unmatched URL - http://example.com/nothing-matched", body
    # There is no author yet, so every current value is blank.
    assert_match "github_url: (blank)", body
    assert_match "Proposed: A proposed description", body
  end

  test "show offers the approve and reject actions" do
    proposal = new_author_proposal

    body = get_avo("/avo/resources/author_proposals/#{proposal.id}")

    assert_match "Avo::Actions::ApproveAuthorProposal", body
    assert_match "Avo::Actions::RejectAuthorProposal", body
  end

  test "search narrows proposals by submitter email" do
    wanted = AuthorProposal.create!(
      author: @author,
      bio_text: "Findable proposal",
      submitter_email: "findme@example.com"
    )
    other = AuthorProposal.create!(
      author_name: "Unrelated Proposal Author",
      bio_text: "Other proposal",
      submitter_email: "somebodyelse@example.com"
    )

    results = search_proposals("findme")

    assert_includes results, wanted
    assert_not_includes results, other
  end

  test "search sanitizes LIKE wildcards in the submitter email query" do
    AuthorProposal.create!(
      author: @author,
      bio_text: "Findable proposal",
      submitter_email: "findme@example.com"
    )

    assert_equal 0, search_proposals("%").count,
                 "a bare % must be escaped rather than matching every proposal"
  end

  private

  def search_proposals(query)
    context = OpenStruct.new(params: { q: query }, query: AuthorProposal.all)
    context.instance_exec(&Avo::Resources::AuthorProposal.search[:query])
  end

  def new_author_proposal
    @new_author_proposal ||= AuthorProposal.create!(
      author_name: "Brand New Person",
      bio_text: "Bio for the brand new person",
      submitter_email: "newauthor@example.com"
    )
  end

  def edit_author_proposal
    @edit_author_proposal ||= AuthorProposal.create!(
      author: @author,
      bio_text: "Updated bio for the existing author",
      submitter_email: "editauthor@example.com"
    )
  end
end
