# frozen_string_literal: true

# Entry model using Rails DelegatedTypes pattern
#
# Entry is the base model for all Ruby ecosystem entries (gems, books,
# courses, tutorials, articles, tools, podcasts, communities). It contains
# shared attributes while delegating type-specific attributes to delegated
# type models.
#
# Attributes:
#   - title: Entry title (required, 2-200 chars)
#   - description: Rich text description via ActionText (required)
#   - url: Primary URL link to the entry (required)
#   - image_url: External image URL (optional, alternative to ActiveStorage)
#   - experience_level: Difficulty level (enum: beginner, intermediate, advanced, all_levels)
#   - published: Visibility control (boolean, default: false)
#   - status: Curation workflow (enum: pending, approved, rejected)
#   - tags: JSON serialized array of tag strings
#   - slug: SEO-friendly URL identifier (auto-generated from title)
#   - entryable_type/entryable_id: Polymorphic association to delegated type
#   - submitter_name: Name of person submitting (optional, for community submissions)
#   - submitter_email: Email of person submitting (required for pending submissions)
#   - featured_at: Timestamp for featured/pinned entries (nullable)
#
# Associations:
#   - delegated_type :entryable (RubyGem, Book, Course, Tutorial, Article, Tool, Podcast, Community,
#                                 Newsletter, Blog, Video, Channel, Documentation, TestingResource,
#                                 DevelopmentEnvironment, JobBoard, Framework, Directory, Product)
#   - has_many :categories through :categories_entries
#   - has_many :authors through :entries_authors
#   - has_many :entry_reviews for review history tracking
#   - has_one_attached :image for uploaded images
#   - has_rich_text :description for rich text content
#
# Usage:
#   ruby_gem = RubyGem.create(gem_name: "rspec")
#   entry = Entry.create(
#     title: "RSpec",
#     description: "Testing framework for Ruby",
#     url: "https://rspec.info",
#     entryable: ruby_gem,
#     status: :approved,
#     published: true
#   )
#   entry.ruby_gem? # => true
#   entry.entryable.gem_name # => "rspec"
#
# == Schema Information
#
# Table name: entries
# Database name: primary
#
#  id               :integer          not null, primary key
#  description      :text
#  entryable_type   :string
#  experience_level :integer
#  featured_at      :datetime
#  image_url        :string
#  published        :boolean          default(FALSE), not null
#  slug             :string
#  status           :integer          default("pending"), not null
#  submitter_email  :string
#  submitter_name   :string
#  tags             :text
#  title            :string
#  url              :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  entryable_id     :integer
#
# Indexes
#
#  index_entries_on_entryable_type_and_entryable_id  (entryable_type,entryable_id)
#  index_entries_on_experience_level                 (experience_level)
#  index_entries_on_published                        (published)
#  index_entries_on_slug                             (slug) UNIQUE
#  index_entries_on_status                           (status)
#  index_entries_on_title                            (title)
#
class Entry < ApplicationRecord
  # DelegatedType - polymorphic association to type-specific models
  # Task 2.2: Updated to include all 19 types (8 existing + 11 new)
  delegated_type :entryable, types: %w[
    RubyGem
    Book
    Course
    Tutorial
    Article
    Tool
    Podcast
    Community
    Newsletter
    Blog
    Video
    Channel
    Documentation
    TestingResource
    DevelopmentEnvironment
    JobBoard
    Framework
    Directory
    Product
  ], optional: true

  # ActionText for rich text description
  has_rich_text :description

  # ActiveStorage for image uploads
  has_one_attached :image

  # JSON serialization for tags array
  serialize :tags, coder: JSON

  # Associations
  has_many :categories_entries, dependent: :destroy
  has_many :categories, through: :categories_entries

  has_many :entries_authors, dependent: :destroy
  has_many :authors, through: :entries_authors

  has_many :entry_reviews, dependent: :destroy

  # Constants
  # Task 2.3: Type parameter to entryable_type mapping for filtering
  VALID_TYPES = {
    "gems" => "RubyGem",
    "books" => "Book",
    "courses" => "Course",
    "tutorials" => "Tutorial",
    "articles" => "Article",
    "tools" => "Tool",
    "podcasts" => "Podcast",
    "communities" => "Community",
    "newsletters" => "Newsletter",
    "blogs" => "Blog",
    "videos" => "Video",
    "channels" => "Channel",
    "documentations" => "Documentation",
    "testing-resources" => "TestingResource",
    "development-environments" => "DevelopmentEnvironment",
    "job-boards" => "JobBoard",
    "frameworks" => "Framework",
    "directories" => "Directory",
    "products" => "Product"
  }.freeze

  # Orders entries by the popularity metric of their entryable, most popular first
  POPULARITY_ORDER_SQL = <<~SQL.squish
    COALESCE(
      CASE entries.entryable_type
        WHEN 'RubyGem' THEN (SELECT downloads_count FROM ruby_gems WHERE ruby_gems.id = entries.entryable_id)
        WHEN 'Community' THEN (SELECT member_count FROM communities WHERE communities.id = entries.entryable_id)
        WHEN 'Podcast' THEN (SELECT episode_count FROM podcasts WHERE podcasts.id = entries.entryable_id)
        ELSE NULL
      END,
      0
    ) DESC,
    entries.updated_at DESC
  SQL

  # Enums
  enum :experience_level, { beginner: 0, intermediate: 1, advanced: 2, all_levels: 3 }
  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  # Validations
  validates :title, presence: true, length: { minimum: 2, maximum: 200 }
  validates :url, presence: true,
                  format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
                           message: "must be a valid URL starting with http:// or https://" }
  validates :image_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
                                  message: "must be a valid URL starting with http:// or https://" },
                        allow_blank: true
  validates :slug, presence: true, uniqueness: true

  # Submitter validations for community submissions
  validates :submitter_email, presence: true, if: :pending?
  validates :submitter_email, format: { with: URI::MailTo::EMAIL_REGEXP,
                                       message: "must be a valid email address" },
                              allow_blank: true

  # Callbacks
  # A slug given on create is kept: the rubyandrailsinfo import carries the legacy
  # slugs so old URLs keep working, and looks records up by them.
  before_validation :generate_slug, if: -> { title.present? && (slug.blank? || (persisted? && title_changed?)) }
  after_save :sync_to_fts, if: :should_sync_fts?
  after_destroy :remove_from_fts

  # Scopes
  scope :published, -> { where(published: true) }
  scope :approved, -> { where(status: :approved) }
  scope :pending, -> { where(status: :pending) }
  scope :visible, -> { published.approved }
  scope :recently_curated, -> { order(updated_at: :desc) }
  scope :oldest_first, -> { reorder(updated_at: :asc) }
  scope :by_popularity, -> { reorder(Arel.sql(POPULARITY_ORDER_SQL)) }
  # Beginner, intermediate, advanced, all_levels, and an unset level last. The enum
  # stores integers, so ordering by the column is ordering by the level.
  scope :beginner_first, lambda {
    reorder(Arel.sql("entries.experience_level IS NULL"), experience_level: :asc, updated_at: :desc)
  }

  # Entries aimed at the given experience level, including those marked for all levels
  scope :for_experience_level, ->(level) { where(experience_level: experience_levels.values_at(level, "all_levels")) }
  scope :with_directory_includes, -> { preload(:entryable, :categories, :authors, :rich_text_description) }

  # Task 2.5: Featured scope - returns entries with featured_at set, ordered by most recent
  scope :featured, -> { where.not(featured_at: nil).order(featured_at: :desc) }

  # Type-specific scopes for existing 8 types
  scope :gems, -> { where(entryable_type: "RubyGem") }
  scope :books, -> { where(entryable_type: "Book") }
  scope :courses, -> { where(entryable_type: "Course") }
  scope :tutorials, -> { where(entryable_type: "Tutorial") }
  scope :articles, -> { where(entryable_type: "Article") }
  scope :tools, -> { where(entryable_type: "Tool") }
  scope :podcasts, -> { where(entryable_type: "Podcast") }
  scope :communities, -> { where(entryable_type: "Community") }

  # Task 2.4: Type-specific scopes for new 11 types
  scope :newsletters, -> { where(entryable_type: "Newsletter") }
  scope :blogs, -> { where(entryable_type: "Blog") }
  scope :videos, -> { where(entryable_type: "Video") }
  scope :channels, -> { where(entryable_type: "Channel") }
  scope :documentations, -> { where(entryable_type: "Documentation") }
  scope :testing_resources, -> { where(entryable_type: "TestingResource") }
  scope :development_environments, -> { where(entryable_type: "DevelopmentEnvironment") }
  scope :job_boards, -> { where(entryable_type: "JobBoard") }
  scope :frameworks, -> { where(entryable_type: "Framework") }
  scope :directories, -> { where(entryable_type: "Directory") }
  scope :products, -> { where(entryable_type: "Product") }

  class << self
    # Experience levels a submitter can pick from, as [label, value] pairs.
    # "all_levels" is excluded: it is what an entry gets when it suits everybody.
    def selectable_experience_levels
      experience_levels.keys.excluding("all_levels").map { |level| [ level.humanize, level ] }
    end

    # Returns entries that are ready for the public directory with eager-loaded associations.
    # Note: Renamed from 'featured' to avoid conflict with featured scope
    def for_homepage(limit_count = 6)
      visible.with_directory_includes.recently_curated.limit(limit_count)
    end
  end

  # Returns related resources from the same categories as this entry.
  # Distribution strategy: selects 2 resources from first category, 2 from second, 2 from third.
  # If fewer than 3 categories exist, distributes evenly or fills from available categories.
  # Excludes current entry, only returns visible entries, orders by recently curated (updated_at DESC).
  #
  # @param limit [Integer] Maximum number of related resources to return (default: 6)
  # @return [Array<Entry>] Array of related Entry objects
  #
  # Example:
  #   entry = Entry.find_by(slug: 'rspec')
  #   related = entry.related_resources(limit: 6)
  #   # => [#<Entry id: 2>, #<Entry id: 5>, ...]
  def related_resources(limit: 6)
    Entry::RelatedResources.new(self, limit: limit).call
  end

  # Returns the primary category for this entry
  # Queries the categories_entries join table for the category marked as primary
  # Falls back to the first category if no primary category is set
  #
  # @return [Category, nil] The primary category or nil if entry has no categories
  #
  # Example:
  #   entry = Entry.find_by(slug: 'rspec')
  #   entry.primary_category # => #<Category id: 1, name: "Testing">
  def primary_category
    categories
      .joins(:categories_entries)
      .where(categories_entries: { entry_id: id, is_primary: true })
      .first || categories.first
  end

  # Returns approved entry reviews for this entry
  # Provides convenient access to all approval reviews in the entry's history
  #
  # @return [ActiveRecord::Relation] EntryReview records with status: :approved
  #
  # Example:
  #   entry.approved_entry_reviews # => [#<EntryReview status: "approved">, ...]
  def approved_entry_reviews
    entry_reviews.where(status: :approved)
  end

  # Returns rejected entry reviews for this entry
  # Provides convenient access to all rejection reviews with feedback comments
  #
  # @return [ActiveRecord::Relation] EntryReview records with status: :rejected
  #
  # Example:
  #   entry.rejected_entry_reviews # => [#<EntryReview status: "rejected", comment: "...">, ...]
  def rejected_entry_reviews
    entry_reviews.where(status: :rejected)
  end

  def type_slug
    Entry::VALID_TYPES.key(entryable_type)
  end

  private

  # Generate URL-friendly slug from title
  # Ensures uniqueness by appending number if needed
  def generate_slug
    self.slug = Slug.new(title, taken_by: Entry.where.not(id: id)).to_s
  end

  # Determine if FTS sync should be triggered
  # Returns true if title, description, or tags changed
  # Note: For ActionText (description), we check if the rich_text_description association was previously changed
  def should_sync_fts?
    saved_change_to_title? ||
    saved_change_to_tags? ||
    previously_new_record? ||
    description_was_changed?
  end

  # Check if ActionText description was changed during this save
  # We check saved changes on the rich_text_description association
  def description_was_changed?
    rich_text_description&.previous_changes.present?
  end

  # Sync entry data to FTS5 virtual table for full-text search
  # Called after save when title, description, or tags changed
  def sync_to_fts
    fts_index.replace(
      title: title || "",
      description: description_plain_text,
      tags: tags.to_a.join(" ")
    )
  end

  # Remove entry from FTS5 virtual table
  # Called after destroy
  def remove_from_fts
    fts_index.delete
  end

  # The entry's row in the FTS5 virtual table backing entry search
  def fts_index
    FtsIndex.new(table: "entries_fts", key_column: "entry_id", key: id)
  end

  # Plain text of the ActionText description, as indexed by FTS5
  def description_plain_text
    return "" if description.blank?

    description.to_plain_text
  end
end
