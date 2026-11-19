# frozen_string_literal: true

# The visible resources and community highlights presented on the home page.
class HomeDirectory
  def initialize
    @entries = Entry.strict_loading.visible.with_directory_includes
    @categories = Category.strict_loading.all
    @authors = Author.strict_loading.all
    @communities = Community.strict_loading.all
  end

  def statistics
    { resources: entries.count, categories: categories.count, authors: authors.count }
  end

  def featured_entries
    entries.recently_curated.limit(6)
  end

  def highlight_categories
    ordered_categories.limit(8)
  end

  def community_channels
    communities.order(member_count: :desc).limit(3)
  end

  def popular_queries
    ordered_categories.limit(5).pluck(:name)
  end

  def recent(type)
    entries.where(entryable_type: Entry::VALID_TYPES.fetch(type)).recently_curated.limit(4)
  end

  private

  attr_reader :entries, :categories, :authors, :communities

  def ordered_categories
    categories.order(:display_order, :name)
  end
end
