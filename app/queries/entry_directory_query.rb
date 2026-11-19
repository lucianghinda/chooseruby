# frozen_string_literal: true

# Builds the filtered, sorted Entry scope behind the directory/browse pages:
# free-text search (FTS5), type, experience level, category, and sort order.
class EntryDirectoryQuery
  include FtsQuerySanitizer

  attr_reader :category, :type

  def initialize(params = {})
    @params = params.to_h.symbolize_keys
    @category = locate_category(@params[:category])
    @type = @params[:type].to_s.strip.presence
    @sort = @params[:sort].to_s.strip.presence
  end

  def call
    filtered_scope
  end

  def query
    @query ||= @params[:q].to_s.strip
  end

  def level
    @level ||= @params[:level].presence
  end

  def sort
    @sort ||= "recent"
  end

  private

  def scope
    Entry.visible.with_directory_includes
  end

  def filtered_scope
    result = filter_by_query(scope)
    result = filter_by_type(result)
    result = filter_by_level(result)
    result = filter_by_category(result)
    apply_sort(result).distinct
  end

  def filter_by_query(current_scope)
    return current_scope if query.blank?

    sanitized_query = sanitize_fts_query(query)

    # Order by FTS5 BM25 relevance (rank), then by updated_at for ties
    current_scope
      .joins("JOIN entries_fts ON entries_fts.entry_id = entries.id")
      .where("entries_fts MATCH ?", sanitized_query)
      .order("entries_fts.rank, entries.updated_at DESC")
  end

  def filter_by_type(current_scope)
    return current_scope if type.blank?
    return current_scope unless Entry::VALID_TYPES.key?(type)

    current_scope.where(entryable_type: Entry::VALID_TYPES[type])
  end

  def filter_by_level(current_scope)
    return current_scope if level.blank?

    levels = Entry.experience_levels
    return current_scope unless levels.key?(level)

    current_scope.where(experience_level: [levels[level], levels["all_levels"]])
  end

  def filter_by_category(current_scope)
    return current_scope if category.blank?

    current_scope.joins(:categories).where(categories: {id: category.id})
  end

  def apply_sort(current_scope)
    case sort
    when "popular"
      current_scope.reorder(Arel.sql(popularity_order_sql))
    when "oldest"
      current_scope.reorder(updated_at: :asc)
    when "beginner_first"
      current_scope.reorder(Arel.sql("experience_level = 'beginner' DESC, experience_level = 'intermediate' DESC, experience_level = 'advanced' DESC, entries.updated_at DESC"))
    else
      # "recent"/"newest" and any unrecognized value - unless a query is
      # present, in which case filter_by_query already ordered by relevance.
      query.present? ? current_scope : current_scope.order(updated_at: :desc)
    end
  end

  def popularity_order_sql
    <<~SQL.squish
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
  end

  def locate_category(slug)
    return if slug.blank?

    Category.find_by(slug:)
  end
end
