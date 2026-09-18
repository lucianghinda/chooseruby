# frozen_string_literal: true

# Finds entries related to a given entry by shared categories: prefers spreading
# results across the entry's top 3 categories, then backfills from any of its
# categories if that didn't reach the requested limit.
class Entry::RelatedResources
  def initialize(entry, limit: 6)
    @entry = entry
    @limit = limit
  end

  def call
    return [] if categories.empty?

    related = related_by_top_categories
    related.concat(related_by_any_category(related)) if related.length < limit
    related.first(limit)
  end

  private

  attr_reader :entry, :limit

  def categories
    entry.categories
  end

  def category_ids
    @category_ids ||= categories.pluck(:id)
  end

  def base_query(category_ids:, exclude_ids:)
    Entry
      .visible
      .with_card_includes
      .joins(:categories_entries)
      .where(categories_entries: { category_id: category_ids })
      .where.not(id: exclude_ids)
      .distinct
      .recently_curated
  end

  def related_by_top_categories
    per_category = (limit.to_f / [ category_ids.length, 3 ].min).ceil

    category_ids.first(3).each_with_object([]) do |category_id, related|
      remaining = limit - related.length
      next if remaining <= 0

      related.concat(fetch_from_category(category_id, exclude_ids: [ entry.id, *related.map(&:id) ], take: [ per_category, remaining ].min))
    end
  end

  def fetch_from_category(category_id, exclude_ids:, take:)
    base_query(category_ids: category_id, exclude_ids: exclude_ids).limit(take).to_a
  end

  def related_by_any_category(already_related)
    remaining = limit - already_related.length

    base_query(category_ids: category_ids, exclude_ids: [ entry.id, *already_related.map(&:id) ])
      .limit(remaining)
      .to_a
  end
end
