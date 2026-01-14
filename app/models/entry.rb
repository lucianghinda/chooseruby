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
#                                 DevelopmentEnvironment, Job, Framework, Directory, Product)
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
    Job
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
    "jobs" => "Job",
    "frameworks" => "Framework",
    "directories" => "Directory",
    "products" => "Product"
  }.freeze

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
  before_validation :generate_slug, if: -> { title.present? && (slug.blank? || title_changed?) }
  after_save :sync_to_fts, if: :should_sync_fts?
  after_destroy :remove_from_fts

  # Scopes
  scope :published, -> { where(published: true) }
  scope :approved, -> { where(status: :approved) }
  scope :pending, -> { where(status: :pending) }
  scope :visible, -> { published.approved }
  scope :recently_curated, -> { order(updated_at: :desc) }
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
  scope :jobs, -> { where(entryable_type: "Job") }
  scope :frameworks, -> { where(entryable_type: "Framework") }
  scope :directories, -> { where(entryable_type: "Directory") }
  scope :products, -> { where(entryable_type: "Product") }

  class << self
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
    base_slug = title.parameterize
    candidate_slug = base_slug
    counter = 1

    while Entry.where(slug: candidate_slug).where.not(id: id).exists?
      candidate_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate_slug
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
    # If rich_text_description was saved in this transaction, it changed
    rich_text_description&.previous_changes&.any? || false
  end

  # Sync entry data to FTS5 virtual table for full-text search
  # Called after save when title, description, or tags changed
  def sync_to_fts
    # Extract plain text from ActionText description
    description_text = if description.present?
                        description.to_plain_text
    else
                        ""
    end

    # Convert tags array to space-separated string
    tags_text = tags.to_a.join(" ")

    # Delete existing FTS row first (FTS5 tables don't support proper upserts)
    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array([
        "DELETE FROM entries_fts WHERE entry_id = ?",
        id
      ])
    )

    # Insert new FTS row
    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array([
        "INSERT INTO entries_fts (entry_id, title, description, tags) VALUES (?, ?, ?, ?)",
        id,
        title || "",
        description_text,
        tags_text
      ])
    )
  end

  # Remove entry from FTS5 virtual table
  # Called after destroy
  def remove_from_fts
    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array([
        "DELETE FROM entries_fts WHERE entry_id = ?",
        id
      ])
    )
  end
end
