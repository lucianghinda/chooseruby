# frozen_string_literal: true

class EntriesController < ApplicationController
  before_action :load_form_data, only: %i[new create]

  def index
    @categories = Category.order(:display_order, :name)
    permitted_params = params.permit(:q, :level, :category, :sort).to_h
    @directory_query = EntryDirectoryQuery.new(permitted_params)
    @query = @directory_query.query
    @active_level = @directory_query.level
    @active_category = @directory_query.category
    @active_sort = @directory_query.sort
    @popular_queries = popular_queries
    @entries = @directory_query.call.page(params[:page]).per(25)
  end

  def start
    @categories = Category.order(:display_order, :name)
    level_param = params[:level].presence || "beginner"
    permitted_params = params.permit(:q, :category, :sort, :level).to_h.merge(level: level_param)
    @directory_query = EntryDirectoryQuery.new(permitted_params)
    @query = @directory_query.query
    @active_level = level_param
    @active_category = @directory_query.category
    @active_sort = @directory_query.sort
    @popular_queries = popular_queries
    @entries = @directory_query.call.page(params[:page]).per(25)
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
    # Validate category limit before processing
    category_ids = all_permitted_params[:category_ids].to_a.reject(&:blank?)
    if category_ids.length > 3
      @entry = Entry.new(common_entry_params)
      @entry.errors.add(:categories, "You can select a maximum of 3 categories")
      flash.now[:alert] = "Please review the highlighted fields."
      render :new, status: :unprocessable_entity
      return
    end

    # Build entry with only Entry attributes
    @entry = Entry.new(common_entry_params)
    @entry.status = :pending
    @entry.published = false

    ActiveRecord::Base.transaction do
      # Build the appropriate delegated type
      entryable = build_entryable
      @entry.entryable = entryable

      if @entry.save
        # Handle author association if author_id is provided
        if all_permitted_params[:author_id].present?
          author = Author.find_by(id: all_permitted_params[:author_id])
          @entry.authors << author if author
        end

        # Send notification emails asynchronously
        ResourceSubmissionMailer.notify_team(@entry).deliver_later
        ResourceSubmissionMailer.confirm_submitter(@entry).deliver_later

        redirect_to entry_success_path
      else
        raise ActiveRecord::Rollback
      end
    end

    unless @entry.persisted?
      flash.now[:alert] = "Please review the highlighted fields."
      render :new, status: :unprocessable_entity
    end
  end

  def success
    # Success confirmation page
  end

  private

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
    if all_permitted_params[:price].present?
      params_hash[:price_cents] = (all_permitted_params[:price].to_f * 100).to_i
    end

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
