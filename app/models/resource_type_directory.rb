# frozen_string_literal: true

# Supplies featured resources and visible category counts for one directory type.
class ResourceTypeDirectory
  def initialize(type)
    @entryable_type = Entry::VALID_TYPES.fetch(type)
  end

  def featured_entries
    entries.featured.with_directory_includes.limit(5)
  end

  def category_stats
    Category.strict_loading.joins(:entries).merge(entries)
      .select("categories.*, COUNT(entries.id) AS directory_resource_count")
      .group("categories.id")
      .map { |category| { category: category, count: category[:directory_resource_count] } }
      .sort_by { |stat| -stat[:count] }
  end

  private

  def entries
    Entry.strict_loading.visible.where(entryable_type: @entryable_type)
  end
end
