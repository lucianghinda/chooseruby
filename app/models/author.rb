# frozen_string_literal: true

# Author model representing Ruby community contributors
#
# Attributes:
#   - name: Author's full name (required, min 2 characters)
#   - bio: Brief biography (optional, max 500 characters)
#   - status: Approval status (pending: 0, approved: 1)
#   - slug: SEO-friendly URL identifier (auto-generated from name)
#   - avatar_url: URL to GitHub avatar (auto-fetched from github_url)
#   - github_url, gitlab_url, website_url, etc.: Social/web links (optional)
#
# Associations:
#   - has_many :entries through :entries_authors join table
#   - has_one_attached :avatar for manual avatar uploads
#
# Usage:
#   author = Author.create(name: "Yukihiro Matsumoto", github_url: "https://github.com/matz")
#   author.approved!
#   author.entries # Returns all associated entries
#
# == Schema Information
#
# Table name: authors
# Database name: primary
#
#  id              :integer          not null, primary key
#  avatar_url      :string
#  bio             :text
#  blog_url        :string
#  bluesky_url     :string
#  github_url      :string
#  gitlab_url      :string
#  linkedin_url    :string
#  name            :string           not null
#  ruby_social_url :string
#  slug            :string           not null
#  status          :integer          default("pending"), not null
#  twitch_url      :string
#  twitter_url     :string
#  website_url     :string
#  youtube_url     :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_authors_on_name    (name)
#  index_authors_on_slug    (slug) UNIQUE
#  index_authors_on_status  (status)
#
class Author < ApplicationRecord
  # Active Storage for manual avatar uploads
  has_one_attached :avatar

  # Associations
  has_many :entries_authors, dependent: :destroy
  has_many :entries, through: :entries_authors

  # Validations
  validates :name, presence: true, length: { minimum: 2 }
  validates :bio, length: { maximum: 500 }, allow_blank: true
  validates :slug, presence: true, uniqueness: true

  # URL validations - all optional but must be valid format if provided
  validates :github_url, :gitlab_url, :website_url, :bluesky_url,
            :ruby_social_url, :twitter_url, :linkedin_url, :youtube_url,
            :twitch_url, :blog_url,
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL starting with http:// or https://" },
            allow_blank: true

  # Status enum
  enum :status, { pending: 0, approved: 1 }, default: :pending

  # Callbacks
  before_validation :generate_slug, if: -> { name.present? && (slug.blank? || name_changed?) }
  after_save :fetch_github_avatar, if: :saved_change_to_github_url?
  after_save :sync_to_fts, if: :saved_change_to_name?
  after_destroy :remove_from_fts

  # Scopes
  scope :approved, -> { where(status: :approved) }
  scope :pending, -> { where(status: :pending) }

  private

  # Generate URL-friendly slug from name
  # Ensures uniqueness by appending number if needed
  def generate_slug
    base_slug = name.parameterize
    candidate_slug = base_slug
    counter = 1

    while Author.where(slug: candidate_slug).where.not(id: id).exists?
      candidate_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate_slug
  end

  # Fetch GitHub avatar URL when github_url changes
  # Uses update_column to avoid triggering callbacks and infinite loop
  def fetch_github_avatar
    return if github_url.blank?

    new_avatar_url = GithubAvatarService.call(github_url)
    update_column(:avatar_url, new_avatar_url) if new_avatar_url.present?
  end

  # Sync author data to FTS5 virtual table for full-text search
  # Called after save when name changed
  def sync_to_fts
    # Handle nil or empty name
    name_text = name.to_s

    # Delete existing FTS row first (FTS5 tables don't support proper upserts)
    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array([
        "DELETE FROM authors_fts WHERE author_id = ?",
        id
      ])
    )

    # Insert new FTS row
    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array([
        "INSERT INTO authors_fts (author_id, name) VALUES (?, ?)",
        id,
        name_text
      ])
    )
  end

  # Remove author from FTS5 virtual table
  # Called after destroy
  def remove_from_fts
    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array([
        "DELETE FROM authors_fts WHERE author_id = ?",
        id
      ])
    )
  end
end
