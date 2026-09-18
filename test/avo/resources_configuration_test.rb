# frozen_string_literal: true

require "test_helper"

class AvoResourcesConfigurationTest < ActiveSupport::TestCase
  # Preserve the administrator-facing field order when declarations are grouped.
  EXPECTED_FIELDS = {
    Article: %i[ id reading_time_minutes publication_date author_name platform entry created_at updated_at ],
    Author: %i[ id name bio status slug avatar avatar_url github_url gitlab_url website_url bluesky_url ruby_social_url twitter_url linkedin_url youtube_url twitch_url blog_url entries created_at updated_at ],
    AuthorProposal: %i[ id status submitter_email submitter_name author author_name resource_url original_resource_url matched_entry link_updates bio_text description_text submission_notes admin_comment reviewed_at created_at updated_at proposal_type changes_summary ],
    Blog: %i[ id name entry created_at updated_at ],
    Book: %i[ id isbn publisher publication_year page_count format purchase_url entry created_at updated_at ],
    CategoriesEntry: %i[ id category entry is_primary is_featured created_at updated_at ],
    Category: %i[ id name slug description icon display_order entries_count entries created_at updated_at ],
    Channel: %i[ id name entry created_at updated_at ],
    Community: %i[ id platform join_url member_count is_official entry created_at updated_at ],
    Course: %i[ id platform instructor duration_hours price_cents currency is_free enrollment_url entry created_at updated_at ],
    DevelopmentEnvironment: %i[ id name entry created_at updated_at ],
    Directory: %i[ id name entry created_at updated_at ],
    Documentation: %i[ id name entry created_at updated_at ],
    Entry: %i[ id title description url entryable image image_url experience_level status published submitter_name submitter_email tags slug categories authors entry_reviews created_at updated_at ],
    EntryReview: %i[ id entry status comment reviewer_id created_at updated_at ],
    Framework: %i[ id name entry created_at updated_at ],
    JobBoard: %i[ id name entry created_at updated_at ],
    Newsletter: %i[ id name entry created_at updated_at ],
    Podcast: %i[ id host episode_count frequency rss_feed_url spotify_url apple_podcasts_url entry created_at updated_at ],
    Product: %i[ id name entry created_at updated_at ],
    RubyGem: %i[ id gem_name rubygems_url github_url documentation_url downloads_count current_version entry created_at updated_at ],
    TestingResource: %i[ id name entry created_at updated_at ],
    Tool: %i[ id tool_type github_url documentation_url license is_open_source entry created_at updated_at ],
    Tutorial: %i[ id reading_time_minutes publication_date author_name platform entry created_at updated_at ],
    User: %i[ id email_address name password role status sessions created_at updated_at ],
    Video: %i[ id name entry created_at updated_at ]
  }.freeze

  EXPECTED_FIELDS.each do |name, expected_fields|
    test "#{name} exposes its configured fields in order" do
      resource = "Avo::Resources::#{name}".constantize.new(view: :show).detect_fields
      fields = resource.get_field_definitions

      assert_equal expected_fields, fields.map(&:id)
      assert_empty resource.invalid_fields
    end
  end

  test "admin resource routes resolve to their registered index controllers" do
    %w[
      Avo::ArticlesController
      Avo::AuthorProposalsController
      Avo::AuthorsController
      Avo::BlogsController
      Avo::BooksController
      Avo::CategoriesController
      Avo::CategoriesEntriesController
      Avo::ChannelsController
      Avo::CommunitiesController
      Avo::CoursesController
      Avo::DevelopmentEnvironmentsController
      Avo::DirectoriesController
      Avo::DocumentationsController
      Avo::EntriesController
      Avo::EntryReviewsController
      Avo::FrameworksController
      Avo::JobBoardsController
      Avo::NewslettersController
      Avo::PodcastsController
      Avo::ProductsController
      Avo::RubyGemsController
      Avo::TestingResourcesController
      Avo::ToolsController
      Avo::TutorialsController
      Avo::VideosController
    ].each do |controller_name|
      resource_name = controller_name.demodulize.delete_suffix("Controller").underscore
      route = Avo::Engine.routes.recognize_path("/resources/#{resource_name}", method: :get)

      assert_equal({ controller: "avo/#{resource_name}", action: "index" }, route)
    end
  end

  test "entry has review actions and all classification filters" do
    resource = Avo::Resources::Entry.new(view: :index)

    assert_equal %w[ApproveEntries RejectEntries PublishEntries UnpublishEntries],
      resource.get_actions.map { |action| action.fetch(:class).to_s.demodulize }
    assert_equal %w[EntryStatusFilter EntryPublishedFilter EntryExperienceLevelFilter EntryTypeFilter EntryCategoryFilter EntryTagsFilter],
      resource.get_filters.map { |filter| filter.fetch(:class).to_s.demodulize }
  end
end

class AvoResourceCallbacksTest < ActiveSupport::TestCase
  test "search callbacks escape wildcard input for all searchable resource types" do
    [ [ Avo::Resources::Author, Author ], [ Avo::Resources::Category, Category ], [ Avo::Resources::AuthorProposal, AuthorProposal ], [ Avo::Resources::Entry, Entry ] ].each do |resource_class, model|
      result = Avo::ExecutionContext.new(target: resource_class.search.fetch(:query), query: model.all, params: { q: "_%" }).handle

      assert_includes result.to_sql, "\\_\\%"
      assert_equal [], result.to_a
    end
  end

  test "author and proposal resources expose review filters and actions" do
    author = Avo::Resources::Author.new(view: :index)
    proposal = Avo::Resources::AuthorProposal.new(view: :index)

    assert_equal [ Avo::Filters::AuthorStatusFilter ], author.get_filters.pluck(:class)
    assert_equal [ Avo::Actions::ApproveAuthors ], author.get_actions.pluck(:class)
    assert_equal [ Avo::Filters::AuthorProposalStatusFilter ], proposal.get_filters.pluck(:class)
    assert_equal [ Avo::Actions::ApproveAuthorProposal, Avo::Actions::RejectAuthorProposal ], proposal.get_actions.pluck(:class)
  end

  test "proposal computed fields and visibility use the comparison presenter" do
    proposal = AuthorProposal.new(author_name: "Suggested Author")
    resource = Avo::Resources::AuthorProposal.new(view: :show, record: proposal).detect_fields
    fields = resource.get_field_definitions.index_by(&:id)

    assert fields.fetch(:author_name).visible?
    assert_equal "New Author", fields.fetch(:proposal_type).value
    assert_equal "Creating new author: Suggested Author", fields.fetch(:changes_summary).value
  end

  test "entry tag suggestions use existing tags and review scope is newest first" do
    Entry.create!(title: "Suggested tags", description: "Description", url: "https://example.com/suggestions", entryable: Book.new, status: :approved, tags: %w[ruby rails])
    resource = Avo::Resources::Entry.new(view: :show).detect_fields
    fields = resource.get_field_definitions.index_by(&:id)

    assert_equal %w[rails ruby], fields.fetch(:tags).suggestions
    scope = fields.fetch(:entry_reviews).scope
    query = Avo::ExecutionContext.new(target: scope, query: EntryReview.all).handle
    assert_equal EntryReview.order(created_at: :desc).to_sql, query.to_sql
  end

  test "rejection actions expose feedback fields and reject missing required feedback" do
    [ [ Avo::Actions::RejectEntries, :comment ], [ Avo::Actions::RejectAuthorProposal, :admin_comment ] ].each do |action_class, expected_field|
      action = action_class.new(view: :index)
      action.items_holder = Avo::Resources::Items::Holder.new(parent: action)
      action.fields
      assert_equal [ expected_field ], action.get_field_definitions.map(&:id)
    end
    action = Avo::Actions::RejectAuthorProposal.new(view: :index)
    action.handle(records: [], fields: { admin_comment: " " })
    assert_equal "Admin comment is required when rejecting proposals", action.response[:messages].last[:body]
  end
end
