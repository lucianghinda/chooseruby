# frozen_string_literal: true

# Balances visible recommendations across categories, then fills unused slots.
class Entry::RelatedResources
  def initialize(entry, limit: 6)
    @entry = entry
    @limit = limit
    @results = []
  end

  def call
    reset
    return [] if category_ids.empty?

    collect_per_category
    append_from_categories(category_ids, maximum: remaining) if remaining.positive?
    results.first(limit)
  end

  private

  attr_reader :entry, :limit, :results, :category_ids

  def reset
    results.clear
    @category_ids = entry.categories.pluck(:id)
  end

  def collect_per_category
    category_ids.first(3).each do |category_id|
      available = remaining
      break if available <= 0

      append_from_categories(category_id, maximum: [ per_category, available ].min)
    end
  end

  def per_category
    (limit.to_f / [ category_ids.length, 3 ].min).ceil
  end

  def remaining
    limit - results.length
  end

  def collected_ids
    [ entry.id, *results.map(&:id) ]
  end

  def append_from_categories(selected_categories, maximum:)
    results.concat(candidate_scope.where(categories_entries: { category_id: selected_categories }).limit(maximum).to_a)
  end

  def candidate_scope
    Entry
      .visible
      .with_resource_includes
      .joins(:categories_entries)
      .where.not(id: collected_ids)
      .distinct
      .recently_curated
  end
end
