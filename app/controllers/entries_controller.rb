# frozen_string_literal: true

class EntriesController < ApplicationController
  # A submitted entry may be filed under at most this many categories.
  MAX_CATEGORIES = 3

  before_action :load_form_data, only: %i[new create]

  def index
    @categories = Category.order(:display_order, :name)
    permitted_params = params.permit(:q, :level, :category, :sort).to_h
    directory_query = EntryDirectoryQuery.new(permitted_params)
    @query = directory_query.query
    @active_level = directory_query.level
    @active_category = directory_query.category
    @active_sort = directory_query.sort
    @popular_queries = popular_queries
    @entries = directory_query.call.page(params[:page]).per(25)
  end

  def start
    @categories = Category.order(:display_order, :name)
    level_param = params[:level].presence || "beginner"
    permitted_params = params.permit(:q, :category, :sort, :level).to_h.merge(level: level_param)
    directory_query = EntryDirectoryQuery.new(permitted_params)
    @query = directory_query.query
    @active_level = level_param
    @active_category = directory_query.category
    @active_sort = directory_query.sort
    @popular_queries = popular_queries
    @entries = directory_query.call.page(params[:page]).per(25)
  end

  def suggestions
    @query = params[:q].to_s.strip
    return head :ok if @query.length < 2

    @popular_queries = popular_queries

    # Sanitize LIKE wildcards to prevent LIKE injection
    sanitized_query = ActiveRecord::Base.sanitize_sql_like(@query)

    @categories = Category.where("name LIKE ?", "%#{sanitized_query}%").order(:name).limit(5)
    @types = Entry::VALID_TYPES.keys.filter do |type_slug|
      view_context.type_name(type_slug).downcase.include?(@query.downcase)
    end.first(4)
    @entries = Entry.visible
      .where("title LIKE ?", "%#{sanitized_query}%")
      .order(updated_at: :desc)
      .limit(5)

    render partial: "entries/suggestions"
  end

  def new
    @entry = Entry.new
  end

  def create
    build_submitted_entry
    return render_invalid_entry if @entry.errors.any?

    submit_entry
    @entry.persisted? ? redirect_to(entry_success_path) : render_invalid_entry
  end

  def success
    # Success confirmation page
  end

  private

  # A publicly submitted entry always starts out pending and unpublished. The
  # category limit is enforced here because Entry does not validate it itself.
  def build_submitted_entry
    @entry = Entry.new(common_entry_params)
    @entry.status = :pending
    @entry.published = false
    @entry.errors.add(:categories, "You can select a maximum of #{MAX_CATEGORIES} categories") if too_many_categories?
  end

  def too_many_categories?
    all_permitted_params[:category_ids].to_a.count(&:present?) > MAX_CATEGORIES
  end

  # Persists the entry together with the delegated type it describes. Leaves
  # the entry unsaved when either of the two cannot be stored.
  def submit_entry
    ActiveRecord::Base.transaction do
      @entry.entryable = build_entryable
      raise ActiveRecord::Rollback unless @entry.save

      attach_submitted_author
    end

    notify_submission if @entry.persisted?
  end

  def attach_submitted_author
    author_id = all_permitted_params[:author_id]
    return if author_id.blank?

    author = Author.find_by(id: author_id)
    @entry.authors << author if author
  end

  def notify_submission
    ResourceSubmissionMailer.notify_team(@entry).deliver_later
    ResourceSubmissionMailer.confirm_submitter(@entry).deliver_later
  end

  def render_invalid_entry
    flash.now[:alert] = "Please review the highlighted fields."
    render :new, status: :unprocessable_entity
  end

  def popular_queries
    Category.order(:display_order, :name).limit(5).pluck(:name)
  end

  def load_form_data
    @categories = Category.order(:name)
    @authors = Author.approved.order(:name)
  end

  def all_permitted_params
    @all_permitted_params ||= params.require(:entry).permit(
      # Common Entry fields
      :title,
      :url,
      :description,
      :image_url,
      :experience_level,
      :submitter_name,
      :submitter_email,
      :resource_type,
      :author_id,
      # RubyGem fields
      :gem_name,
      :github_url,
      :documentation_url,
      :rubygems_url,
      :current_version,
      :downloads_count,
      # Book fields
      :isbn,
      :publisher,
      :publication_year,
      :page_count,
      :format,
      :purchase_url,
      # Course fields
      :platform,
      :instructor,
      :duration_hours,
      :price,
      :currency,
      :is_free,
      :enrollment_url,
      # Tutorial fields
      :reading_time_minutes,
      :publication_date,
      :author_name,
      # Article fields (same as Tutorial, already covered)
      # Tool fields
      :tool_type,
      :license,
      :is_open_source,
      # Podcast fields
      :host,
      :episode_count,
      :frequency,
      :rss_feed_url,
      :spotify_url,
      :apple_podcasts_url,
      # Community fields
      :join_url,
      :member_count,
      :is_official,
      category_ids: []
    )
  end

  def common_entry_params
    all_permitted_params.slice(
      :title,
      :url,
      :description,
      :image_url,
      :experience_level,
      :submitter_name,
      :submitter_email,
      :category_ids
    )
  end

  def build_entryable
    resource_type = params.dig(:entry, :resource_type)

    case resource_type
    when "RubyGem"
      RubyGem.new(ruby_gem_params)
    when "Book"
      Book.new(book_params)
    when "Course"
      Course.new(course_params)
    when "Tutorial"
      Tutorial.new(tutorial_params)
    when "Article"
      Article.new(article_params)
    when "Tool"
      Tool.new(tool_params)
    when "Podcast"
      Podcast.new(podcast_params)
    when "Community"
      Community.new(community_params)
    else
      raise ArgumentError, "Unknown resource type: #{resource_type}"
    end
  end

  def ruby_gem_params
    all_permitted_params.slice(
      :gem_name,
      :github_url,
      :documentation_url,
      :rubygems_url,
      :current_version,
      :downloads_count
    )
  end

  def book_params
    all_permitted_params.slice(
      :isbn,
      :publisher,
      :publication_year,
      :page_count,
      :format,
      :purchase_url
    )
  end

  def course_params
    params_hash = all_permitted_params.slice(
      :platform,
      :instructor,
      :duration_hours,
      :currency,
      :is_free,
      :enrollment_url
    )

    # Convert price from dollars to cents
    price = all_permitted_params[:price]
    params_hash[:price_cents] = (price.to_f * 100).to_i if price.present?

    params_hash
  end

  def tutorial_params
    all_permitted_params.slice(
      :reading_time_minutes,
      :publication_date,
      :author_name,
      :platform
    )
  end

  def article_params
    all_permitted_params.slice(
      :reading_time_minutes,
      :publication_date,
      :author_name,
      :platform
    )
  end

  def tool_params
    all_permitted_params.slice(
      :tool_type,
      :github_url,
      :documentation_url,
      :license,
      :is_open_source
    )
  end

  def podcast_params
    all_permitted_params.slice(
      :host,
      :episode_count,
      :frequency,
      :rss_feed_url,
      :spotify_url,
      :apple_podcasts_url
    )
  end

  def community_params
    all_permitted_params.slice(
      :platform,
      :join_url,
      :member_count,
      :is_official
    )
  end
end
