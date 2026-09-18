# frozen_string_literal: true

require "test_helper"

# Renders every Avo resource's index, show, new and edit pages as an admin so the
# resource definitions in app/avo are exercised end to end.
class AvoAdminPagesTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@test.com", password: "password" }
  end

  RESOURCE_RECORDS = {
    "entries" => -> { Entry.create!(title: "Avo Entry", url: "https://example.com/avo", entryable: RubyGem.create!(gem_name: "avo-gem"), status: :approved, published: true, tags: [ "rails" ]) },
    "authors" => -> { Author.create!(name: "Avo Author", github_url: "https://github.com/avo") },
    "author_proposals" => -> { AuthorProposal.create!(author_name: "Proposed Author", bio_text: "Bio", submitter_email: "p@example.com") },
    "categories" => -> { categories(:testing) },
    "categories_entries" => -> { CategoriesEntry.create!(category: categories(:testing), entry: Entry.create!(title: "Categorised", url: "https://example.com/c", status: :approved)) },
    "entry_reviews" => -> { EntryReview.create!(entry: Entry.create!(title: "Reviewed", url: "https://example.com/r", status: :approved), status: :approved, comment: "Good") },
    "users" => -> { users(:editor) },
    "articles" => -> { Article.create! },
    "blogs" => -> { Blog.create!(name: "Avo Blog") },
    "books" => -> { Book.create!(publisher: "Pragmatic") },
    "channels" => -> { Channel.create!(name: "Avo Channel") },
    "communities" => -> { Community.create!(platform: "Discord", join_url: "https://example.com/discord") },
    "courses" => -> { Course.create! },
    "development_environments" => -> { DevelopmentEnvironment.create!(name: "Avo IDE") },
    "directories" => -> { Directory.create!(name: "Avo Directory") },
    "documentations" => -> { Documentation.create!(name: "Avo Docs") },
    "frameworks" => -> { Framework.create!(name: "Avo Framework") },
    "job_boards" => -> { JobBoard.create!(name: "Avo Jobs") },
    "newsletters" => -> { Newsletter.create!(name: "Avo Weekly") },
    "podcasts" => -> { Podcast.create! },
    "products" => -> { Product.create!(name: "Avo Product") },
    "ruby_gems" => -> { RubyGem.create!(gem_name: "avo-resource-gem") },
    "testing_resources" => -> { TestingResource.create!(name: "Avo Testing") },
    "tools" => -> { Tool.create! },
    "tutorials" => -> { Tutorial.create! },
    "videos" => -> { Video.create!(name: "Avo Video") }
  }.freeze

  RESOURCE_RECORDS.each do |resource_name, build_record|
    test "#{resource_name} admin pages render" do
      record = instance_exec(&build_record)

      get "/avo/resources/#{resource_name}"
      assert_response :success

      get "/avo/resources/#{resource_name}/#{record.id}"
      assert_response :success

      get "/avo/resources/#{resource_name}/new"
      assert_response :success

      get "/avo/resources/#{resource_name}/#{record.id}/edit"
      assert_response :success
    end
  end

  test "entry reviews are listed newest first on the entry page" do
    entry = Entry.create!(title: "Reviewed Twice", url: "https://example.com/twice", status: :approved)
    older = EntryReview.create!(entry: entry, status: :rejected, comment: "Older review", created_at: 2.days.ago)
    newer = EntryReview.create!(entry: entry, status: :approved, comment: "Newer review", created_at: 1.day.ago)

    get "/avo/resources/entries/#{entry.id}/entry_reviews"

    assert_response :success
    assert_operator response.body.index("/entry_reviews/#{newer.id}"), :<, response.body.index("/entry_reviews/#{older.id}")
  end

  test "reject action forms render their comment field" do
    get "/avo/resources/author_proposals/actions/Avo::Actions::RejectAuthorProposal"
    assert_response :success
    assert_select "textarea[name=?]", "fields[admin_comment]"

    get "/avo/resources/entries/actions/Avo::Actions::RejectEntries"
    assert_response :success
    assert_select "textarea[name=?]", "fields[comment]"
  end

  test "named delegated types can be created through Avo" do
    assert_difference "Video.count", 1 do
      post "/avo/resources/videos", params: { video: { name: "Created via Avo" } }
    end

    assert_redirected_to "/avo/resources/videos/#{Video.last.id}"
  end
end
