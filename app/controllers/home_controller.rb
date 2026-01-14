# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @entry_stats = build_entry_stats
    @featured_entries = fetch_featured_entries
    @highlight_categories = fetch_highlight_categories
    @curated_collections = curated_collections_data
    @experience_tracks = experience_tracks_data
    @community_channels = fetch_community_channels
    @popular_queries = popular_queries
    # Task 5.3: Fetch recent entries for each type
    @recent_gems = fetch_recent_gems
    @recent_books = fetch_recent_books
    @recent_courses = fetch_recent_courses
    @recent_tutorials = fetch_recent_tutorials
    @recent_articles = fetch_recent_articles
    @recent_tools = fetch_recent_tools
    @recent_podcasts = fetch_recent_podcasts
    @recent_communities = fetch_recent_communities
    # Task 4.2-4.12: Fetch recent entries for new types
    @recent_newsletters = fetch_recent_newsletters
    @recent_blogs = fetch_recent_blogs
    @recent_videos = fetch_recent_videos
    @recent_channels = fetch_recent_channels
    @recent_documentations = fetch_recent_documentations
    @recent_testing_resources = fetch_recent_testing_resources
    @recent_development_environments = fetch_recent_development_environments
    @recent_jobs = fetch_recent_jobs
    @recent_frameworks = fetch_recent_frameworks
    @recent_directories = fetch_recent_directories
    @recent_products = fetch_recent_products
  end

  private

  def build_entry_stats
    {
      resources: Entry.published.approved.count,
      categories: Category.count,
      authors: Author.count
    }
  end

  def fetch_featured_entries
    Entry.for_homepage
  end

  def fetch_highlight_categories
    Category.order(:display_order, :name).limit(8)
  end

  def fetch_community_channels
    Community.order(member_count: :desc).limit(3)
  end

  # Task 5.2: Fetch methods for each resource type
  def fetch_recent_gems
    Entry.gems.visible.with_directory_includes.recently_curated.limit(4)
  end

  def fetch_recent_books
    Entry.books.visible.with_directory_includes.recently_curated.limit(4)
  end

  def fetch_recent_courses
    Entry.courses.visible.with_directory_includes.recently_curated.limit(4)
  end

  def fetch_recent_tutorials
    Entry.tutorials.visible.with_directory_includes.recently_curated.limit(4)
  end

  def fetch_recent_articles
    Entry.articles.visible.with_directory_includes.recently_curated.limit(4)
  end

  def fetch_recent_tools
    Entry.tools.visible.with_directory_includes.recently_curated.limit(4)
  end

  def fetch_recent_podcasts
    Entry.podcasts.visible.with_directory_includes.recently_curated.limit(4)
  end

  def fetch_recent_communities
    Entry.communities.visible.with_directory_includes.recently_curated.limit(4)
  end

  # Task 4.2: Fetch method for newsletters
  def fetch_recent_newsletters
    Entry.newsletters.visible.with_directory_includes.recently_curated.limit(4)
  end

  # Task 4.3: Fetch method for blogs
  def fetch_recent_blogs
    Entry.blogs.visible.with_directory_includes.recently_curated.limit(4)
  end

  # Task 4.4: Fetch method for videos
  def fetch_recent_videos
    Entry.videos.visible.with_directory_includes.recently_curated.limit(4)
  end

  # Task 4.5: Fetch method for channels
  def fetch_recent_channels
    Entry.channels.visible.with_directory_includes.recently_curated.limit(4)
  end

  # Task 4.6: Fetch method for documentation
  def fetch_recent_documentations
    Entry.documentations.visible.with_directory_includes.recently_curated.limit(4)
  end

  # Task 4.7: Fetch method for testing resources
  def fetch_recent_testing_resources
    Entry.testing_resources.visible.with_directory_includes.recently_curated.limit(4)
  end

  # Task 4.8: Fetch method for development environments
  def fetch_recent_development_environments
    Entry.development_environments.visible.with_directory_includes.recently_curated.limit(4)
  end

  # Task 4.9: Fetch method for jobs
  def fetch_recent_jobs
    Entry.jobs.visible.with_directory_includes.recently_curated.limit(4)
  end

  # Task 4.10: Fetch method for frameworks
  def fetch_recent_frameworks
    Entry.frameworks.visible.with_directory_includes.recently_curated.limit(4)
  end

  # Task 4.11: Fetch method for directories
  def fetch_recent_directories
    Entry.directories.visible.with_directory_includes.recently_curated.limit(4)
  end

  # Task 4.12: Fetch method for products
  def fetch_recent_products
    Entry.products.visible.with_directory_includes.recently_curated.limit(4)
  end

  def popular_queries
    Category.order(:display_order, :name).limit(5).pluck(:name)
  end
end
