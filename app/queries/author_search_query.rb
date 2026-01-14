# frozen_string_literal: true

class AuthorSearchQuery
  def initialize(params = {}, scope: default_scope)
    @params = params.to_h.symbolize_keys
    @scope = scope
  end

  def call
    filtered_scope
  end

  def query
    @query ||= @params[:q].to_s.strip
  end

  private

  attr_reader :scope

  def default_scope
    Author.approved
  end

  def filtered_scope
    # Apply search filter and add entry counts
    scope
      .yield_self { |current| filter_by_query(current) }
      .yield_self { |current| add_entry_counts(current) }
  end

  def filter_by_query(current_scope)
    return current_scope if query.blank?

    # Sanitize query for FTS5
    sanitized_query = sanitize_fts_query(query)

    # Join to FTS5 virtual table and filter by MATCH query
    # Order by FTS5 BM25 relevance (rank), then alphabetically by name for ties
    current_scope
      .joins("JOIN authors_fts ON authors_fts.author_id = authors.id")
      .where("authors_fts MATCH ?", sanitized_query)
      .order("authors_fts.rank, authors.name ASC")
  end

  def add_entry_counts(current_scope)
    # Add entry count for each author
    # Use left_joins to include authors with zero entries
    current_scope
      .select("authors.*, COUNT(entries.id) as entries_count")
      .left_joins(:entries)
      .group("authors.id")
  end

  # Sanitize FTS5 query string to handle special characters and add wildcards
  # Detects quoted phrases and preserves them for exact matching
  # Adds wildcard suffix (*) to non-phrase words for partial matching
  # Escapes FTS5 special characters: ", -, *, (, )
  #
  # Examples:
  #   "matz" => "matz*"
  #   "david hansson" => "david* hansson*"
  #   '"Yukihiro Matsumoto"' => '"Yukihiro Matsumoto"'
  #   'david "heinemeier hansson"' => 'david* "heinemeier hansson"'
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
        cleaned = word.gsub(/[\(\)\-]/, "")
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
