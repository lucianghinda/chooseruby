# frozen_string_literal: true

class ResourceTypesController < ApplicationController
  before_action :validate_type_parameter

  def show
    @type = params[:type]
    @categories = Category.order(:display_order, :name)

    # Prepare query parameters including type
    query_params = params.permit(:q, :level, :category, :type).to_h.merge(type: @type)
    @directory_query = EntryDirectoryQuery.new(query_params)

    # Set instance variables for filters
    @query = @directory_query.query
    @active_level = @directory_query.level
    @active_category = @directory_query.category

    # Fetch featured entries for this type (limit 5)
    @featured_entries = fetch_featured_entries

    # Fetch category stats for this type
    @category_stats = fetch_category_stats

    # Paginate results at 25 per page
    @entries = @directory_query.call.page(params[:page]).per(25)
  end

  private

  def validate_type_parameter
    type = params[:type]
    unless Entry::VALID_TYPES.key?(type)
      raise ActiveRecord::RecordNotFound, "Invalid resource type: #{type}"
    end
  end

  # Fetches featured entries for the current type
  # Returns entries where featured_at is set, ordered by most recent featured_at
  # Only visible (published and approved) entries are returned
  # Limited to 5 featured entries
  def fetch_featured_entries
    entryable_type = Entry::VALID_TYPES[@type]

    Entry
      .visible
      .where(entryable_type: entryable_type)
      .where.not(featured_at: nil)
      .order(featured_at: :desc)
      .with_directory_includes
      .limit(5)
  end

  # Fetches category breakdown stats for the current type
  # Returns a hash of { category_id => count } for all categories
  # that have entries of this type
  # Only counts visible (published and approved) entries
  def fetch_category_stats
    entryable_type = Entry::VALID_TYPES[@type]

    # Get all category_id counts for this type
    category_counts = Entry
      .visible
      .where(entryable_type: entryable_type)
      .joins(:categories_entries)
      .group("categories_entries.category_id")
      .count

    # Convert to hash with category objects as keys
    Category
      .where(id: category_counts.keys)
      .index_by(&:id)
      .transform_values { |category| { category: category, count: category_counts[category.id] } }
      .values
      .sort_by { |stat| -stat[:count] } # Sort by count descending
  end
end
