# frozen_string_literal: true

# Finds approved authors with search relevance and resource counts.
class AuthorSearchQuery
  def initialize(params = {}, scope: Author.approved)
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


  def filtered_scope
    # Apply search filter and add entry counts
    scope
      .yield_self { |current| filter_by_query(current) }
      .select("authors.*, COUNT(entries.id) as entries_count")
      .left_joins(:entries)
      .group("authors.id")
  end

  def filter_by_query(current_scope)
    return current_scope if query.blank?

    # Sanitize query for FTS5
    sanitized_query = FtsQuery.new(query).call

    # Join to FTS5 virtual table and filter by MATCH query
    # Order by FTS5 BM25 relevance (rank), then alphabetically by name for ties
    current_scope
      .joins("JOIN authors_fts ON authors_fts.author_id = authors.id")
      .where("authors_fts MATCH ?", sanitized_query)
      .order("authors_fts.rank, authors.name ASC")
  end
end
