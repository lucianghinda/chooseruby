# frozen_string_literal: true

# Finds literal prefix suggestions without treating user input as LIKE wildcards.
class EntrySuggestions
  attr_reader :query

  def initialize(query, categories: Category.all, entries: Entry.visible)
    @query = query.to_s.strip
    @category_scope = categories
    @entry_scope = entries
  end

  def searchable?
    query.length >= 2
  end

  def categories
    category_scope.where("name LIKE ?", pattern).order(:name).limit(5)
  end

  def entries
    entry_scope.where("title LIKE ?", pattern).order(updated_at: :desc).limit(5)
  end

  def types
    Entry::VALID_TYPES.keys.select do |type_slug|
      yield(type_slug).downcase.include?(query.downcase)
    end.first(4)
  end

  def popular_queries
    category_scope.order(:display_order, :name).limit(5).pluck(:name)
  end

  private

  attr_reader :category_scope, :entry_scope

  def pattern
    "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
  end
end
