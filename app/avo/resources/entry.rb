# frozen_string_literal: true

class Avo::Resources::Entry < Avo::BaseResource
  self.title = :title
  self.includes = [ :entryable, :categories, :authors, :entry_reviews ]
  self.description = "Entry is the main resource. First create a Book/RubyGem/Blog/Newsletter/etc (any of 19 types), then create an Entry and link it."

  # Enable search on title and description
  self.search = {
    query: -> {
      sanitized_query = ActiveRecord::Base.sanitize_sql_like(params[:q])
      query.left_joins(:rich_text_description)
           .where("title LIKE ? OR action_text_rich_texts.body LIKE ?",
                  "%#{sanitized_query}%", "%#{sanitized_query}%")
           .distinct
    }
  }

  def fields
    field :id, as: :id, link_to_record: true

    # Basic information
    field :title, as: :text, required: true, sortable: true, help: "2-200 characters"
    field :description, as: :trix, required: true, help: "Rich text description of the resource"
    field :url, as: :text, required: true, help: "Primary URL link to the resource"

    # Polymorphic association to the specific entry type (Book, RubyGem, etc.)
    field :entryable, as: :belongs_to,
          polymorphic_as: :entryable,
          types: [
            ::Article,
            ::Blog,
            ::Book,
            ::Channel,
            ::Community,
            ::Course,
            ::DevelopmentEnvironment,
            ::Directory,
            ::Documentation,
            ::Framework,
            ::Job,
            ::Newsletter,
            ::Podcast,
            ::Product,
            ::RubyGem,
            ::TestingResource,
            ::Tool,
            ::Tutorial,
            ::Video
          ],
          help: "Select the type and specific record for this entry"

    # Image handling
    field :image, as: :file, help: "Upload an image/logo for the resource"
    field :image_url, as: :text, help: "Or provide an external image URL", hide_on: [ :index ]

    # Classification and status
    field :experience_level, as: :select,
          enum: {
            "all_levels" => "All Levels",
            "beginner" => "Beginner",
            "intermediate" => "Intermediate",
            "advanced" => "Advanced"
          },
          help: "Target experience level for this resource"

    field :status, as: :select,
          enum: {
            "pending" => "Pending",
            "approved" => "Approved",
            "rejected" => "Rejected"
          },
          required: true,
          sortable: true,
          help: "Curation workflow status"

    field :published, as: :boolean,
          help: "Controls public visibility"

    # Submitter information (for community submissions)
    field :submitter_name, as: :text,
          help: "Name of person who submitted this entry (optional for admin-created entries)",
          hide_on: [ :index ]

    field :submitter_email, as: :text,
          help: "Email of submitter (required only for pending status)",
          hide_on: [ :index ]

    # Tags
    field :tags, as: :tags,
          help: "Add tags to categorize this resource. Press Enter or comma to add each tag.",
          suggestions: -> {
            Entry.where.not(tags: nil)
                 .pluck(:tags)
                 .flatten
                 .compact
                 .uniq
                 .sort
          },
          enforce_suggestions: false,
          close_on_select: false

    # Slug
    field :slug, as: :text, readonly: true, help: "Auto-generated SEO-friendly URL"

    # Associations
    field :categories, as: :has_many, through: :categories_entries,
          help: "Assign multiple categories"

    field :authors, as: :has_many, through: :entries_authors,
          searchable: true,
          help: "Assign multiple authors"

    field :entry_reviews, as: :has_many,
          resource: Avo::Resources::EntryReview,
          help: "Review history (latest first)",
          scope: -> { query.order(created_at: :desc) }


    # Timestamps
    field :created_at, as: :date_time, readonly: true, sortable: true
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
  end

  def filters
    filter Avo::Filters::EntryStatusFilter
    filter Avo::Filters::EntryPublishedFilter
    filter Avo::Filters::EntryExperienceLevelFilter
    filter Avo::Filters::EntryTypeFilter
    filter Avo::Filters::EntryCategoryFilter
    filter Avo::Filters::EntryTagsFilter
  end

  def actions
    action Avo::Actions::ApproveEntries
    action Avo::Actions::RejectEntries
    action Avo::Actions::PublishEntries
    action Avo::Actions::UnpublishEntries
  end
end
