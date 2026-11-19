# frozen_string_literal: true

# Configures the admin form and listing for Author records.
class Avo::Resources::Author < Avo::BaseResource
  self.title = :name
  self.includes = []

  # Enable fuzzy search on name field
  self.search = {
    query: -> {
      sanitized_query = ActiveRecord::Base.sanitize_sql_like(params[:q])
      query.where("name LIKE ?", "%#{sanitized_query}%")
    }
  }

  # Authorization is explicitly disabled for now (set to nil in initializer)
  # This can be configured later with Pundit or other authorization systems

  def fields
    identity_fields
    avatar_fields
    link_fields
    entry_fields
    timestamp_fields
  end

  def filters
    filter Avo::Filters::AuthorStatusFilter
  end

  def actions
    action Avo::Actions::ApproveAuthors
  end

  private

  def identity_fields
    field :id, as: :id, link_to_record: true
    field :name, as: :text, required: true, sortable: true
    field :bio, as: :textarea, rows: 5
    field :status, as: :select, enum: ::Author.statuses, required: true, sortable: true
    field :slug, as: :text, readonly: true, help: "Auto-generated from name"
  end

  def avatar_fields
    field :avatar, as: :file, help: "Manual upload (fallback if no GitHub URL)"
    field :avatar_url, as: :text, readonly: true, help: "Auto-fetched from GitHub URL", hide_on: [ :index ]
  end

  def link_fields
    %i[github_url gitlab_url website_url bluesky_url ruby_social_url twitter_url linkedin_url youtube_url twitch_url blog_url].each do |link|
      field link, as: :text, hide_on: [ :index ]
    end
  end

  def entry_fields
    field :entries, as: :has_many, through: :entries_authors, hide_on: [ :index ]
  end

  def timestamp_fields
    field :created_at, as: :date_time, readonly: true, hide_on: [ :index ]
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
  end
end
