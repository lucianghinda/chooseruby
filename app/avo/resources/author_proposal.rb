# frozen_string_literal: true

class Avo::Resources::AuthorProposal < Avo::BaseResource
  self.title = :id
  self.includes = [ :author, :matched_entry ]

  self.visible_on_sidebar = true

  # Enable search on submitter_email
  self.search = {
    query: -> {
      sanitized_query = ActiveRecord::Base.sanitize_sql_like(params[:q])
      query.where("submitter_email LIKE ?", "%#{sanitized_query}%")
    }
  }

  # Read only: the write routes are refused by Avo::AuthorProposalsController, so
  # the buttons that lead to them are not offered either.
  def render_index_controls(**)
    [ Avo::Resources::Controls::ActionsList.new(as_index_control: true) ]
  end

  def render_show_controls
    [ Avo::Resources::Controls::BackButton.new, Avo::Resources::Controls::ActionsList.new ]
  end

  def render_row_controls(item:)
    [ Avo::Resources::Controls::ShowButton.new(item: item) ]
  end

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
          visible: -> { resource.record.new_author_proposal? }

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
          help: "Type of proposal" do
            record.new_author_proposal? ? "New Author" : "Edit Existing Author"
          end

    field :changes_summary, as: :textarea,
          readonly: true,
          computed: true,
          rows: 8,
          hide_on: [ :index, :edit, :new ],
          help: "Summary of proposed changes" do
            author = record.author
            summary = []

            if record.new_author_proposal?
              summary << "Creating new author: #{record.author_name}"
            else
              # A proposal is a "new author" proposal precisely when it has no
              # author, so the association is always loaded on this branch.
              summary << "Editing author: #{author.name}"
            end

            if record.has_resource_proposal?
              if record.matched_entry?
                summary << "\nResource: Matched entry ##{record.matched_entry_id} - #{record.matched_entry.title}"
              else
                summary << "\nResource: Unmatched URL - #{record.resource_url}"
              end
            end

            if record.has_link_updates?
              summary << "\nLink Updates:"
              # `attribute`, not `field`: `field` is the Avo DSL method this
              # very block lives inside. The keys are whitelisted by
              # AuthorProposal::VALID_LINK_FIELDS.
              record.link_updates.each do |attribute, url|
                current_value = author&.public_send(attribute)
                summary << "  - #{attribute}: #{current_value.presence || '(blank)'} → #{url}"
              end
            end

            bio_text = record.bio_text
            if bio_text.present?
              current_bio = author&.bio
              summary << "\nBio:"
              summary << "  Current: #{current_bio.presence || '(blank)'}"
              summary << "  Proposed: #{bio_text}"
            end

            description_text = record.description_text
            if description_text.present?
              summary << "\nDescription:"
              # Author carries no description attribute, so a proposed
              # description never has a current value to compare against.
              summary << "  Current: (blank)"
              summary << "  Proposed: #{description_text}"
            end

            summary.join("\n")
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
