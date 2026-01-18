# frozen_string_literal: true

class ResourcesController < ApplicationController
  def index
    @categories = Category.order(:display_order, :name)

    # Build query with all filter parameters
    permitted_params = params.permit(:q, :level, :type, :sort).to_h
    @directory_query = EntryDirectoryQuery.new(permitted_params)

    # Extract query state for view
    @query = @directory_query.query
    @active_level = @directory_query.level
    @active_type = @directory_query.type

    # Fetch featured resources (global featured using featured_at)
    @featured_entries = Entry.visible.featured.with_directory_includes.limit(6)

    # Paginate filtered results (12 per page)
    @entries = @directory_query.call.page(params[:page]).per(12)
  end

  def show
    # Find entry by slug with strict_loading to prevent N+1 queries
    # Use visible scope to only show published and approved entries
    # Eager load associations to prevent N+1 queries
    slug = params[:slug] || params[:id]

    @entry = Entry
      .strict_loading
      .visible
      .includes(
        :categories,
        :rich_text_description,
        :entryable,
        { image_attachment: :blob },
        authors: { avatar_attachment: :blob }
      )
      .find_by!(slug: slug)

    @author_resources = related_by_author(@entry)
    @related_resources = related_by_topic(@entry)
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
  end

  private

  def related_by_author(entry)
    return Entry.none if entry.authors.blank?

    Entry
      .strict_loading
      .visible
      .includes(:categories, :rich_text_description, :entryable, { image_attachment: :blob }, authors: { avatar_attachment: :blob })
      .joins(:entries_authors)
      .where(entries_authors: { author_id: entry.author_ids })
      .where.not(id: entry.id)
      .distinct
      .recently_curated
      .limit(5)
  end

  def related_by_topic(entry)
    return [] if entry.categories.empty?

    related = entry.related_resources(limit: 5)
    return related if related.size >= 5

    additional_needed = 5 - related.size
    type_related = Entry
      .strict_loading
      .visible
      .includes(:categories, :rich_text_description, :entryable, { image_attachment: :blob }, authors: { avatar_attachment: :blob })
      .where(entryable_type: entry.entryable_type)
      .where.not(id: [ entry.id, *related.map(&:id) ])
      .recently_curated
      .limit(additional_needed)
      .to_a

    (related + type_related).first(5)
  end
end
