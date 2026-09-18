# frozen_string_literal: true

# Finds visible recommendations for one resource without repeating the current entry.
class ResourceRecommendations
  def initialize(entry)
    @entry = entry
  end

  def by_author
    return Entry.none if @entry.authors.blank?

    Entry.visible.with_resource_includes.joins(:entries_authors)
      .where(entries_authors: { author_id: @entry.author_ids })
      .where.not(id: @entry.id).distinct.recently_curated.limit(5)
  end

  def by_topic
    return [] if @entry.categories.empty?

    related = @entry.related_resources(limit: 5)
    remaining = 5 - related.size
    return related unless remaining.positive?

    (related + same_type(related, remaining)).first(5)
  end

  private

  def same_type(related, remaining)
    Entry.visible.with_resource_includes.where(entryable_type: @entry.entryable_type)
      .where.not(id: [ @entry.id, *related.map(&:id) ])
      .recently_curated.limit(remaining).to_a
  end
end
