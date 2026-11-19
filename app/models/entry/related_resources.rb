# frozen_string_literal: true

# The entries a reader is likely to want next after the given entry.
#
# Resources are drawn from the entry's own categories: first an even share from
# each of the leading categories, then, if that did not fill the list, whatever
# else the entry's categories have to offer.
class Entry::RelatedResources
  # Number of leading categories the even share is taken from
  LEADING_CATEGORIES = 3

  def initialize(entry, limit: 6)
    @entry = entry
    @limit = limit
  end

  # @return [Array<Entry>] at most `limit` related entries, never the entry itself
  def call
    return [] if category_ids.empty?

    related = share_per_leading_category
    related.concat(fill_up(related))
    related.first(limit)
  end

  private

  attr_reader :entry, :limit

  def category_ids
    @category_ids ||= entry.categories.pluck(:id)
  end

  # An even share from each leading category, stopping once the list is full
  def share_per_leading_category
    category_ids.first(LEADING_CATEGORIES).each_with_object([]) do |category_id, collected|
      remaining = limit - collected.length
      break collected if remaining <= 0

      collected.concat(entries_in(category_id, excluding: collected, count: [ share, remaining ].min))
    end
  end

  # Whatever the entry's categories still have to offer, once the shares ran dry
  def fill_up(collected)
    remaining = limit - collected.length
    return [] if remaining <= 0

    entries_in(category_ids, excluding: collected, count: remaining)
  end

  def share
    (limit.to_f / [ category_ids.length, LEADING_CATEGORIES ].min).ceil
  end

  def entries_in(category, excluding:, count:)
    Entry
      .strict_loading
      .visible
      .includes(:categories, :rich_text_description, :entryable, { image_attachment: :blob }, authors: { avatar_attachment: :blob })
      .joins(:categories_entries)
      .where(categories_entries: { category_id: category })
      .where.not(id: [ entry.id, *excluding.map(&:id) ])
      .distinct
      .recently_curated
      .limit(count)
      .to_a
  end
end
