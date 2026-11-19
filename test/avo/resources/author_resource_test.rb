# frozen_string_literal: true

require "test_helper"
require "ostruct"
require_relative "../avo_admin_helper"

# Drives the Avo Author admin pages. Most of the Author resource is social link
# fields marked `hide_on: [:index]`, so the show and edit views carry the work.
class AvoAuthorResourceTest < ActionDispatch::IntegrationTest
  include AvoAdminHelper

  SOCIAL_LINKS = {
    github_url: "https://github.com/avo-author",
    gitlab_url: "https://gitlab.com/avo-author",
    website_url: "https://avo-author.example.com",
    bluesky_url: "https://bsky.app/profile/avo-author",
    ruby_social_url: "https://ruby.social/@avo-author",
    twitter_url: "https://twitter.com/avo-author",
    linkedin_url: "https://linkedin.com/in/avo-author",
    youtube_url: "https://youtube.com/@avo-author",
    twitch_url: "https://twitch.tv/avo-author",
    blog_url: "https://blog.avo-author.example.com"
  }.freeze

  setup do
    sign_in_as_admin
    @author = Author.create!(
      { name: "Avo Author Under Test", status: :approved, bio: "A bio rendered by the admin panel" }
        .merge(SOCIAL_LINKS)
    )
  end

  test "index lists authors with their sortable columns" do
    body = get_avo("/avo/resources/authors")

    assert_match @author.name, body
    assert_match "Name", body
    assert_match "Status", body
    assert_match "Slug", body
  end

  test "index hides the social links and timestamps" do
    body = get_avo("/avo/resources/authors")

    assert_no_match(/Github url/, body)
    assert_no_match(/Avatar url/, body)
    assert_no_match(/Created at/, body)
  end

  test "index offers the status filter and the approve action" do
    body = get_avo("/avo/resources/authors")

    assert_match "Avo::Filters::AuthorStatusFilter", body
    assert_match "Avo::Actions::ApproveAuthors", body
  end

  test "show renders every social link of the author" do
    body = get_avo("/avo/resources/authors/#{@author.id}")

    SOCIAL_LINKS.each do |field, url|
      assert_match field.to_s.humanize.capitalize, body, "#{field} must have a label on the show view"
      assert_match url, body, "#{field} must render its value"
    end
  end

  test "show renders the bio and the auto generated slug" do
    body = get_avo("/avo/resources/authors/#{@author.id}")

    assert_match "A bio rendered by the admin panel", body
    assert_match @author.slug, body
  end

  test "show defers the entries association to its own turbo frame" do
    entry = Entry.create!(
      title: "Entry By Avo Author",
      description: "Written by the author under test",
      url: "https://example.com/entry-by-avo-author",
      entryable: RubyGem.create!(gem_name: "entry-by-avo-author"),
      status: :approved
    )
    @author.entries << entry

    body = get_avo("/avo/resources/authors/#{@author.id}")
    assert_match "has_many_field_show_entries", body

    frame = get_avo("/avo/resources/authors/#{@author.id}/entries" \
                    "?view=show&turbo_frame=has_many_field_show_entries")
    assert_match entry.title, frame
  end

  test "new renders the form with the status choices" do
    body = get_avo("/avo/resources/authors/new")

    assert_match "Name", body
    assert_match "<option selected=\"selected\" value=\"pending\">", body
    assert_match "<option value=\"approved\">", body
  end

  test "edit renders the social links prefilled and the slug read only" do
    body = get_avo("/avo/resources/authors/#{@author.id}/edit")

    assert_match SOCIAL_LINKS[:github_url], body
    assert_match SOCIAL_LINKS[:blog_url], body
    assert_match @author.name, body
    assert_match "Auto-generated from name", body
    assert_match(/data-field-id="slug".*?disabled="disabled"/m, body,
                 "the slug field must stay read only on the edit form")
  end

  test "search narrows authors by name" do
    other = Author.create!(name: "Completely Different Person", status: :approved)

    context = OpenStruct.new(params: { q: "Avo Author Under" }, query: Author.all)
    results = context.instance_exec(&Avo::Resources::Author.search[:query])

    assert_includes results, @author
    assert_not_includes results, other
  end
end
