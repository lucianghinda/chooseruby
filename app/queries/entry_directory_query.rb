# frozen_string_literal: true

class EntryDirectoryQuery
  # Sort parameter values mapped onto the ordering they ask for
  SORT_SCOPES = {
    "popular" => :by_popularity,
    "oldest" => :oldest_first,
    "beginner_first" => :beginner_first
  }.freeze

  # Entry search also drops apostrophes, which FTS5 cannot match across the
  # titles and descriptions it indexes
  IGNORED_SEARCH_CHARACTERS = /[()\-']/

  attr_reader :category, :type

  # The entries a directory listing runs against unless the caller narrows it down
  def self.default_scope
    Entry.visible.with_directory_includes
  end

  # @param slug [String, nil] category slug from the request
  # @return [Category, nil] the category to filter by, if the slug names one
  def self.locate_category(slug)
    Category.find_by(slug:) if slug.present?
  end

  def initialize(params = {}, scope: EntryDirectoryQuery.default_scope)
    @params = params.to_h.symbolize_keys
    @scope = scope
    @category = EntryDirectoryQuery.locate_category(@params[:category])
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

  def filtered_scope
    apply_sort(filtered_entries).distinct
  end

  def filtered_entries
    scope
      .yield_self { |current| filter_by_query(current) }
      .yield_self { |current| filter_by_type(current) }
      .yield_self { |current| filter_by_level(current) }
      .yield_self { |current| filter_by_category(current) }
  end

  # Joins the FTS5 virtual table and orders by BM25 relevance (rank),
  # then by updated_at for ties
  def filter_by_query(current_scope)
    return current_scope if query.blank?

    current_scope
      .joins("JOIN entries_fts ON entries_fts.entry_id = entries.id")
      .where("entries_fts MATCH ?", FtsQuery.new(query, ignored_characters: IGNORED_SEARCH_CHARACTERS).to_s)
      .order("entries_fts.rank, entries.updated_at DESC")
  end

  def filter_by_type(current_scope)
    return current_scope if type.blank?
    return current_scope unless Entry::VALID_TYPES.key?(type)

    current_scope.where(entryable_type: Entry::VALID_TYPES[type])
  end

  def filter_by_level(current_scope)
    return current_scope if level.blank?
    return current_scope unless Entry.experience_levels.key?(level)

    current_scope.for_experience_level(level)
  end

  def filter_by_category(current_scope)
    return current_scope if category.blank?

    current_scope.joins(:categories).where(categories: { id: category.id })
  end

  def apply_sort(current_scope)
    sort_scope = SORT_SCOPES[sort]
    return default_order(current_scope) unless sort_scope

    current_scope.public_send(sort_scope)
  end

  # Most recently curated first, unless FTS5 relevance ordering should stand
  def default_order(current_scope)
    query.present? ? current_scope : current_scope.order(updated_at: :desc)
  end
end
