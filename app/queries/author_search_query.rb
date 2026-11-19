# frozen_string_literal: true

class AuthorSearchQuery
  # The authors a search runs against unless the caller narrows it down
  def self.default_scope
    Author.approved
  end

  def initialize(params = {}, scope: AuthorSearchQuery.default_scope)
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

  # The matching authors, each carrying the number of entries they contributed.
  # left_joins keeps authors with zero entries in the result.
  def filtered_scope
    filter_by_query(scope)
      .select("authors.*, COUNT(entries.id) as entries_count")
      .left_joins(:entries)
      .group("authors.id")
  end

  # Joins the FTS5 virtual table and orders by BM25 relevance (rank),
  # then alphabetically by name for ties
  def filter_by_query(current_scope)
    return current_scope if query.blank?

    current_scope
      .joins("JOIN authors_fts ON authors_fts.author_id = authors.id")
      .where("authors_fts MATCH ?", FtsQuery.new(query).to_s)
      .order("authors_fts.rank, authors.name ASC")
  end
end
