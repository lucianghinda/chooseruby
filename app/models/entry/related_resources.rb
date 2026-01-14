# frozen_string_literal: true

class Entry::RelatedResources
  def initialize(entry, limit: 6)
    @entry = entry
    @limit = limit
  end

  def call
    return [] if categories.empty?

    category_ids = categories.pluck(:id)
    per_category = (limit.to_f / [ category_ids.length, 3 ].min).ceil

    related_entries = []
    already_collected_ids = [ entry.id ]

    category_ids.first(3).each do |category_id|
      remaining_needed = limit - related_entries.length
      break if remaining_needed <= 0

      entries_from_category = Entry
        .strict_loading
        .visible
        .includes(:categories, :rich_text_description)
        .joins(:categories_entries)
        .where(categories_entries: { category_id: category_id })
        .where.not(id: already_collected_ids)
        .distinct
        .recently_curated
        .limit([ per_category, remaining_needed ].min)
        .to_a

      related_entries.concat(entries_from_category)
      already_collected_ids.concat(entries_from_category.map(&:id))
    end

    if related_entries.length < limit && category_ids.length > 0
      remaining_needed = limit - related_entries.length

      additional_entries = Entry
        .strict_loading
        .visible
        .includes(:categories, :rich_text_description)
        .joins(:categories_entries)
        .where(categories_entries: { category_id: category_ids })
        .where.not(id: already_collected_ids)
        .distinct
        .recently_curated
        .limit(remaining_needed)
        .to_a

      related_entries.concat(additional_entries)
    end

    related_entries.first(limit)
  end

  private

  attr_reader :entry, :limit

  def categories
    entry.categories
  end
end
