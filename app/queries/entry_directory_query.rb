# frozen_string_literal: true

class EntryDirectoryQuery
  attr_reader :category, :type

  def initialize(params = {}, scope: default_scope)
    @params = params.to_h.symbolize_keys
    @scope = scope
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

  attr_reader :scope

  def default_scope
    Entry.visible.with_directory_includes
  end

  def filtered_scope
    # Apply filters in chain, with FTS5 search ordering by relevance when query present
    scope
      .yield_self { |current| filter_by_query(current) }
      .yield_self { |current| filter_by_type(current) }
      .yield_self { |current| filter_by_level(current) }
      .yield_self { |current| filter_by_category(current) }
      .yield_self { |current| apply_sort(current) }
      .distinct
  end

  def filter_by_query(current_scope)
    return current_scope if query.blank?

    # Sanitize query for FTS5
    sanitized_query = sanitize_fts_query(query)

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
    return current_scope if level.blank?
    return current_scope unless Entry.experience_levels.key?(level)

    selected_level_value = Entry.experience_levels[level]
    all_levels_value = Entry.experience_levels["all_levels"]

    current_scope.where(experience_level: [ selected_level_value, all_levels_value ])
  end

  def filter_by_category(current_scope)
    return current_scope if category.blank?

    current_scope.joins(:categories).where(categories: { id: category.id })
  end

  def apply_sort(current_scope)
    case sort
    when "recent", "newest"
      query.present? ? current_scope : current_scope.order(updated_at: :desc)
    when "popular"
      current_scope.reorder(Arel.sql(popularity_order_sql))
    when "oldest"
      current_scope.reorder(updated_at: :asc)
    when "beginner_first"
      current_scope.reorder(Arel.sql("experience_level = 'beginner' DESC, experience_level = 'intermediate' DESC, experience_level = 'advanced' DESC, entries.updated_at DESC"))
    else
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

  # Sanitize FTS5 query string to handle special characters and add wildcards
  # Detects quoted phrases and preserves them for exact matching
  # Adds wildcard suffix (*) to non-phrase words for partial matching
  # Escapes FTS5 special characters: ", -, *, (, )
  #
  # Examples:
  #   "rails" => "rails*"
  #   "rails framework" => "rails* framework*"
  #   '"web framework"' => '"web framework"'
  #   'rails "web framework"' => 'rails* "web framework"'
  def sanitize_fts_query(query_string)
    return "" if query_string.blank?

    # Extract quoted phrases and their positions
    phrases = []
    query_without_phrases = query_string.gsub(/"([^"]*)"/) do |match|
      phrases << match
      "__PHRASE_#{phrases.length - 1}__"
    end

    # Process non-phrase words: escape special chars and add wildcards
    processed_words = query_without_phrases.split(/\s+/).map do |word|
      # Skip placeholder tokens
      if word.start_with?("__PHRASE_")
        word
      else
        # Remove FTS5 special characters (not quotes since those are for phrase search)
        # We'll just remove problematic chars: (, ), -
        # For wildcard *, we'll remove existing ones and add our own
        cleaned = word.gsub(/[\(\)\-']/, "")
        # Remove any existing wildcards to prevent double-wildcarding
        cleaned = cleaned.gsub(/\*+$/, "")
        # Add wildcard suffix for partial matching (unless word is empty)
        cleaned.present? ? "#{cleaned}*" : ""
      end
    end.reject(&:blank?)

    # Reconstruct query by replacing placeholders with original phrases
    result = processed_words.join(" ")
    phrases.each_with_index do |phrase, index|
      result = result.gsub("__PHRASE_#{index}__", phrase)
    end

    result
  end
end
