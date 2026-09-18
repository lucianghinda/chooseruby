# frozen_string_literal: true

# Builds the public directory scope from search, filters, and sorting.
class EntryDirectoryQuery
  SORT_ORDERS = {
    "popular" => <<~SQL.squish,
      COALESCE(
        CASE entries.entryable_type
          WHEN 'RubyGem' THEN (SELECT downloads_count FROM ruby_gems WHERE ruby_gems.id = entries.entryable_id)
          WHEN 'Community' THEN (SELECT member_count FROM communities WHERE communities.id = entries.entryable_id)
          WHEN 'Podcast' THEN (SELECT episode_count FROM podcasts WHERE podcasts.id = entries.entryable_id)
          ELSE NULL
        END,
        0
      ) DESC,
      entries.updated_at DESC
    SQL
    "oldest" => "entries.updated_at ASC",
    "beginner_first" => "experience_level = #{Entry.experience_levels.fetch('beginner')} DESC, experience_level = #{Entry.experience_levels.fetch('intermediate')} DESC, experience_level = #{Entry.experience_levels.fetch('advanced')} DESC, entries.updated_at DESC"
  }.freeze

  def initialize(params = {}, scope: Entry.visible.with_directory_includes)
    @params = params.to_h.symbolize_keys
    @scope = scope
  end

  def call
    # Apply filters in chain, with FTS5 search ordering by relevance when query present
    matching_scope
      .yield_self { |current| filter_by_category(current) }
      .yield_self { |current| apply_sort(current) }
      .distinct
  end

  def categories
    @categories ||= Category.order(:display_order, :name)
  end

  def popular_queries
    categories.limit(5).pluck(:name)
  end

  def query
    @params[:q].to_s.strip
  end

  def level
    @params[:level].presence
  end

  def sort
    @params[:sort].to_s.strip.presence || "recent"
  end

  def type
    @params[:type].to_s.strip.presence
  end

  def category
    slug = @params[:category]
    @category ||= Category.find_by(slug:) if slug.present?
  end

  private

  attr_reader :scope



  def matching_scope
    scope
      .yield_self { |current| filter_by_query(current) }
      .yield_self { |current| filter_by_type(current) }
      .yield_self { |current| filter_by_level(current) }
  end

  def filter_by_query(current_scope)
    return current_scope if query.blank?

    # Sanitize query for FTS5
    sanitized_query = FtsQuery.new(query, ignored_characters: /[()\-']/).call

    # Join to FTS5 virtual table and filter by MATCH query
    # Order by FTS5 BM25 relevance (rank), then by updated_at for ties
    current_scope
      .joins("JOIN entries_fts ON entries_fts.entry_id = entries.id")
      .where("entries_fts MATCH ?", sanitized_query)
      .order("entries_fts.rank, entries.updated_at DESC")
  end

  def filter_by_type(current_scope)
    return current_scope if type.blank?
    return current_scope unless Entry::VALID_TYPES.key?(type)

    mapped_type = Entry::VALID_TYPES[type]
    current_scope.where(entryable_type: mapped_type)
  end

  def filter_by_level(current_scope)
    levels = Entry.experience_levels
    return current_scope unless levels.key?(level)

    current_scope.where(experience_level: levels.values_at(level, "all_levels"))
  end

  def filter_by_category(current_scope)
    return current_scope if category.blank?

    current_scope.joins(:categories).where(categories: { id: category.id })
  end

  def apply_sort(current_scope)
    ordering = SORT_ORDERS[sort]
    return current_scope.reorder(Arel.sql(ordering)) if ordering
    return current_scope if query.present?

    current_scope.order(updated_at: :desc)
  end
end
