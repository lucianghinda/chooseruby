# frozen_string_literal: true

# Configures the admin form and listing for AuthorProposal records.
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
    proposal_fields
    proposed_change_fields
    review_fields
    timestamp_fields
    comparison_fields
  end

  def filters
    filter Avo::Filters::AuthorProposalStatusFilter
  end

  def actions
    action Avo::Actions::ApproveAuthorProposal
    action Avo::Actions::RejectAuthorProposal
  end

  private

  def proposal_fields
    submission_fields
    author_fields
    resource_fields
  end

  def submission_fields
    field :id, as: :id, link_to_record: true
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
  end

  def author_fields
    field :author, as: :belongs_to,
          help: "Existing author being edited (nil for new author proposals)",
          searchable: true
    field :author_name, as: :text,
          help: "Name for new author (only used when creating new author)",
          hide_on: [ :index ],
          visible: -> { Avo::AuthorProposalComparison.new(resource.record).new_author? }
  end

  def resource_fields
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
  end

  def proposed_change_fields
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
  end

  def review_fields
    field :admin_comment, as: :textarea,
          readonly: true,
          rows: 3,
          help: "Admin feedback on rejection",
          hide_on: [ :index ]
    field :reviewed_at, as: :date_time,
          readonly: true,
          help: "Timestamp when proposal was reviewed",
          hide_on: [ :index ]
  end

  def timestamp_fields
    field :created_at, as: :date_time,
          readonly: true,
          sortable: true,
          help: "When proposal was submitted"
    field :updated_at, as: :date_time,
          readonly: true,
          hide_on: [ :index ]
  end

  def comparison_fields
    field :proposal_type, as: :text,
          readonly: true,
          computed: true,
          hide_on: [ :edit, :new ],
          help: "Type of proposal" do
            Avo::AuthorProposalComparison.new(record).type
          end
    field :changes_summary, as: :textarea,
          readonly: true,
          computed: true,
          rows: 8,
          hide_on: [ :index, :edit, :new ],
          help: "Summary of proposed changes" do
            Avo::AuthorProposalComparison.new(record).summary
          end
  end
end
