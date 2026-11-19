# frozen_string_literal: true

class HomeController < ApplicationController
  # Number of entries shown in each "recently added" section of the homepage.
  RECENT_ENTRIES_LIMIT = 4

  def index
    @entry_stats = build_entry_stats
    @featured_entries = Entry.for_homepage
    @highlight_categories = fetch_highlight_categories
    @curated_collections = curated_collections_data
    @experience_tracks = experience_tracks_data
    @community_channels = fetch_community_channels
    @popular_queries = popular_queries
    # Task 5.3: Fetch recent entries for each type
    @recent_gems = recent_entries(:gems)
    @recent_books = recent_entries(:books)
    @recent_courses = recent_entries(:courses)
    @recent_tutorials = recent_entries(:tutorials)
    @recent_articles = recent_entries(:articles)
    @recent_tools = recent_entries(:tools)
    @recent_podcasts = recent_entries(:podcasts)
    @recent_communities = recent_entries(:communities)
    # Task 4.2-4.12: Fetch recent entries for new types
    @recent_newsletters = recent_entries(:newsletters)
    @recent_blogs = recent_entries(:blogs)
    @recent_videos = recent_entries(:videos)
    @recent_channels = recent_entries(:channels)
    @recent_documentations = recent_entries(:documentations)
    @recent_testing_resources = recent_entries(:testing_resources)
    @recent_development_environments = recent_entries(:development_environments)
    @recent_job_boards = recent_entries(:job_boards)
    @recent_frameworks = recent_entries(:frameworks)
    @recent_directories = recent_entries(:directories)
    @recent_products = recent_entries(:products)
  end

  private

  # Latest curated entries of a single resource type, ready for the directory cards.
  # +type_scope+ is one of Entry's resource type scopes, e.g. :gems or :job_boards.
  def recent_entries(type_scope)
    Entry.public_send(type_scope).visible.with_directory_includes.recently_curated.limit(RECENT_ENTRIES_LIMIT)
  end

  def build_entry_stats
    {
      resources: Entry.published.approved.count,
      categories: Category.count,
      authors: Author.count
    }
  end

  def fetch_highlight_categories
    Category.order(:display_order, :name).limit(8)
  end

  def fetch_community_channels
    Community.order(member_count: :desc).limit(3)
  end

  def popular_queries
    Category.order(:display_order, :name).limit(5).pluck(:name)
  end
end
