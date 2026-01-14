# frozen_string_literal: true

class Avo::Resources::AuthorProposal < Avo::BaseResource
  self.title = :id
  self.includes = [ :author, :matched_entry ]

  # Disable create/edit/delete - proposals are created via public forms only
  self.visible_on_sidebar = true

  # Enable search on submitter_email
  self.search = {
    query: -> {
      sanitized_query = ActiveRecord::Base.sanitize_sql_like(params[:q])
      query.where("submitter_email LIKE ?", "%#{sanitized_query}%")
    }
  }

  def fields
    field :id, as: :id, link_to_record: true

    # Status and submitter information
    field :status, as: :select,
          enum: ::AuthorProposal.statuses,
          required: true,
          sortable: true,
          help: "Proposal workflow status"

    field :submitter_email, as: :text,
          required: true,
          sortable: true,
          help: "Email of person who submitted this proposal"

    field :submitter_name, as: :text,
          help: "Name of submitter (optional)",
          hide_on: [ :index ]

    # Author associations
    field :author, as: :belongs_to,
          help: "Existing author being edited (nil for new author proposals)",
          searchable: true

    field :author_name, as: :text,
          help: "Name for new author (only used when creating new author)",
          hide_on: [ :index ],
          visible: ->(**kwargs) do
            record = kwargs[:record]
            record && record.respond_to?(:new_author_proposal?) && record.new_author_proposal?
          end

    # Resource proposal
    field :resource_url, as: :text,
          help: "Normalized URL for resource to associate",
          hide_on: [ :index ]

    field :original_resource_url, as: :text,
          readonly: true,
          help: "Original URL as entered by submitter",
          hide_on: [ :index ]

    field :matched_entry, as: :belongs_to,
          class_name: "Entry",
          help: "Entry matched from resource URL (if found)",
          searchable: true

    # Proposed changes
    field :link_updates, as: :code,
          readonly: true,
          language: "json",
          help: "JSON hash of proposed link changes",
          hide_on: [ :index ]

    field :bio_text, as: :textarea,
          readonly: true,
          rows: 5,
          help: "Proposed bio text (max 500 characters)",
          hide_on: [ :index ]

    field :description_text, as: :textarea,
          readonly: true,
          rows: 5,
          help: "Proposed description text",
          hide_on: [ :index ]

    field :submission_notes, as: :textarea,
          readonly: true,
          rows: 3,
          help: "Additional notes from submitter",
          hide_on: [ :index ]

    # Review information
    field :admin_comment, as: :textarea,
          readonly: true,
          rows: 3,
          help: "Admin feedback on rejection",
          hide_on: [ :index ]

    field :reviewed_at, as: :date_time,
          readonly: true,
          help: "Timestamp when proposal was reviewed",
          hide_on: [ :index ]

    # Timestamps
    field :created_at, as: :date_time,
          readonly: true,
          sortable: true,
          help: "When proposal was submitted"

    field :updated_at, as: :date_time,
          readonly: true,
          hide_on: [ :index ]

    # Computed fields for comparison view
    field :proposal_type, as: :text,
          readonly: true,
          computed: true,
          hide_on: [ :edit, :new ],
          help: "Type of proposal" do |record|
            unless record && record.respond_to?(:new_author_proposal?)
              ""
            else
              record.new_author_proposal? ? "New Author" : "Edit Existing Author"
            end
          end

    field :changes_summary, as: :textarea,
          readonly: true,
          computed: true,
          rows: 8,
          hide_on: [ :index, :edit, :new ],
          help: "Summary of proposed changes" do |record|
            unless record && record.respond_to?(:new_author_proposal?)
              ""
            else
              summary = []

              if record.new_author_proposal?
                summary << "Creating new author: #{record.author_name}"
              else
                summary << "Editing author: #{record.author&.name}"
              end

              if record.has_resource_proposal?
                if record.matched_entry?
                  summary << "\nResource: Matched entry ##{record.matched_entry_id} - #{record.matched_entry&.title}"
                else
                  summary << "\nResource: Unmatched URL - #{record.resource_url}"
                end
              end

              if record.has_link_updates?
                summary << "\nLink Updates:"
                record.link_updates.each do |field, url|
                  current_value = record.author&.send(field) if record.author
                  summary << "  - #{field}: #{current_value.presence || '(blank)'} → #{url}"
                end
              end

              if record.bio_text.present?
                current_bio = record.author&.bio if record.author
                summary << "\nBio:"
                summary << "  Current: #{current_bio.presence || '(blank)'}"
                summary << "  Proposed: #{record.bio_text}"
              end

              if record.description_text.present?
                current_desc = record.author&.description if record.author&.respond_to?(:description)
                summary << "\nDescription:"
                summary << "  Current: #{current_desc.presence || '(blank)'}"
                summary << "  Proposed: #{record.description_text}"
              end

              summary.join("\n")
            end
          end
  end

  def filters
    filter Avo::Filters::AuthorProposalStatusFilter
  end

  def actions
    action Avo::Actions::ApproveAuthorProposal
    action Avo::Actions::RejectAuthorProposal
  end
end
