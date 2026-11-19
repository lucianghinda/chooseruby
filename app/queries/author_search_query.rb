# frozen_string_literal: true

# Builds the filtered Author scope behind author search: free-text search
# (FTS5) plus each author's entry count.
class AuthorSearchQuery
  include FtsQuerySanitizer

  def initialize(params = {})
    @params = params.to_h.symbolize_keys
  end

  def call
    filtered_scope
  end

  def query
    @query ||= @params[:q].to_s.strip
  end

  private

  def scope
    Author.approved
  end

  def filtered_scope
    add_entry_counts(filter_by_query(scope))
  end

  def filter_by_query(current_scope)
    return current_scope if query.blank?

    sanitized_query = sanitize_fts_query(query)

    # Order by FTS5 BM25 relevance (rank), then alphabetically by name for ties
    current_scope
      .joins("JOIN authors_fts ON authors_fts.author_id = authors.id")
      .where("authors_fts MATCH ?", sanitized_query)
      .order("authors_fts.rank, authors.name ASC")
  end

  def add_entry_counts(current_scope)
    # left_joins (not joins) to include authors with zero entries
    current_scope
      .select("authors.*, COUNT(entries.id) as entries_count")
      .left_joins(:entries)
      .group("authors.id")
  end
end
