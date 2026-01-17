# frozen_string_literal: true

# Category model representing entry classifications
#
# Categories organize entries into logical groupings like "Testing",
# "Authentication", "Background Jobs", etc. Entries can belong to multiple
# categories via a many-to-many relationship.
#
# Attributes:
#   - name: Category name (required, unique, 2-100 chars)
#   - slug: SEO-friendly URL identifier (auto-generated from name)
#   - description: Brief category description (optional, max 500 chars)
#   - icon: Icon identifier for future icon support (optional)
#   - display_order: Manual sorting order (default: 0)
#
# Associations:
#   - has_many :entries through :categories_entries join table
#
# Usage:
#   category = Category.create(name: "Testing", description: "Testing frameworks and tools")
#   category.entries # Returns all entries in this category
#   category.entries_count # Returns count of visible entries
#   category.featured_entries # Returns up to 3 featured visible entries
# == Schema Information
#
# Table name: categories
# Database name: primary
#
#  id            :integer          not null, primary key
#  description   :text
#  display_order :integer          default(0), not null
#  icon          :string
#  name          :string           not null
#  slug          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_categories_on_name  (name) UNIQUE
#  index_categories_on_slug  (slug) UNIQUE
#
class Category < ApplicationRecord
  # Associations
  has_many :categories_entries, dependent: :destroy
  has_many :entries, through: :categories_entries

  # Validations
  validates :name, presence: true, uniqueness: true, length: { minimum: 2, maximum: 100 }
  validates :slug, presence: true, uniqueness: true
  validates :description, length: { maximum: 500 }, allow_blank: true

  # Callbacks
  before_validation :generate_slug, if: -> { name.present? && (slug.blank? || name_changed?) }

  # Returns the count of visible (published and approved) entries in this category
  #
  # @return [Integer] Count of visible entries
  #
  # Example:
  #   category = Category.find_by(slug: 'testing')
  #   category.entries_count # => 12
  def entries_count
    entries.visible.count
  end

  # Returns featured visible entries for this category
  #
  # @param limit [Integer] Maximum number of featured entries to return (default: 3)
  # @return [ActiveRecord::Relation] Featured visible entries ordered by recently curated
  #
  # Example:
  #   category = Category.find_by(slug: 'testing')
  #   category.featured_entries # => [#<Entry id: 1>, #<Entry id: 2>, #<Entry id: 3>]
  #   category.featured_entries(limit: 5) # => Returns up to 5 featured entries
  def featured_entries(limit: 3)
    entries
      .visible
      .joins(:categories_entries)
      .where(categories_entries: { category_id: id, is_featured: true })
      .with_directory_includes
      .recently_curated
      .limit(limit)
  end

  private

  # Generate URL-friendly slug from name
  # Ensures uniqueness by appending number if needed
  def generate_slug
    base_slug = name.parameterize
    candidate_slug = base_slug
    counter = 1

    while Category.where(slug: candidate_slug).where.not(id: id).exists?
      candidate_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate_slug
  end
end
